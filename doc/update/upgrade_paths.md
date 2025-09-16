---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Plan your upgrade path
description: Latest version instructions.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

An upgrade path involves steps to move from your current GitLab version to the GitLab version you want to
upgrade to. To determine your upgrade path:

1. Note where in the upgrade path your current version sits, including required upgrade stops.
1. Consult the [GitLab upgrade notes](versions/_index.md).

Even when not explicitly specified, upgrade GitLab to the latest available patch release of the `major`.`minor` release
rather than the first patch release. For example, `16.8.7` instead of `16.8.0`.

Some `major`.`minor` versions are required stops for some or all environments because there are
fixes for issues relating to the upgrade process.

## Required upgrade stops

Upgrade paths include required upgrade stops, which are versions of GitLab that you must upgrade to before upgrading to
later versions. When moving through an upgrade path:

1. Upgrade to the required upgrade stop after your current version.
1. Allow the background migrations for the upgrade to finish.
1. Upgrade to the next required upgrade stop.

In GitLab 17.5 and later, to provide a predictable upgrade schedule for instance administrators, required upgrade stops occur
at versions `x.2.z`, `x.5.z`, `x.8.z`, and `x.11.z`.

To check available patch releases for a specific minor version, you can search for the minor version
in the [GitLab package repository](https://packages.gitlab.com/gitlab). For example, to search for the latest
GitLab 18.2 Enterprise Edition version, go to <https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=18.2>.

If you're upgrading a GitLab Helm chart instance, see the
[list of GitLab Helm chart mappings](https://docs.gitlab.com/charts/installation/version_mappings/#previous-chart-versions).

### Required GitLab 17 upgrade stops

You must upgrade to these versions of GitLab 17 before upgrading to later versions.

| Required version | Notes |
|:-----------------|:------|
| 17.11.7          | Upgrade to the latest GitLab 17.11 patch release. See [upgrade notes for GitLab 17.11.0](versions/gitlab_17_changes.md#upgrades-to-17110). |
| 17.8.7           | Upgrade to the latest GitLab 17.8 patch release. See [upgrade notes for GitLab 17.8.0](versions/gitlab_17_changes.md#upgrades-to-1780). |
| 17.5.5           | Upgrade to the latest GitLab 17.5 patch release. See [upgrade notes for GitLab 17.5.0](versions/gitlab_17_changes.md#upgrades-to-1750). |
| 17.3.7           | Upgrade to the latest GitLab 17.3 release. See [upgrade notes for GitLab 17.3.0](versions/gitlab_17_changes.md#upgrades-to-1730). |
| 17.1.8           | Required only for instances with [large `ci_pipeline_messages` tables](versions/gitlab_17_changes.md#long-running-pipeline-messages-data-change). See [upgrade notes for GitLab 17.1.0](versions/gitlab_17_changes.md#upgrades-to-1710).|

### Required GitLab 16 upgrade stops

You must upgrade to these versions of GitLab 16 before upgrading to later versions.

| Required version | Notes |
|:-----------------|:------|
| 16.11.10         | See [upgrade notes for GitLab 16.11.0](versions/gitlab_16_changes.md#16110). |
| 16.7.10          | See [upgrade notes for GitLab 16.8.0](versions/gitlab_16_changes.md#1670) and later GitLab 16.7 versions. |
| 16.3.9           | See [upgrade notes for GitLab 16.3.0](versions/gitlab_16_changes.md#1630) and later GitLab 16.3 versions. |
| 16.2.11          | Required only for GitLab instances with [large pipeline variables history](versions/gitlab_16_changes.md#1630). See [upgrade notes for GitLab 16.2.0](versions/gitlab_16_changes.md#1620). |
| 16.1.8           | Required only for GitLab instances [with NPM packages in their package registry](versions/gitlab_16_changes.md#1610). See [upgrade notes for GitLab 16.1.0](versions/gitlab_16_changes.md#1610). |
| 16.0.10          | Required only for GitLab instances with [lots of users](versions/gitlab_16_changes.md#long-running-user-type-data-change) or [large pipeline variables history](versions/gitlab_16_changes.md#1610). See [upgrade notes for GitLab 16.0.0](versions/gitlab_16_changes.md#1600) and later GitLab 16.0 versions. |

### Required GitLab 15 upgrade stops

You must upgrade to these versions of GitLab 15 before upgrading to later versions.

| Required version | Notes |
|:-----------------|:------|
| 15.11.13         | See [upgrade notes for GitLab 15.11.0](versions/gitlab_15_changes.md#15110) and later GitLab 15.11 versions. |
| 15.4.6           | See [upgrade notes for GitLab 15.4.0](versions/gitlab_15_changes.md#1540) and later GitLab 15.4 versions. |
| 15.1.6           | Required only for GitLab instances with multiple web nodes. See [upgrade notes for GitLab 15.1.0](versions/gitlab_15_changes.md#1510). |
| 15.0.5           | See [upgrade notes for GitLab 15.0](versions/gitlab_15_changes.md#1500). |

## Upgrade Path tool

To quickly calculate which upgrade stops are required based on your current and desired target GitLab version, see the
[Upgrade Path tool](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/). This tool is
maintained by the GitLab Support team.

To share feedback and help improve the tool, create an issue or merge request in the
[`upgrade-path` project](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path).

## Earlier GitLab versions

For information on upgrading to earlier GitLab versions, see the [documentation archives](https://archives.docs.gitlab.com).
The versions of the documentation in the archives contain version-specific information for earlier versions of GitLab.
