---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# Review and manage merge requests **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216054) in GitLab 13.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/245190) in GitLab 13.9.

[Merge requests](../index.md) are the primary method of making changes to files in a
GitLab project. [Create and submit a merge request](../creating_merge_requests.md)
to propose changes. Your team leaves [comments](../../../discussions/index.md), and
makes [code suggestions](suggestions.md) you can accept from the user interface.
When your work is reviewed, your team members can choose to accept or reject it.

## Bulk edit merge requests at the project level

Users with permission level of [Developer or higher](../../../permissions.md) can manage merge requests.

When bulk editing merge requests in a project, you can edit the following attributes:

- Status (open/closed)
- Assignee
- Milestone
- Labels
- Subscriptions

To update multiple project merge requests at the same time:

1. In a project, go to **Merge requests**.
1. Click **Edit merge requests**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Click **Update all**.

## Bulk edit merge requests at the group level

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12719) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.2.

Users with permission level of [Developer or higher](../../../permissions.md) can manage merge requests.

When bulk editing merge requests in a group, you can edit the following attributes:

- Milestone
- Labels

To update multiple group merge requests at the same time:

1. In a group, go to **Merge requests**.
1. Click **Edit merge requests**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Click **Update all**.

## Review a merge request

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4213) in GitLab Premium 11.4.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/28154) to GitLab Free in 13.1.

When you review a merge request, you can create comments that are visible only
to you. When you're ready, you can publish them together in a single action.
To start your review:

1. Go to the merge request you want to review, and select the **Changes** tab.
   To learn more about navigating the diffs displayed in this tab, read
   [Changes tab in merge requests](../changes.md).
1. Select a line of code. In GitLab version 13.2 and later, you can [highlight a set of lines](#comment-on-multiple-lines).
1. Write your first comment, and select **Start a review** below your comment:
   ![Starting a review](img/mr_review_start.png)
1. Continue adding comments to lines of code, and select the appropriate button after
   you write a comment:
   - **Add to review**: Keep this comment private and add to the current review.
     These review comments are marked **Pending** and are visible only to you.
   - **Add comment now**: Submits the specific comment as a regular comment instead of as part of the review.
1. (Optional) You can use [quick actions](../../quick_actions.md) inside review comments.
   The comment shows the actions to perform after publication, but does not perform them
   until you submit your review.
1. When your review is complete, you can [submit the review](#submit-a-review). Your comments
   are now visible, and any quick actions included your comments are performed.

### Submit a review

You can submit your completed review in multiple ways:

- Use the `/submit_review` [quick action](../../quick_actions.md) in the text of a non-review comment.
- When creating a review comment, select **Submit review**.
- Scroll to the bottom of the screen and select **Submit review**.

When you submit your review, GitLab:

- Publishes the comments in your review.
- Sends a single email to every notifiable user of the merge request, with your
  review comments attached. Replying to this email creates a new comment on the merge request.
- Perform any quick actions you added to your review comments.

### Resolving/Unresolving threads

Review comments can also resolve or unresolve [resolvable threads](../../../discussions/index.md#resolve-a-thread)).
When replying to a comment, a checkbox is displayed to resolve or unresolve
the thread after publication.

![Resolve checkbox](img/mr_review_resolve.png)

If a particular pending comment resolves or unresolves the thread, this is shown on the pending
comment itself.

![Resolve status](img/mr_review_resolve2.png)

![Unresolve status](img/mr_review_unresolve.png)

### Adding a new comment

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8225) in GitLab 13.10.

If you have a review in progress, you will be presented with the option to **Add to review**:

![New thread](img/mr_review_new_comment_v13_11.png)

### Approval Rule information for Reviewers **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/233736) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/293742) in GitLab 13.9.

When editing the **Reviewers** field in a new or existing merge request, GitLab
displays the name of the matching [approval rule](../approvals/rules.md)
below the name of each suggested reviewer. [Code Owners](../../code_owners.md) are displayed as `Codeowner` without group detail.

This example shows reviewers and approval rules when creating a new merge request:

![Reviewer approval rules in new/edit form](img/reviewer_approval_rules_form_v13_8.png)

This example shows reviewers and approval rules in a merge request sidebar:

![Reviewer approval rules in sidebar](img/reviewer_approval_rules_sidebar_v13_8.png)

### Requesting a new review

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/293933) in GitLab 13.9.

After a reviewer completes their [merge request reviews](../../../discussions/index.md),
the author of the merge request can request a new review from the reviewer:

1. If the right sidebar in the merge request is collapsed, click the
   **{chevron-double-lg-left}** **Expand Sidebar** icon to expand it.
1. In the **Reviewers** section, click the **Re-request a review** icon (**{redo}**)
   next to the reviewer's name.

GitLab creates a new [to-do item](../../../todos.md) for the reviewer, and sends
them a notification email.

#### Approval status

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292936) in GitLab 13.10.

If a user in the reviewer list has approved the merge request, a green tick symbol is
shown to the right of their name.

## Semi-linear history merge requests

A merge commit is created for every merge, but the branch is only merged if
a fast-forward merge is possible. This ensures that if the merge request build
succeeded, the target branch build also succeeds after the merge.

1. Go to your project and select **Settings > General**.
1. Expand **Merge requests**.
1. In the **Merge method** section, select **Merge commit with semi-linear history**.
1. Select **Save changes**.

