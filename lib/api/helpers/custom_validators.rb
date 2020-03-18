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

      class GitRef < Grape::Validations::Base
        # There are few checks that a Git reference should pass through to be valid reference.
        # The link contains some rules that have been added to this validator.
        # https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
        # We have skipped some checks that are optional and can be skipped for exception.
        # We also check for control characters, More info on ctrl chars - https://ruby-doc.org/core-2.7.0/Regexp.html#class-Regexp-label-Character+Classes
        INVALID_CHARS = Regexp.union('..', '\\', '@', '@{', ' ', '~', '^', ':', '*', '?', '[', /[[:cntrl:]]/).freeze
        GIT_REF_LENGTH = (1..1024).freeze

        def validate_param!(attr_name, params)
          revision = params[attr_name]

          return unless invalid_character?(revision)

          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)],
                                               message: 'should be a valid reference path'
        end

        private

        def invalid_character?(revision)
          revision.nil? ||
            revision.start_with?('-') ||
            revision.end_with?('.') ||
            GIT_REF_LENGTH.exclude?(revision.length) ||
            INVALID_CHARS.match?(revision)
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
Grape::Validations.register_validator(:git_ref, ::API::Helpers::CustomValidators::GitRef)
