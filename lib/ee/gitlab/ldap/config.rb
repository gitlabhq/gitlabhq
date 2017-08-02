module EE
  module Gitlab
    module LDAP
      module Config
        extend ActiveSupport::Concern

        class_methods do
          def enabled_extras?
            enabled? && ::License.feature_available?(:ldap_extras)
          end
        end
      end
    end
  end
end
