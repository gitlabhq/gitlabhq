# frozen_string_literal: true

module Ci
  module PipelineCreation
    module Inputs
      def self.parse_params(params)
        return params unless params.is_a?(Hash)

        params.to_hash.transform_values do |value| # `to_hash` to avoid `ActiveSupport::HashWithIndifferentAccess`
          next value unless value.is_a?(String)

          begin
            Gitlab::Json.parse(value) # convert to number, boolean, array
          rescue JSON::ParserError
            value # we treat the value as-is as it's likely a string like 'blue-green'.
          end
        end.deep_symbolize_keys # `deep_symbolize_keys` because Interpolator requires
      end
    end
  end
end
