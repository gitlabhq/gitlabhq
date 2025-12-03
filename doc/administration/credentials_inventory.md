---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Credentials inventory
description: Monitor credentials through a comprehensive access inventory.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

For GitLab.com, see [Credentials inventory for GitLab.com](../user/group/credentials_inventory.md).

{{< /alert >}}

Use the credentials inventory to monitor credentials for all human users and service accounts
in your GitLab instance.

Prerequisites:

- You must be an administrator.

## View the credentials inventory

You can use the credentials inventory to review credential details for personal access tokens,
group access tokens, project access tokens, SSH keys, and GPG keys.

You can view details on:

- Ownership.
- Access scopes.
- Usage patterns.
- Expiration dates.
- Revocation dates.

To view the credentials inventory:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **Credentials**.

## Revoke personal access tokens

To revoke a personal access token:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Credentials**.
1. Next to the personal access token, select **Revoke**.
   If the token was previously expired or revoked, you'll see the date this happened instead.

The access token is revoked and the user is notified by email.

## Revoke project or group access tokens

To revoke a project or group access token:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Credentials**.
1. Select the **Project and group access tokens** tab.
1. Next to the project access token, select **Revoke**.

The access token is revoked and a background process begins to delete the associated project bot user.

## Delete SSH keys

To delete an SSH key:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Credentials**.
1. Select the **SSH Keys** tab.
1. Next to the SSH key, select **Delete**.

The SSH key is deleted and the user is notified.
