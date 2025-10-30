---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service accounts
description: Create non-human accounts for automated processes and third-party service integrations.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Service accounts are user accounts that represent non-human entities rather than individual people.
You can use service accounts to perform automated actions, access data, or run scheduled processes.
Service accounts are commonly used in pipelines or third-party integrations where credentials must
remain stable and unaffected by changes in human user membership.

There are two types of service accounts:

- Instance service accounts: Available to an entire GitLab instance, but must still be added to
  groups and projects like a human user. Only available on GitLab Self-Managed and GitLab Dedicated.
- Group service accounts: Owned by a specific top-level group and can inherit membership to
  subgroups and projects like a human user.

You authenticate as a service account with a [personal access token](personal_access_tokens.md).
Service accounts have the same abilities as human users, and can perform actions
like interacting with [package and container registries](../packages/_index.md),
performing [Git operations](personal_access_tokens.md#clone-repository-using-personal-access-token),
and accessing the API.

Service accounts:

- Do not use a seat.
- Cannot sign in to GitLab through the UI.
- Cannot be managed through services such as LDAP.
- Are identified in the group and project membership as service accounts.
- Do not receive notification emails without [adding a custom email address](../../api/service_accounts.md#create-an-instance-service-account).
- Are not [billable users](../../subscriptions/manage_users_and_seats.md#billable-users) or [internal users](../../administration/internal_users.md).
- Are available for [trial versions](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com&glm_content=free-user-limit-faq/ee/user/free_user_limit.html)
of GitLab.com after the Owner of the top-level group verifies their identity.
- Can be used with trial versions of GitLab Self-Managed and GitLab Dedicated.

You can also manage service accounts through the [service accounts API](../../api/service_accounts.md).

## Prerequisites

- On GitLab.com, you must have the Owner role in a top-level group.
- On GitLab Self-Managed or GitLab Dedicated you must either:
  - Be an administrator for the instance.
  - Have the Owner role in a top-level group and be [allowed to create service accounts](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

## View and manage service accounts

{{< history >}}

- Introduced for GitLab.com in GitLab 17.11

{{< /history >}}

The service accounts page displays information about service accounts in your top-level group or instance. Each top-level group and GitLab Self-Managed instance has a separate service accounts page. From these pages, you can:

- View all service accounts for your group or instance.
- Delete a service account.
- Edit a service account's name or username.
- Manage personal access tokens for a service account.

{{< tabs >}}

{{< tab title="Instance-wide service accounts" >}}

To view service accounts for the entire instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Service accounts**.

{{< /tab >}}

{{< tab title="Group service accounts" >}}

To view service accounts for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Service accounts**.

{{< /tab >}}

{{< /tabs >}}

### Create a service account

{{< history >}}

- Introduced for GitLab.com in GitLab 16.3
- Top-level group owners can create Service accounts [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726) in GitLab 17.5 [with a feature flag](../../administration/feature_flags/_index.md) named `allow_top_level_group_owners_to_create_service_accounts` for GitLab Self-Managed. Disabled by default.
- Top-level group owners can create Service accounts [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502) in GitLab 17.6. Feature flag `allow_top_level_group_owners_to_create_service_accounts` removed.

{{< /history >}}

On GitLab.com, only top-level group Owners can create service accounts.

By default, on GitLab Self-Managed and GitLab Dedicated, only administrators can create either type of service account.
However, you can [configure the instance](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)
to allow top-level group Owners to create group service accounts.

The number of service accounts you can create is limited by your license:

- On GitLab Free, you cannot create service accounts.
- On GitLab Premium, you can create one service account for every paid seat.
- On GitLab Ultimate, you can create an unlimited number of service accounts.

To create a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Select **Add service account**.
1. Enter a name for the service account. A username is automatically generated based on the name. You can modify the username if needed.
1. Select **Create service account**.

### Edit a service account

You can edit the name or username of a service account.

To edit a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Edit**.
1. Edit the name or username for the service account.
1. Select **Save changes**.

### Service account access to groups and projects

Service accounts are similar to [external users](../../administration/external_users.md). When first
created, they have limited access to groups and projects. To give a service account access to
resources, you must add it to each group or project.

There is no limit to the number of service accounts you can add to a group or project. Service accounts
can have different roles in each group, subgroup, or project they are a member of.
On GitLab.com, service accounts for groups can only belong to a single top-level group.

Service account access to groups and projects is managed the same way as
human users in the UI. For more information, see
[groups](../group/_index.md#add-users-to-a-group) and [members of a project](../project/members/_index.md#add-users-to-a-project).

You can assign service accounts to groups and projects using the UI or the [members API](../../api/members.md).
For more information about using the UI, see [add users to a group](../group/_index.md#add-users-to-a-group)
and [add users to a project](../project/members/_index.md#add-users-to-a-project).

You must use the API when the
[global SAML group memberships lock](../group/saml_sso/group_sync.md#global-saml-group-memberships-lock)
or the
[global LDAP group memberships lock](../../administration/auth/ldap/ldap_synchronization.md#global-ldap-group-memberships-lock)
is enabled.

### Delete a service account

When you delete a service account, any contributions made by the account are retained and ownership
is transferred to a system-wide ghost user account. These contributions can include activity such as
merge requests, issues, projects, and groups.

To delete a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete account**.
1. Enter the name of the service account.
1. Select **Delete user**.

You can also delete the service account and any contributions made by the account. These
contributions can include activity such as merge requests, issues, groups, and projects.

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete account and contributions**.
1. Enter the name of the service account.
1. Select **Delete user and contributions**.

You can also delete service accounts through the API.

- For instance service accounts, use the [users API](../../api/users.md#delete-a-user).
- For group service accounts, use the [service accounts API](../../api/service_accounts.md#delete-a-group-service-account).

## View and manage personal access tokens for a service account

The personal access tokens page displays information about the personal access tokens associated with a service account in your top-level group or instance. From these pages, you can:

- Filter, sort, and view details about personal access tokens.
- Rotate personal access tokens.
- Revoke personal access tokens.

You can also manage personal access tokens for service accounts through the API.

- For instance service accounts, use the [personal access tokens API](../../api/personal_access_tokens.md).
- For group service accounts, use the [service accounts API](../../api/service_accounts.md).

To view the personal access tokens page for a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage access tokens**.

### Create a personal access token for a service account

To use a service account, you must create a personal access token to authenticate requests.

To create a personal access token for a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage access tokens**.
1. Select **Add new token**.
1. In **Token name**, enter a name for the token.
1. Optional. In **Token description**, enter a description for the token.
1. In **Expiration date**, enter an expiration date for the token.
   - The token expires on that date at midnight UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.
   - If you do not enter an expiry date, the expiry date is automatically set to 365 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).
1. Select the [desired scopes](personal_access_tokens.md#personal-access-token-scopes).
1. Select **Create personal access token**.

### Rotate a personal access token

You can rotate a personal access token to invalidate the current token and generate a new value.

{{< alert type="warning" >}}

This cannot be undone. Any services that rely on the rotated token will stop working.

{{< /alert >}}

To rotate a personal access token for a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage access tokens**.
1. Next to an active token, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}).
1. Select **Rotate**.
1. On the confirmation dialog, select **Rotate**.

### Revoke a personal access token

You can rotate a personal access token to invalidate the current token.

{{< alert type="warning" >}}

This cannot be undone. Any services that rely on the revoked token will stop working.

{{< /alert >}}

To revoke a personal access token for a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage access tokens**.
1. Next to an active token, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}).
1. Select **Revoke**.
1. On the confirmation dialog, select **Revoke**.

## Rate limits

[Rate limits](../../security/rate_limits.md) apply to service accounts:

- On GitLab.com, [GitLab.com-specific rate limits](../gitlab_com/_index.md#rate-limits-on-gitlabcom) apply.
- On GitLab Self-Managed and GitLab Dedicated, these rate limits apply:
  - [Configurable rate limits](../../security/rate_limits.md#configurable-limits)
  - [Non-configurable rate limits](../../security/rate_limits.md#non-configurable-limits)

## Related topics

- [Billable users](../../subscriptions/manage_users_and_seats.md#billable-users)
- [Associated records](account/delete_account.md#associated-records)
- [Project access tokens - bot users](../project/settings/project_access_tokens.md#bot-users-for-projects)
- [Group access tokens - bot users](../group/settings/group_access_tokens.md#bot-users-for-groups)
- [Internal users](../../administration/internal_users.md)
