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

{{< /history >}}

{{< alert type="note" >}}

For GitLab Self-Managed, see [Credentials inventory for GitLab Self-Managed](../../administration/credentials_inventory.md).

{{< /alert >}}

Use the credentials inventory to monitor and control access to your groups and projects for GitLab.com.

As the Owner for a top-level group, you can:

- Revoke personal access tokens.
- Delete SSH keys.
- Review credential details for your [enterprise users](../enterprise_user/_index.md) including:
  - Ownership.
  - Access scopes.
  - Usage patterns.
  - Expiration dates.
  - Revocation dates.

## Revoke personal access tokens

To revoke personal access tokens for enterprise users in your group:

1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Next to the personal access token, select **Revoke**.
   If the token was previously expired or revoked, you'll see the date this happened instead.

The access token is revoked and the user is notified by email.

## Delete SSH keys

To delete SSH keys for enterprise users in your group:

1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Select the **SSH keys** tab.
1. Next to the SSH key, select **Delete**.

The SSH key is deleted and the user is notified.

## Revoke project or group access tokens

You cannot view or revoke project or group access tokens using the credentials inventory on GitLab.com.
[Issue 498333](https://gitlab.com/gitlab-org/gitlab/-/issues/498333) proposes to add this feature.
