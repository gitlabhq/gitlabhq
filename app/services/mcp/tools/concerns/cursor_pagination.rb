# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module CursorPagination
        DEFAULT_PAGE_SIZE = 20
        MIN_PAGE_SIZE = 1
        MAX_PAGE_SIZE = 100

        # Every relay argument we expose, with the sentence that describes it. SUPPORTED_PARAMS
        # comes from these keys so the accepted list cannot drift from the described list.
        PARAM_TEXTS = {
          first: 'Number of %{items} to return after the cursor (forward pagination).',
          last: 'Number of %{items} to return before the cursor (backward pagination).',
          after: 'Cursor for forward pagination of %{items}. Use %{cursor_location} from a previous response.',
          before: 'Cursor for backward pagination of %{items}. Use %{cursor_location} from a previous response.'
        }.freeze
        SUPPORTED_PARAMS = PARAM_TEXTS.keys.freeze

        # Most tools pass GraphQL's pageInfo straight through. A tool that flattens the response
        # into its own snake_case shape (like get_pipeline's page_info) passes cursor_style:
        # :snake_case so the description tells callers where to actually find the cursor.
        CURSOR_LOCATIONS = {
          camel_case: { after: 'pageInfo.endCursor', before: 'pageInfo.startCursor' },
          snake_case: { after: 'page_info.end_cursor', before: 'page_info.start_cursor' },
          metadata: { after: 'metadata.end_cursor', before: 'metadata.start_cursor' }
        }.freeze

        # first and last are bounded page sizes, after and before are opaque cursor strings.
        PAGE_SIZE_PARAMS = %i[first last].freeze
        FORWARD_PARAMS = %i[first after].freeze

        class << self
          # Returns input_schema properties for the requested params, so every tool describes
          # and bounds its pagination the same way. Splat the result into the properties hash.
          def input_schema_params(
            items:, params: FORWARD_PARAMS, prefix: nil, applies_to: nil,
            cursor_style: :camel_case)
            unsupported = params - SUPPORTED_PARAMS
            raise ArgumentError, "Unsupported cursor pagination params: #{unsupported.join(', ')}" if unsupported.any?

            bounds = "Max #{MAX_PAGE_SIZE}."
            condition = "Applies only when #{applies_to}." if applies_to
            cursor_locations = CURSOR_LOCATIONS.fetch(cursor_style)

            params.index_with { |param| param_schema(param, items, bounds, condition, cursor_locations) }
              .transform_keys { |param| :"#{prefix}#{param}" }
          end

          private

          def param_schema(param, items, bounds, condition, cursor_locations)
            text = format(PARAM_TEXTS.fetch(param), items: items, cursor_location: cursor_locations[param])

            return { type: 'string', description: sentences(text, condition) } unless page_size?(param)

            {
              type: 'integer',
              description: sentences(text, bounds, condition),
              minimum: MIN_PAGE_SIZE,
              maximum: MAX_PAGE_SIZE
            }
          end

          def page_size?(param)
            PAGE_SIZE_PARAMS.include?(param)
          end

          def sentences(*parts)
            parts.compact.join(' ')
          end
        end

        private

        def default_page_size
          DEFAULT_PAGE_SIZE
        end

        def paginated_first
          params[:first] || default_page_size
        end

        # When both first and last are present, forward wins. GraphQL rejects both.
        def resolve_pagination_direction
          if params[:last].present? && !params[:first].present?
            { last: params[:last], before: params[:before] }
          else
            { first: paginated_first, after: params[:after] }
          end
        end
      end
    end
  end
end
