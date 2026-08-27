# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class ListMergeRequestsTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser
        include Mcp::Tools::Concerns::CursorPagination

        PARENT_PARAMS = %i[url project_id].freeze

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('merge_requests/list_merge_requests.query.graphql'),
          operation_name: 'project'
        }

        def build_variables
          people = scoped_people

          {
            fullPath: project_full_path,
            authorUsername: people[:author],
            assigneeUsername: people[:assignee],
            reviewerUsername: people[:reviewer],
            state: params[:state],
            milestoneTitle: params[:milestone],
            labelName: split_labels(params[:labels]),
            search: params[:search],
            first: paginated_first,
            after: params[:after]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def project_full_path
          @project_full_path ||= resolve_project.full_path
        end

        def resolve_project
          provided = PARENT_PARAMS.select { |key| params[key].present? }

          raise ArgumentError, 'Provide exactly one of: url or project_id' unless provided.one?

          identifier = provided.first == :url ? parse_parent_url(params[:url])[:path] : params[:project_id]

          find_parent_by_id_or_path!(:project, identifier)
        end

        # The GraphQL mergeRequests connection has no `scope` argument, so
        # created_by_me/assigned_to_me/review_requested are emulated through the
        # username filters. An explicit username always wins for its own field.
        def scoped_people
          author = params[:author_username]
          assignee = params[:assignee_username]
          reviewer = params[:reviewer_username]

          case params[:scope]
          when 'created_by_me'
            author ||= current_user&.username
          when 'assigned_to_me'
            assignee ||= current_user&.username
          when 'review_requested'
            reviewer ||= current_user&.username
          end

          { author: author, assignee: assignee, reviewer: reviewer }
        end

        # Splitting on ',' is lossless because BaseLabel forbids commas in label titles.
        def split_labels(labels)
          return if labels.blank?

          labels.split(',').map(&:strip).reject(&:blank?).presence
        end

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)

          processed_result = super
          return processed_result if processed_result[:isError]

          merge_requests = processed_result[:structuredContent]['mergeRequests']
          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless merge_requests

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(merge_requests) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, merge_requests)
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error(
            'Project not found or inaccessible'
          )
        end
      end
    end
  end
end
