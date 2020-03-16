# frozen_string_literal: true

module API
  module Helpers
    module CustomValidators
      class FilePath < Grape::Validations::Base
        def validate_param!(attr_name, params)
          path = params[attr_name]

          Gitlab::Utils.check_path_traversal!(path)
        rescue StandardError
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)],
                                               message: "should be a valid file path"
        end
      end

      class GitSha < Grape::Validations::Base
        def validate_param!(attr_name, params)
          sha = params[attr_name]

          return if Commit::EXACT_COMMIT_SHA_PATTERN.match?(sha)

          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)],
                                                message: "should be a valid sha"
        end
      end

      class Absence < Grape::Validations::Base
        def validate_param!(attr_name, params)
          return if params.respond_to?(:key?) && !params.key?(attr_name)

          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:absence)
        end
      end

      class IntegerNoneAny < Grape::Validations::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return if value.is_a?(Integer) ||
              [IssuableFinder::FILTER_NONE, IssuableFinder::FILTER_ANY].include?(value.to_s.downcase)

          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)],
                                               message: "should be an integer, 'None' or 'Any'"
        end
      end

      class ArrayNoneAny < Grape::Validations::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return if value.is_a?(Array) ||
              [IssuableFinder::FILTER_NONE, IssuableFinder::FILTER_ANY].include?(value.to_s.downcase)

          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)],
                                               message: "should be an array, 'None' or 'Any'"
        end
      end
    end
  end
end

Grape::Validations.register_validator(:file_path, ::API::Helpers::CustomValidators::FilePath)
Grape::Validations.register_validator(:git_sha, ::API::Helpers::CustomValidators::GitSha)
Grape::Validations.register_validator(:absence, ::API::Helpers::CustomValidators::Absence)
Grape::Validations.register_validator(:integer_none_any, ::API::Helpers::CustomValidators::IntegerNoneAny)
Grape::Validations.register_validator(:array_none_any, ::API::Helpers::CustomValidators::ArrayNoneAny)
