---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Group access tokens
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Group access tokens provide authenticated access to a group and its projects. They are similar to
personal access tokens and project access tokens, but are attached to a group rather than a user
or project. You cannot use group access tokens to create other group, project, or personal
access tokens.

You can use a group access token to authenticate:

- With the [GitLab API](../../../api/rest/authentication.md#personal-project-and-group-access-tokens).
- With Git over HTTPS. Use:
  - Any non-blank value as a username.
  - The group access token as the password.

Prerequisites:

- The Owner role for the group.

> [!note]
> On GitLab.com, group access tokens require a Premium or Ultimate subscription. They are not
> available during a [trial](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded).
>
> On GitLab Self-Managed and GitLab Dedicated, group access tokens are available with any license.

## View your access tokens

{{< history >}}

- In GitLab 16.0 and earlier, token usage information is updated every 24 hours.
- The frequency of token usage information updates [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/410168) in GitLab 16.1 from 24 hours to 10 minutes.
- Ability to view IP addresses [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428577) in GitLab 17.8 [with a flag](../../../administration/feature_flags/_index.md) named `pat_ip`. Enabled by default in 17.9.
- Ability to view IP addresses made [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/513302) in GitLab 17.10. Feature flag `pat_ip` removed.

{{< /history >}}

The group access tokens page displays information about your access tokens.

From this page, you can perform the following actions:

- Create, rotate, and revoke group access tokens.
- View all active and inactive group access tokens.
- View token information, including, scopes, assigned roles, and expiration dates.
- View usage information, including usage dates, and of the last five distinct connection IP addresses.
  > [!note]
  > GitLab periodically updates token usage information when the token performs a Git operation or
  > authenticates an operation with the [REST](../../../api/rest/_index.md) or
  > [GraphQL](../../../api/graphql/_index.md) API. Token usage times are updated every 10 minutes,
  > token usage IP addresses update every minute.

To view your group access tokens:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Access tokens**.

Active and usable access tokens are stored in the **Active group access tokens** section.
Expired, rotated, or revoked tokens are stored in the **Inactive group access tokens** section.

## Create a group access token

{{< history >}}

- Ability to create non-expiring group access tokens was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0.
- Maximum allowable lifetime limit [extended to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) in GitLab 17.6 [with a flag](../../../administration/feature_flags/_index.md) named `buffered_token_expiration_limit`. Disabled by default.
- Group access token description [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443819) in GitLab 17.7.

{{< /history >}}

> [!flag]
> The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
> For more information, see the history.

### With the UI

To create a group access token:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Access tokens**.
1. Select **Add new token**.
1. In **Token name**, enter a name. The token name is visible to any user with permissions to view the group.
1. Optional. In **Token description**, enter a description for the token.
1. In **Expiration date**, enter an expiry date for the token.
   - The token expires at midnight UTC on that date.
   - If you do not enter a date, the expiry date is set to 365 days from today.
   - By default, the expiry date cannot be more than 365 days from today. On GitLab 17.6 and later,
     administrators can [modify the maximum lifetime of access tokens](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).
1. Select a role for the token.
1. Select one or more [group access token scopes](#group-access-token-scopes).
1. Select **Create group access token**.

A group access token is displayed. Save the group access token somewhere safe. After you leave
or refresh the page, you cannot view it again.

All group access tokens inherit the
[default prefix setting](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)
configured for personal access tokens.

> [!warning]
> Group access tokens are treated as internal users.
> If an internal user creates a group access token, that token can access
> all projects that have visibility level set to Internal.

### With the Rails console

If you are an administrator, you can create group access tokens in the Rails console:

1. Run the following commands in a [Rails console](../../../administration/operations/rails_console.md):

   ```ruby
   # Set the GitLab administration user to use. If user ID 1 is not available or is not an administrator, use 'admin = User.admins.first' instead to select an administrator.
   admin = User.find(1)

   # Set the group you want to create a token for. For example, group with ID 109.
   group = Group.find(109)

   # Create the group bot user. For further group access tokens, the username should be `group_{group_id}_bot_{random_string}` and email address `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`.
   random_string = SecureRandom.hex(16)
   service_response = Users::CreateService.new(admin, { name: 'group_token', username: "group_#{group.id}_bot_#{random_string}", email: "group_#{group.id}_bot_#{random_string}@noreply.#{Gitlab.config.gitlab.host}", user_type: :project_bot }).execute
   bot = service_response.payload[:user] if service_response.success?

   # Confirm the group bot.
   bot.confirm

   # Add the bot to the group with the required role.
   group.add_member(bot, :maintainer)

   # Give the bot a personal access token.
   token = bot.personal_access_tokens.create(scopes:[:api, :write_repository], name: 'group_token')

   # Get the token value.
   gtoken = token.token
   ```

1. Test if the generated group access token works:

   1. Use the group access token in the `PRIVATE-TOKEN` header with GitLab REST APIs. For example:

      - [Create an epic](../../../api/epics.md#create-an-epic) in the group.
      - [Create a project pipeline](../../../api/pipelines.md#create-a-new-pipeline) in one of the group's projects.
      - [Create an issue](../../../api/issues.md#create-an-issue) in one of the group's projects.

   1. Use the group token to [clone a group's project](../../../topics/git/clone.md#clone-with-https)
      using HTTPS.

### Group access token scopes

{{< history >}}

- `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4 [with a flag](../../../administration/feature_flags/_index.md) named `k8s_proxy_pat`. Enabled by default.
- Feature flag `k8s_proxy_pat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.
- `self_rotate` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111) in GitLab 17.9. Enabled by default.

{{< /history >}}

Scopes define the actions available when you authenticate with a group access token.

| Scope                    | Description |
| ------------------------ | ----------- |
| `api`                    | Grants complete read and write access to the scoped group and related project API, including the [container registry](../../packages/container_registry/_index.md), the [dependency proxy](../../packages/dependency_proxy/_index.md), and the [package registry](../../packages/package_registry/_index.md). |
| `read_api`               | Grants read access to the scoped group and related project API, including the [package registry](../../packages/package_registry/_index.md). |
| `read_repository`        | Grants read access (pull) to all repositories in the group. |
| `write_repository`       | Grants read and write access (pull and push) to all repositories in the group. |
| `read_registry`          | Grants read access (pull) to [container registry](../../packages/container_registry/_index.md) images if any project in the group is private and authorization is required. Available only when the container registry is enabled. |
| `write_registry`         | Grants write access (push) to the [container registry](../../packages/container_registry/_index.md). To push images, you must include the `read_registry` scope. Available only when the container registry is enabled. |
| `read_virtual_registry`  | Grants read access (pull) to container images through the [dependency proxy](../../packages/dependency_proxy/_index.md). Available only when the dependency proxy is enabled. |
| `write_virtual_registry` | Grants read and write access (pull, push, and delete) to container images through the [dependency proxy](../../packages/dependency_proxy/_index.md). Available only when the dependency proxy is enabled. |
| `create_runner`          | Grants permission to create runners in the group. |
| `manage_runner`          | Grants permission to manage runners in the group. |
| `ai_features`            | Grants permission to perform API actions for GitLab Duo, the Code Suggestions API, and the GitLab Duo Chat API. Designed to work with the GitLab Duo Plugin for JetBrains. For all other extensions, see the individual extension documentation. Does not work for GitLab Self-Managed versions 16.5, 16.6, and 16.7. |
| `k8s_proxy`              | Grants permission to perform Kubernetes API calls using the agent for Kubernetes in the group. |
| `self_rotate`            | Grants permission to rotate this token using the [personal access token API](../../../api/personal_access_tokens.md#rotate-a-personal-access-token). Does not allow rotation of other tokens. |

## Rotate a group access token

{{< history >}}

- Ability to view expired and revoked tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.3 [with a flag](../../../administration/feature_flags/_index.md) named `retain_resource_access_token_user_after_revoke`. Disabled by default.
- Ability to view expired and revoked tokens until they are automatically deleted [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/471683) in GitLab 17.9. Feature flag `retain_resource_access_token_user_after_revoke` removed.

{{< /history >}}

Rotate a token to create a new token with the same permissions and scope as the original.
The original token becomes inactive immediately, and GitLab retains both versions for
audit purposes. You can view both active and inactive tokens on the access tokens page.

On GitLab Self-Managed and GitLab Dedicated, you can modify the
[retention period for inactive tokens](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period).

> [!warning]
> This action cannot be undone. Tools that rely on a rotated access token will stop working until
> you reference your new token.

To rotate a group access token:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Access tokens**.
1. For the relevant token, select **Rotate** ({{< icon name="retry" >}}).
1. In the confirmation dialog, select **Rotate**.

## Revoke a group access token

{{< history >}}

- Ability to view expired and revoked tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.3 [with a flag](../../../administration/feature_flags/_index.md) named `retain_resource_access_token_user_after_revoke`. Disabled by default.
- Ability to view expired and revoked tokens until they are automatically deleted [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/471683) in GitLab 17.9. Feature flag `retain_resource_access_token_user_after_revoke` removed.

{{< /history >}}

Revoke a token to immediately invalidate it and prevent further use. Revoked tokens are not
deleted immediately, but you can filter token lists to show only active tokens. By default,
GitLab deletes revoked group and project access tokens after 30 days. For more information, see
[inactive token retention](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period).

> [!warning]
> This action cannot be undone. Tools that rely on a revoked access token will stop working until
> you add a new token.

To revoke a group access token:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Access tokens**.
1. For the relevant token, select **Revoke** ({{< icon name="remove" >}}).
1. In the confirmation dialog, select **Revoke**.

## Access token expiration

Personal, group, and project access tokens expire at midnight UTC on the expiry date.
After they expire, they can no longer be used to authenticate requests.

In GitLab 16.0 and later, new access tokens must have an expiry date. If an expiry date isn't
explicitly set during token creation, an expiry date of 365 days from the current date is applied.
In GitLab Ultimate, administrators can configure a
[maximum allowable lifetime](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)
for access tokens.

Depending on your GitLab version and offering, your existing access tokens might have an expiry date
automatically applied when upgrading GitLab versions. For more information,
see [non-expiring access tokens](../../../update/deprecations.md#non-expiring-access-tokens).

### Group access token expiry emails

{{< history >}}

- 60 and 30 day expiry notifications [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464040) in GitLab 17.6 [with a flag](../../../administration/feature_flags/_index.md) named `expiring_pats_30d_60d_notifications`. Disabled by default.
- 60 and 30 day notifications [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792) in GitLab 17.7. Feature flag `expiring_pats_30d_60d_notifications` removed.
- Notifications to inherited group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) in GitLab 17.7 [with a flag](../../../administration/feature_flags/_index.md) named `pat_expiry_inherited_members_notification`. Disabled by default.
- Feature flag `pat_expiry_inherited_members_notification` [enabled by default in GitLab 17.10](https://gitlab.com/gitlab-org/gitlab/-/issues/393772).
- Feature flag `pat_expiry_inherited_members_notification` removed in GitLab `17.11`

{{< /history >}}

GitLab runs a daily check at 1:00 AM UTC to identify group access tokens that expire soon.
Direct members with the Owner role are notified by email seven days before a token expires. In
GitLab 17.6 and later, notifications are also sent 30 and 60 days before a token expires.

In GitLab 17.7 and later, inherited members with the Owner role can also receive these emails.
You can configure this for every group on the [GitLab instance](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members)
or a [specific group](../manage.md#expiry-emails-for-group-and-project-access-tokens).
If applied to a parent group, this setting is inherited by all descendant groups and projects.

Expired tokens appear in the inactive group access tokens section until they're automatically
deleted. On GitLab Self-Managed, you can modify this
[retention period](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period).

## Bot users for groups

When you create a group access token, GitLab creates a bot user and associates it with the token.

Bot users have the following properties:

- They are granted permissions that correspond with the role and scope of the associated access token.
- They are members of the group and inherit membership in subgroups and projects, but cannot be
  added directly to any other groups or projects.
- They are [non-billable users](../../../subscriptions/manage_seats.md#criteria-for-non-billable-users)
  and do not count towards your license limit.
- Their contributions are associated with the bot user account.
- When removed, their contributions are moved to a
  [ghost user](../../profile/account/delete_account.md#associated-records).

When the bot user is created, the following attributes are defined:

| Attribute | Value                                                                                                | Example |
| --------- | ---------------------------------------------------------------------------------------------------- | ------- |
| Name      | The name of the associated access token.                                                             | `Main token - Read registry` |
| Username  | Generated in this format: `group_{group_id}_bot_{random_string}`                                     | `group_123_bot_4ffca233d8298ea1` |
| Email     | Generated in this format: `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}` | `group_123_bot_4ffca233d8298ea1@noreply.example.com` |

## Restrict the creation of group and project access tokens

To limit potential abuse, you can restrict users from creating access tokens in a top-level group
and any descendant subgroups or projects. Any existing tokens remain valid until they expire or
are manually revoked.

To restrict the creation of access tokens:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Clear the **Users can create group access tokens and project access tokens in this group** checkbox.
1. Select **Save changes**.

## Related topics

- [Personal access tokens](../../profile/personal_access_tokens.md)
- [Project access tokens](../../project/settings/project_access_tokens.md)
- [Group access tokens API](../../../api/group_access_tokens.md)
