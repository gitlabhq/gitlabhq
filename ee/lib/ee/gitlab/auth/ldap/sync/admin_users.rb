module EE
  module Gitlab
    module Auth
      module LDAP
        module Sync
          class AdminUsers < Sync::Users
            private

            def attribute
              :admin
            end

            def member_dns
              return [] if admin_group.empty?

              proxy.dns_for_group_cn(admin_group)
            end

            def admin_group
              proxy.adapter.config.admin_group
            end
          end
        end
      end
    end
  end
end
