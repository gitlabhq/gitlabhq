module EE
  module Ci
    module Variable
      extend ActiveSupport::Concern

      module VariableClassMethods
        def key_uniqueness_scope
          %i[project_id environment_scope]
        end
      end

      prepended do
        singleton_class.prepend(VariableClassMethods)

        validates(
          :environment_scope,
          presence: true,
          format: { with: ::Gitlab::Regex.environment_scope_regex,
                    message: ::Gitlab::Regex.environment_scope_regex_message }
        )

        validate :validate_updating_environment_scope

        private

        def validate_updating_environment_scope
          return unless environment_scope_changed?

          unless project.feature_available?(:variable_environment_scope)
            errors.add(:environment_scope, 'is not enabled for this project')
          end
        end
      end
    end
  end
end
