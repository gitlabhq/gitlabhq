# frozen_string_literal: true

module API
  module Validations
    module Validators
      # TODO Delete this validator along with the packages_conan_allow_empty_username_channel feature flag
      # Use a regexp validator in its place: regexp: Gitlab::Regex.conan_recipe_user_channel_regex
      # https://gitlab.com/gitlab-org/gitlab/-/issues/346006
      class PackagesConanUserChannel < Grape::Validations::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          if Feature.enabled?(:packages_conan_allow_empty_username_channel)
            unless Gitlab::Regex.conan_recipe_user_channel_regex.match?(value)
              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: 'is invalid'
              )
            end
          else
            unless Gitlab::Regex.conan_recipe_component_regex.match?(value)
              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: 'is invalid'
              )
            end
          end
        end
      end
    end
  end
end
