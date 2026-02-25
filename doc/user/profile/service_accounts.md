---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Service accounts
description: Create non-human accounts for automated processes and third-party service integrations.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Project service accounts [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/585509) in GitLab 18.10
  [with a flag](../../administration/feature_flags/_index.md) named `allow_projects_to_create_service_accounts`.
  Disabled by default.
- Subgroup service accounts [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/585513) in GitLab 18.10
  [with a flag](../../administration/feature_flags/_index.md) named `allow_subgroups_to_create_service_accounts`.
  Disabled by default.

{{< /history >}}

Service accounts are user accounts that represent non-human entities rather than individual people.
Use service accounts to perform automated actions, access data, or run scheduled processes. Service
accounts are commonly used in pipelines or third-party integrations where credentials must stay
stable regardless of changes to your team's membership.

Service accounts authenticate with a [personal access token](personal_access_tokens.md).
They can interact with [package and container registries](../packages/_index.md),
perform [Git operations](personal_access_tokens.md#clone-repository-using-personal-access-token),
and access the API.

Service accounts:

- Do not use a seat.
- Cannot sign in to GitLab through the UI.
- Cannot be managed through services such as LDAP.
- Appear in group and project membership lists as service accounts.
- Do not receive notification emails unless you add a [custom email address](../../api/service_accounts.md#create-an-instance-service-account).
- Are not [billable users](../../subscriptions/manage_users_and_seats.md#billable-users) or [internal users](../../administration/internal_users.md).
- Are available on [trial versions](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com&glm_content=free-user-limit-faq/ee/user/free_user_limit.html)
  of GitLab. On GitLab.com, the Owner of the top-level group must verify their identity first.

You can also manage service accounts through the [service accounts API](../../api/service_accounts.md).

## Types of service accounts

Service accounts have three types, each with a different scope and prerequisites:

{{< tabs >}}

{{< tab title="Instance service accounts" >}}

Instance service accounts are available to an entire GitLab instance, but must still be added
to groups and projects like a human user.

Prerequisites:

- Administrator access to the instance.

{{< /tab >}}

{{< tab title="Group service accounts" >}}

Group service accounts are owned by a specific group and can be invited to the group where they were
created or to any descendant subgroups or projects. They cannot be invited to ancestor groups.

Prerequisites:

- On GitLab.com, you must have the Owner role for the group.
- On GitLab Self-Managed or GitLab Dedicated, you must either:
  - Be an administrator for the instance.
  - Have the Owner role in a group and be [allowed to create service accounts](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

{{< /tab >}}

{{< tab title="Project service accounts" >}}

Project service accounts are owned by a specific project and are available only to that project.

Prerequisites:

- On GitLab.com, you must have the Owner or Maintainer role for the project.
- On GitLab Self-Managed or GitLab Dedicated, you must either:
  - Be an administrator for the instance.
  - Have the Owner or Maintainer role in a project.

{{< /tab >}}

{{< /tabs >}}

## View and manage service accounts

{{< history >}}

- Introduced for GitLab.com in GitLab 17.11

{{< /history >}}

The service accounts page displays information about service accounts in your group, project, or instance. Each group, project, and GitLab Self-Managed instance has a separate service accounts page. From these pages, you can:

- View all service accounts for your group or instance.
- Delete a service account.
- Edit a service account's name or username.
- Manage personal access tokens for a service account.

{{< tabs >}}

{{< tab title="Instance service accounts" >}}

To view service accounts for the entire instance:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Service accounts**.

{{< /tab >}}

{{< tab title="Group service accounts" >}}

To view service accounts for a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Service accounts**.

{{< /tab >}}

{{< tab title="Project service accounts" >}}

To view service accounts for a project:

1. On the top bar, select **Search or go to** and find your project.
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
- On GitLab Premium and Ultimate, you can create an unlimited number of service accounts.

To create a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Select **Add service account**.
1. Enter a name for the service account. A username is automatically generated based on the name. You can modify the username if needed.
1. Select **Create service account**.

### Edit a service account

{{< history >}}

- [Added](https://gitlab.com/gitlab-org/gitlab/-/work_items/581050) username limits for service accounts with composite identities in GitLab 18.9.

{{< /history >}}

You can edit the name or username of a service account.

> [!note]
> You cannot update the username of a service account associated with a [composite identity](../duo_agent_platform/composite_identity.md).

To edit a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Edit**.
1. Edit the name or username for the service account.
1. Select **Save changes**.

### Add a service account to a group or project

Service accounts have limited access until you add them as members of a group or project. You can
add any number of service accounts to a group or project, and each service account can have a
different role in each group, subgroup, or project.

Service account access depends on the type of service account:

- Instance service accounts: Can be invited to any group or project on the instance.
- Group service accounts: Can be invited to the group where they were created or to any
  descendant subgroups or projects.
- Project service accounts: Can be invited only to the project where they were created.

When a group is [shared with another group](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group),
all members of that group, including service accounts, gain access to the shared group.

You can assign service accounts to groups and projects using:

- The GitLab UI:
  - [Add users to a group](../group/_index.md#add-users-to-a-group).
  - [Add users to a project](../project/members/_index.md#add-users-to-a-project).
- The API:
  - The [group members API](../../api/group_members.md).
  - The [project members API](../../api/project_members.md).

> [!note]
> If the [global SAML group memberships lock](../group/saml_sso/group_sync.md#global-saml-group-memberships-lock)
> or the [global LDAP group memberships lock](../../administration/auth/ldap/ldap_synchronization.md#global-ldap-group-memberships-lock)
> settings are enabled, you must use the API to control service account memberships.

## Fork projects with a service account

Service accounts can fork projects through the [Project forks API](../../api/project_forks.md), but
cannot fork to their personal namespace. When forking with a service account, you must specify
a target group namespace.

Prerequisites:

- The service account has the Developer role and is a member of the target group.
- The `api` scope is turned on for the service account's personal access token.

To fork a project using a service account:

1. Identify the target group where the fork is created.
1. Ensure the service account is a member of that group with appropriate permissions.
1. Use the [fork project API](../../api/project_forks.md) with either `namespace_id` or `namespace_path`:

   ```shell
    curl --request POST --header "PRIVATE-TOKEN: <service_account_token>" \
      --data "namespace_path=target-group" \
      "https://gitlab.example.com/api/v4/projects/<project_id>/fork"
   ```

### Delete a service account

When you delete a service account, any contributions made by the account are retained and ownership
is transferred to a ghost user. These contributions can include activity such as
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

> [!warning]
> This cannot be undone. Services that rely on the rotated token stop working.

To rotate a personal access token for a service account:

1. Go to the [Service accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage access tokens**.
1. Next to an active token, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}).
1. Select **Rotate**.
1. On the confirmation dialog, select **Rotate**.

### Revoke a personal access token

You can rotate a personal access token to invalidate the current token.

> [!warning]
> This cannot be undone. Services that rely on the revoked token stop working.

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
