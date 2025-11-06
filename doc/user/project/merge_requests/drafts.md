---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Prevent an incomplete merge request from merging until it's ready by setting it as a draft.
title: Draft merge requests
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If a merge request isn't ready to merge, you can block it from merging until you
[mark it as ready](#mark-merge-requests-as-ready). Merge requests marked as **Draft**
cannot merge until you remove the **Draft** flag, even if they meet all other merge criteria:

![merge blocked](img/merge_request_draft_blocked_v16_0.png)

## Mark merge requests as drafts

You can flag a merge request as a draft in several ways:

- Viewing a merge request: In the upper-right corner of the merge request,
  select **Merge request actions** ({{< icon name="ellipsis_v" >}}), then **Mark as draft**.
- Creating or editing a merge request: You can do either of the following:
  - Add `[Draft]`, `Draft:` or `(Draft)` to the beginning of the merge request's title.
  - Select **Mark as draft** below the **Title** field
- Commenting in an existing merge request: Add the `/draft`
  [quick action](../quick_actions.md#issues-merge-requests-and-epics)
  in a comment. To mark a merge request as ready, use `/ready`.
- Creating a commit: Add `draft:`, `Draft:`, `fixup!`, or `Fixup!` to the
  beginning of a commit message targeting the merge request's source branch. This
  method is not a toggle. Adding this text again in a later commit doesn't mark the
  merge request as ready.

## Mark merge requests as ready

When a merge request is ready to merge, you can remove the `Draft` flag in several ways:

- Viewing a merge request: In the upper-right corner of the merge request, select **Mark as ready**.
  Users with at least the Developer role can also scroll to the bottom of the merge request
  description and select **Mark as ready**.
- Editing an existing merge request: Remove `[Draft]`, `Draft:` or `(Draft)`
  from the beginning of the title, or clear **Mark as draft** below the **Title** field.
- Commenting in an existing merge request: Add the `/ready`
  [quick action](../quick_actions.md#issues-merge-requests-and-epics)
  in a comment in the merge request.

When you mark a merge request as ready, GitLab notifies
[merge request participants and watchers](../../profile/notifications.md#notifications-on-issues-merge-requests-and-epics).

## Include or exclude drafts when searching

When you view or search in your project's merge requests list, to include or exclude
draft merge requests:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Code** > **Merge requests**.
1. To filter by merge request status, select **Open**, **Merged**, **Closed**,
   or **All** in the navigation bar.
1. Select the search box to display a list of filters and select **Draft**, or
   enter the word `draft`.
1. Select `=`.
1. Select **Yes** to include drafts, or **No** to exclude, and press **Return**
   to update the list of merge requests:

   ![Filter draft merge requests](img/filter_draft_merge_requests_v16_0.png)

## Pipelines for drafts

Draft merge requests run the same pipelines as merge requests marked as ready.

To skip a pipeline for a draft merge request, see [Skip pipelines for draft merge requests](../../../ci/yaml/workflow.md#skip-pipelines-for-draft-merge-requests).
