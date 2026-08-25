# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class SaveMergeRequestService < Base::AggregatedService
        include Gitlab::Utils::Override

        CREATE_PARAMS = ::API::Helpers::MergeRequestsHelpers.create_merge_request_mcp_params.freeze
        CREATE_REQUIRED_PARAMS = %i[title source_branch target_branch].freeze
        UPDATE_PARAMS = ::API::Helpers::MergeRequestsHelpers.update_merge_request_mcp_params.freeze
        UPDATE_ONLY_PARAMS = (UPDATE_PARAMS - CREATE_PARAMS - %i[merge_request_iid]).freeze

        FORWARDED_KEY = { project_id: :id, assignees: :assignee_ids, reviewers: :reviewer_ids }.freeze

        register_version '0.1.0', {
          description: <<~DESC.strip,
            Create or update a merge request in a GitLab project.

            merge_request_iid alone decides the operation. Omitting it always creates a new
            merge request; provide it to update an existing one.
            - Create: omit merge_request_iid. title, source_branch, and target_branch are required.
            - Update: provide merge_request_iid.

            Use state_event (close or reopen) to change an existing merge request's state.
          DESC
          annotations: {
            readOnlyHint: false,
            destructiveHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              project_id: {
                type: 'string',
                description: 'ID or full path of the project.'
              },
              merge_request_iid: {
                type: 'integer',
                description: 'Internal ID of the merge request. Provide to update an existing ' \
                  'merge request; omit to create a new one.'
              },
              title: {
                type: 'string',
                description: 'Title of the merge request. Required when creating.'
              },
              description: {
                type: 'string',
                description: 'Description of the merge request.'
              },
              source_branch: {
                type: 'string',
                description: 'Source branch. Required when creating.'
              },
              target_branch: {
                type: 'string',
                description: 'Target branch. Required when creating.'
              },
              target_project_id: {
                type: 'integer',
                description: 'Target project ID. Defaults to the source project. Applies when creating.'
              },
              labels: {
                type: 'array',
                items: { type: 'string' },
                description: 'Label names. Replaces all existing labels.'
              },
              add_labels: {
                type: 'array',
                items: { type: 'string' },
                description: 'Label names to add. Applies when updating.'
              },
              remove_labels: {
                type: 'array',
                items: { type: 'string' },
                description: 'Label names to remove. Applies when updating.'
              },
              assignees: {
                type: 'array',
                items: { type: 'string' },
                description: 'Usernames to assign. Alternative to assignee_ids; provide one. ' \
                  'Pass an empty array to remove all assignees.'
              },
              assignee_ids: {
                type: 'array',
                items: { type: 'integer' },
                description: 'User IDs to assign. Alternative to assignees; provide one.'
              },
              reviewers: {
                type: 'array',
                items: { type: 'string' },
                description: 'Usernames to request review from. Alternative to reviewer_ids; provide one. ' \
                  'Pass an empty array to remove all reviewers.'
              },
              reviewer_ids: {
                type: 'array',
                items: { type: 'integer' },
                description: 'User IDs to request review from. Alternative to reviewers; provide one.'
              },
              milestone_id: {
                type: 'integer',
                description: 'Milestone ID to assign.'
              },
              milestone: {
                type: 'string',
                description: 'Title of a project or ancestor-group milestone to assign. ' \
                  'Mutually exclusive with milestone_id.'
              },
              remove_source_branch: {
                type: 'boolean',
                description: 'Remove the source branch when the merge request is merged.'
              },
              squash: {
                type: 'boolean',
                description: 'Squash commits into a single commit when merging.'
              },
              state_event: {
                type: 'string',
                enum: %w[close reopen],
                description: 'State transition to perform. Applies when updating.'
              },
              discussion_locked: {
                type: 'boolean',
                description: 'Lock the merge request discussion. Applies when updating.'
              },
              allow_collaboration: {
                type: 'boolean',
                description: 'Allow commits from members who can merge to the target branch. Applies when updating.'
              }
            },
            required: ['project_id']
          }
        }

        override :tool_name
        def self.tool_name
          'save_merge_request'
        end

        override :tool_aliases
        def self.tool_aliases
          %w[create_merge_request update_merge_request]
        end

        protected

        override :perform_default
        def perform_default(arguments = {})
          transformed_args = transform_arguments(arguments)
          operation = transformed_args[:operation]
          params[:arguments] = transformed_args.except(:operation)
          tool = select_tool(transformed_args)

          raise Mcp::Tools::Manager::ToolNotFoundError, self.class.tool_name unless tool

          execute_tool_with_enhanced_response(tool, operation, ignored_params(arguments, operation))
        end

        override :transform_arguments
        def transform_arguments(args)
          args = resolve_usernames(normalize_project_id(args))
          operation = detect_operation(args)

          transformed = case operation
                        when :create then args.slice(*CREATE_PARAMS)
                        when :update then args.slice(*UPDATE_PARAMS)
                        end

          transformed.merge(operation: operation)
        end

        override :select_tool
        def select_tool(args)
          name = :"#{args[:operation]}_merge_request"
          tools.find { |tool| tool.name.to_sym == name }
        end

        private

        def execute_tool_with_enhanced_response(tool, operation, ignored)
          response = tool.execute(request:, params:)
          action = "Merge request #{operation}d successfully via #{self.class.tool_name}."
          action += " Ignored params not valid for #{operation}: #{ignored.join(', ')}." if ignored.any?

          enhance_response_with_operation(
            response,
            operation: operation,
            tool_name: :"#{operation}_merge_request",
            action_description: action
          )
        end

        def ignored_params(arguments, operation)
          allowed = operation == :update ? UPDATE_PARAMS : CREATE_PARAMS
          arguments.keys.map(&:to_sym).reject { |key| allowed.include?(FORWARDED_KEY.fetch(key, key)) }
        end

        def normalize_project_id(args)
          return args unless args.key?(:project_id)

          args.merge(id: args[:project_id]).except(:project_id)
        end

        def resolve_usernames(args)
          args = args.dup
          resolve_people(args, :assignees, :assignee_ids)
          resolve_people(args, :reviewers, :reviewer_ids)
          args
        end

        def resolve_people(args, usernames_key, ids_key)
          return unless args.key?(usernames_key)

          raise ArgumentError, "Provide #{usernames_key} or #{ids_key}, not both." if args.key?(ids_key)

          args[ids_key] = user_ids_for(args.delete(usernames_key))
        end

        def user_ids_for(usernames)
          usernames = Array(usernames).map(&:to_s)
          return [] if usernames.empty?

          found = ::User.by_username(usernames).index_by { |user| user.username.downcase }

          unless usernames.all? { |name| found.key?(name.downcase) }
            raise ArgumentError, 'One or more usernames could not be resolved.'
          end

          usernames.map { |name| found[name.downcase].id }
        end

        def invoked_via_alias?(operation)
          params[:name].to_s == "#{operation}_merge_request"
        end

        def detect_operation(args)
          if args[:merge_request_iid].present?
            if invoked_via_alias?(:create)
              raise ArgumentError,
                'create_merge_request does not accept merge_request_iid. Remove it to create a new ' \
                  'merge request, or use save_merge_request to update an existing one.'
            end

            return :update
          end

          if invoked_via_alias?(:update)
            raise ArgumentError,
              'update_merge_request requires merge_request_iid. Provide it to update an existing ' \
                'merge request, or use save_merge_request to create one.'
          end

          update_only = UPDATE_ONLY_PARAMS.select { |key| args.key?(key) }
          if update_only.any?
            raise ArgumentError,
              "These fields only apply when updating: #{update_only.join(', ')}. " \
                'Provide merge_request_iid to update, or remove them to create a merge request.'
          end

          if CREATE_REQUIRED_PARAMS.any? { |key| args[key].blank? }
            raise ArgumentError,
              'Cannot determine operation. Provide merge_request_iid to update an existing merge request, ' \
                "or #{CREATE_REQUIRED_PARAMS.join(', ')} to create a new one."
          end

          :create
        end
      end
    end
  end
end
