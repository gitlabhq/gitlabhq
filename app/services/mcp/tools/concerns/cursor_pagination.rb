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
          snake_case: { after: 'page_info.end_cursor', before: 'page_info.start_cursor' }
        }.freeze

        # first and last are bounded page sizes, after and before are opaque cursor strings.
        PAGE_SIZE_PARAMS = %i[first last].freeze
        FORWARD_PARAMS = %i[first after].freeze

        class << self
          # Returns input_schema properties for the requested params, so every tool describes
          # and bounds its pagination the same way. Splat the result into the properties hash.
          #
          # Pass default_page_size: nil when the tool sends the page size on to GraphQL
          # untouched, so the schema does not promise a default the tool never applies.
          def input_schema_params(
            items:, params: FORWARD_PARAMS, prefix: nil, applies_to: nil,
            default_page_size: DEFAULT_PAGE_SIZE, cursor_style: :camel_case)
            unsupported = params - SUPPORTED_PARAMS
            raise ArgumentError, "Unsupported cursor pagination params: #{unsupported.join(', ')}" if unsupported.any?

            # The same for every param in one call, so build them once instead of per param.
            bounds = page_size_bounds(default_page_size)
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

          def page_size_bounds(default_page_size)
            return "Max #{MAX_PAGE_SIZE}." unless default_page_size

            "Default #{default_page_size}, max #{MAX_PAGE_SIZE}."
          end

          def sentences(*parts)
            parts.compact.join(' ')
          end
        end

        private

        # Applies the default the schema documents. The including tool must expose params.
        def paginated_first
          params[:first] || DEFAULT_PAGE_SIZE
        end
      end
    end
  end
end
