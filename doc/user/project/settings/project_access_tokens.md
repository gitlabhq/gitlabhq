---
stage: Manage
group: Access
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# Project access tokens

NOTE: **Note:**
Project access tokens are supported for self-managed instances on Core and above. They are also supported on GitLab.com Bronze and above.

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2587) in GitLab 13.0.
> - It was [deployed](https://gitlab.com/groups/gitlab-org/-/epics/2587) behind a feature flag, disabled by default.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/218722) in GitLab 13.3.
> - [Became available on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/235765) in 13.5.
> - It's recommended for production use.

Project access tokens are scoped to a project and can be used to authenticate with the [GitLab API](../../../api/README.md#personalproject-access-tokens). You can also use project access tokens with Git to authenticate over HTTP.

Project access tokens expire on the date you define, at midnight UTC.

For examples of how you can use a project access token to authenticate with the API, see the following section from our [API Docs](../../../api/README.md#personalproject-access-tokens).

## Creating a project access token

1. Log in to GitLab.
1. Navigate to the project you would like to create an access token for.
1. In the **Settings** menu choose **Access Tokens**.
1. Choose a name and optional expiry date for the token.
1. Choose the [desired scopes](#limiting-scopes-of-a-project-access-token).
1. Click the **Create project access token** button.
1. Save the project access token somewhere safe. Once you leave or refresh
   the page, you won't be able to access it again.

## Project bot users

For each project access token created, a bot user will also be created and added to the project with
["Maintainer" level permissions](../../permissions.md#project-members-permissions).

For the bot:

- The name is set to the name of the token.
- The username is set to `project_{project_id}_bot` for the first access token, such as `project_123_bot`.
- The username is set to `project_{project_id}_bot{bot_count}` for further access tokens, such as `project_123_bot1`.

API calls made with a project access token are associated with the corresponding bot user.

These users will appear in **Members** but can not be modified.
Furthermore, the bot user can not be added to any other project.

- The username is set to `project_{project_id}_bot` for the first access token, such as `project_123_bot`.
- The username is set to `project_{project_id}_bot{bot_count}` for further access tokens, such as `project_123_bot1`.

When the project access token is [revoked](#revoking-a-project-access-token) the bot user is then deleted and all records are moved to a system-wide user with the username "Ghost User". For more information, see [Associated Records](../../profile/account/delete_account.md#associated-records).

Project bot users are [GitLab-created service accounts](../../../subscriptions/self_managed/index.md#billable-users) and do not count as licensed seats.

## Revoking a project access token

At any time, you can revoke any project access token by clicking the
respective **Revoke** button in **Settings > Access Tokens**.

## Limiting scopes of a project access token

Project access tokens can be created with one or more scopes that allow various
actions that a given token can perform. The available scopes are depicted in
the following table.

| Scope              |  Description |
| ------------------ |  ----------- |
| `api`              | Grants complete read/write access to the scoped project API. |
| `read_api`         | Grants read access to the scoped project API. |
| `read_registry`    | Allows read-access (pull) to [container registry](../../packages/container_registry/index.md) images if a project is private and authorization is required. |
| `write_registry`   | Allows write-access (push) to [container registry](../../packages/container_registry/index.md). |
| `read_repository`  | Allows read-only access (pull) to the repository. |
| `write_repository` | Allows read-write access (pull, push) to the repository. |
