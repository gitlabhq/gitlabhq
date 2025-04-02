---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Personal access tokens
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Personal access tokens can be an alternative to [OAuth2](../../api/oauth2.md) and used to:

- Authenticate with the [GitLab API](../../api/rest/authentication.md#personalprojectgroup-access-tokens).
- Authenticate with Git using HTTP Basic Authentication.

In both cases, you authenticate with a personal access token in place of your password. Username is not evaluated as part of the authentication process.

Personal access tokens are:

- Required when [two-factor authentication (2FA)](account/two_factor_authentication.md) or
  [SAML](../../integration/saml.md#password-generation-for-users-created-through-saml) is enabled.
- Used with a GitLab username to authenticate with GitLab features that require usernames. For example,
  [GitLab-managed Terraform state backend](../infrastructure/iac/terraform_state.md#use-your-gitlab-backend-as-a-remote-data-source)
  and [Docker container registry](../packages/container_registry/authenticate_with_container_registry.md),
- Similar to [project access tokens](../project/settings/project_access_tokens.md) and [group access tokens](../group/settings/group_access_tokens.md), but are attached
  to a user rather than a project or group.

{{< alert type="note" >}}

Though required, GitLab usernames are ignored when authenticating with a personal access token.
There is an [issue for tracking](https://gitlab.com/gitlab-org/gitlab/-/issues/212953) to make GitLab
use the username.

{{< /alert >}}

For examples of how you can use a personal access token to authenticate with the API, see the [API documentation](../../api/rest/authentication.md#personalprojectgroup-access-tokens).

Alternately, GitLab administrators can use the API to create [impersonation tokens](../../api/rest/authentication.md#impersonation-tokens).
Use impersonation tokens to automate authentication as a specific user.

## Create a personal access token

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348660) in GitLab 15.3, default expiration of 30 days is populated in the UI.
- Ability to create non-expiring personal access tokens [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0.
- Maximum allowable lifetime limit [extended to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) in GitLab 17.6 [with a flag](../feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.
- Personal access token description [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443819) in GitLab 17.7.

{{< /history >}}

{{< alert type="flag" >}}

The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

{{< alert type="warning" >}}

The ability to create personal access tokens without an expiry date was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369122) in GitLab 15.4 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0. For more information on when personal access tokens expire and expiry dates are added to existing tokens, see the documentation on [access token expiration](#access-token-expiration).

{{< /alert >}}

You can create as many personal access tokens as you like.

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Select **Add new token**.
1. In **Token name**, enter a name for the token.
1. Optional. In **Token description**, enter a description for the token.
1. In **Expiration date**, enter an expiration date for the token.
   - The token expires on that date at midnight UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.
   - If you do not enter an expiry date, the expiry date is automatically set to 365 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).

1. Select the [desired scopes](#personal-access-token-scopes).
1. Select **Create personal access token**.

Save the personal access token somewhere safe. After you leave the page,
you no longer have access to the token.

### Prefill personal access token name and scopes

You can link directly to the personal access token page and have the form prefilled with a name and
list of scopes. To do this, you can append a `name` parameter and a list of comma-separated scopes
to the URL. For example:

```plaintext
https://gitlab.example.com/-/user_settings/personal_access_tokens?name=Example+Access+token&scopes=api,read_user,read_registry
```

{{< alert type="warning" >}}

Personal access tokens must be treated carefully. Read our [token security considerations](../../security/tokens/_index.md#security-considerations)
for guidance on managing personal access tokens (for example, setting a short expiry and using minimal scopes).

{{< /alert >}}

## Revoke or rotate a personal access token

{{< history >}}

- Ability to use the UI to rotate a personal access token [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241523) in GitLab 17.7.

{{< /history >}}

At any time, you can use the UI to revoke or, in GitLab 17.7 and later, rotate a personal access token.

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. In the **Active personal access tokens** area, for the relevant token, select **Revoke** ({{< icon name="remove" >}}) or **Rotate** ({{< icon name="retry" >}}).
1. On the confirmation dialog, select **Revoke** or **Rotate**.

   {{< alert type="warning" >}}

   These actions cannot be undone. Any tools that rely on a revoked or rotated access token will stop working.

   {{< /alert >}}

## Disable personal access tokens

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- You must be an administrator.

Depending on your GitLab version, you can use either the application settings API
or the Admin UI to disable personal access tokens.

### Use the application settings API

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384201) in GitLab 15.7.

{{< /history >}}

In GitLab 15.7 and later, you can use the [`disable_personal_access_tokens` attribute in the application settings API](../../api/settings.md#available-settings) to disable personal access tokens.

{{< alert type="note" >}}

After you have used the API to disable personal access tokens, those tokens cannot be used in subsequent API calls to manage this setting. To re-enable personal access tokens, you must use the [GitLab Rails console](../../administration/operations/rails_console.md). You can also upgrade to GitLab 17.3 or later so you can use the Admin UI instead.

{{< /alert >}}

### Use the Admin UI

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/436991) in GitLab 17.3.

{{< /history >}}

In GitLab 17.3 and later, you can use the Admin UI to disable personal access tokens:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Select the **Disable personal access tokens** checkbox.
1. Select **Save changes**.

### Disable personal access tokens for enterprise users

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369504) in GitLab 16.11 [with a flag](../../administration/feature_flags.md) named `enterprise_disable_personal_access_tokens`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/369504) in GitLab 17.2
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/369504) in GitLab 17.3 . Feature flag `enterprise_disable_personal_access_tokens` removed.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the group that the enterprise user belongs to.

Disabling the personal access tokens of a group's [enterprise users](../enterprise_user/_index.md):

- Stops the enterprise users from creating new personal access tokens. This behavior applies
  even if an enterprise user is also an administrator of the group.
- Disables the existing personal access tokens of the enterprise users.

{{< alert type="warning" >}}

Disabling personal access tokens for enterprise users does not disable personal access tokens for [service accounts](service_accounts.md).

{{< /alert >}}

To disable the enterprise users' personal access tokens:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Personal access tokens**, select **Disable personal access tokens**.
1. Select **Save changes**.

When you delete or block an enterprise user account, their personal access tokens are automatically revoked.

## View token usage information

{{< history >}}

- In GitLab 16.0 and earlier, token usage information is updated every 24 hours.
- The frequency of token usage information updates [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/410168) in GitLab 16.1 from 24 hours to 10 minutes.
- Ability to view IP addresses [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428577) in GitLab 17.8 [with a flag](../../administration/feature_flags.md) named `pat_ip`. Enabled by default in 17.9.
- Ability to view IP addresses made [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/513302) in GitLab 17.10. Feature flag `pat_ip` removed.

{{< /history >}}

Token usage information updates periodically. The time the token was last used updates every 10 minutes, and the most recently used IP address updates every minute. GitLab considers a token used when the token:

- Authenticates with the [REST](../../api/rest/_index.md) or [GraphQL](../../api/graphql/_index.md) APIs.
- Performs a Git operation.

To view the last time a token was used, and the IP addresses from where the token was used:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. In the **Active personal access tokens** area, view the **Last Used** date and **Last Used IPs** for
   the relevant token. **Last Used IPs** shows the last five distinct IP addresses.

## Personal access token scopes

{{< history >}}

- Personal access tokens no longer being able to access container or package registries [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387721) in GitLab 16.0.
- `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4 [with a flag](../../administration/feature_flags.md) named `k8s_proxy_pat`. Enabled by default.
- Feature flag `k8s_proxy_pat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.
- `read_service_ping` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412) in GitLab 17.1.
- `manage_runner` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460721) in GitLab 17.1.
- `self_rotate` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111) in GitLab 17.9. Enabled by default.

{{< /history >}}

A personal access token can perform actions based on the assigned scopes.

| Scope              | Access                                                                                                                                                                                                                                                                                                             |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | Grants complete read/write access to the API, including all groups and projects, the container registry, the dependency proxy, and the package registry. Also grants complete read/write access to the registry and repository using Git over HTTP.                                                                                                                                                           |
| `read_user`        | Grants read-only access to the authenticated user's profile through the `/user` API endpoint, which includes username, public email, and full name. Also grants access to read-only API endpoints under [`/users`](../../api/users.md).                                                                            |
| `read_api`         | Grants read access to the API, including all groups and projects, the container registry, and the package registry.                    |
| `read_repository`  | Grants read-only access to repositories on private projects using Git-over-HTTP or the Repository Files API.                                                                                                                                                                                                       |
| `write_repository` | Grants read-write access to repositories on private projects using Git-over-HTTP (not using the API).                                                                                                                                                                                                              |
| `read_registry`    | Grants read-only (pull) access to [container registry](../packages/container_registry/_index.md) images if a project is private and authorization is required. Available only when the container registry is enabled.                                                                                               |
| `write_registry`   | Grants read-write (push) access to [container registry](../packages/container_registry/_index.md) images if a project is private and authorization is required. Available only when the container registry is enabled.  |
| `read_virtual_registry`  | If a project is private and authorization is required, grants read-only (pull) access to container images through the [dependency proxy](../packages/dependency_proxy/_index.md). Available only when the dependency proxy is enabled. |
| `write_virtual_registry` | If a project is private and authorization is required, grants read (pull), write (push), and delete access to container images through the [dependency proxy](../packages/dependency_proxy/_index.md). Available only when the dependency proxy is enabled. |
| `sudo`             | Grants permission to perform API actions as any user in the system, when authenticated as an administrator.                                                                                                                                                                                                        |
| `admin_mode`       | Grants permission to perform API actions when [Admin Mode](../../administration/settings/sign_in_restrictions.md#admin-mode) is enabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107875) in GitLab 15.8. Available only to administrators on GitLab Self-Managed instances. |
| `create_runner`    | Grants permission to create runners.                                                                                                                                                                                                                                                                               |
| `manage_runner`    | Grants permission to manage runners.                                                                    |
| `ai_features`      | This scope:<br>- Grants permission to perform API actions for features like GitLab Duo, Code Suggestions API and Duo Chat API.<br>- Does not work for GitLab Self-Managed versions 16.5, 16.6, and 16.7.<br>For GitLab Duo plugin for JetBrains, this scope:<br>- Supports users with AI features enabled in the GitLab Duo plugin for JetBrains.<br>- Addresses a security vulnerability in JetBrains IDE plugins that could expose personal access tokens.<br>- Is designed to minimize potential risks for GitLab Duo plugin users by limiting the impact of compromised tokens.<br>For all other extensions, see the individual scope requirements in their documentation.                                                                                                                                |
| `k8s_proxy`        | Grants permission to perform Kubernetes API calls using the agent for Kubernetes.                                                                                                                                                                                                                                  |
| `self_rotate`      | Grants permission to rotate this token using the [personal access token API](../../api/personal_access_tokens.md#rotate-a-personal-access-token). Does not allow rotation of other tokens. |
| `read_service_ping`| Grant access to download Service Ping payload through the API when authenticated as an admin use. |

{{< alert type="warning" >}}

If you enabled [external authorization](../../administration/settings/external_authorization.md), personal access tokens cannot access container or package registries. If you use personal access tokens to access these registries, this measure breaks this use of these tokens. Disable external authorization to use personal access tokens with container or package registries.

{{< /alert >}}

## Access token expiration

{{< history >}}

- Maximum token lifetime of 400 days [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241523) in GitLab 17.6 [with a flag](../feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Personal access tokens expire on the date you define, at midnight, 00:00 AM UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.

- GitLab runs a check at 1:00 AM UTC every day to identify personal access tokens that expire soon. The owners of these tokens are [notified by email](#personal-access-token-expiry-emails).
- GitLab runs a check at 02:00 AM UTC every day to identify personal access tokens that expire on the current date. The owners of these tokens are notified by email.
- In GitLab Ultimate, administrators can
  [limit the allowable lifetime of access tokens](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens). If not set, the maximum allowable lifetime of a personal access token is 365 days. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).
- In GitLab Free and Premium, the maximum allowable lifetime of a personal access token is 365 days. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).
- If you do not set an expiry date when creating a personal access token, the expiry date is set to the
  [maximum allowed lifetime for the token](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).
  If the maximum allowed lifetime is not set, the default expiry date is 365 days from the date of creation.

Whether your existing personal access tokens have expiry dates automatically applied
depends on what GitLab offering you have, and when you upgraded to GitLab 16.0 or later:

- On GitLab.com, during the 16.0 milestone, existing personal access tokens without
  an expiry date were automatically given an expiry date of 365 days later than the current date.
- On GitLab Self-Managed, if you upgraded from GitLab 15.11 or earlier to GitLab 16.0 or later:
  - On or before July 23, 2024, existing personal access tokens without an expiry
    date were automatically given an expiry date of 365 days later than the current date.
    This change is a breaking change.
  - On or after July 24, 2024, existing personal access tokens without an expiry
    date did not have an expiry date set.

On GitLab Self-Managed, if you do a new install of one of the following GitLab
versions, your existing personal access tokens do not have expiry dates
automatically applied:

- 16.0.9
- 16.1.7
- 16.2.10
- 16.3.8
- 16.4.6
- 16.5.9
- 16.6.9
- 16.7.9
- 16.8.9
- 16.9.10
- 16.10.9
- 16.11.7
- 17.0.5
- 17.1.3
- 17.2.1

### Personal access token expiry emails

{{< history >}}

- 60 and 30 day expiry notifications [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464040) in GitLab 17.6 [with a flag](../../administration/feature_flags.md) named `expiring_pats_30d_60d_notifications`. Disabled by default.
- 60 and 30 day notifications [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792) in GitLab 17.7. Feature flag `expiring_pats_30d_60d_notifications` removed.

{{< /history >}}

GitLab runs a check every day at 1:00 AM UTC to identify personal access tokens that are expiring in the near future. The owners of these tokens are notified by email when these tokens expire in a certain number of days. The number of days differs depending on the version of GitLab:

- In GitLab 17.6 and later, personal access token owners are notified by email when the check identifies their personal access tokens as expiring in the next 60 days. An additional email is sent when the check identifies their group access tokens as expiring in the next 30 days.
- Personal access token owners are notified by email when the check identifies their group access tokens as expiring in the next seven days.

### Personal access token expiry calendar

You can subscribe to an iCalendar endpoint which contains events at the expiry date for each token. After signing in, this endpoint is available at `/-/user_settings/personal_access_tokens.ics`.

### Create a service account personal access token with no expiry date

You can [create a personal access token for a service account](../../api/group_service_accounts.md#create-a-personal-access-token-for-a-service-account-user) with no expiry date. These personal access tokens never expire, unlike non-service account personal access tokens.

{{< alert type="note" >}}

Allowing personal access tokens for service accounts to be created with no expiry date only affects tokens created after you change this setting. It does not affect existing tokens.

{{< /alert >}}

#### GitLab.com

Prerequisites:

- You must have the Owner role for the top-level group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General > Permissions and group features**.
1. Clear the **Service account token expiration** checkbox.

You can now create personal access tokens for a service account user with no expiry date.

#### GitLab Self-Managed

Prerequisites:

- You must be an administrator for your GitLab Self-Managed instance.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Clear the **Service account token expiration** checkbox.

You can now create personal access tokens for a service account user with no expiry date.

## Require DPoP headers with personal access tokens

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181053) in GitLab 17.10 [with a flag](../../administration/feature_flags.md) named `dpop_authentication`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Demonstrating Proof of Possession (DPoP) enhances the security of your personal access tokens,
and minimizes the effects of unintended token leaks. When you enable this feature on your
account, all REST and GraphQL API requests containing a PAT must also provide a signed DPoP header. Creating a
signed DPoP header requires your corresponding private SSH key.

{{< alert type="note" >}}

If you enable this feature, all REST and GraphQL API requests without a valid DPoP header fail with a `DpopValidationError`.

{{< /alert >}}

Prerequisites:

- You must have [added at least one public SSH key](../ssh.md#add-an-ssh-key-to-your-gitlab-account)
  to your account, with the **Usage type** of **Signing**, or **Authentication & Signing**.
- You must have installed and configured the [GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)
  for your GitLab account.

To require DPoP on all calls to the REST and GraphQL APIs:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. Go to the **Use Demonstrating Proof of Possession** section, and select **Enable DPoP**.
1. Select **Save changes**.
1. To generate a DPoP header with the [GitLab CLI](../../editor_extensions/gitlab_cli/_index.md),
   run this command in your terminal. Replace `<your_access_token>` with your access token, and `~/.ssh/id_rsa`
   with the location of your private key:

   ```shell
    bin/glab auth dpop-gen --pat "<your_access_token>" --private-key ~/.ssh/id_rsa
   ```

The DPoP header you generated in the CLI can be used:

- With the REST API:

  ```shell
  curl --header "Private-Token: <your_access_token>" \
    --header "DPoP: <dpop-from-glab>" \
    "https://gitlab.example.com/api/v4/projects"
  ```

- With GraphQL:

  ```shell
   curl --request POST \
   --header "Content-Type: application/json" \
   --header "Private-Token: <your_access_token>" \
   --header "DPoP: <dpop-from-glab>" \
   --data '{
   "query": "query { currentUser { id } }"
   }' \
   "https://gitlab.example.com/api/graphql"
  ```

To learn more about DPoP headers, see the blueprint
[Sender Constraining Personal Access Tokens](https://gitlab.com/gitlab-com/gl-security/product-security/appsec/security-feature-blueprints/-/tree/main/sender_constraining_access_tokens).

## Create a personal access token programmatically

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can create a predetermined personal access token
as part of your tests or automation.

Prerequisites:

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

   For example, to create a token that belongs to a user with username `automation-bot` and expires in a year:

   ```ruby
   user = User.find_by_username('automation-bot')
   token = user.personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token', expires_at: 365.days.from_now)
   token.set_token('token-string-here123')
   token.save!
   ```

This code can be shortened into a single-line shell command by using the
[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner):

```shell
sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token', expires_at: 365.days.from_now); token.set_token('token-string-here123'); token.save!"
```

## Revoke a personal access token programmatically

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can programmatically revoke a personal access token
as part of your tests or automation.

Prerequisites:

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

## Clone repository using personal access token

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

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

### Unrevoke a personal access token

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If a personal access token is revoked accidentally by any method, administrators can unrevoke that token. By default, a daily job deletes revoked tokens at 1:00 AM system time.

{{< alert type="warning" >}}

Running the following commands changes data directly. This could be damaging if not done correctly, or under the right conditions. You should first run these commands in a test environment with a backup of the instance ready to be restored, just in case.

{{< /alert >}}

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
