---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Credentials inventory for GitLab Self-Managed
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Group access tokens [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102959) in GitLab 15.6.

{{< /history >}}

{{< alert type="note" >}}

For GitLab.com, see [Credentials inventory for GitLab.com](../user/group/credentials_inventory.md).

{{< /alert >}}

Use the credentials inventory to monitor and control access to your GitLab self-managed instance.

As an administrator, you can:

- Revoke personal or project access tokens.
- Delete SSH keys.
- Review credential details including:
  - Ownership.
  - Access scopes.
  - Usage patterns.
  - Expiration dates.
  - Revocation dates.

## Revoke personal access tokens

To revoke a personal access token in your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Credentials**.
1. Next to the personal access token, select **Revoke**.
   If the token was previously expired or revoked, you'll see the date this happened instead.

The access token is revoked and the user is notified by email.

![The credentials inventory page listing personal access tokens.](img/credentials_inventory_personal_access_tokens_v14_9.png)

## Revoke project access tokens

To revoke a project access token in your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Credentials**.
1. Select the **Project access tokens** tab.
1. Next to the project access token, select **Revoke**.

The access token is revoked and a background process begins to delete the associated project bot user.

![The credentials inventory page listing project access tokens.](img/credentials_inventory_project_access_tokens_v14_9.png)

## Delete SSH keys

To delete an SSH key in your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Credentials**.
1. Select the **SSH Keys** tab.
1. Next to the SSH key, select **Delete**.

The SSH key is deleted and the user is notified.

![The credentials inventory page listing SSH keys.](img/credentials_inventory_ssh_keys_v14_9.png)

## View GPG keys

You can see details for each GPG key including the owner, ID, and [verification status](../user/project/repository/signed_commits/gpg.md).

To view information about GPG keys in your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Credentials**.
1. Select the **GPG Keys** tab.

![The credentials inventory page listing GPG keys.](img/credentials_inventory_gpg_keys_v14_9.png)
