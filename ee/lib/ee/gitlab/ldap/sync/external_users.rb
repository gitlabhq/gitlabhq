module EE
  module Gitlab
    module LDAP
      module Sync
        class ExternalUsers
          attr_reader :provider, :proxy

          def self.execute(proxy)
            self.new(proxy).update_permissions
          end

          def initialize(proxy)
            @provider = proxy.provider
            @proxy = proxy
          end

          def update_permissions
            return unless external_groups.any?

            current_external_users = ::User.external.with_provider(provider)
            verified_external_users = []

            external_groups.each do |group|
              group_dns = proxy.dns_for_group_cn(group)

              group_dns.each do |member_dn|
                user = ::Gitlab::LDAP::User.find_by_uid_and_provider(member_dn, provider)

                if user.present?
                  user.external = true
                  user.save
                  verified_external_users << user
                else
                  Rails.logger.debug do
                    <<-MSG.strip_heredoc.tr("\n", ' ')
                      #{self.class.name}: User with DN `#{member_dn}` should be marked as
                      external but there is no user in GitLab with that identity.
                      Membership will be updated once the user signs in for the first time.
                    MSG
                  end
                end
              end
            end

            # Restore normal access to users no longer found in the external groups
            current_external_users.each do |user|
              unless verified_external_users.include?(user)
                user.external = false
                user.save
              end
            end
          end

          private

          def external_groups
            proxy.adapter.config.external_groups
          end
        end
      end
    end
  end
end
