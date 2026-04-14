---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Active sessions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab lists all devices that have logged into your account. You can
review the sessions, and revoke any you don't recognize.

## List all active sessions

To list all active sessions:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access** > **Active sessions**.

![Active sessions list](img/active_sessions_list_v12_7.png)

## Active sessions limit

GitLab allows users to have up to 100 active sessions at once. If the number of active sessions
exceeds 100, the oldest ones are deleted.

## Revoke a session

To revoke an active session:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access** > **Active sessions**.
1. Select **Revoke** next to a session. The current session cannot be revoked, as this would sign you out of GitLab.

> [!note]
> When any session is revoked all **Remember me** tokens for all
> devices are revoked. For details about **Remember me**, see
> [cookies used for sign-in](_index.md#cookies-used-for-sign-in).

## Revoke sessions through the Rails console

You can also revoke user sessions through the Rails console. You can use this to revoke
multiple sessions at the same time.

### Revoke all sessions for all users

To revoke all sessions for all users:

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Optional. List all active sessions with the following command:

   ```ruby
   # Show all users with active sessions
    puts "=== Currently Logged In Users ==="
    User.find_each do |user|
        sessions = ActiveSession.list(user)
        if sessions.any?
            puts "\n#{user.username} (#{user.name}):"
            sessions.each do |session|
                puts "  - IP: #{session.ip_address}, Browser: #{session.browser}, Last active: #{session.updated_at}"
            end
        end
    end
   ```

1. Revoke all sessions with the following command:

   ```ruby
   User.find_each do |user|
      ActiveSession.destroy_all_but_current(user, nil)
   end
   ```

1. Optional. Confirm all sessions have been revoked by running the "List all active sessions" command again.

### Revoke all sessions for all users of a group

1. Save the following script to your GitLab instance. For example, `scripts/session_revocation/revoke_group_sessions.rb`.

   ```ruby
   # frozen_string_literal: true
   #
   # Revoke all active sessions for members of a group, including:
   # - Direct and inherited members of the top-level group
   # - Direct members of all subgroups
   # - Members invited via group shares at the top-level and subgroup level
   #
   # Usage (Rails console):
   #   DRY_RUN = true
   #   GROUP_IDENTIFIER = 'your-group-path' # or numeric ID
   #   load 'scripts/session_revocation/revoke_group_sessions.rb'

   DRY_RUN = true unless defined?(DRY_RUN)
   # Replace `your-group-path` with your group ID or the full path to your group
   GROUP_IDENTIFIER = 'your-group-path' unless defined?(GROUP_IDENTIFIER) 

   # ---------------------------------------------------------------

   def find_group(identifier)
      # Try finding by full path first (handles numeric group names)
      group = Group.find_by_full_path(identifier.to_s)
      return group if group

      # Fallback to ID lookup if path not found and identifier is numeric
      if identifier.is_a?(Integer) || identifier.to_s.match?(/\A\d+\z/)
         Group.find_by(id: identifier)
      end
   end

   def collect_member_user_ids(group)
      user_ids = Set.new

      # Direct and inherited members of the top-level group
      user_ids.merge(group.members_with_parents.pluck(:user_id))

      # Members invited via group shares into the top-level group
      group.shared_with_group_links.each do |link|
         user_ids.merge(link.shared_with_group.members_with_parents.pluck(:user_id))
      end

      # Traverse all subgroups
      group.descendants.find_each do |subgroup|
         # Direct members of each subgroup
         user_ids.merge(subgroup.members.pluck(:user_id))

         # Members invited via group shares into each subgroup
         subgroup.shared_with_group_links.each do |link|
            user_ids.merge(link.shared_with_group.members_with_parents.pluck(:user_id))
         end
      end

      user_ids.to_a
   end

   def revoke_sessions_for_group(group, dry_run:)
      member_user_ids = collect_member_user_ids(group)

      puts "Found #{member_user_ids.count} unique members in group '#{group.full_path}' (including subgroups and group shares)"

      # Only process active, non-bot human users to avoid unnecessary Redis lookups
      users = User.active.human.id_in(member_user_ids)

      revoked_sessions = 0
      affected_users = []
      skipped_users = []

      users.find_each do |user|
         sessions = ActiveSession.list(user)

         if sessions.empty?
            skipped_users << user.username
            next
         end

         session_ids = sessions.map(&:session_private_id).compact

         if session_ids.empty?
            puts "  [WARN] User #{user.username} has sessions but all session_private_ids are nil, skipping."
            skipped_users << user.username
            next
         end

         unless dry_run
            Gitlab::Redis::Sessions.with do |redis|
               ActiveSession.destroy_sessions(redis, user, session_ids)
            end

            # Emit audit event for security traceability
            Gitlab::AppLogger.info(
               message: "Sessions revoked via admin script",
               user_id: user.id,
               username: user.username,
               session_count: session_ids.size,
               group: group.full_path,
               performed_at: Time.current.iso8601
            )
         end

         revoked_sessions += session_ids.size
         affected_users << user.username
      end

      [revoked_sessions, affected_users, skipped_users]
   end

   # ---------------------------------------------------------------

   group = find_group(GROUP_IDENTIFIER)

   if group.nil?
      puts "ERROR: Group '#{GROUP_IDENTIFIER}' not found. Aborting."
   end

   puts "=== Session Revocation #{DRY_RUN ? '(DRY RUN)' : '(LIVE)'} ==="
   puts "Group: #{group.full_path} (ID: #{group.id})"
   puts

   revoked_sessions, affected_users, skipped_users = revoke_sessions_for_group(group, dry_run: DRY_RUN)

   prefix = DRY_RUN ? "[DRY RUN] Would revoke" : "Revoked"
   puts "#{prefix} #{revoked_sessions} sessions for #{affected_users.size} users"
   puts "Users affected: #{affected_users.sort.join(', ')}" if affected_users.any?
   puts "Users skipped (no active sessions): #{skipped_users.size}" if skipped_users.any?

   if DRY_RUN && revoked_sessions.positive?
      puts "\nTo actually revoke sessions, set DRY_RUN = false and run again."
   end
   ```

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run the following command to target the group. Replace `your-group-path` with your group ID or the full path to your group: 

   ```ruby
   GROUP_IDENTIFIER = 'your-group-path'
   ```

1. Run the following command to list all active sessions in the group:

   ```ruby
   DRY_RUN = true
   load 'scripts/session_revocation/revoke_group_sessions.rb'
   ```

1. Run the following command to revoke all sessions in the group:

   ```ruby
   DRY_RUN = false
   load 'scripts/session_revocation/revoke_group_sessions.rb'
   ```

1. Run the following command to verify all sessions are closed. The output should list 0 active sessions:

   ```ruby
   DRY_RUN = true
   load 'scripts/session_revocation/revoke_group_sessions.rb'
   ```

### Revoke all sessions for a user

To revoke all sessions for a specific user:

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Find the user with the following commands:

   - By username:

     ```ruby
     user = User.find_by_username 'exampleuser'
     ```

   - By user ID:

     ```ruby
     user = User.find(123)
     ```

   - By email address:

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. Optional. List all active sessions for the user with the following command:

   ```ruby
   ActiveSession.list(user)
   ```

1. Revoke all sessions with the following command:

   ```ruby
   ActiveSession.list(user).each { |session| ActiveSession.destroy_session(user, session.session_private_id) }
   ```

1. Verify all sessions are closed with the following command:

   ```ruby
   # If all sessions are closed, returns an empty array.
   ActiveSession.list(user)
   ```
