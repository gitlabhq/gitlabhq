module EE
  module Gitlab
    module Auth
      module LDAP
        module Config
          extend ActiveSupport::Concern

          class_methods do
            def group_sync_enabled?
              enabled? && ::License.feature_available?(:ldap_group_sync)
            end
          end
        end
      end
    end
  end
end
