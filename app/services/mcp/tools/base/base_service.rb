# frozen_string_literal: true

module Mcp
  module Tools
    module Base
      class BaseService
        include Mcp::Tools::Concerns::GovernanceContainerResolver

        ID_FIELD_PATTERN = /(?:\A|_)i?id\z/

        # override this method when renaming tools
        def self.tool_aliases
          []
        end

        def initialize(name:)
          @name = name
        end

        def tool_aliases
          self.class.tool_aliases
        end

        def set_cred(**)
          raise NoMethodError
        end

        def description
          raise NoMethodError
        end

        def input_schema
          raise NoMethodError
        end

        def execute(request: nil, params: nil) # rubocop: disable Lint/UnusedMethodArgument -- request param to match Mcp::Tools::Base::ApiTool
          args = reject_omitted_arguments(params[:arguments])
          validate_arguments!(args)
          perform(args)
        rescue ArgumentError => e
          Response.error("Validation error: #{e.message}", reason: Response::Reason::BAD_REQUEST)
        rescue Mcp::Tools::Concerns::ResourceFinder::ResourceNotFoundError => e
          Response.error("Tool execution failed: #{e.message}", reason: Response::Reason::NOT_FOUND)
        rescue Mcp::Tools::Concerns::ResourceFinder::ResourceForbiddenError, ::Gitlab::Access::AccessDeniedError => e
          Response.error("Tool execution failed: #{e.message}", reason: Response::Reason::UNAUTHORIZED)
        rescue StandardError => e
          ::Gitlab::ErrorTracking.track_exception(e, mcp_tool: name)
          Response.error("Tool execution failed: #{e.message}")
        end

        def to_h
          result = {
            name: name,
            description: description,
            inputSchema: input_schema
          }

          result[:icons] = [icons.first] if icons.present?

          tool_annotations = annotations
          result[:annotations] = tool_annotations if tool_annotations.present?

          result
        end

        def icons
          IconConfig.gitlab_icons
        end

        def available?(_current_user)
          true
        end

        def toolset
          Toolsets::UNASSIGNED
        end

        def unlisted?
          false
        end

        # Returns tool annotations (e.g., readOnly flag for governance controls).
        # Tools should override this method to provide custom annotations.
        # Returns empty hash by default, which will be omitted from to_h output.
        def annotations
          {}
        end

        protected

        def perform(_arguments = {}, _query = {})
          raise NoMethodError
        end

        private

        attr_reader :name, :current_user, :access_token

        # Values a client sends for a field it doesn't mean behave like an omitted key: `null`, `""`, zero or
        # negative IDs, and `0` on integer fields with a minimum of 1.
        def reject_omitted_arguments(arguments)
          return arguments unless arguments.respond_to?(:reject)

          arguments.reject { |key, value| omitted_value?(key, value) }
        end

        def omitted_value?(key, value)
          return true if value.nil? || value == ''
          return true if zero_filled_id?(key, value)

          value == 0 && schema_minimum_one_field?(key)
        end

        def zero_filled_id?(key, value)
          value.is_a?(Integer) && value <= 0 && key.to_s.match?(ID_FIELD_PATTERN) &&
            arguments_where_zero_is_a_value.exclude?(key.to_s)
        end

        # Override for ID arguments where 0 means something, such as `milestone_id: 0` to remove a milestone.
        def arguments_where_zero_is_a_value
          []
        end

        def schema_minimum_one_field?(key)
          props = input_schema[:properties] || {}
          prop = props[key.to_sym] || props[key.to_s]
          prop.is_a?(Hash) && prop[:type] == 'integer' && prop[:minimum]&.>=(1)
        end

        def validate_arguments!(arguments)
          schemer = JSONSchemer.schema(input_schema)
          json_arguments = arguments ? arguments.deep_stringify_keys : {}
          errors = schemer.validate(json_arguments).to_a

          return if errors.empty?

          validations = errors.map do |error|
            case error['type']
            when 'required'
              "#{error['details']['missing_keys'].first} is missing"
            when 'maxItems'
              field = error['data_pointer'].sub(%r{^/}, '')
              "#{field} cannot contain more than #{error['schema']['maxItems']} items"
            when 'enum'
              field = error['data_pointer'].sub(%r{^/}, '')
              "Invalid #{field}: '#{error['data']}'. Must be one of: #{error['schema']['enum'].join(', ')}"
            else
              field = error['data_pointer'].sub(%r{^/}, '')
              "#{field} is invalid"
            end
          end.uniq

          raise ArgumentError, validations.join(', ')
        end

        def input_schema_pagination_params
          {
            per_page: {
              type: 'integer',
              description: 'Number of items to list per page.',
              minimum: 1
            },
            page: {
              type: 'integer',
              description: 'Page number to retrieve.',
              minimum: 1
            }
          }
        end

        def version
          raise NoMethodError
        end
      end
    end
  end
end
