module EE
  module Gitlab
    module Auth
      module LDAP
        module Sync
          class ExternalUsers < Sync::Users
            private

            def attribute
              :external
            end

            def member_dns
              external_groups.flat_map do |group|
                proxy.dns_for_group_cn(group)
              end.uniq
            end

            def external_groups
              proxy.adapter.config.external_groups
            end
          end
        end
      end
    end
  end
end
