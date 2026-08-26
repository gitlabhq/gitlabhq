# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      class AddCommitService < Base::GraphqlService
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        PartialEditError = Class.new(StandardError)

        override :tool_aliases
        def self.tool_aliases
          ['create_commit']
        end

        register_version '0.1.0', {
          description: 'Add a commit with one or more file actions to a project branch.',
          annotations: {
            readOnlyHint: false,
            destructiveHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the project. Provide this or project_id.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Provide this or url.'
              },
              branch: {
                type: 'string',
                description: 'Name of the branch to commit into.'
              },
              start_branch: {
                type: 'string',
                description: 'Name of the branch from which to create a new branch. ' \
                  'Required when branch does not exist yet.'
              },
              commit_message: {
                type: 'string',
                description: 'Commit message.'
              },
              actions: {
                type: 'array',
                description: 'File actions to commit as a single batch.',
                minItems: 1,
                maxItems: 100,
                items: {
                  type: 'object',
                  properties: {
                    action: {
                      type: 'string',
                      enum: %w[create update delete move chmod],
                      description: 'Action to perform.'
                    },
                    file_path: {
                      type: 'string',
                      description: 'Full path to the file.'
                    },
                    content: {
                      type: 'string',
                      description: 'File content for create, update, or move actions. ' \
                        'Mutually exclusive with old_str and new_str.'
                    },
                    old_str: {
                      type: 'string',
                      description: 'Existing text to replace in an update action. Requires new_str.'
                    },
                    new_str: {
                      type: 'string',
                      description: 'Replacement text for old_str in an update action.'
                    },
                    previous_path: {
                      type: 'string',
                      description: 'Original file path for a move action.'
                    },
                    encoding: {
                      type: 'string',
                      enum: %w[text base64],
                      description: 'Encoding of the file content. Defaults to text.'
                    },
                    last_commit_id: {
                      type: 'string',
                      description: 'Last commit that touched the file, used for optimistic concurrency.'
                    },
                    execute_filemode: {
                      type: 'boolean',
                      description: 'Whether the file is executable.'
                    }
                  },
                  required: %w[action file_path],
                  additionalProperties: false
                }
              }
            },
            required: %w[branch commit_message actions]
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Repositories::AddCommitTool
        end

        def perform_v0_1_0(arguments)
          arguments = arguments.with_indifferent_access
          validation_error = validate_project_identifier(arguments)
          return validation_error if validation_error

          execute_graphql_tool(arguments.merge(actions: expand_partial_edits(arguments)))
        rescue PartialEditError => error
          Base::Response.error(error.message)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end

        private

        def validate_project_identifier(arguments)
          return if arguments[:project_id].present? ^ arguments[:url].present?

          Base::Response.error('Provide exactly one of project_id or url')
        end

        def partial?(action)
          action.key?(:old_str) || action.key?(:new_str)
        end

        def expand_partial_edits(arguments)
          actions = arguments[:actions].map(&:with_indifferent_access)
          partial_actions = actions.select { |action| partial?(action) }
          return actions if partial_actions.empty?

          validate_partial_actions!(partial_actions)
          # rubocop:disable Rails/Pluck -- partial_actions is a plain Array of Hashes, not an ActiveRecord relation
          contents = read_blob_contents(arguments, partial_actions.map { |action| action[:file_path] }.uniq)
          # rubocop:enable Rails/Pluck

          actions.map { |action| partial?(action) ? expand_partial_action(action, contents) : action }
        end

        def validate_partial_actions!(actions)
          actions.each do |action|
            unless action[:action] == 'update'
              raise PartialEditError, 'Partial edits are only supported for update actions'
            end

            unless action.key?(:old_str) && action.key?(:new_str)
              raise PartialEditError, 'Provide both old_str and new_str for a partial edit'
            end

            raise PartialEditError, 'old_str cannot be empty' if action[:old_str].empty?
            raise PartialEditError, 'Provide either content or old_str and new_str, not both' if action.key?(:content)

            if action[:encoding].present? && action[:encoding] != 'text'
              raise PartialEditError, 'Partial edits require text encoding'
            end
          end
        end

        def read_blob_contents(arguments, paths)
          result = read_blobs(arguments, paths)

          if result[:isError]
            raise PartialEditError, 'Could not read the file(s) needed to expand the partial edit; ' \
              "check the project and ref. Error: #{result.dig(:content, 0, :text)}"
          end

          result[:structuredContent].dig('repository', 'blobs', 'nodes').to_h do |node|
            [node['path'], node['rawTextBlob']]
          end
        end

        def read_blobs(arguments, paths)
          Mcp::Tools::Repositories::BlobsTool.new(
            current_user: current_user,
            params: arguments.slice(:project_id, :url).merge(
              paths: paths,
              ref: partial_edit_ref(arguments)
            )
          ).execute
        end

        # The mutation commits onto `branch` when it already exists, ignoring `start_branch`
        # entirely; start_branch only seeds a *new* branch. Mirror that here so old_str is
        # matched against the same content the commit will actually be based on.
        def partial_edit_ref(arguments)
          return arguments[:branch] if arguments[:start_branch].blank?
          return arguments[:branch] if resolve_project(arguments).repository.branch_exists?(arguments[:branch])

          arguments[:start_branch]
        end

        def resolve_project(arguments)
          if arguments[:project_id].present?
            find_project!(arguments[:project_id])
          else
            parsed_url = parse_parent_url(arguments[:url])
            raise ArgumentError, 'URL must identify a project' unless parsed_url[:type] == :project

            find_project!(parsed_url[:path])
          end
        end

        def expand_partial_action(action, contents)
          content = contents[action[:file_path]]
          raise PartialEditError, "File '#{action[:file_path]}' was not found" unless contents.key?(action[:file_path])

          if content.nil?
            raise PartialEditError, "File '#{action[:file_path]}' is binary and cannot be partially edited"
          end

          occurrences = content.scan(action[:old_str]).length
          raise PartialEditError, "old_str was not found in '#{action[:file_path]}'" if occurrences == 0

          if occurrences > 1
            raise PartialEditError,
              "old_str is ambiguous in '#{action[:file_path]}'; provide more surrounding context"
          end

          updated_content = content.sub(action[:old_str]) { action[:new_str] }
          contents[action[:file_path]] = updated_content
          action.except(:old_str, :new_str).merge(content: updated_content)
        end
      end
    end
  end
end
