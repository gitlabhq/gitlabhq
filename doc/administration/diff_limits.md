---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure the maximum diff size to display on GitLab Self-Managed."
---

# Diff limits administration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can set a maximum size for display of diff files (patches).

For details about diff files, [view changes between files](../user/project/merge_requests/changes.md).
Read more about the [built-in limits for merge requests and diffs](instance_limits.md#merge-requests).

## Configure diff limits

WARNING:
These settings are experimental. An increased maximum increases resource
consumption of your instance. Keep this in mind when adjusting the maximum.

To speed the loading of merge request views and branch comparison views
on your instance, configure these maximum values for diffs:

| Value | Definition | Default value | Maximum value |
| ----- | ---------- | :-----------: | :-----------: |
| **Maximum diff patch size** | The total size, in bytes, of the entire diff. | 200 KB | 500 KB |
| **Maximum diff files** | The total number of files changed in a diff. | 1000 | 3000 |
| **Maximum diff lines** | The total number of lines changed in a diff. | 50,000 | 100,000 |

When a diff reaches 10% of any of these values, the files are shown in a
collapsed view, with a link to expand the diff. Diffs that exceed any of the
set values are presented as **Too large** are cannot be expanded in the UI.

To configure these values:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Diff limits**.
1. Enter a value for the diff limit.
1. Select **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
