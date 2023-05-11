---
type: concepts, howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Personal access tokens **(FREE)**

> - Notifications for expiring tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) in GitLab 12.6.
> - Token lifetime limits [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) in GitLab 12.6.
> - Additional notifications for expiring tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214721) in GitLab 13.3.
> - Prefill for token name and scopes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334664) in GitLab 14.1.

Personal access tokens can be an alternative to [OAuth2](../../api/oauth2.md) and used to:

- Authenticate with the [GitLab API](../../api/rest/index.md#personalprojectgroup-access-tokens).
- Authenticate with Git using HTTP Basic Authentication.

In both cases, you authenticate with a personal access token in place of your password.

WARNING:
The ability to create personal access tokens without expiry was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369122) in GitLab 15.4 and is planned for removal in GitLab
16.0. When this ability is removed, existing personal access tokens without an expiry are planned to have an expiry added.
The automatic adding of an expiry occurs on GitLab.com during the 16.0 milestone. The automatic adding of an expiry
occurs on self-managed instances when they are upgraded to GitLab 16.0. This change is a breaking change.

Personal access tokens are:

- Required when [two-factor authentication (2FA)](account/two_factor_authentication.md) is enabled.
- Used with a GitLab username to authenticate with GitLab features that require usernames. For example,
  [GitLab-managed Terraform state backend](../infrastructure/iac/terraform_state.md#use-your-gitlab-backend-as-a-remote-data-source)
  and [Docker container registry](../packages/container_registry/authenticate_with_container_registry.md),
- Similar to [project access tokens](../project/settings/project_access_tokens.md) and [group access tokens](../group/settings/group_access_tokens.md), but are attached
  to a user rather than a project or group.

NOTE:
Though required, GitLab usernames are ignored when authenticating with a personal access token.
There is an [issue for tracking](https://gitlab.com/gitlab-org/gitlab/-/issues/212953) to make GitLab
use the username.

For examples of how you can use a personal access token to authenticate with the API, see the [API documentation](../../api/rest/index.md#personalprojectgroup-access-tokens).

Alternately, GitLab administrators can use the API to create [impersonation tokens](../../api/rest/index.md#impersonation-tokens).
Use impersonation tokens to automate authentication as a specific user.

## Create a personal access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348660) in GitLab 15.3, default expiration of 30 days is populated in the UI.

You can create as many personal access tokens as you like.

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. Enter a name and optional expiry date for the token.
1. Select the [desired scopes](#personal-access-token-scopes).
1. Select **Create personal access token**.

Save the personal access token somewhere safe. After you leave the page,
you no longer have access to the token.

### Prefill personal access token name and scopes

You can link directly to the Personal Access Token page and have the form prefilled with a name and
list of scopes. To do this, you can append a `name` parameter and a list of comma-separated scopes
to the URL. For example:

```plaintext
https://gitlab.example.com/-/profile/personal_access_tokens?name=Example+Access+token&scopes=api,read_user,read_registry
```

WARNING:
Personal access tokens must be treated carefully. Read our [token security considerations](../../security/token_overview.md#security-considerations)
for guidance on managing personal access tokens (for example, setting a short expiry and using minimal scopes).

## Revoke a personal access token

At any time, you can revoke a personal access token.

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. In the **Active personal access tokens** area, next to the key, select **Revoke**.

## View the last time a token was used

Token usage information is updated every 24 hours. GitLab considers a token used when the token is used to:

- Authenticate with the [REST](../../api/rest/index.md) or [GraphQL](../../api/graphql/index.md) APIs.
- Perform a Git operation.

To view the last time a token was used:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. In the **Active personal access tokens** area, next to the key, view the **Last Used** date.

## Personal access token scopes

> Personal access tokens no longer being able to access container or package registries [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387721) in GitLab 16.0.

A personal access token can perform actions based on the assigned scopes.

| Scope              | Access |
|--------------------|--------|
| `api`              | Grants complete read/write access to the API, including all groups and projects, the container registry, and the package registry. |
| `read_user`        | Grants read-only access to the authenticated user's profile through the `/user` API endpoint, which includes username, public email, and full name. Also grants access to read-only API endpoints under [`/users`](../../api/users.md). |
| `read_api`         | Grants read access to the API, including all groups and projects, the container registry, and the package registry. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28944) in GitLab 12.10.) |
| `read_repository`  | Grants read-only access to repositories on private projects using Git-over-HTTP or the Repository Files API. |
| `write_repository` | Grants read-write access to repositories on private projects using Git-over-HTTP (not using the API). |
| `read_registry`    | Grants read-only (pull) access to a [Container Registry](../packages/container_registry/index.md) images if a project is private and authorization is required. Available only when the Container Registry is enabled. |
| `write_registry`   | Grants read-write (push) access to a [Container Registry](../packages/container_registry/index.md) images if a project is private and authorization is required. Available only when the Container Registry is enabled. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28958) in GitLab 12.10.) |
| `sudo`             | Grants permission to perform API actions as any user in the system, when authenticated as an administrator. |
| `admin_mode`             | Grants permission to perform API actions as an administrator, when Admin Mode is enabled. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107875) in GitLab 15.8.) |

