---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Service accounts

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

A service account is a type of machine user that is not tied to an individual human
user.

A service account:

- Does not use a licensed seat, but is not available on [trial versions](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com?&glm_content=free-user-limit-faq/ee/user/free_user_limit.html).
- Is not a:
  - Billable user.
  - Bot user.
- Is listed in group membership as a service account.
- Cannot sign in to GitLab through the UI.

You should use service accounts in pipelines or integrations where credentials must be
set up and maintained without being impacted by changes in human user membership.

You can authenticate as a service account with a [personal access token](personal_access_tokens.md).
Service account users with a personal access token have the same abilities as a standard user.
This includes interacting with [registries](../packages/index.md) and using the personal access
token for [Git operations](personal_access_tokens.md#clone-repository-using-personal-access-token).

[Rate limits](../../security/rate_limits.md) apply to service accounts:

- On GitLab.com, there are [GitLab.com-specific rate limits](../gitlab_com/index.md#gitlabcom-specific-rate-limits).
- On self-managed GitLab and GitLab Dedicated, there are both:
  - [Configurable rate limits](../../security/rate_limits.md#configurable-limits).
  - [Non-configurable rate limits](../../security/rate_limits.md#non-configurable-limits).

## Create a service account

The number of service accounts you can create is restricted by the number of service
accounts allowed under your license:

- On GitLab Free, service accounts are not available.
- On GitLab Premium, you can create one service account for every paid seat you have.
- On GitLab Ultimate, you can create an unlimited number of service accounts.

How you create an account differs depending on whether you are on GitLab.com or self-managed.

### GitLab.com

Prerequisites:

- You must have the Owner role in a top-level group.

1. [Create a service account](../../api/groups.md#create-service-account-user).

   This service account is associated only with your top-level group.

1. [List all service account users](../../api/groups.md#list-service-account-users).

1. [Create a personal access token](../../api/groups.md#create-personal-access-token-for-service-account-user)
   for the service account user.

   You define the scopes for the service account by [setting the scopes for the personal access token](personal_access_tokens.md#personal-access-token-scopes).

   Optional. You can [create a personal access token with no expiry date](personal_access_tokens.md#when-personal-access-tokens-expire).

   The response includes the personal access token value.

1. Make this service account a group or project member by [manually adding the service account user to the group or project](#add-a-service-account-to-subgroup-or-project).
1. Use the returned personal access token value to authenticate as the service account user.

### Self-managed GitLab

Prerequisites:

- You must be an administrator for your self-managed instance.

1. [Create a service account](../../api/users.md#create-service-account-user).

   This service account is associated with the entire instance, not a specific group
   or project in the instance.

1. [List all service account users](../../api/users.md#list-service-account-users).

1. [Create a personal access token](../../api/users.md#create-a-personal-access-token)
   for the service account user.

   You define the scopes for the service account by [setting the scopes for the personal access token](personal_access_tokens.md#personal-access-token-scopes).

   Optional. You can [create a personal access token with no expiry date](personal_access_tokens.md#when-personal-access-tokens-expire).

   The response includes the personal access token value.

1. Make this service account a group or project member by
   [manually adding the service account user to the group or project](#add-a-service-account-to-subgroup-or-project).
1. Use the returned personal access token value to authenticate as the service account user.

## Add a service account to subgroup or project

In terms of functionality, a service account is the same as an [external user](../../administration/external_users.md)
and has minimal access when you first create it.

You must manually add the service account to each
[project](../project/members/index.md#add-users-to-a-project) or
[group](../group/index.md#add-users-to-a-group) you want the account to have access to.

There is no limit to the number of service accounts you can add to a project or group.

A service account:

- Can have different roles across multiple subgroups and projects of the same top level group.
- On GitLab.com, only belongs to one top-level group.

### Add to a subgroup or project

You can add the service account to a subgroup or project through the:

- [API](../../api/members.md#add-a-member-to-a-group-or-project).
- [Group members UI](../group/index.md#add-users-to-a-group).
- [Project members UI](../project/members/index.md#add-users-to-a-project).

### Change a service account role in a subgroup or project

You can change a service account role in a subgroup or project through the UI or the API.

To use the UI, go to the subgroup's or project's membership list and change the service
account's role.

To use the API, call the following endpoint:

```shell
curl --request POST --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>" \ --data "user_id=<service_account_user_id>&access_level=30" "https://gitlab.example.com/api/v4/projects/<project_id>/members"
```

For more information on the attributes, see the [API documentation on editing a member of a group or project](../../api/members.md#edit-a-member-of-a-group-or-project).

### Rotate the personal access token

Prerequisites:

- For GitLab.com, you must have the Owner role in a top-level group.
- For self-managed GitLab, you must be an administrator for your self-managed instance.

Use the groups API to [rotate the personal access token](../../api/groups.md#rotate-a-personal-access-token-for-service-account-user) for a service account user.

### Revoke a personal access token

Prerequisites:

- You must be signed in as the service account user.

To revoke a personal access token, use the [personal access tokens API](../../api/personal_access_tokens.md#revoke-a-personal-access-token). You can use either of the following methods:

- Use a [personal access token ID](../../api/personal_access_tokens.md#using-a-personal-access-token-id-1). The token used to perform the revocation must have the [`admin_mode`](personal_access_tokens.md#personal-access-token-scopes) scope.
- Use a [request header](../../api/personal_access_tokens.md#using-a-request-header-1). The token used to perform the request is revoked.

### Delete a service account

#### GitLab.com

Prerequisites:

- You must have the Owner role in a top-level group.

To delete a service account, [use the groups API to delete the service account user](../../api/groups.md#delete-service-account-user).

#### Self-managed GitLab

Prerequisites:

- You must be an administrator for the instance the service account is associated with.

To delete a service account, [use the users API to delete the service account user](../../api/users.md#user-deletion).

### Disable a service account

Prerequisites:

- You must have the Owner role for the group the service account is associated with.

If you are not an administrator for the instance or group a service account is associated with, you cannot directly delete that service account. Instead:

1. Remove the service account as a member of all subgroups and projects:

   ```shell
   curl --request DELETE --header "PRIVATE-TOKEN: <access_token_id>" "https://gitlab.example.com/api/v4/groups/<group_id>/members/<service_account_id>"
   ```

   For more information, see the [API documentation on removing a member from a group or project](../../api/members.md#remove-a-member-from-a-group-or-project).

## Related topics

- [Billable users](../../subscriptions/self_managed/index.md#billable-users)
- [Associated records](account/delete_account.md#associated-records)
- [Project access tokens - bot users](../project/settings/project_access_tokens.md#bot-users-for-projects)
- [Group access tokens - bot users](../group/settings/group_access_tokens.md#bot-users-for-groups)
- [Internal users](../../development/internal_users.md#internal-users)
