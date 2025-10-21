---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: How the GitLab UI helps you track merge requests from creation to merging.
title: 'Tutorial: Understand your merge requests on the Merge requests homepage'
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13448) in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `merge_request_dashboard`. Disabled by default.
- Feature flag `merge_request_dashboard` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/480854) on GitLab.com in GitLab 17.9.
- Feature flag `mr_dashboard_list_type_toggle` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/535244) on GitLab.com in GitLab 18.1.
- Feature flag `merge_request_dashboard` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194999) in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

This tutorial introduces you to the new user interface for managing merge requests.

Whether you're an author awaiting review, or a reviewer providing feedback, this page
helps you track your work. It sorts your work into clear categories to help you:

- Spend less time tracking merge requests that need your attention.
- Focus on the most urgent work first.
- See the status of your contributions.
- Prevent in-progress work from being forgotten.
- Improve your code review velocity.

## See it in action

To see your merge request homepage on GitLab.com, either:

- Use the <kbd>Shift</kbd>+<kbd>m</kbd> [keyboard shortcut](../../user/shortcuts.md).
- On the left sidebar, select **Merge requests**.

It's organized into three tabs, to help you focus on what needs your attention right now, while
still giving you access to other recent work:

![The three homepage tabs are shown at the top of the screen.](img/homepage_tabs_v18_1.png)

- **Active**: These merge requests need attention from you, or a member of your team.
- **Merged**: These merge requests merged in the last 14 days, and you were an assignee or a reviewer.
- **Search**: Search all merge requests, and filter them as needed.

GitLab shows the total number of **Active** merge requests on the left sidebar on all pages. For example, this user has:

![The upper-left area of the sidebar showing the number of active merge requests.](img/homepage_totals_v18_3.png)

- 9 open issues ({{< icon name="issue-type-issue" >}})
- 1 active merge request ({{< icon name="merge-request-open" >}})
- 1 to-do item ({{< icon name="todo-done" >}})

Each table row groups related information about a merge request together into columns:

![The 'Returned to you' section of the Active tab, showing a table with information about three merge requests.](img/homepage_rows_v17_9.png)

- **Status** - The current status of the merge request.
- **Title** - Important metadata about the issue, including:
  - The merge request title.
  - The assignee's avatar.
  - The number of files and lines added and removed (`+` / `-`).
  - Milestone.
