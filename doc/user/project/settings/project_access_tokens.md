---
stage: Software Supply Chain Security
group: Authentication
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Project access tokens
---

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386041) for trial subscriptions in GitLab 16.1.

Project access tokens are similar to passwords, except you can [limit access to resources](#scopes-for-a-project-access-token),
select a limited role, and provide an expiry date.

NOTE:
Actual access to a project is controlled by a combination of [roles and permissions](../../permissions.md), and the [token scopes](#scopes-for-a-project-access-token).

Use a project access token to authenticate:

- With the [GitLab API](../../../api/rest/authentication.md#personalprojectgroup-access-tokens).
- With Git, when using HTTP Basic Authentication, use:
  - Any non-blank value as a username.
  - The project access token as the password.

Project access tokens are similar to [group access tokens](../../group/settings/group_access_tokens.md)
and [personal access tokens](../../profile/personal_access_tokens.md), but project access tokens are scoped to a project, so you cannot use them to access resources from other projects.

On GitLab Self-Managed instances, project access tokens are subject to the same [maximum lifetime limits](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) as personal access tokens if the limit is set.

You can use project access tokens:

- On GitLab SaaS: If you have the Premium or Ultimate license tier, only one project access token is available with a [trial license](https://about.gitlab.com/free-trial/).
- On GitLab Self-Managed instances: With any license tier. If you have the Free tier,
  consider [restricting the creation of project access tokens](#restrict-the-creation-of-project-access-tokens) to lower potential abuse.

You cannot use project access tokens to create other group, project, or personal access tokens.

Project access tokens inherit the [default prefix setting](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)
configured for personal access tokens.

## Create a project access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89114) in GitLab 15.1, Owners can select Owner role for project access tokens.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348660) in GitLab 15.3, default expiration of 30 days and default role of Guest is populated in the UI.
> - Ability to create non-expiring project access tokens [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0.
> - Maximum allowable lifetime limit [extended to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) in GitLab 17.6 [with a flag](../../../administration/feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.
> - Project access token description [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443819) in GitLab 17.7.

FLAG:
The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

WARNING:
The ability to create project access tokens without an expiry date was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369122) in GitLab 15.4 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0. For more information on expiry dates added to existing tokens, see the documentation on [access token expiration](#access-token-expiration).

To create a project access token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Access tokens**.
1. Select **Add new token**.
1. In **Token name**, enter a name. The token name is visible to any user with permissions to view the project.
1. Optional. In **Token description**, enter a description for the token.
1. In **Expiration date**, enter an expiry date for the token.
   - The token expires on that date at midnight UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.
   - If you do not enter an expiry date, the expiry date is automatically set to 30 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).
   - An instance-wide [maximum lifetime](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) setting can limit the maximum allowable lifetime in GitLab Self-Managed instances.
1. Select a role for the token.
1. Select the [desired scopes](#scopes-for-a-project-access-token).
1. Select **Create project access token**.

A project access token is displayed. Save the project access token somewhere safe. After you leave or refresh the page, you can't view it again.

WARNING:
Project access tokens are treated as [internal users](../../../administration/internal_users.md).
If an internal user creates a project access token, that token is able to access
all projects that have visibility level set to [Internal](../../public_access.md).

## Revoke or rotate a project access token

> - Ability to view expired and revoked tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.3 [with a flag](../../../administration/feature_flags.md) named `retain_resource_access_token_user_after_revoke`. Disabled by default.
> - Ability to view expired and revoked tokens limited to 30 days and [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/471683) in GitLab 17.9. Feature flag `retain_resource_access_token_user_after_revoke` removed.

In GitLab 17.9 and later, you can view both active and inactive project
access tokens on the access tokens page.

The inactive project access tokens table displays revoked and expired tokens for 30 days after they became inactive.

Tokens that belong to [an active token family](../../../api/personal_access_tokens.md#automatic-reuse-detection) are displayed for 30 days after the latest active token from the family is expired or revoked.

### Use the UI

To revoke or rotate a project access token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Access tokens**.
1. For the relevant token, select **Revoke** (**{remove}**) or **Rotate** (**{retry}**).
1. On the confirmation dialog, select **Revoke** or **Rotate**.

## Scopes for a project access token

> - `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `k8s_proxy_pat`. Enabled by default.
> - Feature flag `k8s_proxy_pat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.
> - `self_rotate` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111) in GitLab 17.9. Enabled by default.

The scope determines the actions you can perform when you authenticate with a project access token.

NOTE:
See the warning in [create a project access token](#create-a-project-access-token) regarding internal projects.

| Scope              | Description                                                                                                                                                                                                                                                                              |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | Grants complete read and write access to the scoped project API, including the [container registry](../../packages/container_registry/_index.md), the [dependency proxy](../../packages/dependency_proxy/_index.md), and the [package registry](../../packages/package_registry/_index.md). |
| `read_api`         | Grants read access to the scoped project API, including the [package registry](../../packages/package_registry/_index.md).                                                                                                                                                                |
| `read_registry`    | Grants read access (pull) to the [container registry](../../packages/container_registry/_index.md) images if a project is private and authorization is required.                                                                                                                          |
| `write_registry`   | Grants write access (push) to the [container registry](../../packages/container_registry/_index.md). You need both read and write access to push images.                                                                                                                              |
| `read_repository`  | Grants read access (pull) to the repository.                                                                                                                                                                                                                                             |
| `write_repository` | Grants read and write access (pull and push) to the repository.                                                                                                                                                                                                                          |
| `create_runner`    | Grants permission to create runners in the project.                                                                                                                                                                                                                                      |
| `manage_runner`    | Grants permission to manage runners in the project.                                                                                                                                                                                                                                      |
| `ai_features`      | Grants permission to perform API actions for GitLab Duo. This scope is designed to work with the GitLab Duo Plugin for JetBrains. For all other extensions, see scope requirements.                                                                                                          |
| `k8s_proxy`        | Grants permission to perform Kubernetes API calls using the agent for Kubernetes in the project.                                                                                                                                                                                         |
| `self_rotate`      | Grants permission to rotate this token using the [personal access token API](../../../api/personal_access_tokens.md#use-a-request-header). Does not allow rotation of other tokens. |

## Restrict the creation of project access tokens

To limit potential abuse, you can restrict users from creating tokens for a group hierarchy. This setting is only configurable for a top-level group and applies to every downstream project and subgroup. Any existing project access tokens remain valid until their expiration date or until manually revoked.

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. In **Permissions**, clear the **Users can create project access tokens and group access tokens in this group** checkbox.

## Access token expiration

Whether your existing project access tokens have expiry dates automatically applied
depends on what GitLab offering you have, and when you upgraded to GitLab 16.0 or later:

- On GitLab.com, during the 16.0 milestone, existing project access tokens without
  an expiry date were automatically given an expiry date of 365 days later than the current date.
- On GitLab Self-Managed, if you upgraded from GitLab 15.11 or earlier to GitLab 16.0 or later:
  - On or before July 23, 2024, existing project access tokens without an expiry
    date were automatically given an expiry date of 365 days later than the current date.
    This change is a breaking change.
  - On or after July 24, 2024, existing project access tokens without an expiry
    date did not have an expiry date set.

On GitLab Self-Managed, if you do a new install of one of the following GitLab
versions, your existing project access tokens do not have expiry dates
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

### Project access token expiry emails

> - Sixty and thirty day expiry notification emails [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464040) in GitLab 17.6 [with a flag](../../../administration/feature_flags.md) named `expiring_pats_30d_60d_notifications`. Disabled by default.
> - Sixty and thirty day notification emails [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792) in GitLab 17.7. Feature flag `expiring_pats_30d_60d_notifications` removed.
> - Notifications to inherited group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) in GitLab 17.7 [with a flag](../../../administration/feature_flags.md) named `pat_expiry_inherited_members_notification`. Disabled by default.

FLAG:
The availability of the sixty and thirty day expiry notification emails is controlled by a feature flag. For more information, see the history.

GitLab runs a check every day at 1:00 AM UTC to identify project access tokens that are expiring in the near future. Members of the project with at least the Maintainer role are notified by email when these tokens expire in a certain number of days. The number of days differs depending on the version of GitLab:

- In GitLab 17.6 and later, project maintainers and owners are notified by email when the check identifies their project access tokens as expiring in the next sixty days. An additional email is sent when the check identifies their project access tokens as expiring in the next thirty days.
- Project maintainers and owners are notified by email when the check identifies their project access tokens as expiring in the next seven days.
- In GitLab 17.7 and later, project members who have inherited the Owner or Maintainer role due to the project belonging to a group can also receive notification emails. You can enable this by changing:
  - The [group setting](../../group/manage.md#expiry-emails-for-group-and-project-access-tokens) in any of the parent groups of the project.
  - On GitLab Self-Managed, the [instance setting](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members).

Your expired access tokens are listed in the [inactive project access tokens table](#revoke-or-rotate-a-project-access-token) for 30 days after the tokens expire.

## Bot users for projects

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.2 [with a flag](../../../administration/feature_flags.md) named `retain_resource_access_token_user_after_revoke`. Disabled by default. When enabled new bot users are made members with no expiry date and, when the token is later revoked or expires, the bot user is retained for 30 days.
> - Inactive bot users retention is [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.9. Feature flag `retain_resource_access_token_user_after_revoke` removed.

Bot users for projects are [GitLab-created non-billable users](../../../subscriptions/self_managed/_index.md#billable-users).
Each time you create a project access token, a bot user is created and added to the project.
This user is not a billable user, so it does not count toward the license limit.

The bot users for projects have [permissions](../../permissions.md#project-members-permissions) that correspond with the
selected role and [scope](#scopes-for-a-project-access-token) of the project access token.

- The name is set to the name of the token.
- The username is set to `project_{project_id}_bot_{random_string}`. For example, `project_123_bot_4ffca233d8298ea1`.
- The email is set to `project_{project_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`. For example, `project_123_bot_4ffca233d8298ea1@noreply.example.com`.

API calls made with a project access token are associated with the corresponding bot user.

Bot users for projects:

- Are included in a project's member list but cannot be modified.
- Cannot be added to any other project.
- Can have a maximum role of Owner for a project. For more information, see
  [Create a project access token](../../../api/project_access_tokens.md#create-a-project-access-token).

When the project access token is [revoked](#revoke-or-rotate-a-project-access-token):

- The bot user is retained for 30 days.
- After 30 days the bot user is deleted. All records are moved to a system-wide user with the username [Ghost User](../../profile/account/delete_account.md#associated-records).

See also [Bot users for groups](../../group/settings/group_access_tokens.md#bot-users-for-groups).

## Token availability

More than one project access token is only available in paid subscriptions. In Premium and Ultimate trial subscriptions, only one project access token is included. For more information, see the ["What is included" section of the GitLab Trial FAQ](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded).
