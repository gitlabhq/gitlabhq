module Ci
  module HasEnvironmentScope
    extend ActiveSupport::Concern

    prepended do
      validates(
        :environment_scope,
        presence: true,
        format: { with: ::Gitlab::Regex.environment_scope_regex,
                  message: ::Gitlab::Regex.environment_scope_regex_message }
      )
    end

    def environment_scope=(new_environment_scope)
      super(new_environment_scope.to_s.strip)
    end
  end
end
