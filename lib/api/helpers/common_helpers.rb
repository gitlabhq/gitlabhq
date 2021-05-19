# frozen_string_literal: true

module API
  module Helpers
    module CommonHelpers
      def convert_parameters_from_legacy_format(params)
        params.tap do |params|
          assignee_id = params.delete(:assignee_id)

          if assignee_id.present?
            params[:assignee_ids] = [assignee_id]
          end
        end
      end

      # Grape v1.3.3 no longer automatically coerces an Array
      # type to an empty array if the value is nil.
      def coerce_nil_params_to_array!
        keys_to_coerce = params_with_array_types

        params.each do |key, val|
          params[key] = Array(val) if val.nil? && keys_to_coerce.include?(key)
        end
      end

      def params_with_array_types
        options[:route_options][:params].map do |key, val|
          param_type = val[:type]
          # Search for parameters with Array types (e.g. "[String]", "[Integer]", etc.)
          if param_type =~ %r(\[\w*\])
            key
          end
        end.compact.to_set
      end

      def endpoint_id
        "#{request.request_method} #{route.origin}"
      end
    end
  end
end

API::Helpers::CommonHelpers.prepend_mod_with('API::Helpers::CommonHelpers')
