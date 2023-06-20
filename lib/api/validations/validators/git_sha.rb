# frozen_string_literal: true

module API
  module Validations
    module Validators
      class GitSha < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          sha = params[attr_name]

          return if Commit::EXACT_COMMIT_SHA_PATTERN.match?(sha)

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "should be a valid sha"
          )
        end
      end
    end
  end
end