## Perform inline code reviews

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/13950) in GitLab 11.5.

In a merge request, you can leave comments in any part of the file being changed.
In the merge request Diff UI, you can:

- **Comment on a single line**: Select the **{comment}** **comment** icon in the
  gutter to expand the diff lines and display a comment box.
- [**Comment on multiple lines**](#comment-on-multiple-lines).

### Comment on multiple lines

> - [Introduced](https://gitlab.com/gitlab-org/ux-research/-/issues/870) in GitLab 13.2.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49875) click-and-drag features in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/299121) in GitLab 13.9.

When commenting on a diff, you can select which lines of code your comment refers
to by either:

![Comment on any diff file line](img/comment-on-any-diff-line_v13_10.png)

- Dragging the **{comment}** **comment** icon in the gutter to highlight
  lines in the diff. GitLab expands the diff lines and displays a comment box.
- After starting a comment by selecting the **{comment}** **comment** icon in the
  gutter, select the first line number your comment refers to in the **Commenting on lines**
  select box. New comments default to single-line comments, unless you select
  a different starting line.

Multiline comments display the comment's line numbers above the body of the comment:

![Multiline comment selection displayed above comment](img/multiline-comment-saved.png)

## Associated features

These features are associated with merge requests:

- [Bulk editing merge requests](../../../project/bulk_editing.md):
  Update the attributes of multiple merge requests simultaneously.
- [Cherry-pick changes](../cherry_pick_changes.md):
  Cherry-pick any commit in the UI by selecting the **Cherry-pick** button in a merged merge requests or a commit.
- [Fast-forward merge requests](../fast_forward_merge.md):
  For a linear Git history and a way to accept merge requests without creating merge commits
- [Find the merge request that introduced a change](../versions.md):
  When viewing the commit details page, GitLab links to the merge request(s) containing that commit.
- [Merge requests versions](../versions.md):
  Select and compare the different versions of merge request diffs
- [Resolve conflicts](../resolve_conflicts.md):
  GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.
- [Revert changes](../revert_changes.md):
  Revert changes from any commit from a merge request.

## Troubleshooting

Sometimes things don't go as expected in a merge request. Here are some
troubleshooting steps.

### Merge request cannot retrieve the pipeline status

This can occur if Sidekiq doesn't pick up the changes fast enough.

#### Sidekiq

Sidekiq didn't process the CI state change fast enough. Please wait a few
seconds and the status should update automatically.

#### Bug

Merge request pipeline statuses can't be retrieved when the following occurs:

1. A merge request is created
1. The merge request is closed
1. Changes are made in the project
1. The merge request is reopened

To enable the pipeline status to be properly retrieved, close and reopen the
merge request again.

## Tips

Here are some tips to help you be more efficient with merge requests in
the command line.

### Copy the branch name for local checkout

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23767) in GitLab 13.4.

The merge request sidebar contains the branch reference for the source branch
used to contribute changes for this merge request.

To copy the branch reference into your clipboard, select the **Copy branch name** button
(**{copy-to-clipboard}**) in the right sidebar. Use it to checkout the branch locally
from the command line by running `git checkout <branch-name>`.

### Checkout merge requests locally through the `head` ref

A merge request contains all the history from a repository, plus the additional
commits added to the branch associated with the merge request. Here's a few
ways to check out a merge request locally.

You can check out a merge request locally even if the source
project is a fork (even a private fork) of the target project.

This relies on the merge request `head` ref (`refs/merge-requests/:iid/head`)
that is available for each merge request. It allows checking out a merge
request by using its ID instead of its branch.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223156) in GitLab
13.4, 14 days after a merge request gets closed or merged, the merge request
`head` ref is deleted. This means that the merge request isn't available
for local checkout from the merge request `head` ref anymore. The merge request
can still be re-opened. If the merge request's branch
exists, you can still check out the branch, as it isn't affected.

#### Checkout locally by adding a Git alias

Add the following alias to your `~/.gitconfig`:

```plaintext
[alias]
    mr = !sh -c 'git fetch $1 merge-requests/$2/head:mr-$1-$2 && git checkout mr-$1-$2' -
```

Now you can check out a particular merge request from any repository and any
remote. For example, to check out the merge request with ID 5 as shown in GitLab
from the `origin` remote, do:

```shell
git mr origin 5
```

This fetches the merge request into a local `mr-origin-5` branch and check
it out.

#### Checkout locally by modifying `.git/config` for a given repository

Locate the section for your GitLab remote in the `.git/config` file. It looks
like this:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

You can open the file with:

```shell
git config -e
```

Now add the following line to the above section:

```plaintext
fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

In the end, it should look like this:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
  fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

Now you can fetch all the merge requests:

```shell
git fetch origin

...
From https://gitlab.com/gitlab-org/gitlab-foss.git
 * [new ref]         refs/merge-requests/1/head -> origin/merge-requests/1
 * [new ref]         refs/merge-requests/2/head -> origin/merge-requests/2
...
```

And to check out a particular merge request:

```shell
git checkout origin/merge-requests/1
```

All the above can be done with the [`git-mr`](https://gitlab.com/glensc/git-mr) script.

## Cached merge request count

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299542) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/327319) in GitLab 14.0.

In a group, the sidebar displays the total count of open merge requests. This value is cached if it's greater than
than 1000. The cached value is rounded to thousands (or millions) and updated every 24 hours.
