---
type: concepts, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Personal access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3749) in GitLab 8.8.
> - [Notifications for expiring tokens](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) added in GitLab 12.6.
> - [Token lifetime limits](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) added in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.
> - [Additional notifications for expiring tokens](https://gitlab.com/gitlab-org/gitlab/-/issues/214721) added in GitLab 13.3.
> - [Prefill token name and scopes](https://gitlab.com/gitlab-org/gitlab/-/issues/334664) added in GitLab 14.1.

If you're unable to use [OAuth2](../../api/oauth2.md), you can use a personal access token to authenticate with the [GitLab API](../../api/index.md#personalproject-access-tokens). You can also use a personal access token with Git to authenticate over HTTP.

In both cases, you authenticate with a personal access token in place of your password.

Personal access tokens are required when [Two-Factor Authentication (2FA)](account/two_factor_authentication.md) is enabled.

For examples of how you can use a personal access token to authenticate with the API, see the [API documentation](../../api/index.md#personalproject-access-tokens).

Alternately, GitLab administrators can use the API to create [impersonation tokens](../../api/index.md#impersonation-tokens).
Use impersonation tokens to automate authentication as a specific user.

## Create a personal access token

You can create as many personal access tokens as you like.

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access Tokens**.
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

## Revoke a personal access token

At any time, you can revoke a personal access token.

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access Tokens**.
1. In the **Active personal access tokens** area, next to the key, select **Revoke**.

## View the last time a token was used

Token usage is updated once every 24 hours. It is updated each time the token is used to request
[API resources](../../api/api_resources.md) and the [GraphQL API](../../api/graphql/index.md).

To view the last time a token was used:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access Tokens**.
1. In the **Active personal access tokens** area, next to the key, view the **Last Used** date.

## Personal access token scopes

A personal access token can perform actions based on the assigned scopes.

| Scope              | Introduced in | Access      |
| ------------------ | ------------- | ----------- |
| `api`              | [8.15](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5951)   | Read-write for the complete API, including all groups and projects, the Container Registry, and the Package Registry. |
| `read_user`        | [8.15](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5951)   | Read-only for endpoints under `/users`. Essentially, access to any of the `GET` requests in the [Users API](../../api/users.md). |
| `read_api`         | [12.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28944)      | Read-only for the complete API, including all groups and projects, the Container Registry, and the Package Registry. |
| `read_repository`  | [10.7](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17894)  | Read-only (pull) for the repository through `git clone`. |
| `write_repository` | [11.11](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26021) | Read-write (pull, push) for the repository through `git clone`. Required for accessing Git repositories over HTTP when 2FA is enabled. |
| `read_registry`    | [9.3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11845)   | Read-only (pull) for [Container Registry](../packages/container_registry/index.md) images if a project is private and authorization is required. |
| `write_registry`    | [12.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28958)     | Read-write (push) for [Container Registry](../packages/container_registry/index.md) images if a project is private and authorization is required. |
| `sudo`             | [10.2](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14838)  | API actions as any user in the system (if the authenticated user is an administrator). |

## When personal access tokens expire

Personal access tokens expire on the date you define, at midnight UTC.

- GitLab runs a check at 01:00 AM UTC every day to identify personal access tokens that expire in the next seven days. The owners of these tokens are notified by email.
- GitLab runs a check at 02:00 AM UTC every day to identify personal access tokens that expire on the current date. The owners of these tokens are notified by email.
- In GitLab Ultimate, administrators can
  [limit the lifetime of personal access tokens](../admin_area/settings/account_and_limit_settings.md#limit-the-lifetime-of-personal-access-tokens).
- In GitLab Ultimate, administrators can choose whether or not to
  [enforce personal access token expiration](../admin_area/settings/account_and_limit_settings.md#allow-expired-personal-access-tokens-to-be-used).

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
   token = user.personal_access_tokens.create(scopes: [:read_user, :read_repository], name: 'Automation token')
   token.set_token('token-string-here123')
   token.save!
   ```

This code can be shortened into a single-line shell command by using the
[Rails runner](../../administration/troubleshooting/debug.md#using-the-rails-runner):

```shell
sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: [:read_user, :read_repository], name: 'Automation token'); token.set_token('token-string-here123'); token.save!"
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
[Rails runner](../../administration/troubleshooting/debug.md#using-the-rails-runner):

```shell
sudo gitlab-rails runner "PersonalAccessToken.find_by_token('token-string-here123').revoke!"
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