WARNING:
If you enabled [external authorization](../admin_area/settings/external_authorization.md), personal access tokens cannot access container or package registries. If you use personal access tokens to access these registries, this measure breaks this use of these tokens. Disable external authorization to use personal access tokens with container or package registries.

## When personal access tokens expire

Personal access tokens expire on the date you define, at midnight UTC.

- GitLab runs a check at 01:00 AM UTC every day to identify personal access tokens that expire in the next seven days. The owners of these tokens are notified by email.
- GitLab runs a check at 02:00 AM UTC every day to identify personal access tokens that expire on the current date. The owners of these tokens are notified by email.
- In GitLab Ultimate, administrators can
  [limit the lifetime of access tokens](../admin_area/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).

## Create a personal access token programmatically **(FREE SELF)**

You can create a predetermined personal access token
as part of your tests or automation.

Prerequisite:

- You need sufficient access to run a
  [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session)
  for your GitLab instance.

To create a personal access token programmatically:

1. Open a Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Run the following commands to reference the username, the token, and the scopes.

   The token must be 20 characters long. The scopes must be valid and are visible
   [in the source code](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/auth.rb).

   For example, to create a token that belongs to a user with username `automation-bot`:

   ```ruby
   user = User.find_by_username('automation-bot')
   token = user.personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token')
   token.set_token('token-string-here123')
   token.save!
   ```

This code can be shortened into a single-line shell command by using the
[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner):

```shell
sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token'); token.set_token('token-string-here123'); token.save!"
```

## Revoke a personal access token programmatically **(FREE SELF)**

You can programmatically revoke a personal access token
as part of your tests or automation.

Prerequisite:

- You need sufficient access to run a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session)
  for your GitLab instance.

To revoke a token programmatically:

1. Open a Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. To revoke a token of `token-string-here123`, run the following commands:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.revoke!
   ```

This code can be shortened into a single-line shell command using the
[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner):

```shell
sudo gitlab-rails runner "PersonalAccessToken.find_by_token('token-string-here123').revoke!"
```

## Clone repository using personal access token **(FREE SELF)**

To clone a repository when SSH is disabled, clone it using a personal access token by running the following command:

```shell
git clone https://<username>:<personal_token>@gitlab.com/gitlab-org/gitlab.git
```

This method saves your personal access token in your bash history. To avoid this, run the following command:

```shell
git clone https://<username>@gitlab.com/gitlab-org/gitlab.git
```

When asked for your password for `https://gitlab.com`, enter your personal access token.

The `username` in the `clone` command:

- Can be any string value.
- Must not be an empty string.

Remember this if you set up an automation pipeline that depends on authentication.

## Troubleshooting

### Unrevoke a personal access token **(FREE SELF)**

If a personal access token is revoked accidentally by any method, administrators can unrevoke that token. By default, a daily job deletes revoked tokens at 1:00 AM system time.

WARNING:
Running the following commands changes data directly. This could be damaging if not done correctly, or under the right conditions. You should first run these commands in a test environment with a backup of the instance ready to be restored, just in case.

1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Unrevoke the token:

   ```ruby
   token = PersonalAccessToken.find_by_token('<token_string>')
   token.update!(revoked:false)
   ```

   For example, to unrevoke a token of `token-string-here123`:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.update!(revoked:false)
   ```

## Alternatives to personal access tokens

For Git over HTTPS, an alternative to personal access tokens is to use an [OAuth credential helper](account/two_factor_authentication.md#oauth-credential-helpers).
