---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configure the maximum diff size to display on GitLab Self-Managed.
title: Diff limits administration
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Showing the full contents of large files can slow down merge requests. To prevent this,
you can configure limits for diffs displayed in merge requests, including the maximum diff
size, number of files changed, number of lines changed, diff versions, and diff commits.
These limits apply to both the GitLab UI and API endpoints that return diff information.

When a diff reaches 10% of the maximum diff patch size, maximum diff files, or maximum diff lines values,
GitLab shows the files in a collapsed view with a link to expand the diff. Diffs that exceed any of
these three values are shown as **Too large**, and you cannot expand them in the UI.

The maximum diff versions and maximum diff commits values limit merge request updates.
Merge requests that reach these limits cannot be updated further:

| Value                       | Definition                                                              | Default value | Maximum value |
|-----------------------------|-------------------------------------------------------------------------|:-------------:|:-------------:|
| **Maximum diff patch size** | The total size, in bytes, of the entire diff.                           |    200 KB     |    500 KB     |
| **Maximum diff files**      | The total number of files changed in a diff.                            |     1000      |     3000      |
| **Maximum diff lines**      | The total number of lines changed in a diff.                            |    50,000     |    100,000    |
| **Maximum diff versions**   | The number of diff versions per merge request.                          |     1,000     |     None      |
| **Maximum diff commits**    | The total number of diff commits across all versions per merge request. |   1,000,000   |     None      |

[Diff limits cannot be configured](../user/gitlab_com/_index.md#diff-display-limits) on GitLab.com.

For details about diff files, [view changes between files](../user/project/merge_requests/changes.md).
Read more about the [built-in limits for merge requests and diffs](instance_limits.md#merge-requests).

## Configure diff limits

> [!warning]
> These settings are experimental. An increased maximum increases resource
> consumption of your instance. Keep this in mind when adjusting the maximum.

Prerequisites:

- Administrator access.

To set maximum values for diff display in merge requests:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Diff limits**.
1. Enter a value for the diff limit.
1. Select **Save changes**.
