module EE
  module Ci
    module Variable
      extend ActiveSupport::Concern

      prepended do
        validates(
          :environment_scope,
          presence: true,
          format: { with: ::Gitlab::Regex.environment_scope_regex,
                    message: ::Gitlab::Regex.environment_scope_regex_message }
        )

        before_save :verify_updating_environment_scope

        private

        def verify_updating_environment_scope
          return unless environment_scope_changed?

          unless project.feature_available?(:variable_environment_scope)
            # Ignore the changes to this value to mimic CE behaviour
            self.environment_scope = environment_scope_was
          end
        end
      end
    end
  end
end
