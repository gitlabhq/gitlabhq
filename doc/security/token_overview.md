---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Token overview

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

This document lists tokens used in GitLab, their purpose and, where applicable, security guidance.

## Personal access tokens

You can create [Personal access tokens](../user/profile/personal_access_tokens.md) to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of your personal access tokens. By default,
they inherit permissions from the user who created them.

You can use the personal access tokens API to programmatically take action,
such as [rotating a personal access token](../api/personal_access_tokens.md#rotate-a-personal-access-token).

You will receive an email when personal access tokens are 7 days or less from expiration.

## OAuth2 tokens

GitLab can serve as an [OAuth2 provider](../api/oauth2.md) to allow other services to access the GitLab API on a user's behalf.

You can limit the scope and lifetime of your OAuth2 tokens.

## Impersonation tokens

An [Impersonation token](../api/rest/index.md#impersonation-tokens) is a special type of personal access
token. It can be created only by an administrator for a specific user. Impersonation tokens can
help you build applications or scripts that authenticate with the GitLab API, repositories, and the GitLab registry as a specific user.

You can limit the scope and set an expiration date for an impersonation token.

## Project access tokens

[Project access tokens](../user/project/settings/project_access_tokens.md#project-access-tokens)
are scoped to a project. As with [Personal access tokens](#personal-access-tokens), you can use them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of project access tokens. When you
create a project access token, GitLab creates a [bot user for projects](../user/project/settings/project_access_tokens.md#bot-users-for-projects).
Bot users for projects are service accounts and do not count as licensed seats.

You can use the [project access tokens API](../api/project_access_tokens.md) to
programmatically take action, such as
[rotating a project access token](../api/project_access_tokens.md#rotate-a-project-access-token).

Project Owners and Maintainers with a direct membership receive an email when project access tokens are seven days or less from expiration. Inherited members do not receive an email.

## Group access tokens

[Group access tokens](../user/group/settings/group_access_tokens.md#group-access-tokens)
are scoped to a group. As with [Personal access tokens](#personal-access-tokens), you can use them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of group access tokens. When you
create a group access token, GitLab creates a [bot user for groups](../user/group/settings/group_access_tokens.md#bot-users-for-groups).
Bot users for groups are service accounts and do not count as licensed seats.

You can use the [group access tokens API](../api/group_access_tokens.md) to
programmatically take action, such as
[rotating a group access token](../api/group_access_tokens.md#rotate-a-group-access-token).

All group owners with a direct membership receive an email when group access tokens are 7 days or less from expiration. Inherited members do not receive an email.

## Deploy tokens

[Deploy tokens](../user/project/deploy_tokens/index.md) allow you to download (`git clone`) or push and pull packages and container registry images of a project without having a user and a password. Deploy tokens cannot be used with the GitLab API.

Deploy tokens can be managed by project maintainers and owners.

## Deploy keys

[Deploy keys](../user/project/deploy_keys/index.md) allow read-only or read-write access to your repositories by importing an SSH public key into your GitLab instance. Deploy keys cannot be used with the GitLab API or the registry.

This is useful, for example, for cloning repositories to your Continuous Integration (CI) server. By using deploy keys, you don't have to set up a fake user account.

Project maintainers and owners can add or enable a deploy key for a project repository.

## Runner authentication tokens

In GitLab 16.0 and later, to register a runner, you can use a runner authentication token
instead of a runner registration token. Runner registration tokens have
been [deprecated](../ci/runners/new_creation_workflow.md).

After you create a runner and its configuration, you receive a runner authentication token
that you use to register the runner. The runner authentication token is stored locally in the
[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) file, which
you use to configure the runner.

The runner uses the runner authentication token to authenticate with GitLab when
it picks up jobs from the job queue. After the runner authenticates with GitLab,
the runner receives a [job token](../ci/jobs/ci_job_token.md), which it uses to
execute the job.

The runner authentication token stays on the runner machine. The execution environments
for the following executors only have access to the job token and not the runner authentication token:

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

Malicious access to a runner's file system may expose the `config.toml` file and the
runner authentication token. The attacker could use the runner authentication token
to [clone the runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

You can use the `runners` API to
programmatically [rotate or revoke a runner authentication token](../api/runners.md#reset-runners-authentication-token-by-using-the-current-token).

## Runner registration tokens (deprecated)

WARNING:
The ability to pass a runner registration token has been [deprecated](../ci/runners/new_creation_workflow.md) and is
planned for removal in GitLab 18.0, along with support for certain configuration arguments. This change is a breaking change. GitLab has implemented a new
[GitLab Runner token architecture](../ci/runners/new_creation_workflow.md), which introduces
a new method for registering runners and eliminates the
runner registration token.

Runner registration tokens are used to [register](https://docs.gitlab.com/runner/register/) a [runner](https://docs.gitlab.com/runner/) with GitLab. Group or project owners or instance administrators can obtain them through the GitLab user interface. The registration token is limited to runner registration and has no further scope.

You can use the runner registration token to add runners that execute jobs in a project or group. The runner has access to the project's code, so be careful when assigning project and group-level permissions.

## CI/CD job tokens

The [CI/CD](../ci/jobs/ci_job_token.md) job token
is a short lived token only valid for the duration of a job. It gives a CI/CD job
access to a limited amount of API endpoints.
API authentication uses the job token, by using the authorization of the user
triggering the job.

The job token is secured by its short life-time and limited scope. It could possibly be leaked if multiple jobs run on the same machine ([like with the shell runner](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)). On Docker Machine runners, configuring [`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section) is recommended to make sure runner machines only ever run one build and are destroyed afterwards. This may impact performance, as provisioning machines takes some time.

## GitLab cluster agent tokens

When [registering a GitLab agent for Kubernetes](../user/clusters/agent/install/index.md#register-the-agent-with-gitlab), GitLab generates an access token to authenticate the cluster agent with GitLab.

To revoke this cluster agent token, you can use either the:

- [Agents API](../api/cluster_agents.md#revoke-an-agent-token) to revoke the token.
- [UI](../user/clusters/agent/work_with_agent.md#reset-the-agent-token) to reset the token.

For both methods, you must know the token, agent, and project IDs. To find this information, use the [Rails console](../administration/operations/rails_console.md)

```irb
# Find token ID
Clusters::AgentToken.find_by_token('glagent-xxx').id

# Find agent ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.id
=> 1234

# Find project ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.project_id
=> 12345
```

You can also revoke a token directly in the Rails console:

```irb
# Revoke token with RevokeService, including generating an audit event
Clusters::AgentTokens::RevokeService.new(token: Clusters::AgentToken.find_by_token('glagent-xxx'), current_user: User.find_by_username('admin-user')).execute

# Revoke token manually, which does not generate an audit event
Clusters::AgentToken.find_by_token('glagent-xxx').revoke!
```

## Other tokens

### Feed token

Each user has a long-lived feed token that does not expire. This token allows authentication for:

- RSS readers to load a personalized RSS feed.
- Calendar applications to load a personalized calendar.

You cannot use this token to access any other data.

The user-scoped feed token can be used for all feeds, however feed and calendar URLs are generated
with a different token that is only valid for one feed.

Anyone who has your token can read activity and issue RSS feeds or your calendar feed as if they were you, including confidential issues. If that happens, [reset the token](../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token).

#### Disable a feed token

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Under **Feed token**, select the **Disable feed token** checkbox, then select **Save changes**.

### Incoming email token

Each user has a long-lived incoming email token that does not expire. This token allows a user to [create a new issue by email](../user/project/issues/create_issues.md#by-sending-an-email), and is included in that user's personal project-specific email addresses. You cannot use this token to access any other data. Anyone who has your token can create issues and merge requests as if they were you. If that happens, reset the token.

## Available scopes

This table shows available scopes per token. Scopes can be limited further on token creation.

| Token name                  | API access                | Registry access           | Repository access |
|-----------------------------|---------------------------|---------------------------|-------------------|
| Personal access token       | **{check-circle}** Yes    | **{check-circle}** Yes    | **{check-circle}** Yes |
| OAuth2 token                | **{check-circle}** Yes    | **{dotted-circle}** No    | **{check-circle}** Yes |
| Impersonation token         | **{check-circle}** Yes    | **{check-circle}** Yes    | **{check-circle}** Yes |
| Project access token        | **{check-circle}** Yes(1) | **{check-circle}** Yes(1) | **{check-circle}** Yes(1) |
| Group access token          | **{check-circle}** Yes(2) | **{check-circle}** Yes(2) | **{check-circle}** Yes(2) |
| Deploy token                | **{dotted-circle}** No    | **{check-circle}** Yes    | **{check-circle}** Yes |
| Deploy key                  | **{dotted-circle}** No    | **{dotted-circle}** No    | **{check-circle}** Yes |
| Runner registration token   | **{dotted-circle}** No    | **{dotted-circle}** No    | ✴️(3)              |
| Runner authentication token | **{dotted-circle}** No    | **{dotted-circle}** No    | ✴️(3)              |
| Job token                   | ✴️(4)                      | **{dotted-circle}** No    | **{check-circle}** Yes |

1. Limited to the one project.
1. Limited to the one group.
1. Runner registration and authentication token don't provide direct access to repositories, but can be used to register and authenticate a new runner that may execute jobs which do have access to the repository
1. Limited to certain [endpoints](../ci/jobs/ci_job_token.md).

## Token prefixes

The following table shows the prefixes for each type of token.

|            Token name             |      Prefix        |
|-----------------------------------|--------------------|
| Personal access token             | `glpat-`           |
| OAuth Application Secret          | `gloas-`           |
| Impersonation token               | `glpat-`           |
| Project access token              | `glpat-`           |
| Group access token                | `glpat-`           |
| Deploy token                      | `gldt-` ([Added in GitLab 16.7](https://gitlab.com/gitlab-org/gitlab/-/issues/376752)) |
| Runner authentication token       | `glrt-`            |
| CI/CD Job token                   | `glcbt-` <br /> &bull; ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426137) in GitLab 16.8 behind a feature flag named `prefix_ci_build_tokens`. Disabled by default.) <br /> &bull; ([Generally available](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17299) in GitLab 16.9. Feature flag `prefix_ci_build_tokens` removed.) |
| Trigger token                     | `glptt-`           |
| Feed token                        | `glft-`            |
| Incoming mail token               | `glimt-`           |
| GitLab agent for Kubernetes token | `glagent-`         |
| GitLab session cookies            | `_gitlab_session=` |
| SCIM Tokens                       | `glsoat-` <br /> &bull; ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435096) in GitLab 16.8 behind a feature flag named `prefix_scim_tokens`. Disabled by default.) <br > &bull; ([Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435423) in GitLab 16.9. Feature flag `prefix_scim_tokens` removed.) |
| Feature Flags Client token        | `glffct-`          |

## Security considerations

1. Treat access tokens like passwords and keep them secure.
1. When creating a scoped token, consider using the most limited scope possible to reduce the impact of accidentally leaking the token.
1. When creating a token, consider setting a token that expires when your task is complete. For example, if performing a one-off import, set the
   token to expire after a few hours or a day. This reduces the impact of a token that is accidentally leaked because it is useless when it expires.
1. If you have set up a demo environment to showcase a project you have been working on and you are recording a video or writing a blog post describing that project, make sure you are not leaking sensitive secrets (for example a personal access token (PAT), feed token or trigger token) during that process. If you have finished the demo, you must revoke all the secrets created during that demo. For more information, see [revoking a PAT](../user/profile/personal_access_tokens.md#revoke-a-personal-access-token).
1. Adding access tokens to URLs is a security risk, especially when cloning or adding a remote because Git then writes the URL to its `.git/config` file in plain text. URLs are
   also generally logged by proxies and application servers, which makes those credentials visible to system administrators. Instead, pass API calls an access token using
   headers like [the `Private-Token` header](../api/rest/index.md#personalprojectgroup-access-tokens).
1. You can also store token using a [Git credential storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
1. Do not:

   - Store tokens in plain text in your projects.
   - Include tokens when pasting code, console commands, or log outputs into an issue, MR description, or comment.

   Consider an approach such as [using external secrets in CI](../ci/secrets/index.md).
1. Do not log credentials in the console logs or artifacts. Consider [protecting](../ci/variables/index.md#protect-a-cicd-variable) and
   [masking](../ci/variables/index.md#mask-a-cicd-variable) your credentials.
1. Review all active access tokens of all types on a regular basis and revoke any that are no longer needed. This includes:
   - Personal, project, and group access tokens.
   - Feed tokens.
   - Trigger tokens.
   - Runner registration tokens.
   - Any other sensitive secrets etc.

## Expired access tokens

If an existing access token is in use and reaches the `expires_at` value, the token
expires and:

- Can no longer be used for authentication.
- Is not visible in the UI.

Requests made using this token return a `401 Unauthorized` response. Too many
unauthorized requests in a short period of time from the same IP address
result in `403 Forbidden` responses from GitLab.com.

For more information on authentication request limits, see [Git and container registry failed authentication ban](../user/gitlab_com/index.md#git-and-container-registry-failed-authentication-ban).

### Identify expired access tokens from logs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464652) in GitLab 17.2.

Prerequisites:

You must:

- Be an administrator.
- Have access to the [`api_json.log`](../administration/logs/index.md#api_jsonlog) file.

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

To find more information about this token, use the [personal access token API](../api/personal_access_tokens.md#get-single-personal-access-token).
You can also use the API to [rotate the token](../api/personal_access_tokens.md#rotate-a-personal-access-token).

### Replace expired access tokens

To replace the token:

1. Check where this token may have been used previously, and remove it from any
   automation might still use the token.
   - For personal access tokens, use the [API](../api/personal_access_tokens.md#list-personal-access-tokens)
     to list tokens that have expired recently. For example, go to `https://gitlab.com/api/v4/personal_access_tokens`,
     and locate tokens with a specific `expires_at` date.
   - For project access tokens, use the
     [project access tokens API](../api/project_access_tokens.md#list-project-access-tokens)
     to list recently expired tokens.
   - For group access tokens, use the
     [group access tokens API](../api/group_access_tokens.md#list-group-access-tokens)
     to list recently expired tokens.
1. Create a new access token:
   - For personal access tokens, [use the UI](../user/profile/personal_access_tokens.md#create-a-personal-access-token)
     or [Users API](../api/users.md#create-a-personal-access-token).
   - For a project access token, [use the UI](../user/project/settings/project_access_tokens.md#create-a-project-access-token)
     or [project access tokens API](../api/project_access_tokens.md#create-a-project-access-token).
   - For a group access token, [use the UI](../user/group/settings/group_access_tokens.md#create-a-group-access-token-using-ui)
     or [group access tokens API](../api/group_access_tokens.md#create-a-group-access-token).
1. Replace the old access token with the new access token. This process varies
   depending on how you use the token, for example if configured as a secret or
   embedded within an application. Requests made from this token should no longer
   return `401` responses.

## Troubleshooting

### Identify personal, project, and group access tokens expiring on a certain date

Access tokens that have no expiration date are valid indefinitely, which is a
security risk if the access token is divulged.

To manage this risk, when you upgrade to GitLab 16.0 and later, any
[personal](../user/profile/personal_access_tokens.md),
[project](../user/project/settings/project_access_tokens.md), or
[group](../user/group/settings/group_access_tokens.md) access
token that does not have an expiration date automatically has an expiration
date set at one year from the date of upgrade.

If you are not aware of when your tokens expire because the dates have changed,
you might have unexpected authentication failures when trying to sign into GitLab
on that date.

To manage this issue, you should upgrade to GitLab 17.2 or later, because these versions
contain a [tool that assists with analyzing, extending, or remove token expiration dates](../administration/raketasks/tokens/index.md).

If you cannot run the tool, you can also run scripts in self-managed instances to identify
tokens that either:

- Expire on a specific date.
- Have no expiration date.

You run these scripts from your terminal window in either:

- A [Rails console session](../administration/operations/rails_console.md#starting-a-rails-console-session).
- Using the [Rails Runner](../administration/operations/rails_console.md#using-the-rails-runner).

The specific scripts you run differ depending on if you have upgraded to GitLab 16.0
and later, or not:

- If you have not yet upgraded to GitLab 16.0 or later, [identify tokens that do not have an expiration date](#find-tokens-with-no-expiration-date).
- If you have upgraded to GitLab 16.0 or later, use scripts to identify any of
  the following:
  - [Tokens expiring on a specific date](#find-all-tokens-expiring-on-a-specific-date).
  - [Tokens expiring in a specific month](#find-tokens-expiring-in-a-given-month).
  - [Dates when many tokens expire](#identify-dates-when-many-tokens-expire).

After you have identified tokens affected by this issue, you can run a final script
to [extend the lifetime of specific tokens](#extend-token-lifetime) if needed.

These scripts return results in the following format:

```plaintext
Expired Group Access Token in Group ID 25, Token ID: 8, Name: Example Token, Scopes: ["read_api", "create_runner"], Last used:
Expired Project Access Token in Project ID 2, Token ID: 9, Name: Test Token, Scopes: ["api", "read_registry", "write_registry"], Last used: 2022-02-11 13:22:14 UTC
```

For more information on this, see [incident 18003](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18003).

#### Find all tokens expiring on a specific date

This script finds tokens that expire on a specific date.

Prerequisites:

- You must know the exact date your instance was upgraded to GitLab 16.0.

To use it:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, connect to your instance.
1. Start a Rails console session with `sudo gitlab-rails console`.
1. Depending on your needs, copy either the entire [`expired_tokens.rb`](#expired_tokensrb)
   or [`expired_tokens_date_range.rb`](#expired_tokens_date_rangerb) script below, and paste it into the console.
   Change the `expires_at_date` to the date one year after your instance was upgraded to GitLab 16.0.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Depending on your needs, copy either the entire [`expired_tokens.rb`](#expired_tokensrb)
   or [`expired_tokens_date_range.rb`](#expired_tokens_date_rangerb) script below, and save it
   as a file on your instance:
   - Name it `expired_tokens.rb`.
   - Change the `expires_at_date` to the date one year after your instance was upgraded to GitLab 16.0.
   - The file must be accessible to `git:git`.
1. Run this command, changing the path to the _full_ path to your `expired_tokens.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../administration/operations/rails_console.md#troubleshooting).

::EndTabs

##### `expired_tokens.rb`

This script requires you to know the exact date your GitLab instance
was upgraded to GitLab 16.0.

```ruby
# Change this value to the date one year after your GitLab instance was upgraded.

expires_at_date = "2024-05-22"

# Check for expiring personal access tokens
PersonalAccessToken.owner_is_human.where(expires_at: expires_at_date).find_each do |token|
  puts "Expired Personal Access Token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: expires_at_date).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

#### Find tokens expiring in a given month

This script finds tokens that expire in a particular month. You don't need to know
the exact date your instance was upgraded to GitLab 16.0. To use it:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire [`tokens_with_no_expiry.rb`](#tokens_with_no_expiryrb) script below.
   If desired, change the `date_range` to a different range.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire [`tokens_with_no_expiry.rb`](#tokens_with_no_expiryrb) script below, and save it as a file on your instance:
   - Name it `expired_tokens_date_range.rb`.
   - If desired, change the `date_range` to a different range.
   - The file must be accessible to `git:git`.
1. Run this command, changing `/path/to/expired_tokens_date_range.rb`
   to the _full_ path to your `expired_tokens_date_range.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens_date_range.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../administration/operations/rails_console.md#troubleshooting).

::EndTabs

##### `expired_tokens_date_range.rb`

```ruby
# This script enables you to search for tokens that expire within a
# certain date range (like 1.month) from the current date. Use it if
# you're unsure when exactly your GitLab 16.0 upgrade completed.

date_range = 1.month

# Check for personal access tokens
PersonalAccessToken.owner_is_human.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  puts "Expired Personal Access Token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

#### Identify dates when many tokens expire

This script identifies dates when most of tokens expire. You can use it in combination with other scripts on this page to identify and extend large batches of tokens that may be approaching their expiration date, in case your team has not yet set up token rotation.

The script returns results in this format:

```plaintext
42 Personal Access Tokens will expire at 2024-06-27
17 Personal Access Tokens will expire at 2024-09-23
3 Personal Access Tokens will expire at 2024-08-13
```

To use it:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire [`dates_when_most_of_tokens_expire.rb`](#dates_when_most_of_tokens_expirerb) script.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire [`dates_when_most_of_tokens_expire.rb`](#dates_when_most_of_tokens_expirerb)
   script, and save it as a file on your instance:
   - Name it `dates_when_most_of_tokens_expire.rb`.
   - The file must be accessible to `git:git`.
1. Run this command, changing `/path/to/dates_when_most_of_tokens_expire.rb`
   to the _full_ path to your `dates_when_most_of_tokens_expire.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/dates_when_most_of_tokens_expire.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../administration/operations/rails_console.md#troubleshooting).

::EndTabs

##### `dates_when_most_of_tokens_expire.rb`

```ruby
PersonalAccessToken
  .select(:expires_at, Arel.sql('count(*)'))
  .where('expires_at >= NOW()')
  .group(:expires_at)
  .order(Arel.sql('count(*) DESC'))
  .limit(10)
  .each do |token|
    puts "#{token.count} Personal Access Tokens will expire at #{token.expires_at}"
  end
```

#### Find tokens with no expiration date

This script finds tokens that lack an expiration date: `expires_at` is `NULL`. For users
who have not yet upgraded to GitLab version 16.0 or later, the token `expires_at`
value is `NULL`, and can be used to identify tokens to add an expiration date to.

You can use this script in either the [Rails console](../administration/operations/rails_console.md)
or the [Rails Runner](../administration/operations/rails_console.md#using-the-rails-runner):

::Tabs

:::TabTitle Rails console session

1. In your terminal window, connect to your instance.
1. Start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire [`tokens_with_no_expiry.rb`](#tokens_with_no_expiryrb) script below.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire [`tokens_with_no_expiry.rb`](#tokens_with_no_expiryrb) script below, and save it as a file on your instance:
   - Name it `tokens_with_no_expiry.rb`.
   - The file must be accessible to `git:git`.
1. Run this command, changing the path to the _full_ path to your `tokens_with_no_expiry.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/tokens_with_no_expiry.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../administration/operations/rails_console.md#troubleshooting).

::EndTabs

##### `tokens_with_no_expiry.rb`

This script finds tokens without a value set for `expires_at`.

   ```ruby
   # This script finds tokens which do not have an expires_at value set.

   # Check for expiring personal access tokens
   PersonalAccessToken.owner_is_human.where(expires_at: nil).find_each do |token|
     puts "Expires_at is nil for Personal Access Token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
   end

   # Check for expiring project and group access tokens
   PersonalAccessToken.project_access_token.where(expires_at: nil).find_each do |token|
     token.user.members.each do |member|
       type = member.is_a?(GroupMember) ? 'Group' : 'Project'

       puts "Expires_at is nil for #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
     end
   end
   ```

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

Users that have intentionally set a token to expire on the specified date will have their
token lifetimes extended as well.

To use the script:

::Tabs

:::TabTitle Rails console session

1. In your terminal window, start a Rails console session with `sudo gitlab-rails console`.
1. Paste in the entire [`extend_expiring_tokens.rb`](#extend_expiring_tokensrb) script below.
   If desired, change the `expiring_date` to a different date.
1. Press <kbd>Enter</kbd>.

:::TabTitle Rails Runner

1. In your terminal window, connect to your instance.
1. Copy this entire [`extend_expiring_tokens.rb`](#extend_expiring_tokensrb) script below, and save it as a file on your instance:
   - Name it `extend_expiring_tokens.rb`.
   - If desired, change the `expiring_date` to a different date.
   - The file must be accessible to `git:git`.
1. Run this command, changing `/path/to/extend_expiring_tokens.rb`
   to the _full_ path to your `extend_expiring_tokens.rb` file:

   ```shell
   sudo gitlab-rails runner /path/to/extend_expiring_tokens.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../administration/operations/rails_console.md#troubleshooting).

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