- **Author** - The author's avatar.
- **Reviewers** - The reviewers' avatars. Reviewers with a green check mark have approved the merge request.
- **Checks** - A compact assessment of mergeability.
  - Number of open threads, for example `0 of 3`.
  - Current required [approval status](../../user/project/merge_requests/approvals/_index.md#in-the-list-of-merge-requests).
  - Most recent pipeline's status.
  - Date of last update.

## Set your display preferences

On the upper right, select **Display preferences** ({{< icon name="preferences">}}) to sort your merge requests by:

- **Workflow**. This view groups merge requests by their status. Merge requests needing your attention are shown first, regardless of whether
  you are the author or the reviewer.
- **Role**. This view groups merge requests by whether you are the reviewer or the author.

{{< tabs >}}

{{< tab title="Workflow view" >}}

In the **Workflow** view, the **Active** tab sorts merge requests in this order:

- **Returned to you**
- **Review requested**
- **Your merge requests**

Merge requests in these states are excluded from the **Active** count:

- **Waiting for assignee**
- **Waiting for approvals**
- **Approved by you**
- **Approved by others**

{{< /tab >}}

{{< tab title="Role view" >}}

In the **Role** view, the **Active** tab sorts merge requests in this order:

- **Reviewer (Active)**
- **Reviewer (Inactive)**
- **Your merge requests (Active)**
- **Your merge requests (Inactive)**

{{< /tab >}}

{{< /tabs >}}

## Understand the Role view

The **Role** view groups merge requests you are an assignee or reviewer for:

- **Reviewer (Active)**: Awaiting review from you.
- **Reviewer (Inactive)**: Already reviewed by you.
- **Your merge requests (Active)**
- **Your merge requests (Inactive)**

Merge requests in the **Active** lists count toward the total shown on the left sidebar.

## Understand the Workflow view

The **Workflow** view groups merge requests by where they are in the
[review process](../../user/project/merge_requests/reviews/_index.md). This view helps you understand
what action to take next:

```mermaid
flowchart LR
    A[Create a<br>merge request] --> B{Reviewers<br>added?}
    B-->|Yes| D[<strong>Review<br>requested</strong>]
    B -.->|No| C[<strong>Assigned<br>to you</strong>]
    D -->|Approved| E[<strong>Approved<br>by others</strong>]
    D -..->|Changes<br>requested| F[<strong>Returned<br>to you</strong>]
    F -->|Author<br>makes changes| D
    E -->G{All<br>approvals?}
    G -->|Yes| K[Ready to merge!]
    G -.->|No| J[Remains in<br><strong>Waiting for approvals</strong>]

    linkStyle default stroke:red
    linkStyle 0 stroke:green
    linkStyle 1 stroke:green
    linkStyle 3 stroke:green
    linkStyle 5 stroke:green
    linkStyle 6 stroke:green
    linkStyle 7 stroke:green
    style K stroke:black,fill:#28a745,color:#fff
```

This review flow assumes:

1. The **Assignee** is the author of the merge request.
1. **Reviewers** are the users who review the work in the merge request.
1. Reviewers use the [**Start a review**](../../user/project/merge_requests/reviews/_index.md#start-a-review) and
   [**Submit a review**](../../user/project/merge_requests/reviews/_index.md#submit-a-review) features.

Merge requests in one of the **Active** statuses count toward the total shown on the left sidebar:

- Active statuses: **Returned to you**, **Review requested**, **Your merge requests**
- Inactive statuses: **Waiting for assignee**, **Waiting for approvals**, **Approved by you**, **Approved by others**

## Workflow view: active statuses

These merge requests need attention from you, or a member of your team.

### Returned to you

Reviewers have provided feedback, or requested changes.

- Next step: Address reviewer comments, and implement suggested changes.
- Statuses:
  - **Changes requested**: A reviewer has requested changes.
  - **Reviewer commented**: A reviewer has left comments but not requested changes.

### Review requested

You're a reviewer for this merge request.

- Next step: Review the merge request. Provide approval and feedback. Request changes when needed.
- Statuses:
  - **Requested**: You've not yet started a review.
  - **Review started**: You've started a review, but not completed it yet.

### Your merge requests

You're the merge request author or assignee. You've not added reviewers yet.

- Next step: Add reviewers to start the review process.
- Statuses:
  - **Draft**: The merge request is marked as draft.
  - **Reviewers needed**: The merge request is not a draft, but has no reviewers.

## Workflow view: inactive statuses

The **Active** tab shows all your in-progress merge requests, sorted by status.
These merge requests are excluded from the active count, because no action is required from you right now:

### Waiting for assignee

Your assigned merge requests that are waiting for approvals, and reviews you have requested changes for.

- Next step: Wait for reviews and approvals.
- Statuses:
  - **You requested changes**: You've completed your review and requested changes.
  - **You commented**: You've commented, but have not completed your review.

### Waiting for approvals

Your assigned merge requests that are waiting for approvals, and reviews you have requested changes for.

- Next step: Wait until all approval requirements are met.
- Statuses:
  - **Approvals required** - Number of required approvals remaining.
  - **Approved** - Either you have approved, or all required approvals are satisfied.
  - **Waiting for approvals**.

### Approved by you

Merge requests you've reviewed and approved.

- Next step: Wait for other approvals and other merge requirements to be met.
- Statuses:
  - **Approved** - You've approved, and required approvals are satisfied.
  - **Approval required** - You've approved, but not all required approvals are satisfied.

### Approved by others

Merge requests that have received approvals from other team members.

- Next step: Potentially ready to merge, if all requirements are met.
- Statuses:
  - **Approved** - Your merge request has received the necessary approvals.
