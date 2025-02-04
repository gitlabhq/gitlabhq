---
stage: Systems
group: Distribution
description: Latest version instructions.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade paths
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Upgrading across multiple GitLab versions in one go is *only possible by accepting downtime*.
If you don't want any downtime, read how to [upgrade with zero downtime](zero_downtime.md).

Upgrade paths include required upgrade stops, which are versions of GitLab that you must upgrade to before upgrading to
later versions. When moving through an upgrade path:

1. Upgrade to the required upgrade stop after your current version.
1. Allow the background migrations for the upgrade to finish.
1. Upgrade to the next required upgrade stop.

To provide a predictable upgrade schedule for instance administrators, from GitLab 17.5, required upgrade stops will occur at versions `x.2.z`, `x.5.z`, `x.8.z`, and `x.11.z`.

To determine your upgrade path:

1. Note where in the upgrade path your current version sits, including required upgrade stops:

   - GitLab 15 includes the following required upgrade stops:
     - [`15.0.5`](versions/gitlab_15_changes.md#1500).
     - [`15.1.6`](versions/gitlab_15_changes.md#1510). GitLab instances with multiple web nodes.
     - [`15.4.6`](versions/gitlab_15_changes.md#1540).
     - [`15.11.13`](versions/gitlab_15_changes.md#15110).
   - GitLab 16 includes the following required upgrade stops:
     - [`16.0.10`](versions/gitlab_16_changes.md#1600). Instances with
       [lots of users](versions/gitlab_16_changes.md#long-running-user-type-data-change) or
       [large pipeline variables history](versions/gitlab_16_changes.md#1610).
     - [`16.1.8`](versions/gitlab_16_changes.md#1610). Instances with NPM packages in their package registry.
     - [`16.2.11`](versions/gitlab_16_changes.md#1620). Instances with [large pipeline variables history](versions/gitlab_16_changes.md#1630).
     - [`16.3.9`](versions/gitlab_16_changes.md#1630).
     - [`16.7.10`](versions/gitlab_16_changes.md#1670).
     - [`16.11.10`](https://gitlab.com/gitlab-org/gitlab/-/releases).
   - GitLab 17 includes the following required upgrade stops:
     - [`17.1.8`](versions/gitlab_17_changes.md#long-running-pipeline-messages-data-change). Instances with large `ci_pipeline_messages` tables.
     - [`17.3.7`](versions/gitlab_17_changes.md#1730). The latest GitLab 17.3 release.
     - [`17.5.z`](versions/gitlab_17_changes.md#1750). The latest GitLab 17.5 release.
     - [`17.8.z`](versions/gitlab_17_changes.md#1780). The latest GitLab 17.8 release.
     - `17.11.z`. Not yet released.

1. Consult the version-specific upgrade instructions:
   - [GitLab 17 changes](versions/gitlab_17_changes.md)
   - [GitLab 16 changes](versions/gitlab_16_changes.md)
   - [GitLab 15 changes](versions/gitlab_15_changes.md)

Even when not explicitly specified, upgrade GitLab to the latest available patch release of the `major`.`minor` release
rather than the first patch release. For example, `16.8.7` instead of `16.8.0`.

This includes `major`.`minor` versions you must stop at on the upgrade path because there may
be fixes for issues relating to the upgrade process.

Specifically around a major version, crucial database schema and migration patches may be included in the latest patch
releases.

## Upgrade Path tool

To quickly calculate which upgrade stops are required based on your current and desired target GitLab version, see the
[Upgrade Path tool](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/). This tool is
maintained by the [GitLab Support team](https://handbook.gitlab.com/handbook/support/#about-the-support-team).

To share feedback and help improve the tool, create an issue or merge request in the [upgrade-path project](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path).

## Earlier GitLab versions

For information on upgrading to earlier GitLab versions, see the [documentation archives](https://archives.docs.gitlab.com).
The versions of the documentation in the archives contain version-specific information for even earlier versions of GitLab.

For example, the [documentation for GitLab 15.11](https://archives.docs.gitlab.com/15.11/ee/update/#upgrade-paths)
contains information on versions back to GitLab 12.
