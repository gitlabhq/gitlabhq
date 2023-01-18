---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Getting started with merge requests."
---

# Getting started with merge requests **(FREE)**

A merge request (**MR**) is the basis of GitLab as a tool for code
collaboration and version control.

When working in a Git-based platform, you can use branching
strategies to collaborate on code.

A repository is composed by its _default branch_, which contains
the major version of the codebase, from which you create minor
branches, also called _feature branches_, to propose changes to
the codebase without introducing them directly into the major
version of the codebase.

Branching is especially important when collaborating with others,
avoiding changes to be pushed directly to the default branch
without prior reviews, tests, and approvals.

When you create a new feature branch, change the files, and push
it to GitLab, you have the option to create a **merge request**,
which is essentially a _request_ to merge one branch into another.

The branch you added your changes into is called _source branch_
while the branch you request to merge your changes into is
called _target branch_.

The target branch can be the default or any other branch, depending
on the branching strategies you choose.

In a merge request, beyond visualizing the differences between the
original content and your proposed changes, you can execute a
[significant number of tasks](#what-you-can-do-with-merge-requests)
before concluding your work and merging the merge request.

You can watch our [GitLab Flow video](https://www.youtube.com/watch?v=InKNIvky2KE) for
a quick overview of working with merge requests.

## What you can do with merge requests

When you start a new merge request, you can immediately include the following
options. You can also add them later by either selecting **Edit** on the merge
request's page at the top-right side, or by using
[keyboard shortcuts for merge requests](../../shortcuts.md#merge-requests):

- [Assign](index.md#assign-a-user-to-a-merge-request) the merge request to a colleague for review. With [multiple assignees](index.md#assign-multiple-users), you can assign it to more than one person at a time.
- Set a [milestone](../milestones/index.md) to track time-sensitive changes.
- Add [labels](../labels.md) to help contextualize and filter your merge requests over time.
- [Require approval](approvals/index.md#required-approvals) from your team.
- [Close issues automatically](#merge-requests-to-close-issues) when they are merged.
- Enable the [delete source branch when merge request is accepted](#deleting-the-source-branch) option to keep your repository clean.
- Enable the [squash commits when merge request is accepted](squash_and_merge.md) option to combine all the commits into one before merging, thus keep a clean commit history in your repository.
- Set the merge request as a [**Draft**](drafts.md) to avoid accidental merges before it is ready.

After you have created the merge request, you can also:

- [Discuss](../../discussions/index.md) your implementation with your team in the merge request thread.
- [Perform inline code reviews](reviews/index.md).
- Add [merge request dependencies](dependencies.md) to restrict it to be merged only when other merge requests have been merged.
- Preview continuous integration [pipelines on the merge request widget](widgets.md).
- Preview how your changes look directly on your deployed application with [Review Apps](widgets.md#live-preview-with-review-apps).
- [Allow collaboration on merge requests across forks](allow_collaboration.md).
- Perform a [Review](reviews/index.md) to create multiple comments on a diff and publish them when you're ready.
- Add [code suggestions](reviews/suggestions.md) to change the content of merge requests directly into merge request threads, and easily apply them to the codebase directly from the UI.
- Add a time estimation and the time spent with that merge request with [Time Tracking](../time_tracking.md#time-tracking).

Many of these options can be set:

- From the merge request page, with [keyboard shortcuts](../../shortcuts.md#merge-requests).
- When pushing changes from the command line, with [Git push options](../push_options.md).

See also other [features associated to merge requests](reviews/index.md#associated-features).

### Reviewer

WARNING:
Requesting a code review is an important part of contributing code. However, deciding who should review
your code and asking for a review are no easy tasks. Using the "assignee" field for both authors and
reviewers makes it hard for others to determine who's doing what on a merge request.

The merge request Reviewers feature enables you to request a review of your work, and
see the status of the review. Reviewers help distinguish the roles of the users
involved in the merge request. In comparison to an **Assignee**, who is directly
responsible for creating or merging a merge request, a **Reviewer** is a team member
who may only be involved in one aspect of the merge request, such as a peer review.

To request a review of a merge request, expand the **Reviewers** select box in
the right-hand sidebar. Search for the users you want to request a review from.
When selected, GitLab creates a [to-do list item](../../todos.md) for each reviewer.

To learn more, read [Review a merge request](reviews/index.md).

### Merge requests to close issues

To create a merge request to close an issue when it's merged, you can either:

- [Add a note in the MR description](../issues/managing_issues.md#closing-issues-automatically).
- In the issue, select **Create a merge request**. Then, you can either:

  - Create a new branch and [a draft merge request](../merge_requests/drafts.md)
    in one action. The branch is named `issuenumber-title` by default, but you can
    choose any name, and GitLab verifies that it's not already in use. The merge request
    inherits the milestone and labels of the issue, and is set to automatically
    close the issue when it is merged.
  - Create a [new branch](creating_merge_requests.md#from-an-issue)
    only, with its name starting with the issue number.

If the issue is [confidential](../issues/confidential_issues.md),
you may want to use a different workflow for
[merge requests for confidential issues](confidential.md)
to prevent confidential information from being exposed.

### Deleting the source branch

When creating a merge request, select the
**Delete source branch when merge request accepted** option, and the source
branch is deleted when the merge request is merged. To make this option
enabled by default for all new merge requests, enable it in the
[project's settings](../settings/index.md#configure-merge-request-settings-for-a-project).

This option is also visible in an existing merge request next to
the merge request button and can be selected or cleared before merging.
It is only visible to users with the Maintainer role
in the source project.

If the user viewing the merge request does not have the correct
permissions to delete the source branch and the source branch
is set for deletion, the merge request widget displays the
**Deletes source branch** text.

![Delete source branch status](img/remove_source_branch_status.png)

## Recommendations and best practices for merge requests

- When working locally in your branch, add multiple commits and only push when
  you're done, so GitLab runs only one pipeline for all the commits pushed
  at once. By doing so, you save CI/CD minutes.
- Delete feature branches on merge or after merging them to keep your repository clean.
- Take one thing at a time and ship the smallest changes possible. By doing so,
  reviews are faster and your changes are less prone to errors.
- Do not use capital letters nor special chars in branch names.
