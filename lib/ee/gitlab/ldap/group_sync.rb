require 'net/ldap/dn'

module EE
  module Gitlab
    module LDAP
      class GroupSync
        attr_reader :provider

        # Open a connection so we can run all queries through it.
        # It's more efficient than the default of opening/closing per LDAP query.
        def self.open(provider, &block)
          ::Gitlab::LDAP::Adapter.open(provider) do |adapter|
            block.call(self.new(provider, adapter))
          end
        end

        def self.execute
          # Shuffle providers to prevent a scenario where sync fails after a time
          # and only the first provider or two get synced. This shuffles the order
          # so subsequent syncs should eventually get to all providers. Obviously
          # we should avoid failure, but this is an additional safeguard.
          ::Gitlab::LDAP::Config.providers.shuffle.each do |provider|
            self.open(provider) do |group_sync|
              group_sync.update_permissions
            end
          end

          true
        end

        def initialize(provider, adapter = nil)
          @adapter = adapter
          @provider = provider
        end

        def update_permissions
          if group_base.present?
            logger.debug { "Performing LDAP group sync for '#{provider}' provider" }
            sync_groups
            logger.debug { "Finished LDAP group sync for '#{provider}' provider" }
          else
            logger.debug { "No `group_base` configured for '#{provider}' provider. Skipping" }
          end

          if admin_group.present?
            logger.debug { "Syncing admin users for '#{provider}' provider" }
            sync_admin_users
            logger.debug { "Finished syncing admin users for '#{provider}' provider" }
          else
            logger.debug { "No `admin_group` configured for '#{provider}' provider. Skipping" }
          end

          if external_groups.empty?
            logger.debug { "No `external_groups` configured for '#{provider}' provider. Skipping" }
          else
            logger.debug { "Syncing external users for '#{provider}' provider" }
            sync_external_users
            logger.debug { "Finished syncing external users for '#{provider}' provider" }
          end

          nil
        end

        # Iterate of all GitLab groups with LDAP links. Build an access hash
        # representing a user's highest access level among the LDAP links within
        # the same GitLab group.
        def sync_groups
          # Order results by last_ldap_sync_at ASC so groups with older last
          # sync time are handled first
          groups_where_group_links_with_provider_ordered.each do |group|
            lease = ::Gitlab::ExclusiveLease.new(
              "ldap_group_sync:#{provider}:#{group.id}",
              timeout: 3600
            )
            next unless lease.try_obtain

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
        end

        # Update global administrators based on the specified admin group CN
        def sync_admin_users
          admin_group_member_dns = dns_for_group_cn(admin_group)
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
              logger.debug do
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

        # Update external users based on the specified external groups CN
        def sync_external_users
          current_external_users = ::User.external.with_provider(provider)
          verified_external_users = []

          external_groups.each do |group|
            group_dns = dns_for_group_cn(group)

            group_dns.each do |member_dn|
              user = ::Gitlab::LDAP::User.find_by_uid_and_provider(member_dn, provider)

              if user.present?
                user.external = true
                user.save
                verified_external_users << user
              else
                logger.debug do
                  <<-MSG.strip_heredoc.tr("\n", ' ')
                    #{self.class.name}: User with DN `#{member_dn}` should be marked as
                    external but there is no user in GitLab with that identity.
                    Membership will be updated once the user signs in for the first time.
                  MSG
                end
              end
            end
          end

          update_external_permissions(current_external_users, verified_external_users)
        end

        private

        # Cache LDAP group member DNs so we don't query LDAP groups more than once.
        def dns_for_group_cn(group_cn)
          @dns_for_group_cn ||= Hash.new { |h, k| h[k] = ldap_group_member_dns(k) }
          @dns_for_group_cn[group_cn]
        end

        # Cache user DN so we don't generate excess queries to map UID to DN
        def dn_for_uid(uid)
          @dn_for_uid ||= Hash.new { |h, k| h[k] = member_uid_to_dn(k) }
          @dn_for_uid[uid]
        end

        def adapter
          @adapter ||= ::Gitlab::LDAP::Adapter.new(provider)
        end

        def config
          @config ||= ::Gitlab::LDAP::Config.new(provider)
        end

        def group_base
          config.group_base
        end

        def admin_group
          config.admin_group
        end

        def external_groups
          config.external_groups
        end

        def ldap_group_member_dns(ldap_group_cn)
          ldap_group = Group.find_by_cn(ldap_group_cn, adapter)
          unless ldap_group.present?
            logger.warn { "Cannot find LDAP group with CN '#{ldap_group_cn}'. Skipping" }
            return []
          end

          member_dns = ldap_group.member_dns
          if member_dns.empty?
            # Group must be empty
            return [] unless ldap_group.memberuid?

            members = ldap_group.member_uids
            member_dns = members.map { |uid| dn_for_uid(uid) }
          end
          ensure_full_dns!(member_dns)

          logger.debug { "Members in '#{ldap_group.name}' LDAP group: #{member_dns}" }

          # Various lookups in this method could return `nil` values.
          # Compact the array to remove those entries
          member_dns.compact
        end

        # At least one customer reported that their LDAP `member` values contain
        # only `uid=username` and not the full DN. This method allows us to
        # account for that. See gitlab-ee#442
        def ensure_full_dns!(dns)
          dns.map! do |dn|
            begin
              parsed_dn = Net::LDAP::DN.new(dn).to_a
            rescue RuntimeError => e
              # Net::LDAP raises a generic RuntimeError. Bad library! Bad!
              logger.error { "Found malformed DN: '#{dn}'. Skipping. #{e.message}" }
              next
            end

            # If there is more than one key/value set we must have a full DN,
            # or at least the probability is higher.
            if parsed_dn.count > 2
              dn
            elsif parsed_dn[0] == 'uid'
              dn_for_uid(parsed_dn[1])
            else
              logger.warn { "Found potentially malformed/incomplete DN: '#{dn}'" }
              dn
            end
          end

          # Remove `nil` values generated by the rescue above.
          dns.compact!
        end

        def member_uid_to_dn(uid)
          identity = Identity.find_by(provider: provider, secondary_extern_uid: uid)

          if identity.present?
            # Use the DN on record in GitLab when it's available
            identity.extern_uid
          else
            ldap_user = ::Gitlab::LDAP::Person.find_by_uid(uid, adapter)

            # Can't find a matching user for group entry
            return nil unless ldap_user.present?

            # Update user identity so we don't have to go through this again
            update_identity(ldap_user.dn, uid)

            ldap_user.dn
          end
        end

        def update_identity(dn, uid)
          identity =
            Identity.find_by(provider: provider, extern_uid: dn)

          # User may not exist in GitLab yet. Skip.
          return unless identity.present?

          identity.secondary_extern_uid = uid
          identity.save
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

        def update_external_permissions(users, verified)
          # Restore normal access to users no longer found in the external groups
          users.each do |user|
            unless verified.include?(user)
              user.external = false
              user.save
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

        def groups_where_group_links_with_provider_ordered
          ::Group.where_group_links_with_provider(provider)
            .preload(:ldap_group_links)
            .reorder('last_ldap_sync_at ASC, namespaces.id ASC')
            .distinct
        end

        def logger
          Rails.logger
        end
      end
    end
  end
end
