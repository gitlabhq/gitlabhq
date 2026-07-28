# frozen_string_literal: true

module Mcp
  module Tools
    module Wikis
      class ListWikiPagesTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder

        DEFAULT_PAGE_SIZE = 20

        PROJECT_QUERY = load_graphql('wikis/list_project_wiki_pages.query.graphql')

        register_version VERSIONS[:v0_1_0], {}

        def execute
          return wiki_unavailable_error if group_request? && !group_wikis_supported?

          super
        end

        def graphql_operation
          group_request? ? group_query : PROJECT_QUERY
        end

        def build_variables
          {
            fullPath: full_path,
            first: params[:first] || DEFAULT_PAGE_SIZE,
            after: params[:after]
          }.compact
        end

        def operation_name
          group_request? ? 'group' : 'project'
        end

        protected

        def build_variables_0_1_0
          build_variables
        end

        private

        def container_type
          if params[:project_id].present? && params[:group_id].blank?
            :project
          elsif params[:group_id].present? && params[:project_id].blank?
            :group
          else
            raise ArgumentError, 'Provide exactly one of project_id or group_id.'
          end
        end

        def full_path
          group_request? ? find_group!(params[:group_id]).full_path : find_project!(params[:project_id]).full_path
        end

        def group_request?
          container_type == :group
        end

        # Overridden in EE to enable group wiki support.
        def group_wikis_supported?
          false
        end

        # Overridden in EE to supply the group wiki query document.
        def group_query
          nil
        end

        def wiki_unavailable_error
          ::Mcp::Tools::Base::Response.error(
            "This wiki isn't available. It may be disabled, not available on the current plan, or you " \
              "don't have permission to view it. If you expected access, check the wiki's settings or " \
              "contact an administrator."
          )
        end

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)

          processed_result = super

          return processed_result if processed_result[:isError]

          data = processed_result[:structuredContent]

          return wiki_unavailable_error if wiki_unavailable?(data)

          wiki_pages = extract_wiki_pages(data)
          return wiki_unavailable_error unless wiki_pages

          page_info = extract_page_info(data)
          structured_content = {
            items: wiki_pages,
            metadata: {
              # `end_cursor` is present only when more pages exist, so it doubles as the
              # "more pages" signal.
              end_cursor: page_info['endCursor']
            }
          }

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end

        def extract_wiki_pages(structured_content)
          nodes = structured_content&.dig('wikiPages', 'nodes')
          nodes&.select { |node| node['slug'].present? }
               &.map { |node| node.slice('title', 'slug', 'webUrl') }
        end

        def extract_page_info(structured_content)
          structured_content&.dig('wikiPages', 'pageInfo') || {}
        end

        # A present-but-null `wikiPages` means the container resolved but `:read_wiki` was denied,
        # which is distinct from a licensed-but-empty wiki (`wikiPages: { nodes: [] }`).
        def wiki_unavailable?(data)
          data&.key?('wikiPages') && data['wikiPages'].nil?
        end

        def resource_not_found?(result)
          result['errors'].blank? && result.dig('data', operation_name).nil?
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error(
            "#{container_type.to_s.capitalize} not found, or you do not have access to it."
          )
        end
      end
    end
  end
end

Mcp::Tools::Wikis::ListWikiPagesTool.prepend_mod
