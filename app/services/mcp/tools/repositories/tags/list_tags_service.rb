# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      module Tags
        class ListTagsService < Base::CustomService
          extend ::Gitlab::Utils::Override
          include ::Gitlab::Utils::StrongMemoize
          include ::Mcp::Tools::Concerns::UrlParser

          DEFAULT_FIRST = 20
          MAX_FIRST = 100
          SORT = 'updated_desc'
          PARENT_PARAMS = %i[url project_id].freeze

          register_version '0.1.0', {
            description: 'List tags in a GitLab project, most recently updated first. Identify the project ' \
              'with exactly one of url or project_id. When search is given, a tag whose name matches it ' \
              'exactly is listed first. Returns each tag name and its tip commit, not ' \
              'the tag message, commit diff, or file contents. When metadata.has_next_page is true, ' \
              'pass metadata.end_cursor as after to fetch the next page.',
            annotations: {
              readOnlyHint: true
            },
            input_schema: {
              type: 'object',
              required: [],
              properties: {
                url: {
                  type: 'string',
                  description: 'GitLab URL of the project.'
                },
                project_id: {
                  type: 'string',
                  description: 'ID or full path of the project.'
                },
                search: {
                  type: 'string',
                  description: 'Filter tags by name. Supports ^ to anchor the start, $ to anchor the end, ' \
                    'and * as a wildcard.'
                },
                after: {
                  type: 'string',
                  description: 'Cursor for forward pagination. Use metadata.end_cursor from the ' \
                    'previous response.'
                },
                first: {
                  type: 'integer',
                  minimum: 1,
                  maximum: MAX_FIRST,
                  description: "Number of tags to return. Default is #{DEFAULT_FIRST}, " \
                    "maximum is #{MAX_FIRST}."
                }
              }
            }
          }

          override :authorize!
          def authorize!(params)
            super
          rescue ::Gitlab::Access::AccessDeniedError
            raise ArgumentError, "Project '#{project_path(arguments_from(params))}' not found or inaccessible"
          end

          protected

          def auth_ability
            :read_code
          end

          def auth_target(params)
            project(arguments_from(params))
          end

          override :perform_default
          def perform_default(arguments = {})
            arguments ||= {}

            tags, has_next_page = fetch_page(arguments)

            data = {
              tags: tags.map { |tag| tag_entry(tag, arguments) },
              metadata: {
                has_next_page: has_next_page,
                end_cursor: has_next_page ? tags.last.name : nil
              }
            }

            formatted_content = [{ type: 'text', text: Gitlab::Json.generate(data) }]
            ::Mcp::Tools::Base::Response.success(formatted_content, data)
          end

          private

          def arguments_from(params)
            params[:arguments] || {}
          end

          # Keyed on the resolved path, not the instance, so authorize! and perform_default
          # can only share a lookup when they identify the same project.
          def project(arguments)
            path = project_path(arguments)

            strong_memoize_with(:project, path) do
              find_project!(path)
            end
          end

          def project_path(arguments)
            strong_memoize_with(:project_path, arguments) do
              provided = PARENT_PARAMS.select { |key| arguments[key].present? }

              raise ArgumentError, 'Provide exactly one of: url or project_id' unless provided.one?

              if provided.first == :project_id
                arguments[:project_id].to_s
              else
                parsed = parse_parent_url(arguments[:url])

                raise ArgumentError, 'The url must point to a project, not a group' unless parsed[:type] == :project

                parsed[:path]
              end
            end
          end

          def fetch_page(arguments)
            return [[], false] unless project(arguments).repo_exists?

            first = first(arguments)
            finder = ::TagsFinder.new(project(arguments).repository, sort: SORT, search: arguments[:search],
              page_token: arguments[:after], per_page: first)

            if arguments[:search].present?
              tags = drop_through_cursor(finder.execute, arguments[:after])

              [tags.first(first), tags.size > first]
            else
              tags = finder.execute(gitaly_pagination: true)

              # Gitaly returns at most `first` tags, so a full page is the only hint that more may
              # follow. The page after an exact multiple is legitimately empty.
              [tags, tags.size == first]
            end
          rescue ::Gitlab::Git::InvalidPageToken
            raise invalid_cursor(arguments[:after])
          end

          # A search loads and filters every tag in Ruby, so the cursor is applied here, not by Gitaly.
          def drop_through_cursor(tags, after)
            return tags if after.blank?

            index = tags.index { |tag| tag.name == after }
            raise invalid_cursor(after) unless index

            tags.drop(index + 1)
          end

          def invalid_cursor(after)
            ArgumentError.new("Invalid after cursor: '#{after}'")
          end

          # The schema validates first before perform runs, so this only fills in a default.
          def first(arguments)
            arguments[:first] || DEFAULT_FIRST
          end

          def tag_entry(tag, arguments)
            raw_commit = tag.dereferenced_target

            {
              name: tag.name,
              commit: raw_commit && { sha: raw_commit.id,
                                      title: ::Commit.new(raw_commit, project(arguments)).title }
            }
          end
        end
      end
    end
  end
end
