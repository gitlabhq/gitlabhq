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

Service accounts were previously managed exclusively through the API. You can now use either the UI or the API.

- For instance-level service accounts, use the [Service account users API](../../api/user_service_accounts.md).
- For group-level service accounts, use the [Group service accounts API](../../api/group_service_accounts.md).

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

## Manage a service account

You can view, delete or edit an existing service account.

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Delete a service account by selecting the three-dot menu (**⋮**) and choosing **Delete**.
1. Edit a service account's name or username by selecting the three-dot menu (**⋮**) and choosing **Edit**.

## Add a service account to subgroup or project

In terms of functionality, a service account is the same as an [external user](../../administration/external_users.md)
and has minimal access when you first create it.

You must manually add the service account to each
[project](../project/members/_index.md#add-users-to-a-project) or
[group](../group/_index.md#add-users-to-a-group) you want the account to have access to.

There is no limit to the number of service accounts you can add to a project or group.

A service account:

- Can have different roles across multiple subgroups and projects of the same top-level group.
- When created by a top-level group owner, only belongs to one top-level group.

### Add to a subgroup or project

You can add the service account to a subgroup or project through the:

- [API](../../api/members.md#add-a-member-to-a-group-or-project).
- [Group members UI](../group/_index.md#add-users-to-a-group).
- [Project members UI](../project/members/_index.md#add-users-to-a-project).

### Change a service account role in a subgroup or project

You can change a service account role in a subgroup or project through the UI or the API.

To use the UI, go to the subgroup's or project's membership list and change the service
account's role.

To use the API, call the following endpoint:

```shell
curl --request POST --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>" \ --data "user_id=<service_account_user_id>&access_level=30" "https://gitlab.example.com/api/v4/projects/<project_id>/members"
```

For more information on the attributes, see the [API documentation on editing a member of a group or project](../../api/members.md#edit-a-member-of-a-group-or-project).

## View and manage personal access tokens for a service account

The personal access tokens page displays information about the personal access tokens associated with a service account in your top-level group or instance. From these pages, you can:

- Filter, sort, and view details about personal access tokens.
- Rotate personal access tokens.
- Revoke personal access tokens.

To view the personal access tokens page for a service account:

1. Go to the [Service Accounts](#view-and-manage-service-accounts) page.
1. Identify a service account.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Manage Access Tokens**.

## Create a personal access token for a service account

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

## Rotate a personal access token

Prerequisites:

- For service accounts created by top-level group Owners, you must have the Owner role in the top-level group or be an administrator.
- For service accounts created by administrators, you must be an administrator for your GitLab Self-Managed instance.

Use the groups API to [rotate the personal access token](../../api/group_service_accounts.md#rotate-a-personal-access-token-for-a-service-account-user) for a service account user.

## Revoke a personal access token

Prerequisites:

- You must be signed in as the service account user.

To revoke a personal access token, use the [personal access tokens API](../../api/personal_access_tokens.md#revoke-a-personal-access-token). You can use either of the following methods:

- Use a [personal access token ID](../../api/personal_access_tokens.md#revoke-a-personal-access-token). The token used to perform the revocation must have the [`admin_mode`](personal_access_tokens.md#personal-access-token-scopes) scope.
- Use a [request header](../../api/personal_access_tokens.md#self-revoke). The token used to perform the request is revoked.

## Delete a service account via API

### Top-Level Group Owners

Prerequisites:

- You must have the Owner role in a top-level group.

To delete a service account, [use the service accounts API to delete the service account user](../../api/group_service_accounts.md#delete-a-service-account-user).

### Administrators in GitLab Self-Managed

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

Prerequisites:

- You must be an administrator for the instance the service account is associated with.

To delete a service account, [use the users API to delete the service account user](../../api/users.md#delete-a-user).

## Restrict a service account

Prerequisites:

- You must have the Owner role for the group the service account is associated with.

If you are not an administrator for the instance or group a service account is associated with, you cannot directly delete that service account. Instead:

1. Remove the service account as a member of all subgroups and projects:

   ```shell
   curl --request DELETE --header "PRIVATE-TOKEN: <access_token_id>" "https://gitlab.example.com/api/v4/groups/<group_id>/members/<service_account_id>"
   ```

   For more information, see the [API documentation on removing a member from a group or project](../../api/members.md#remove-a-member-from-a-group-or-project).

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
