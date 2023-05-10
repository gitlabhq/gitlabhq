---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: howto
---

# Security and Compliance Admin Area settings **(ULTIMATE SELF)**

The settings for package metadata synchronization are located in the [Admin Area](index.md).

## Choose package registry metadata to sync

WARNING:
The full package metadata sync can take up to 30 GB of data. Ensure you have provisioned enough disk space before enabling this feature.
We are actively working on reducing this data size in [epic 10415](https://gitlab.com/groups/gitlab-org/-/epics/10415).

To choose the packages you want to synchronize with the GitLab License Database for [License Compliance](../../compliance/license_scanning_of_cyclonedx_files/index.md):

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Security and Compliance**.
1. Expand **License Compliance**.
1. Select or clear checkboxes for the package registries that you want to sync.
1. Select **Save changes**.
