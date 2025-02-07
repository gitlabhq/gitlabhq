---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab tokens
---

When working with GitLab tokens, you might encounter the following issues.

## Expired access tokens

If an existing access token is in use and reaches the `expires_at` value, the token
expires and:

- Can no longer be used for authentication.
- Is not visible in the UI.

Requests made using this token return a `401 Unauthorized` response. Too many
unauthorized requests in a short period of time from the same IP address
result in `403 Forbidden` responses from GitLab.com.

For more information on authentication request limits, see [Git and container registry failed authentication ban](../../user/gitlab_com/_index.md#git-and-container-registry-failed-authentication-ban).

### Identify expired access tokens from logs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464652) in GitLab 17.2.

Prerequisites:

You must:

- Be an administrator.
- Have access to the [`api_json.log`](../../administration/logs/_index.md#api_jsonlog) file.

To identify which `401 Unauthorized` requests are failing due to
expired access tokens, use the following fields in the `api_json.log` file:

|Field name|Description|
|----------|-----------|
|`meta.auth_fail_reason`|The reason the request was rejected. Possible values: `token_expired`, `token_revoked`, `insufficient_scope`, and `impersonation_disabled`.|
|`meta.auth_fail_token_id`|A string describing the type and ID of the attempted token.|

When a user attempts to use an expired token, the `meta.auth_fail_reason`
is `token_expired`. The following shows an excerpt from a log
entry:

```json
{
  "status": 401,
  "method": "GET",
  "path": "/api/v4/user",
  ...
  "meta.auth_fail_reason": "token_expired",
  "meta.auth_fail_token_id": "PersonalAccessToken/12",
}
```

`meta.auth_fail_token_id` indicates that an access token of ID 12 was used.

To find more information about this token, use the [personal access token API](../../api/personal_access_tokens.md#get-single-personal-access-token).
You can also use the API to [rotate the token](../../api/personal_access_tokens.md#rotate-a-personal-access-token).

### Replace expired access tokens

To replace the token:

1. Check where this token may have been used previously, and remove it from any
   automation might still use the token.
   - For personal access tokens, use the [API](../../api/personal_access_tokens.md#list-personal-access-tokens)
     to list tokens that have expired recently. For example, go to `https://gitlab.com/api/v4/personal_access_tokens`,
     and locate tokens with a specific `expires_at` date.
   - For project access tokens, use the
     [project access tokens API](../../api/project_access_tokens.md#list-all-project-access-tokens)
     to list recently expired tokens.
   - For group access tokens, use the
     [group access tokens API](../../api/group_access_tokens.md#list-all-group-access-tokens)
     to list recently expired tokens.
1. Create a new access token:
   - For personal access tokens, [use the UI](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)
     or [User tokens API](../../api/user_tokens.md#create-a-personal-access-token).
   - For a project access token, [use the UI](../../user/project/settings/project_access_tokens.md#create-a-project-access-token)
     or [project access tokens API](../../api/project_access_tokens.md#create-a-project-access-token).
   - For a group access token, [use the UI](../../user/group/settings/group_access_tokens.md#create-a-group-access-token-using-ui)
     or [group access tokens API](../../api/group_access_tokens.md#create-a-group-access-token).
1. Replace the old access token with the new access token. This process varies
   depending on how you use the token, for example if configured as a secret or
   embedded in an application. Requests made from this token should no longer
   return `401` responses.

### Extend token lifetime

Delay the expiration of certain tokens with this script.

From GitLab 16.0, all access tokens have an expiration date. After you deploy at least GitLab 16.0,
any non-expiring access tokens expire one year from the date of deployment.

If this date is approaching and there are tokens that have not yet
been rotated, you can use this script to delay expiration and give
users more time to rotate their tokens.

#### Extend lifetime for specific tokens

This script extends the lifetime of all tokens which expire on a specified date, including:

- Personal access tokens
- Group access tokens
- Project access tokens

For group and project access tokens, this script only extends the lifetime of these tokens if they were given an expiration date automatically when upgrading to GitLab 16.0 or later. If a group or project access token was generated with an expiration date, or was rotated, the validity of that token is dependent on a valid membership to a resource, and therefore the token lifetime cannot be extended using this script.

To use the script:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire `extend_expiring_tokens.rb` script below.
   If desired, change the `expiring_date` to a different date.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire `extend_expiring_tokens.rb` script below, and save it as a file on your instance:
   - Name it `extend_expiring_tokens.rb`.
   - If desired, change the `expiring_date` to a different date.
   - The file must be accessible to `git:git`.
1. Run this command, changing `/path/to/extend_expiring_tokens.rb`
   to the _full_ path to your `extend_expiring_tokens.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/extend_expiring_tokens.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../../administration/operations/rails_console.md#troubleshooting).

::EndTabs

##### `extend_expiring_tokens.rb`

```ruby
expiring_date = Date.new(2024, 5, 30)
new_expires_at = 6.months.from_now

total_updated = PersonalAccessToken
                  .not_revoked
                  .without_impersonation
                  .where(expires_at: expiring_date.to_date)
                  .update_all(expires_at: new_expires_at.to_date)

puts "Updated #{total_updated} tokens with new expiry date #{new_expires_at}"
```

## Identify personal, project, and group access tokens expiring on a certain date

Access tokens that have no expiration date are valid indefinitely, which is a
security risk if the access token is divulged.

To manage this risk, when you upgrade to GitLab 16.0 and later, any
[personal](../../user/profile/personal_access_tokens.md),
[project](../../user/project/settings/project_access_tokens.md), or
[group](../../user/group/settings/group_access_tokens.md) access
token that does not have an expiration date automatically has an expiration
date set at one year from the date of upgrade.

In GitLab 17.3 and later, this automatic setting of expiry on existing tokens has been reverted, and you can [disable expiration date enforcement for new access tokens](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens).

If you are not aware of when your tokens expire because the dates have changed,
you might have unexpected authentication failures when trying to sign into GitLab
on that date.

To manage this issue, you should upgrade to GitLab 17.2 or later, because these versions
contain a [tool that assists with analyzing, extending, or remove token expiration dates](../../administration/raketasks/tokens/_index.md).

If you cannot run the tool, you can also run scripts in self-managed instances to identify
tokens that either:

- Expire on a specific date.
- Have no expiration date.

You run these scripts from your terminal window in either:

- A [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
- Using the [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner).

The specific scripts you run differ depending on if you have upgraded to GitLab 16.0
and later, or not:

- If you have not yet upgraded to GitLab 16.0 or later, identify tokens that do not have an expiration date.
- If you have upgraded to GitLab 16.0 or later, use scripts to identify any of
  the following:
  - [Tokens expiring on a specific date](#find-all-tokens-expiring-on-a-specific-date).
  - [Tokens expiring in a specific month](#find-tokens-expiring-in-a-given-month).
  - [Dates when many tokens expire](#identify-dates-when-many-tokens-expire).

After you have identified tokens affected by this issue, you can run a final script
to extend the lifetime of specific tokens if needed.

These scripts return results in the following format:

```plaintext
Expired group access token in Group ID 25, Token ID: 8, Name: Example Token, Scopes: ["read_api", "create_runner"], Last used:
Expired project access token in Project ID 2, Token ID: 9, Name: Test Token, Scopes: ["api", "read_registry", "write_registry"], Last used: 2022-02-11 13:22:14 UTC
```

For more information on this, see [incident 18003](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18003).

### Find all tokens expiring on a specific date

This script finds tokens that expire on a specific date.

Prerequisites:

- You must know the exact date your instance was upgraded to GitLab 16.0.

To use it:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, connect to your instance.
1. Start a Rails console session with `sudo gitlab-rails console`.
1. Depending on your needs, copy either the entire `expired_tokens.rb`
   or `expired_tokens_date_range.rb` script below, and paste it into the console.
   Change the `expires_at_date` to the date one year after your instance was upgraded to GitLab 16.0.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Depending on your needs, copy either the entire `expired_tokens.rb`
   or `expired_tokens_date_range.rb` script below, and save it
   as a file on your instance:
   - Name it `expired_tokens.rb`.
   - Change the `expires_at_date` to the date one year after your instance was upgraded to GitLab 16.0.
   - The file must be accessible to `git:git`.
1. Run this command, changing the path to the _full_ path to your `expired_tokens.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../../administration/operations/rails_console.md#troubleshooting).

::EndTabs

#### `expired_tokens.rb`

This script requires you to know the exact date your GitLab instance
was upgraded to GitLab 16.0.

```ruby
# Change this value to the date one year after your GitLab instance was upgraded.

expires_at_date = "2024-05-22"

# Check for expiring personal access tokens
PersonalAccessToken.owner_is_human.where(expires_at: expires_at_date).find_each do |token|
  if token.user.blocked?
    next
    # Hide unusable, blocked PATs from output
  end

  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: expires_at_date).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

NOTE:
To not only hide, but also remove, tokens belonging to blocked users, add `token.destroy!` directly below
`if token.user.blocked?`. However, this action does not leave an audit event,
unlike the [API method](../../api/personal_access_tokens.md#revoke-a-personal-access-token).

### Find tokens expiring in a given month

This script finds tokens that expire in a particular month. You don't need to know
the exact date your instance was upgraded to GitLab 16.0. To use it:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire `tokens_with_no_expiry.rb` script below.
   If desired, change the `date_range` to a different range.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire `tokens_with_no_expiry.rb` script below, and save it as a file on your instance:
   - Name it `expired_tokens_date_range.rb`.
   - If desired, change the `date_range` to a different range.
   - The file must be accessible to `git:git`.
1. Run this command, changing `/path/to/expired_tokens_date_range.rb`
   to the _full_ path to your `expired_tokens_date_range.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens_date_range.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../../administration/operations/rails_console.md#troubleshooting).

::EndTabs

#### `expired_tokens_date_range.rb`

```ruby
# This script enables you to search for tokens that expire within a
# certain date range (like 1.month) from the current date. Use it if
# you're unsure when exactly your GitLab 16.0 upgrade completed.

date_range = 1.month

# Check for personal access tokens
PersonalAccessToken.owner_is_human.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

### Identify dates when many tokens expire

This script identifies dates when most of tokens expire. You can use it in combination with other scripts on this page to identify and extend large batches of tokens that may be approaching their expiration date, in case your team has not yet set up token rotation.

The script returns results in this format:

```plaintext
42 Personal access tokens will expire at 2024-06-27
17 Personal access tokens will expire at 2024-09-23
3 Personal access tokens will expire at 2024-08-13
```

To use it:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire `dates_when_most_of_tokens_expire.rb` script.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire `dates_when_most_of_tokens_expire.rb`
   script, and save it as a file on your instance:
   - Name it `dates_when_most_of_tokens_expire.rb`.
   - The file must be accessible to `git:git`.
1. Run this command, changing `/path/to/dates_when_most_of_tokens_expire.rb`
   to the _full_ path to your `dates_when_most_of_tokens_expire.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/dates_when_most_of_tokens_expire.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../../administration/operations/rails_console.md#troubleshooting).

::EndTabs

#### `dates_when_most_of_tokens_expire.rb`

```ruby
PersonalAccessToken
  .select(:expires_at, Arel.sql('count(*)'))
  .where('expires_at >= NOW()')
  .group(:expires_at)
  .order(Arel.sql('count(*) DESC'))
  .limit(10)
  .each do |token|
    puts "#{token.count} Personal access tokens will expire at #{token.expires_at}"
  end
```

### Find tokens with no expiration date

This script finds tokens that lack an expiration date: `expires_at` is `NULL`. For users
who have not yet upgraded to GitLab version 16.0 or later, the token `expires_at`
value is `NULL`, and can be used to identify tokens to add an expiration date to.

You can use this script in either the [Rails console](../../administration/operations/rails_console.md)
or the [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner):

::Tabs

:::TabTitle Rails console session

1. In your terminal window, connect to your instance.
1. Start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire `tokens_with_no_expiry.rb` script below.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire `tokens_with_no_expiry.rb` script below, and save it as a file on your instance:
   - Name it `tokens_with_no_expiry.rb`.
   - The file must be accessible to `git:git`.
1. Run this command, changing the path to the _full_ path to your `tokens_with_no_expiry.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/tokens_with_no_expiry.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../../administration/operations/rails_console.md#troubleshooting).

::EndTabs

#### `tokens_with_no_expiry.rb`

This script finds tokens without a value set for `expires_at`.

   ```ruby
   # This script finds tokens which do not have an expires_at value set.

   # Check for expiring personal access tokens
   PersonalAccessToken.owner_is_human.where(expires_at: nil).find_each do |token|
     puts "Expires_at is nil for personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
   end

   # Check for expiring project and group access tokens
   PersonalAccessToken.project_access_token.where(expires_at: nil).find_each do |token|
     token.user.members.each do |member|
       type = member.is_a?(GroupMember) ? 'Group' : 'Project'

       puts "Expires_at is nil for #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
     end
   end
   ```
