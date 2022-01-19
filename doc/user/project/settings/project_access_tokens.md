---
stage: Manage
group: Authentication & Authorization
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# Project access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/210181) in GitLab 13.0.
> - [Became available on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/235765) in GitLab 13.5 for paid groups only.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/235765) in GitLab 13.5.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/342327) in GitLab 14.5. Default prefix added.

You can use a project access token to authenticate:

- With the [GitLab API](../../../api/index.md#personalprojectgroup-access-tokens).
- With Git, when using HTTP Basic Authentication.

After you configure a project access token, you don't need a password when you authenticate.
Instead, you can enter any non-blank value.

Project access tokens are similar to [group access tokens](../../group/settings/group_access_tokens.md)
and [personal access tokens](../../profile/personal_access_tokens.md), except they are
associated with a project rather than a group or user.

You can use project access tokens:

- On GitLab SaaS if you have the Premium license tier or higher. Project access tokens are not available with a [trial license](https://about.gitlab.com/free-trial/).
- On self-managed instances of GitLab, with any license tier. If you have the Free tier:
  - Review your security and compliance policies around
    [user self-enrollment](../../admin_area/settings/sign_up_restrictions.md#disable-new-sign-ups).
  - Consider [disabling project access tokens](#enable-or-disable-project-access-token-creation) to
    lower potential abuse.

Project access tokens inherit the [default prefix setting](../../admin_area/settings/account_and_limit_settings.md#personal-access-token-prefix)
configured for personal access tokens.

## Create a project access token

To create a project access token:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Access Tokens**.
1. Enter a name.
1. Optional. Enter an expiry date for the token. The token will expire on that date at midnight UTC.
1. Select a role for the token.
1. Select the [desired scopes](#scopes-for-a-project-access-token).
1. Select  **Create project access token**.

A project access token is displayed. Save the project access token somewhere safe. After you leave or refresh the page, you can't view it again.

## Revoke a project access token

To revoke a project access token:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Access Tokens**.
1. Next to the project access token to revoke, select **Revoke**.

## Scopes for a project access token

The scope determines the actions you can perform when you authenticate with a project access token.

| Scope              | Description                                                                                                                                                 |
|:-------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | Grants complete read and write access to the scoped project API, including the [Package Registry](../../packages/package_registry/index.md).                |
| `read_api`         | Grants read access to the scoped project API, including the [Package Registry](../../packages/package_registry/index.md).                                   |
| `read_registry`    | Allows read access (pull) to the [Container Registry](../../packages/container_registry/index.md) images if a project is private and authorization is required. |
| `write_registry`   | Allows write access (push) to the [Container Registry](../../packages/container_registry/index.md).                                                             |
| `read_repository`  | Allows read access (pull) to the repository.                                                                                                                |
| `write_repository` | Allows read and write access (pull and push) to the repository.                                                                                             |

## Enable or disable project access token creation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/287707) in GitLab 13.11.

To enable or disable project access token creation for all projects in a top-level group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Permissions**, turn on or off **Allow project and group access token creation**.

Even when creation is disabled, you can still use and revoke existing project access tokens.

## Project bot users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/210181) in GitLab 13.0.
> - [Excluded from license seat use](https://gitlab.com/gitlab-org/gitlab/-/issues/223695) in GitLab 13.5.

Project bot users are [GitLab-created service accounts](../../../subscriptions/self_managed/index.md#billable-users).
Each time you create a project access token, a bot user is created and added to the project.
These bot users do not count as licensed seats.

The bot users have [permissions](../../permissions.md#project-members-permissions) that correspond with the
selected role and [scope](#scopes-for-a-project-access-token) of the project access token.

- The name is set to the name of the token.
- The username is set to `project_{project_id}_bot` for the first access token. For example, `project_123_bot`.
- The email is set to `project{project_id}_bot@noreply.{Gitlab.config.gitlab.host}`. For example, `project123_bot@noreply.example.com`.
- For additional access tokens in the same project, the username is set to `project_{project_id}_bot{bot_count}`. For
  example, `project_123_bot1`.
- For additional access tokens in the same project, the email is set to `project{project_id}_bot{bot_count}@noreply.{Gitlab.config.gitlab.host}`.
  For example, `project123_bot1@noreply.example.com`.

API calls made with a project access token are associated with the corresponding bot user.

Bot users:

- Are included in a project's member list but cannot be modified.
- Cannot be added to any other project.

When the project access token is [revoked](#revoke-a-project-access-token):

- The bot user is deleted.
- All records are moved to a system-wide user with the username `Ghost User`. For more information, see
  [associated records](../../profile/account/delete_account.md#associated-records).
