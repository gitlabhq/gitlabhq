---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Credentials inventory

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20912) in GitLab 12.6.
> - [Bot-created access tokens not displayed in personal access token list](https://gitlab.com/gitlab-org/gitlab/-/issues/351759) in GitLab 14.9.

As a GitLab administrator, you are responsible for the overall security of your instance.
To assist, GitLab provides an inventory of all the credentials that can be used to access
your self-managed instance.

In the credentials inventory, you can view all:

- Personal access tokens (PATs).
- Project access tokens (introduced in GitLab 14.8).
- Group access tokens ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102959) in GitLab 15.6).
- SSH keys.
- GPG keys.

You can also [revoke](#revoke-a-users-personal-access-token), [delete](#delete-a-users-ssh-key), and view:

- Who they belong to.
- Their access scope.
- Their usage pattern.
- [In GitLab 13.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/214809), when they:
  - Expire.
  - Were revoked.

## Revoke a user's personal access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214811) in GitLab 13.4.

You can revoke a user's personal access token.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Credentials**.
1. By the personal access token, select **Revoke**.

If a **Revoke** button is not available, the token may be expired or revoked, or an expiration date set.

| Token state | Revoke button displayed? | Comments                                                                   |
|-------------|--------------------------|----------------------------------------------------------------------------|
| Active      | Yes                      | Allows administrators to revoke the PAT, such as for a compromised account |
| Expired     | No                       | Not applicable; token is already expired                                   |
| Revoked     | No                       | Not applicable; token is already revoked                                   |

When a PAT is revoked from the credentials inventory, the instance notifies the user by email.

![Credentials inventory page - Personal access tokens](img/credentials_inventory_personal_access_tokens_v14_9.png)

## Revoke a user's project access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/243833) in GitLab 14.8.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Credentials**.
1. Select the **Project Access Tokens** tab.
1. By the project access token, select **Revoke**.

The project access token is revoked and a background worker is queued to delete the project bot user.

![Credentials inventory page - Project access tokens](img/credentials_inventory_project_access_tokens_v14_9.png)

## Delete a user's SSH key

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225248) in GitLab 13.5.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Credentials**.
1. Select the **SSH Keys** tab.
1. By the SSH key, select **Delete**.

The instance notifies the user.

![Credentials inventory page - SSH keys](img/credentials_inventory_ssh_keys_v14_9.png)

## Review existing GPG keys

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/282429) in GitLab 13.10.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/292961) in GitLab 13.12.

You can view all existing GPG in your GitLab instance by going to the
credentials inventory GPG Keys tab, as well as the following properties:

- Who the GPG key belongs to.
- The ID of the GPG key.
- Whether the GPG key is [verified or unverified](../user/project/repository/signed_commits/gpg.md).

![Credentials inventory page - GPG keys](img/credentials_inventory_gpg_keys_v14_9.png)
