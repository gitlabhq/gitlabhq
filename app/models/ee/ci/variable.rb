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
      end
    end
  end
end
