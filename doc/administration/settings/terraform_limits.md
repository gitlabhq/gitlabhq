---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform limits
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352951) in GitLab 15.7.

You can limit the total storage of [Terraform state files](../terraform_state.md).
The limit applies to each individual
state file version, and is checked whenever a new version is created.

To add a storage limit:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Terraform limits**.
1. Enter a size limit in bytes. Set to `0` to allow files of unlimited size.

When Terraform state files exceed this limit, they are not saved, and associated Terraform operations are rejected.
