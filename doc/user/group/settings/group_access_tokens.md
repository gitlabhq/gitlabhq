---
stage: Software Supply Chain Security
group: Authentication
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Group access tokens
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

With group access tokens, you can use a single token to:

- Perform actions for groups.
- Manage the projects within the group.

You can use a group access token to authenticate:

- With the [GitLab API](../../../api/rest/authentication.md#personalprojectgroup-access-tokens).
- Authenticate with Git over HTTPS.
  Use:

  - Any non-blank value as a username.
  - The group access token as the password.

> On GitLab.com, you can use group access tokens if you have the Premium or Ultimate license tier. Group access tokens are not available with a [trial license](https://about.gitlab.com/free-trial/).
>
> On GitLab Dedicated and self-managed instances, you can use group access tokens with any license tier. If you have the Free tier:
>
> - Review your security and compliance policies around [user self-enrollment](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups).
> - Consider [restricting the creation of group access tokens](#restrict-the-creation-of-group-access-tokens) to lower potential abuse.

Group access tokens are similar to [project access tokens](../../project/settings/project_access_tokens.md)
and [personal access tokens](../../profile/personal_access_tokens.md), except they are
associated with a group rather than a project or user.

In self-managed instances, group access tokens are subject to the same [maximum lifetime limits](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) as personal access tokens if the limit is set.

You cannot use group access tokens to create other group, project, or personal access tokens.

Group access tokens inherit the [default prefix setting](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)
configured for personal access tokens.

## Create a group access token using UI

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348660) in GitLab 15.3, default expiration of 30 days and default role of Guest is populated in the UI.
> - Ability to create non-expiring group access tokens [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0.
> - Maximum allowable lifetime limit [extended to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) in GitLab 17.6 [with a flag](../../../administration/feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.
> - Group access token description [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443819) in GitLab 17.7.

FLAG:
The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

WARNING:
The ability to create group access tokens without an expiry date was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369122) in GitLab 15.4 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0. For more information on expiry dates added to existing tokens, see the documentation on [access token expiration](#access-token-expiration).

To create a group access token:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Access tokens**.
1. Select **Add new token**.
1. In **Token name**, enter a name. The token name is visible to any user with permissions to view the group.
1. Optional. In **Token description**, enter a description for the token.
1. In **Expiration date**, enter an expiry date for the token:
   - The token expires on that date at midnight UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.
   - If you do not enter an expiry date, the expiry date is automatically set to 365 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).

   - An instance-wide [maximum lifetime](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) setting can limit the maximum allowable lifetime in self-managed instances.
1. Select a role for the token.
1. Select the [desired scopes](#scopes-for-a-group-access-token).
1. Select **Create group access token**.

A group access token is displayed. Save the group access token somewhere safe. After you leave or refresh the page, you can't view it again.

WARNING:
Group access tokens are treated as [internal users](../../../administration/internal_users.md).
If an internal user creates a group access token, that token is able to access
all projects that have visibility level set to [Internal](../../public_access.md).

## Create a group access token using Rails console

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

      - [Create an epic](../../../api/epics.md#new-epic) in the group.
      - [Create a project pipeline](../../../api/pipelines.md#create-a-new-pipeline) in one of the group's projects.
      - [Create an issue](../../../api/issues.md#new-issue) in one of the group's projects.

   1. Use the group token to [clone a group's project](../../../topics/git/clone.md#clone-with-https)
      using HTTPS.

## Revoke or rotate a group access token

> - Ability to view expired and revoked tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.3 [with a flag](../../../administration/feature_flags.md) named `retain_resource_access_token_user_after_revoke`. Disabled by default.
> - Ability to view expired and revoked tokens limited to 30 days and [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/471683) in GitLab 17.9. Feature flag `retain_resource_access_token_user_after_revoke` removed.

In GitLab 17.9 and later, you can view both active and inactive group
access tokens on the access tokens page.

The inactive group access tokens table displays revoked and expired tokens for 30 days after they became inactive.

Tokens that belong to [an active token family](../../../api/personal_access_tokens.md#automatic-reuse-detection) are displayed for 30 days after the latest active token from the family is expired or revoked.

### Use the UI

To revoke or rotate a group access token:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Access tokens**.
1. For the relevant token, select **Revoke** (**{remove}**) or **Rotate** (**{retry}**).
1. On the confirmation dialog, select **Revoke** or **Rotate**.

## Scopes for a group access token

> - `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `k8s_proxy_pat`. Enabled by default.
> - Feature flag `k8s_proxy_pat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.
> - `self_rotate` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111) in GitLab 17.9. Enabled by default.

The scope determines the actions you can perform when you authenticate with a group access token.

| Scope              | Description                                                                                                                                                                                                                                                                                                |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | Grants complete read and write access to the scoped group and related project API, including the [container registry](../../packages/container_registry/_index.md), the [dependency proxy](../../packages/dependency_proxy/_index.md), and the [package registry](../../packages/package_registry/_index.md). |
| `read_api`         | Grants read access to the scoped group and related project API, including the [package registry](../../packages/package_registry/_index.md).                                                                                                                                                                |
| `read_registry`    | Grants read access (pull) to the [container registry](../../packages/container_registry/_index.md) images if any project within a group is private and authorization is required.                                                                                                                           |
| `write_registry`   | Grants write access (push) to the [container registry](../../packages/container_registry/_index.md). You need both read and write access to push images.                                                                                                                                                |
| `read_repository`  | Grants read access (pull) to all repositories within a group.                                                                                                                                                                                                                                              |
| `write_repository` | Grants read and write access (pull and push) to all repositories within a group.                                                                                                                                                                                                                           |
| `create_runner`    | Grants permission to create runners in a group.                                                                                                                                                                                                                                                            |
| `manage_runner`    | Grants permission to manage runners in a group.                                                                                                                                                                                                                                                            |
| `ai_features`      | Grants permission to perform API actions for GitLab Duo. This scope is designed to work with the GitLab Duo Plugin for JetBrains. For all other extensions, see scope requirements.                                                                                                          |
| `k8s_proxy`        | Grants permission to perform Kubernetes API calls using the agent for Kubernetes in a group.                                                                                                                                                                                                               |
| `self_rotate`      | Grants permission to rotate this token using the [personal access token API](../../../api/personal_access_tokens.md#use-a-request-header). Does not allow rotation of other tokens. |

## Restrict the creation of group access tokens

To limit potential abuse, you can restrict users from creating tokens for a group hierarchy. This setting is only configurable for a top-level group and applies to every downstream subgroup and project. Any existing group access tokens remain valid until their expiration date or until manually revoked.

To restrict the creation of group access tokens:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Permissions**, clear the **Users can create project access tokens and group access tokens in this group** checkbox.
1. Select **Save changes**.

## Access token expiration

Whether your existing group access tokens have expiry dates automatically applied
depends on what GitLab offering you have, and when you upgraded to GitLab 16.0 or later:

- On GitLab.com, during the 16.0 milestone, existing group access tokens without
  an expiry date were automatically given an expiry date of 365 days later than the current date.
- On GitLab Self-Managed, if you upgraded from GitLab 15.11 or earlier to GitLab 16.0 or later:
  - On or before July 23, 2024, existing group access tokens without an expiry
    date were automatically given an expiry date of 365 days later than the current date.
    This change is a breaking change.
  - On or after July 24, 2024, existing group access tokens without an expiry
    date did not have an expiry date set.

On GitLab Self-Managed, if you do a new install of one of the following GitLab
versions, your existing group access tokens do not have expiry dates
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

### Group access token expiry emails

> - Sixty and thirty day expiry notification emails [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464040) in GitLab 17.6 [with a flag](../../../administration/feature_flags.md) named `expiring_pats_30d_60d_notifications`. Disabled by default.
> - Sixty and thirty day notification emails [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792) in GitLab 17.7. Feature flag `expiring_pats_30d_60d_notifications` removed.
> - Notifications to inherited group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) in GitLab 17.7 [with a flag](../../../administration/feature_flags.md) named `pat_expiry_inherited_members_notification`. Disabled by default.

FLAG:
The availability of the sixty and thirty day expiry notification emails is controlled by a feature flag. For more information, see the history.

GitLab runs a check every day at 1:00 AM UTC to identify group access tokens that are expiring in the near future. Members of the group with the Owner role are notified by email when these tokens expire in a certain number of days. The number of days differs depending on the version of GitLab:

- In GitLab 17.6 and later, group Owners are notified by email when the check identifies their group access tokens as expiring in the next sixty days. An additional email is sent when the check identifies their group access tokens as expiring in the next thirty days.
- Group Owners are notified by email when the check identifies their group access tokens as expiring in the next seven days.
- In GitLab 17.7 and later, members with the inherited role of Owner in the group can also receive notification emails. You can configure this by changing:
  - The [group setting](../manage.md#expiry-emails-for-group-and-project-access-tokens) for the group or any parent group.
  - On GitLab Self-Managed, the [instance setting](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members).

Your expired access tokens are listed in the [inactive group access tokens table](#revoke-or-rotate-a-group-access-token) for 30 days after the tokens expire.

## Bot users for groups

Bot users for groups are [GitLab-created non-billable users](../../../subscriptions/self_managed/_index.md#billable-users).
Each time you create a group access token, a bot user is created and added to the group.
These bot users are similar to
[bot users for projects](../../project/settings/project_access_tokens.md#bot-users-for-projects), except they are added
to groups instead of projects. Bot users for groups:

- Is not a billable user, so it does not count toward the license limit.
- Can have a maximum role of Owner for a group. For more information, see
  [Create a group access token](../../../api/group_access_tokens.md#create-a-group-access-token).
- Have a username set to `group_{group_id}_bot_{random_string}`. For example, `group_123_bot_4ffca233d8298ea1`.
- Have an email set to `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`. For example, `group_123_bot_4ffca233d8298ea1@noreply.example.com`.

All other properties are similar to [bot users for projects](../../project/settings/project_access_tokens.md#bot-users-for-projects).

## Token availability

Group access tokens are only available in paid subscriptions, and not available in trial subscriptions. For more information, see the ["What is included" section of the GitLab Trial FAQ](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded).
