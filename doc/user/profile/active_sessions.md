---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. On the left sidebar, select **Active sessions**.

![Active sessions list](img/active_sessions_list_v12_7.png)

## Active sessions limit

GitLab allows users to have up to 100 active sessions at once. If the number of active sessions
exceeds 100, the oldest ones are deleted.

## Revoke a session

To revoke an active session:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. On the left sidebar, select **Active sessions**.
1. Select **Revoke** next to a session. The current session cannot be revoked, as this would sign you out of GitLab.

{{< alert type="note" >}}

When any session is revoked all **Remember me** tokens for all
devices are revoked. For details about **Remember me**, see
[cookies used for sign-in](_index.md#cookies-used-for-sign-in).

{{< /alert >}}

## Revoke sessions through the Rails console

You can also revoke user sessions through the Rails console. You can use this to revoke
multiple sessions at the same time.

### Revoke all sessions for all users

To revoke all sessions for all users:

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Optional. List all active sessions with the following command:

   ```ruby
   ActiveSession.list(User.all)
1. Revoke all sessions with the following command:

   ```ruby
   ActiveSession.destroy_all
   ```

1. Verify sessions are closed with the following command:

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
