# frozen_string_literal: true

module API
  module Validations
    module Validators
      class FilePath < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          options = @option.is_a?(Hash) ? @option : {}
          path_allowlist = options.fetch(:allowlist, [])
          path = params[attr_name]
          Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!(path, path_allowlist)
        rescue StandardError
          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "should be a valid file path"
          )
        end
      end
    end
  end
end
