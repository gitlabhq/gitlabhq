module EE
  module Gitlab
    module LDAP
      module Sync
        class AdminUsers
          attr_reader :provider, :proxy

          def self.execute(proxy)
            self.new(proxy).update_permissions
          end

          def initialize(proxy)
            @provider = proxy.provider
            @proxy = proxy
          end

          def update_permissions
            return if admin_group.empty?

            admin_group_member_dns = proxy.dns_for_group_cn(admin_group)
            current_admin_users = ::User.admins.with_provider(provider)
            verified_admin_users = []

            # Verify existing admin users and add new ones.
            admin_group_member_dns.each do |member_dn|
              user = ::Gitlab::LDAP::User.find_by_uid_and_provider(member_dn, provider)

              if user.present?
                user.admin = true
                user.save
                verified_admin_users << user
              else
                Rails.logger.debug do
                  <<-MSG.strip_heredoc.tr("\n", ' ')
                    #{self.class.name}: User with DN `#{member_dn}` should have admin
                    access but there is no user in GitLab with that identity.
                    Membership will be updated once the user signs in for the first time.
                  MSG
                end
              end
            end

            # Revoke the unverified admins.
            current_admin_users.each do |user|
              unless verified_admin_users.include?(user)
                user.admin = false
                user.save
              end
            end
          end

          private

          def admin_group
            proxy.adapter.config.admin_group
          end
        end
      end
    end
  end
end
