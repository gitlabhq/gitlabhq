---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform state settings
description: Configure Terraform state encryption and storage limits.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can configure settings for [Terraform state files](../terraform_state.md), including
encryption and storage limits.

## Terraform state encryption

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19738) in GitLab 18.8.

{{< /history >}}

By default, GitLab encrypts Terraform state files before storing them. You can turn off
encryption if needed.

When encryption is turned off, Terraform state files are stored as they are received,
without any encryption applied.

Prerequisites:

- You must have administrator access.
- The `skip_encrypting_terraform_state_file` feature flag must be enabled.

To configure Terraform state encryption:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Terraform state**.
1. Select or clear the **Turn on Terraform state encryption** checkbox.
1. Select **Save changes**.

> [!warning]
> When you turn off encryption, the change affects only new Terraform state files.
> Existing encrypted files remain encrypted and continue to work as expected.

## Terraform state storage limits

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352951) in GitLab 15.7.

{{< /history >}}

You can limit the total storage of [Terraform state files](../terraform_state.md).
The limit applies to each individual state file version and is checked when a new version is created.

Prerequisites:

- You must have administrator access.

To add a storage limit:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Terraform state**.
1. In the **Terraform state size limit (bytes)** field, enter a size limit in bytes. Set to `0` to allow files of unlimited size.
1. Select **Save changes**.

When Terraform state files exceed this limit, GitLab does not save them and rejects the associated Terraform operations.
