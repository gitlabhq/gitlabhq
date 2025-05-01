---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Configure the maximum diff size to display on GitLab Self-Managed.
title: Diff limits administration
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can set a maximum size for display of diff files (patches) in GitLab Self-Managed and GitLab Dedicated.
[Diff limits cannot be configured](../user/gitlab_com/_index.md#diff-display-limits) on GitLab.com.

For details about diff files, [view changes between files](../user/project/merge_requests/changes.md).
Read more about the [built-in limits for merge requests and diffs](instance_limits.md#merge-requests).

## Configure diff limits

{{< alert type="warning" >}}

These settings are experimental. An increased maximum increases resource
consumption of your instance. Keep this in mind when adjusting the maximum.

{{< /alert >}}

To speed the loading of merge request views and branch comparison views
on your instance, configure these maximum values for diffs:

| Value | Definition | Default value | Maximum value |
| ----- | ---------- | :-----------: | :-----------: |
| **Maximum diff patch size** | The total size, in bytes, of the entire diff. | 200 KB | 500 KB |
| **Maximum diff files** | The total number of files changed in a diff. | 1000 | 3000 |
| **Maximum diff lines** | The total number of lines changed in a diff. | 50,000 | 100,000 |

When a diff reaches 10% of any of these values, the files are shown in a
collapsed view, with a link to expand the diff. Diffs that exceed any of the
set values are presented as **Too large** and cannot be expanded in the UI.

To configure these values:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Diff limits**.
1. Enter a value for the diff limit.
1. Select **Save changes**.
