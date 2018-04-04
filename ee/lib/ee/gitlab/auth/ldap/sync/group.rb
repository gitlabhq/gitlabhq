module EE
  module Gitlab
    module Auth
      module LDAP
        module Sync
          class Group
            attr_reader :provider, :group, :proxy

            class << self
              # Sync members across all providers for the given group.
              def execute_all_providers(group)
                return unless ldap_sync_ready?(group)

                begin
                  group.start_ldap_sync
                  Rails.logger.debug { "Started syncing all providers for '#{group.name}' group" }

                  # Shuffle providers to prevent a scenario where sync fails after a time
                  # and only the first provider or two get synced. This shuffles the order
                  # so subsequent syncs should eventually get to all providers. Obviously
                  # we should avoid failure, but this is an additional safeguard.
                  ::Gitlab::Auth::LDAP::Config.providers.shuffle.each do |provider|
                    Sync::Proxy.open(provider) do |proxy|
                      new(group, proxy).update_permissions
                    end
                  end

                  group.finish_ldap_sync
                  Rails.logger.debug { "Finished syncing all providers for '#{group.name}' group" }
                rescue ::Gitlab::Auth::LDAP::LDAPConnectionError
                  Rails.logger.warn("Error syncing all providers for '#{group.name}' group")
                  group.fail_ldap_sync
                end
              end

              # Sync members across a single provider for the given group.
              def execute(group, proxy)
                return unless ldap_sync_ready?(group)

                begin
                  group.start_ldap_sync
                  Rails.logger.debug { "Started syncing '#{proxy.provider}' provider for '#{group.name}' group" }

                  sync_group = new(group, proxy)
                  sync_group.update_permissions

                  group.finish_ldap_sync
                  Rails.logger.debug { "Finished syncing '#{proxy.provider}' provider for '#{group.name}' group" }
                rescue ::Gitlab::Auth::LDAP::LDAPConnectionError
                  Rails.logger.warn("Error syncing '#{proxy.provider}' provider for '#{group.name}' group")
                  group.fail_ldap_sync
                end
              end

              def ldap_sync_ready?(group)
                fail_stuck_group(group)

                return true unless group.ldap_sync_started?

                Rails.logger.warn "Group '#{group.name}' is not ready for LDAP sync. Skipping"
                false
              end

              def fail_stuck_group(group)
                return unless group.ldap_sync_started?

                if group.ldap_sync_last_sync_at < 1.hour.ago
                  group.mark_ldap_sync_as_failed('The sync took too long to complete.')
                end
              end
            end

            def initialize(group, proxy)
              @provider = proxy.provider
              @group = group
              @proxy = proxy
            end

            def update_permissions
              unless group.ldap_sync_started?
                logger.warn "Group '#{group.name}' LDAP sync status must be 'started' before updating permissions"
                return
              end

              access_levels = AccessLevels.new
              # Only iterate over group links for the current provider
              group.ldap_group_links.with_provider(provider).each do |group_link|
                next unless group_link.active?

                update_access_levels(access_levels, group_link)
              end

              update_existing_group_membership(group, access_levels)
              add_new_members(group, access_levels)
            end

            private

            def update_access_levels(access_levels, group_link)
              if member_dns = get_member_dns(group_link)
                access_levels.set(member_dns, to: group_link.group_access)

                logger.debug do
                  "Resolved '#{group.name}' group member access: #{access_levels.to_hash}"
                end
              end
            end

            def get_member_dns(group_link)
              group_link.cn ? dns_for_group_cn(group_link.cn) : UserFilter.filter(@proxy, group_link.filter)
            end

            def dns_for_group_cn(group_cn)
              if config.group_base.blank?
                logger.debug { "No `group_base` configured for '#{provider}' provider and group link CN #{group_cn}. Skipping" }

                return nil
              end

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
                member_dn = identity.extern_uid.downcase

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

                # Skip validations and callbacks. We have a limited set of attrs
                # due to the `select` lookup, and we need to be efficient.
                # Low risk, because the member should already be valid.
                member.update_column(:ldap, true) unless member.ldap?

                # Don't do anything if the user already has the desired access level
                if member.access_level == desired_access
                  access_levels.delete(member_dn)
                  next
                end

                # Check and update the access level. If `desired_access` is `nil`
                # we need to delete the user from the group.
                if desired_access.present?
                  # Delete this entry from the hash now that we're acting on it
                  access_levels.delete(member_dn)

                  next if member.ldap? && member.override?

                  add_or_update_user_membership(
                    user,
                    group,
                    desired_access
                  )
                elsif group.last_owner?(user)
                  warn_cannot_remove_last_owner(user, group)
                else
                  group.users.destroy(user)
                end
              end
            end

            def add_new_members(group, access_levels)
              logger.debug { "Adding new members to '#{group.name}' group" }

              access_levels.each do |member_dn, access_level|
                user = ::Gitlab::Auth::LDAP::User.find_by_uid_and_provider(member_dn, provider)

                if user.present?
                  add_or_update_user_membership(
                    user,
                    group,
                    access_level
                  )
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

            def add_or_update_user_membership(user, group, access, current_user: nil)
              # Prevent the last owner of a group from being demoted
              if access < ::Gitlab::Access::OWNER && group.last_owner?(user)
                warn_cannot_remove_last_owner(user, group)
              else
                # If you pass the user object, instead of just user ID,
                # it saves an extra user database query.
                group.add_user(
                  user,
                  access,
                  current_user: current_user,
                  ldap: true
                )
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
              group.members.select(:id, :access_level, :user_id, :ldap, :override)
                .with_identity_provider(provider).preload(:user)
            end

            def logger
              Rails.logger
            end

            def config
              @proxy.adapter.config
            end
          end
        end
      end
    end
  end
end
