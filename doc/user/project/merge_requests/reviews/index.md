---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use merge request reviews to discuss and improve code before it is merged into your project."
---

# Merge request reviews

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

[Merge requests](../index.md) are the primary method of making changes to files in a
GitLab project. [Create and submit a merge request](../creating_merge_requests.md)
to propose changes. Your team leaves [comments](../../../discussions/index.md) on
your merge request, and makes [Code Suggestions](suggestions.md) you can accept
from the user interface. When your work is reviewed, your team members can choose
to accept or reject it.

You can review merge requests from the GitLab interface. If you install the
[GitLab Workflow VS Code extension](../../../../editor_extensions/visual_studio_code/index.md), you can also
review merge requests in Visual Studio Code.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Merge request review](https://www.youtube.com/watch?v=2MayfXKpU08&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED&index=183).
<!-- Video published on 2023-04-29 -->

## GitLab Duo Suggested Reviewers

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/groups/gitlab-org/modelops/applied-ml/review-recommender/-/epics/3) in GitLab 15.4 as a [Beta](../../../../policy/experiment-beta-support.md#beta) feature [with a flag](../../../../administration/feature_flags.md) named `suggested_reviewers_control`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/368356) in GitLab 15.6.
> - Beta designation [removed from the UI](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113058) in GitLab 15.10.
> - Feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134728) in GitLab 16.6.

