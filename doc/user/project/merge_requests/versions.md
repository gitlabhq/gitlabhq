---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use diff versions to compare pushes contained in a single merge request.
title: Merge request diff versions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you create a merge request, you select two branches to compare. The differences
between the two branches are shown as a diff in the merge request. Each time
you push commits to a branch connected to a merge request, GitLab updates the
merge request diff to a new diff version.

{{< alert type="note" >}}

Diff versions are updated on each push, not each commit. If a push contains multiple
commits, only one new diff version is created.

{{< /alert >}}

By default, GitLab compares the latest push in your source branch (`feature`)
against the most recent commit in the target branch, often `main`.

## Compare diff versions

If you've pushed to your branch multiple times, the diff version from each previous push
is available for comparison. When your merge request contains many changes or
sequential changes to the same file, you might want to compare a smaller number of changes.

Prerequisites:

- The merge request branch must contain commits from multiple pushes. Individual commits
  in the same push do not generate new diff versions.

To compare diff versions:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Code** > **Merge requests**.
1. Select a merge request.
1. To view the current diff version for this merge request, select **Changes**.
1. Next to **Compare** ({{< icon name="file-tree" >}}), select the pushes to compare. This example
   compares `main` to the most recent push (latest diff version) of the branch:

   ![Merge request versions dropdown list](img/versions_dropdown_v16_6.png)

   This example branch has four commits, but the branch contains only three diff versions
   because two commits were pushed at the same time.

## View diff versions from a system note

GitLab adds a system note to a merge request each time you push new changes to
the merge request's branch. In this example, a single push added two commits:

![Merge request versions system note](img/versions_system_note_v16_6.png)

To view the diff for that commit, select the commit SHA.

For more information, see how to [show or filter system notes on a merge request](../system_notes.md#on-a-merge-request).

## Related topics

- [Merge request diff storage for administrators](../../../administration/merge_request_diffs.md)
