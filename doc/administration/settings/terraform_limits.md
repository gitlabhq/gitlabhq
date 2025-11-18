---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform limits
description: Configure Terraform storage limits.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352951) in GitLab 15.7.

{{< /history >}}

You can limit the total storage of [Terraform state files](../terraform_state.md).
The limit applies to each individual
state file version, and is checked whenever a new version is created.

To add a storage limit:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Preferences**.
1. Expand **Terraform limits**.
1. Enter a size limit in bytes. Set to `0` to allow files of unlimited size.

When Terraform state files exceed this limit, they are not saved, and associated Terraform operations are rejected.
