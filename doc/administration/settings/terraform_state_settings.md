---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/19738) in GitLab 18.8.

{{< /history >}}

By default, GitLab encrypts Terraform state files before storing them. You can turn off
encryption if needed.

When encryption is turned off, Terraform state files are stored as they are received,
without any encryption applied.

Prerequisites:

- You must have administrator access.

To configure Terraform state encryption:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Preferences**.
1. Expand **Terraform state**.
1. Select or clear the **Turn on Terraform state encryption** checkbox.
1. Select **Save changes**.

> [!warning]
> When you turn off encryption, the change affects only new Terraform state files.
> Existing encrypted files remain encrypted and continue to work as expected.

## Encryption key rotation

You cannot rotate the Terraform state encryption key.

The encryption key is derived from the `db_key_base` application secret and the
project ID. For more information, see
[decryption process](../terraform_state.md#decryption-process).
Because the key is derived rather than stored directly, no standalone Terraform
state key exists to rotate.

Rotating `db_key_base` itself is not supported because it encrypts data across
the entire instance, including CI/CD variables, integration and webhook
credentials, and authentication tokens.

> [!warning]
> If you change `db_key_base`, existing Terraform state files become unreadable.
> GitLab raises an error if more than one `db_key_base` is configured and no
> re-encryption tool exists.

Key rotation is proposed in
[issue 25332](https://gitlab.com/gitlab-org/gitlab/-/issues/25332).

## Terraform state storage limits

You can limit the total storage of [Terraform state files](../terraform_state.md).
The limit applies to each individual state file version and is checked when a new version is created.

Prerequisites:

- You must have administrator access.

To add a storage limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Preferences**.
1. Expand **Terraform state**.
1. In the **Terraform state size limit (bytes)** field, enter a size limit in bytes. Set to `0` to allow files of unlimited size.
1. Select **Save changes**.

When Terraform state files exceed this limit, GitLab does not save them and rejects the associated Terraform operations.
