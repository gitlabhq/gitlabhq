# frozen_string_literal: true

module Mcp
  module Tools
    class SearchService < AggregatedService
      include Gitlab::Utils::StrongMemoize
      extend ::Gitlab::Utils::Override

      # description and input_schema
      # rely upon the database and are defined
      # as methods for lazy loading
      register_version '0.1.0', {}

      override :tool_name
      def self.tool_name
        'search'
      end

      override :tool_aliases
      def self.tool_aliases
        ['gitlab_search']
      end

      override :description
      def description
        description_parts.join("\n")
      end

      override :input_schema
      def input_schema
        {
          type: 'object',
          properties: properties,
          required: %w[scope search],
          additionalProperties: false
        }
      end

      override :annotations
      def annotations
        { readOnlyHint: true }
      end

      private

      def properties
        state_description = <<~DESC.strip
          Filter results by state. Available states:
          - Issues: #{Issue.available_states.keys.join(', ')}
          - Merge requests: #{MergeRequest.available_states.keys.join(', ')})

          Only applies to issues and merge_requests scopes.
        DESC

        scope_description = <<~DESC.strip
          Specify the type of content to search for. Available content types vary by search context:

          - GitLab instance: #{::Search::Scope.global.join(', ')}
          - Group: #{::Search::Scope.group.join(', ')}
          - Project: #{::Search::Scope.project.join(', ')}

          Examples:
          - Use "issues" to search for issues
          - Use "merge_requests" to search for merge requests
          - Use "blobs" to search code files
          - Use "notes" to search comments across different content
          - Use "commits" to search commit messages
        DESC

        order_by_description = <<~DESC.strip
          Specify how to order search results.
          - Allowed values: created_at only
          - Default behavior:
            * Basic search: sorted by created_at descending
            * Advanced search: sorted by relevance
        DESC

        sort_description = <<~DESC.strip
          Specify the sort direction for results. Works with order_by parameter
          - Allowed values: asc, desc
          - Default: desc
        DESC

        properties_hash = {
          scope: {
            type: 'string',
            description: scope_description
          },
          search: {
            type: 'string',
            description: 'The term to search for'
          },
          group_id: {
            type: 'string',
            description: 'Provide to search within a group. The ID or URL-encoded path of the group'
          },
          project_id: {
            type: 'string',
            description: 'Provide to search within a project. The ID or URL-encoded path of the project'
          },
          state: {
            type: 'string',
            description: state_description
          },
          confidential: {
            type: 'boolean',
            description: 'Filter results by confidentiality. Available for issues scope; other scopes are ignored.'
          },
          order_by: {
            type: 'string',
            description: order_by_description
          },
          sort: {
            type: 'string',
            description: sort_description
          }
        }

        properties_hash.merge(input_schema_pagination_params)
      end

      def description_parts
        [
          'Search across GitLab with automatic selection of the best available search method.',
          '',
          "**Capabilities:** #{search_capabilities.join(', ')}",
          '',
          '**Syntax Examples:**',
          "- Basic: \"bug fix\", \"filename:*.rb\", \"extension:js\""
        ]
      end

      def search_capabilities
        ['basic (keywords, file filters)']
      end

      override :select_tool
      def select_tool(args)
        tool_name = case search_level(args).as_sym
                    when :global
                      :gitlab_search_in_instance
                    when :group
                      :gitlab_search_in_group
                    when :project
                      :gitlab_search_in_project
                    else
                      raise ArgumentError, "Unsupported search level: #{search_level(args).as_sym}"
                    end

        tools.find { |tool| tool.name.to_sym == tool_name }
      end

      override :transform_arguments
      def transform_arguments(args)
        case search_level(args).as_sym
        when :group
          args.merge(id: args[:group_id])
        when :project
          args.merge(id: args[:project_id])
        else
          args
        end
      end

      def search_level(args)
        strong_memoize_with(:search_level, args) do
          ::Search::Level.new(args)
        end
      end

      # overridden in EE
      def advanced_search_enabled?
        false
      end

      # overridden in EE
      def exact_code_search_enabled?
        false
      end
    end
  end
end

Mcp::Tools::SearchService.prepend_mod
