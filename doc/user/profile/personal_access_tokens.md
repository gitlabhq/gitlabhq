---
type: concepts, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Personal access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3749) in GitLab 8.8.
> - [Notifications about expiring tokens](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) added in GitLab 12.6.
> - [Token lifetime limits](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) added in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.

If you're unable to use [OAuth2](../../api/oauth2.md), you can use a personal access token to authenticate with the [GitLab API](../../api/README.md#personalproject-access-tokens).

You can also use personal access tokens with Git to authenticate over HTTP or SSH. Personal access tokens are required when [Two-Factor Authentication (2FA)](../account/two_factor_authentication.md) is enabled. In both cases, you can authenticate with a token in place of your password.

Personal access tokens expire on the date you define, at midnight UTC.

- GitLab runs a check at 01:00 AM UTC every day to identify personal access tokens that will expire in under seven days. The owners of these tokens are notified by email.
- In GitLab Ultimate, administrators may [limit the lifetime of personal access tokens](../admin_area/settings/account_and_limit_settings.md#limiting-lifetime-of-personal-access-tokens-ultimate-only).

For examples of how you can use a personal access token to authenticate with the API, see the following section from our [API Docs](../../api/README.md#personalproject-access-tokens).

GitLab also offers [impersonation tokens](../../api/README.md#impersonation-tokens) which are created by administrators via the API. They're a great fit for automated authentication as a specific user.

## Creating a personal access token

You can create as many personal access tokens as you like from your GitLab
profile.

1. Log in to GitLab.
1. In the upper-right corner, click your avatar and select **Settings**.
1. On the  **User Settings** menu, select **Access Tokens**.
1. Choose a name and optional expiry date for the token.
1. Choose the [desired scopes](#limiting-scopes-of-a-personal-access-token).
1. Click the **Create personal access token** button.
1. Save the personal access token somewhere safe. Once you leave or refresh
   the page, you won't be able to access it again.

### Revoking a personal access token

At any time, you can revoke any personal access token by clicking the
respective **Revoke** button under the **Active Personal Access Token** area.

## Limiting scopes of a personal access token

Personal access tokens can be created with one or more scopes that allow various
actions that a given token can perform. The available scopes are depicted in
the following table.

| Scope              | Introduced in | Description |
| ------------------ | ------------- | ----------- |
| `read_user`        | [GitLab 8.15](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5951)   | Allows access to the read-only endpoints under `/users`. Essentially, any of the `GET` requests in the [Users API](../../api/users.md) are allowed. |
| `api`              | [GitLab 8.15](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5951)   | Grants complete read/write access to the API, including all groups and projects, the container registry, and the package registry. |
| `read_api`           | [GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28944)  | Grants read access to the API, including all groups and projects, the container registry, and the package registry. |
| `read_registry`    | [GitLab 9.3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11845)   | Allows to read (pull) [container registry](../packages/container_registry/index.md) images if a project is private and authorization is required. |
| `sudo`             | [GitLab 10.2](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14838)  | Allows performing API actions as any user in the system (if the authenticated user is an admin). |
| `read_repository`  | [GitLab 10.7](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17894)  | Allows read-only access (pull) to the repository through `git clone`. |
| `write_repository` | [GitLab 11.11](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26021) | Allows read-write access (pull, push) to the repository through `git clone`. Required for accessing Git repositories over HTTP when 2FA is enabled. |

## Programmatically creating a personal access token

You can programmatically create a predetermined personal access token for use in
automation or tests. You will need sufficient access to run a
[Rails console session](../../administration/troubleshooting/debug.md#starting-a-rails-console-session)
for your GitLab instance.

To create a token belonging to a user with username `automation-bot`, run the
following in the Rails console (`sudo gitlab-rails console`):

```ruby
user = User.find_by_username('automation-bot')
token = user.personal_access_tokens.create(scopes: [:read_user, :read_repository], name: 'Automation token')
token.set_token('token-string-here123')
token.save!
```

This can be shortened into a single-line shell command using the
[GitLab Rails Runner](../../administration/troubleshooting/debug.md#using-the-rails-runner):

```shell
sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: [:read_user, :read_repository], name: 'Automation token'); token.set_token('token-string-here123'); token.save!"
```

NOTE: **Note:**
The token string must be 20 characters in length, or it will not be
recognized as a personal access token.

The list of valid scopes and what they do can be found
[in the source code](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/auth.rb).

## Programmatically revoking a personal access token

You can programmatically revoke a personal access token. You will need
sufficient access to run a [Rails console session](../../administration/troubleshooting/debug.md#starting-a-rails-console-session)
for your GitLab instance.

To revoke a known token `token-string-here123`, run the following in the Rails
console (`sudo gitlab-rails console`):

```ruby
token = PersonalAccessToken.find_by_token('token-string-here123')
token.revoke!
```

This can be shorted into a single-line shell command using the
[GitLab Rails Runner](../../administration/troubleshooting/debug.md#using-the-rails-runner):

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
