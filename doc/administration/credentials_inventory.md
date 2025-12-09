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
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/297441) on GitLab.com in GitLab 17.5.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/work_items/498333) group and project token support to GitLab.com in GitLab 17.7.

{{< /history >}}

Use the credentials inventory to monitor and control access to your organization.

- On GitLab.com, the credentials inventory monitors enterprise users and service
accounts in a top-level group.
- On GitLab Self-Managed and GitLab Dedicated, the credentials inventory monitors
all human users and service accounts across the entire instance.

Prerequisites:

- On GitLab.com, you must have the Owner role for a group.
- On GitLab Self-Managed and GitLab Dedicated, you must be an administrator.

## View the credentials inventory

You can use the credentials inventory to view:

- Personal access tokens.
- Group access tokens.
- Project access tokens.
- SSH keys.
- GPG keys (GitLab Self-Managed and GitLab Dedicated only).

To view the credentials inventory:

{{< tabs >}}

{{< tab title="For an instance" >}}

1. In the upper-right corner, select **Admin**.
1. Select **Credentials**.

{{< /tab >}}

{{< tab title="For a group" >}}

1. On the top bar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.

{{< /tab >}}

{{< /tabs >}}

You can use the inventory to review credential details including:

- Ownership.
- Access scopes.
- Usage patterns.
- Expiration dates.
- Revocation dates.

## Revoke personal access tokens

To revoke a personal access token:

{{< tabs >}}

{{< tab title="For an instance" >}}

1. In the upper-right corner, select **Admin**.
1. Select **Credentials**.
1. Next to the personal access token, select **Revoke**.
   If the token was previously expired or revoked, the associated date is displayed.

The access token is revoked and the user is notified by email.

{{< /tab >}}

{{< tab title="For a group" >}}

1. On the top bar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Next to the personal access token, select **Revoke**.
   If the token was previously expired or revoked, the associated date is displayed.

The access token is revoked and the user is notified by email.

{{< /tab >}}

{{< /tabs >}}

## Revoke project or group access tokens

To revoke a project or group access token:

{{< tabs >}}

{{< tab title="For an instance" >}}

1. In the upper-right corner, select **Admin**.
1. Select **Credentials**.
1. Select the **Project and group access tokens** tab.
1. Next to the project access token, select **Revoke**.

{{< /tab >}}

{{< tab title="For a group" >}}

1. On the top bar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Select the **Project and group access tokens** tab.
1. Next to the project access token, select **Revoke**.

{{< /tab >}}

{{< /tabs >}}

## Delete SSH keys

To delete an SSH key:

{{< tabs >}}

{{< tab title="For an instance" >}}

1. In the upper-right corner, select **Admin**.
1. Select **Credentials**.
1. Select the **SSH Keys** tab.
1. Next to the SSH key, select **Delete**.

The SSH key is deleted and the user is notified.

{{< /tab >}}

{{< tab title="For a group" >}}

1. On the top bar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure**.
1. Select **Credentials**.
1. Select the **SSH Keys** tab.
1. Next to the SSH key, select **Delete**.

The SSH key is deleted and the user is notified.

{{< /tab >}}

{{< /tabs >}}
