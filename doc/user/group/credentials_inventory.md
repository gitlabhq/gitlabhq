---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Credentials inventory for GitLab.com
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/297441) on GitLab.com in GitLab 17.5.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/work_items/498333) group and project token support to GitLab.com in GitLab 17.7.

{{< /history >}}

{{< alert type="note" >}}

For GitLab Self-Managed and GitLab Dedicated, see [Credentials inventory](../../administration/credentials_inventory.md).

{{< /alert >}}

Use the credentials inventory to monitor credentials for enterprise users and service accounts
in your top-level group.

Prerequisites:

- You must have the Owner role for a top-level group.

## View the credentials inventory

You can use the credentials inventory to review credential details for personal access tokens,
group access tokens, project access tokens, and SSH keys.

You can view details on:

- Ownership.
- Access scopes.
- Usage patterns.
- Expiration dates.
- Revocation dates.

To view the credentials inventory:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md), this field is on the top bar.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.

## Revoke personal access tokens

To revoke a personal access token:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md), this field is on the top bar.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Next to the personal access token, select **Revoke**.
   If the token was previously expired or revoked, you'll see the date this happened instead.

The access token is revoked and the user is notified by email.

## Revoke project or group access tokens

To revoke a project or group access token:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md), this field is on the top bar.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Select the **Project and group access tokens** tab.
1. Next to the project access token, select **Revoke**.

## Delete SSH keys

To delete an SSH key:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md), this field is on the top bar.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Select the **SSH Keys** tab.
1. Next to the SSH key, select **Delete**.

The SSH key is deleted and the user is notified.