GitLab uses machine learning to suggest reviewers for your merge request.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [GitLab Duo Suggested Reviewers](https://www.youtube.com/embed/ivwZQgh4Rxw).
<!-- Video published on 2023-11-03 -->

To suggest reviewers, GitLab uses:

- The changes in the merge request
- The project's contribution graph

GitLab Duo Suggested Reviewers also integrates with Code Owners, profile status, and merge request rules, helping you make a more informed decision when choosing reviewers that can meet your review criteria.

![GitLab Duo Suggested Reviewers](img/suggested_reviewers_v16_3.png)

For more information, see [Data usage in GitLab Duo Suggested Reviewers](data_usage.md).

### Enable Suggested Reviewers

Enabling Suggested Reviewers triggers GitLab to create an ML model for your
project that is used to generate reviewers. The larger your project, the longer
this process can take. Usually, the model is ready to generate suggestions
within a few hours.

Prerequisites:

- You have the Owner or Maintainer role in the project.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Scroll to **Suggested reviewers**, and select **Enable suggested reviewers**.
1. Select **Save changes**.

After you enable the feature, no additional action is needed. After the model is ready,
recommendations populate the **Reviewer** dropdown list in the right-hand sidebar
of a merge request with new commits.

## Review a merge request

When you review a merge request, you can create comments that are visible only
to you. When you're ready, you can publish them together in a single action.
To start your review:

1. Go to the merge request you want to review, and select the **Changes** tab.
   For more information about navigating the diffs displayed in this tab, see
   [Changes in merge requests](../changes.md).
1. Select **Add a comment to this line** (**{comment}**) in the gutter to expand the diff lines
   and display a comment box. In GitLab version 13.2 and later, you can
   [select multiple lines](#comment-on-multiple-lines).
1. In the text area, write your first comment, then select **Start a review** below your comment.
1. Continue adding comments to lines of code. After each comment, select **Add to review**.
   Comments made as part of a review are visible only to you until you submit your review.
1. Optional. You can use [quick actions](../../quick_actions.md) inside review comments.
   The comment shows the actions to perform after publication, but does not perform them
   until you submit your review.
1. When your review is complete, you can [submit the review](#submit-a-review). Your comments
   are now visible, and any [quick actions](../../quick_actions.md) included in
   your comments are performed.

If you [approve a merge request](../approvals/index.md#approve-a-merge-request) and
are shown in the reviewer list, a green check mark **{check-circle-filled}**
displays next to your name.

### Request a review

To assign a reviewer to a merge request, in a text area in
the merge request, use the `/assign_reviewer @user`
[quick action](../../quick_actions.md#issues-merge-requests-and-epics). Alternatively:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. On the right sidebar, in the **Reviewers** section, select **Edit**.
1. Search for the user you want to assign, and select the user.

The merge request is added to the user's review requests.

#### From multiple users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To assign multiple reviewers to a merge request, in a text area in
the merge request, use the `/assign_reviewer @user`
[quick action](../../quick_actions.md#issues-merge-requests-and-epics). Alternatively:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. On the right sidebar, in the **Reviewers** section, select **Edit**.
1. From the dropdown list, select all the users you want
   to assign to the merge request.

To remove a reviewer, clear the user from the same dropdown list.

### Download merge request changes as a diff

To download the changes included in a merge request as a diff:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Select your merge request.
1. In the upper-right corner, select **Code > Plain diff**.

If you know the URL of the merge request, you can also download the diff from
the command line by appending `.diff` to the URL. This example downloads the diff
for merge request `000000`:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff
```

To download and apply the diff in a one-line CLI command:

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff" | git apply
```

### Download merge request changes as a patch file

To download the changes included in a merge request as a patch file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Select your merge request.
1. In the upper-right corner, select **Code > Patches**.

If you know the URL of the merge request, you can also download the patch from
the command line by appending `.patch` to the URL. This example downloads the patch
file for merge request `000000`:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch
```

To download and apply the patch in a one-line CLI command using [`git am`](https://git-scm.com/docs/git-am):

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" | git am
```

### Submit a review

You can submit your completed review in multiple ways:

- Use the `/submit_review` [quick action](../../quick_actions.md) in the text of a non-review comment.
- Select **Finish review**, then select **Submit review** at the bottom of the modal window.
  In the modal window, you can supply a **Summary comment**, approve the merge request, and
  include quick actions:

  ![Finish review with comment](img/mr_summary_comment_v16_9.png)

When you submit your review, GitLab:

- Publishes the comments in your review.
- Sends a single email to every notifiable user of the merge request, with your
  review comments attached. Replying to this email creates a new comment on the merge request.
- Perform any quick actions you added to your review comments.
- Optional. Shows whether you have also approved or requested changes:
  - **Comment**: Leave general feedback without explicit approval.
  - **Approve**: Leave feedback and approve the changes.
  - **Request changes**: Leave feedback that should be addressed before merging.

### Resolve or unresolve thread with a comment

Review comments can also resolve or unresolve [resolvable threads](../index.md#resolve-a-thread).
To resolve or unresolve a thread when replying to a comment:

1. In the comment text area, write your comment.
1. Select or clear **Resolve thread**.
1. Select **Add comment now** or **Add to review**.

Pending comments display information about the action to be taken when the comment is published:

- **{check-circle-filled}** Thread is resolved.
- **{check-circle}** Thread stays unresolved.

### Add a new comment

If you have a review in progress, you can also add a comment from the **Overview** tab by selecting
 **Add to review**:

![New thread](img/mr_review_new_comment_v16_6.png)

### Approval Rule information for Reviewers

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When editing the **Reviewers** field in a new or existing merge request, GitLab
displays the name of the matching [approval rule](../approvals/rules.md)
below the name of each reviewer. [Code Owners](../../codeowners/index.md) are displayed as `Codeowner` without group detail.

This example shows reviewers and approval rules when creating a new merge request:

![Reviewer approval rules in new/edit form](img/reviewer_approval_rules_form_v15_9.png)

This example shows reviewers and approval rules in a merge request sidebar:

![Reviewer approval rules in sidebar](img/reviewer_approval_rules_sidebar_v15_9.png)

### Request a new review

After a reviewer completes their [merge request reviews](../../../discussions/index.md),
the author of the merge request can request a new review from the reviewer:

1. If the right sidebar in the merge request is collapsed, select the
   **{chevron-double-lg-left}** **Expand Sidebar** icon to expand it.
1. In the **Reviewers** section, select the **Re-request a review** icon (**{redo}**)
   next to the reviewer's name.

GitLab creates a new [to-do item](../../../todos.md) for the reviewer, and sends
them a notification email.

## Comment on multiple lines

When commenting on a diff, you can select which lines of code your comment refers
to by either:

- Dragging **Add a comment to this line** (**{comment}**) in the gutter to highlight
  lines in the diff. GitLab expands the diff lines and displays a comment box.
- After starting a comment by selecting **Add a comment to this line** (**{comment}**) in the
  gutter, select the first line number your comment refers to in the **Commenting on lines**
  select box. New comments default to single-line comments, unless you select
  a different starting line.

![Comment on any diff file line](img/comment_on_any_diff_line_v16_6.png)

Multiline comments display the comment's line numbers above the body of the comment:

![Multiline comment selection displayed above comment](img/multiline-comment-saved.png)

## Bulk edit merge requests at the project level

Users with at least the Developer role can manage merge requests.

When bulk-editing merge requests in a project, you can edit the following attributes:

- Status (open/closed)
- Assignee
- Milestone
- Labels
- Subscriptions

To update multiple project merge requests at the same time:

1. In a project, go to **Code > Merge requests**.
1. Select **Bulk edit**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Select **Update all**.

## Bulk edit merge requests at the group level

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Users with at least the Developer role can manage merge requests.

When bulk editing merge requests in a group, you can edit the following attributes:

- Milestone
- Labels

To update multiple group merge requests at the same time:

1. In a group, go to **Code > Merge requests**.
1. Select **Bulk edit**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Select **Update all**.

## Associated features

These features are associated with merge requests:

- [Cherry-pick changes](../cherry_pick_changes.md):
  Cherry-pick any commit in the UI by selecting the **Cherry-pick** button in a merged merge requests or a commit.
- [Fast-forward merge requests](../methods/index.md#fast-forward-merge):
  For a linear Git history and a way to accept merge requests without creating merge commits
- [Find the merge request that introduced a change](../versions.md):
  When viewing the commit details page, GitLab links to the merge requests containing that commit.
- [Merge requests versions](../versions.md):
  Select and compare the different versions of merge request diffs
- [Resolve conflicts](../conflicts.md):
  GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.
- [Revert changes](../revert_changes.md):
  Revert changes from any commit from a merge request.
- [Keyboard shortcuts](../../../shortcuts.md#merge-requests):
  Access and modify specific parts of a merge request with keyboard commands.

## Related topics

- [Merge methods](../methods/index.md)
- [Draft Notes API](../../../../api/draft_notes.md)
