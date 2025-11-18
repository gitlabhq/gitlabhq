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

Showing the full contents of large files can cause merge requests to load more slowly.
To prevent this, set maximum values for the diff size, number of files changed, and number of
lines changed. These limits apply to both the GitLab UI and API endpoints that return diff
information.

When a diff reaches 10% of any of these values, GitLab shows the files in a collapsed view with a link
to expand the diff. Diffs that exceed any of these values are shown as **Too large**, and you cannot
expand them in the UI:

| Value | Definition | Default value | Maximum value |
| ----- | ---------- | :-----------: | :-----------: |
| **Maximum diff patch size** | The total size, in bytes, of the entire diff. | 200 KB | 500 KB |
| **Maximum diff files** | The total number of files changed in a diff. | 1000 | 3000 |
| **Maximum diff lines** | The total number of lines changed in a diff. | 50,000 | 100,000 |

[Diff limits cannot be configured](../user/gitlab_com/_index.md#diff-display-limits) on GitLab.com.

For details about diff files, [view changes between files](../user/project/merge_requests/changes.md).
Read more about the [built-in limits for merge requests and diffs](instance_limits.md#merge-requests).

## Configure diff limits

{{< alert type="warning" >}}

These settings are experimental. An increased maximum increases resource
consumption of your instance. Keep this in mind when adjusting the maximum.

{{< /alert >}}

To set maximum values for diff display in merge requests:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Diff limits**.
1. Enter a value for the diff limit.
1. Select **Save changes**.
