module EE
  module Gitlab
    module LDAP
      module Sync
        class Group
          attr_reader :provider, :group, :proxy

          def self.execute(group, proxy)
            self.new(group, proxy).update_permissions
          end

          def initialize(group, proxy)
            @provider = proxy.provider
            @group = group
            @proxy = proxy
          end

          def update_permissions
            lease = ::Gitlab::ExclusiveLease.new(
              "ldap_group_sync:#{provider}:#{group.id}",
              timeout: 3600
            )
            return unless lease.try_obtain

            logger.debug { "Syncing '#{group.name}' group" }

            access_levels = AccessLevels.new
            # Only iterate over group links for the current provider
            group.ldap_group_links.with_provider(provider).each do |group_link|
              if member_dns = dns_for_group_cn(group_link.cn)
                access_levels.set(member_dns, to: group_link.group_access)
                logger.debug do
                  "Resolved '#{group.name}' group member access: #{access_levels.to_hash}"
                end
              end
            end

            update_existing_group_membership(group, access_levels)
            add_new_members(group, access_levels)

            group.update(last_ldap_sync_at: Time.now)

            logger.debug { "Finished syncing '#{group.name}' group" }
          end

          private

          def dns_for_group_cn(group_cn)
            proxy.dns_for_group_cn(group_cn)
          end

          def dn_for_uid(uid)
            proxy.dn_for_uid(uid)
          end

          def update_existing_group_membership(group, access_levels)
            logger.debug { "Updating existing membership for '#{group.name}' group" }

            select_and_preload_group_members(group).each do |member|
              user = member.user
              identity = user.identities.select(:id, :extern_uid)
                           .with_provider(provider).first
              member_dn = identity.extern_uid

              # Skip if this is not an LDAP user with a valid `extern_uid`.
              next unless member_dn.present?

              # Prevent shifting group membership, in case where user is a member
              # of two LDAP groups from different providers linked to the same
              # GitLab group. This is not ideal, but preserves existing behavior.
              if user.ldap_identity.id != identity.id
                access_levels.delete(member_dn)
                next
              end

              desired_access = access_levels[member_dn]

              # Don't do anything if the user already has the desired access level
              if member.access_level == desired_access
                access_levels.delete(member_dn)
                next
              end

              # Check and update the access level. If `desired_access` is `nil`
              # we need to delete the user from the group.
              if desired_access.present?
                add_or_update_user_membership(user, group, desired_access)

                # Delete this entry from the hash now that we've acted on it
                access_levels.delete(member_dn)
              elsif group.last_owner?(user)
                warn_cannot_remove_last_owner(user, group)
              else
                group.users.delete(user)
              end
            end
          end

          def add_new_members(group, access_levels)
            logger.debug { "Adding new members to '#{group.name}' group" }

            access_levels.each do |member_dn, access_level|
              user = ::Gitlab::LDAP::User.find_by_uid_and_provider(member_dn, provider)

              if user.present?
                add_or_update_user_membership(user, group, access_level)
              else
                logger.debug do
                  <<-MSG.strip_heredoc.tr("\n", ' ')
                    #{self.class.name}: User with DN `#{member_dn}` should have access
                    to '#{group.name}' group but there is no user in GitLab with that
                    identity. Membership will be updated once the user signs in for
                    the first time.
                  MSG
                end
              end
            end
          end

          def add_or_update_user_membership(user, group, access)
            # Prevent the last owner of a group from being demoted
            if access < ::Gitlab::Access::OWNER && group.last_owner?(user)
              warn_cannot_remove_last_owner(user, group)
            else
              # If you pass the user object, instead of just user ID,
              # it saves an extra user database query.
              group.add_users([user], access, skip_notification: true)
            end
          end

          def warn_cannot_remove_last_owner(user, group)
            logger.warn do
              <<-MSG.strip_heredoc.tr("\n", ' ')
                #{self.class.name}: LDAP group sync cannot remove #{user.name}
                (#{user.id}) from group #{group.name} (#{group.id}) as this is
                the group's last owner
              MSG
            end
          end

          def select_and_preload_group_members(group)
            group.members.select_access_level_and_user
              .with_identity_provider(provider).preload(:user)
          end

          def logger
            Rails.logger
          end
        end
      end
    end
  end
end
