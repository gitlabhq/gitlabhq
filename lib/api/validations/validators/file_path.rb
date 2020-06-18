# frozen_string_literal: true

module API
  module Validations
    module Validators
      class FilePath < Grape::Validations::Base
        def validate_param!(attr_name, params)
          path = params[attr_name]

          Gitlab::Utils.check_path_traversal!(path)
        rescue ::Gitlab::Utils::PathTraversalAttackError
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)],
                                               message: "should be a valid file path"
        end
      end
    end
  end
end
