---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service accounts
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

A service account is a type of machine user that is not tied to an individual human
user.

A service account:

- Does not use a licensed seat, but is not available on [trial versions](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com?&glm_content=free-user-limit-faq/ee/user/free_user_limit.html) on GitLab.com. It is available on trial versions on GitLab Self-Managed.
- Is not a:
  - Billable user.
  - Bot user.
- Is listed in group membership as a service account.
- Cannot sign in to GitLab through the UI.
- Does not receive notification emails because it is a non-human account with an invalid email unless the email address is set to a valid address.

You should use service accounts in pipelines or integrations where credentials must be
set up and maintained without being impacted by changes in human user membership.

You can authenticate as a service account with a [personal access token](personal_access_tokens.md).
Service account users with a personal access token have the same abilities as a standard user.
This includes interacting with [registries](../packages/_index.md) and using the personal access
token for [Git operations](personal_access_tokens.md#clone-repository-using-personal-access-token).

[Rate limits](../../security/rate_limits.md) apply to service accounts:

- On GitLab.com, there are [GitLab.com-specific rate limits](../gitlab_com/_index.md#rate-limits-on-gitlabcom).
- On GitLab Self-Managed and GitLab Dedicated, there are both:
  - [Configurable rate limits](../../security/rate_limits.md#configurable-limits).
  - [Non-configurable rate limits](../../security/rate_limits.md#non-configurable-limits).

You can also manage service accounts through the API.

- For instance-level service accounts, use the [service account users API](../../api/user_service_accounts.md).
- For group-level service accounts, use the [group service accounts API](../../api/group_service_accounts.md).

## View and manage service accounts

The Service Accounts page displays information about service accounts in your top-level group or instance. Each top-level group and GitLab Self-Managed instance has a separate Service Accounts page. From these pages, you can:

- View all service accounts for your group or instance.
- Delete a service account.
- Edit a service account's name or username.
- Manage personal access tokens for a service account.

{{< tabs >}}

{{< tab title="Instance-level service accounts" >}}

Prerequisites:

- You must be an administrator for the instance.

To view the Service Accounts page:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Service Accounts**.

{{< /tab >}}

{{< tab title="Group-level service accounts" >}}

Prerequisites:

- You must have the Owner role in a top-level group.

To view the Service Accounts page:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Service Accounts**.

{{< /tab >}}

{{< /tabs >}}

## Create a service account

{{< history >}}

- Introduced for GitLab.com in GitLab 16.3
- Top-level group owners can create Service accounts [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726) in GitLab 17.5 [with a feature flag](../../administration/feature_flags.md) named `allow_top_level_group_owners_to_create_service_accounts` for GitLab Self-Managed. Disabled by default.
- Top-level group owners can create Service accounts [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502) in GitLab 17.6. Feature flag `allow_top_level_group_owners_to_create_service_accounts` removed.

{{< /history >}}

The number of service accounts you can create is restricted by the number of service
accounts allowed under your license:

- On GitLab Free, service accounts are not available.
- On GitLab Premium, you can create one service account for every paid seat you have.
- On GitLab Ultimate, you can create an unlimited number of service accounts.

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts:
  - You must have the Owner role in a top-level group.
  - For GitLab Self-Managed or GitLab Dedicated, you must be [allowed to create service accounts](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Select **Add service account**.
1. Enter a name for the service account. A username is automatically generated based on the name. You can modify the username if needed.
1. Select **Create service account**.

## Edit a service account

You can view, delete or edit an existing service account.

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts, you must have the Owner role in a top-level group.

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Edit**.
1. Edit the name or username for the service account.
1. Select **Save changes**.

## Delete a service account

When you delete a service account, any contributions made by the account are retained and ownership
is transfered to a system-wide ghost user account. These contributions can include activity such as
merge requests, issues, projects, and groups.

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts, you must have the Owner role in a top-level group.

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete Account**.
1. Enter the name of the service account.
1. Select **Delete user**.

You can also delete the service account and any contributions made by the account. These
contributions can include activity such as merge requests, issues, groups, and projects.

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete Account and Contributions**.
1. Enter the name of the service account.
1. Select **Delete user and contributions**.

You can also delete service accounts through the API.

- For instance-level service accounts, use the [users API](../../api/users.md#delete-a-user).
- For group-level service accounts, use the [group service accounts API](../../api/group_service_accounts.md#delete-a-service-account-user).

## Service account access to groups and projects

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts, you must have the Owner role in a top-level group.

Service accounts are similar to [external users](../../administration/external_users.md). When first
created, they have limited access to groups and projects. To give a service account access to
resources, you must add it to each group or project.

There is no limit to the number of service accounts you can add to a group or project. Service accounts
can have different roles in each group, subgroup, or project they are a member of.
However, group-level service accounts can only belong to one top-level group.

Access to groups and projects is the same for both human and service users. For more information, see
[groups](../group/_index.md#add-users-to-a-group) and [members of a project](../project/members/_index.md#add-users-to-a-project).

You can also manage group and project assignments with the [members API](../../api/members.md).

## View and manage personal access tokens for a service account

The personal access tokens page displays information about the personal access tokens associated with a service account in your top-level group or instance. From these pages, you can:

- Filter, sort, and view details about personal access tokens.
- Rotate personal access tokens.
- Revoke personal access tokens.

You can also manage personal access tokens for service accounts through the API.

- For instance-level service accounts, use the [personal access tokens API](../../api/user_service_accounts.md).
- For group-level service accounts, use the [group service accounts API](../../api/group_service_accounts.md).

To view the personal access tokens page for a service account:

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage Access Tokens**.

### Create a personal access token for a service account

To use a service account, you must create a personal access token to authenticate requests.

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts, you must have the Owner role in a top-level group.

To create a personal access token:

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage Access Tokens**.
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

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts, you must have the Owner role in a top-level group.

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage Access Tokens**.
1. Select **Rotate**.
1. On the confirmation dialog, select **Rotate**.

### Revoke a personal access token

Prerequisites:

- For instance-level service accounts, you must be an administrator for the instance.
- For group-level service accounts, you must have the Owner role in a top-level group.

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage Access Tokens**.
1. Select **Revoke**.
1. On the confirmation dialog, select **Revoke**.

## Related topics

- [Billable users](../../subscriptions/self_managed/_index.md#billable-users)
- [Associated records](account/delete_account.md#associated-records)
- [Project access tokens - bot users](../project/settings/project_access_tokens.md#bot-users-for-projects)
- [Group access tokens - bot users](../group/settings/group_access_tokens.md#bot-users-for-groups)
- [Internal users](../../administration/internal_users.md)

## Troubleshooting

### "You are about to incur additional charges" warning when adding a service account

When you add a service account, you might see a warning message stating that this action will incur additional charges due to exceeding the subscription seat count.
This behavior is being tracked in [issue 433141](https://gitlab.com/gitlab-org/gitlab/-/issues/433141).

Adding a service account does not:

- Incur additional charges.
- Increase your seat usage count after you've added the account.
