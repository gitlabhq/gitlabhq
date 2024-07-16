---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Security and compliance Admin area settings

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed

The settings for package metadata synchronization are located in the [Admin area](index.md).

## Choose package registry metadata to sync

To choose the packages you want to synchronize with the GitLab Package Metadata Database for [License Compliance](../../user/compliance/license_scanning_of_cyclonedx_files/index.md) and [Continuous Vulnerability Scanning](../../user/application_security/continuous_vulnerability_scanning/index.md):

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > Security and compliance**.
1. In **Package registry metadata to sync**, select or clear checkboxes for the
   package registries that you want to sync.
1. Select **Save changes**.

For this data synchronization to work, you must allow outbound network traffic from your GitLab instance to the domain `storage.googleapis.com`. See also the offline setup instructions described in [Enabling the Package Metadata Database](../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database).
