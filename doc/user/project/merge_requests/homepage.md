---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the merge request homepage to find your work, and work you need to review.
title: Merge request homepage
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If you are the author, assignee, or reviewer of a merge request, it appears on your merge request
homepage. This page sorts your merge requests by **Workflow** or by **Role**. The **Workflow** view
shows you which merge requests need your attention first, regardless of whether it's your work or
the work of someone else. The workflow view groups merge requests by their stage in this review process:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart LR
    accTitle: Merge request review workflow
    accDescr: Flow from merge request creation through review, approval, and merge stages with decision points for reviewers and approvals.

    A[Your<br>merge request] --> B{Reviewers<br>added?}
    B-->|Yes| D[<strong>Review<br>requested</strong>]
    B -.->|No| C[<strong>Your merge<br>requests</strong>]
    D -->|Approved| E[<strong>Approved<br>by others</strong>]
    D -..->|Changes<br>requested| F[<strong>Returned<br>to you</strong>]
    F -->|You make<br>changes| D
    E -->G{All<br>approvals?}
    G -->|Yes| K[Ready to merge]
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

This review flow assumes reviewers use the **Start a review** and **Submit a review** features.

The **Role** view sorts your merge requests by your role in the merge request.

## See your merge request homepage

{{< history >}}

- Merge request homepage [introduced](https://gitlab.com/groups/gitlab-org/-/epics/13448) in GitLab 17.9 [with a flag](../../../administration/feature_flags/_index.md) named `merge_request_dashboard`. Disabled by default.
- Feature flag `merge_request_dashboard` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/480854) on GitLab.com in GitLab 17.9.
- Feature flag `mr_dashboard_list_type_toggle` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/535244) for GitLab.com in GitLab 18.1.
- Feature flag `merge_request_dashboard` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194999) in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab shows your total **Active** merge requests on the left sidebar on all pages:

![Upper area of the GitLab left sidebar displaying user activity summary: 9 open issues, 1 active merge request, and 1 to-do item.](img/homepage_totals_v18_3.png)

This user has:

- 9 open issues ({{< icon name="issue-type-issue" >}})
- 1 active merge request ({{< icon name="merge-request-open" >}})
- 1 to-do item ({{< icon name="todo-done" >}})

Your merge request homepage shows more information about these merge requests. To see it,
use any of these methods:

- Use the <kbd>Shift</kbd>+<kbd>m</kbd> [keyboard shortcut](../../shortcuts.md).
- On the left sidebar, select **Merge requests** ({{< icon name="merge-request-open">}}).
- On the left sidebar, select **Search or go to**, then from the dropdown list, select **Merge requests**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.

To help you focus on what needs your attention right now, GitLab organizes your merge request homepage
into three tabs:

![The three homepage tabs shown at the top of the screen.](img/homepage_tabs_v18_1.png)

- **Active**: These merge requests need attention from you, or a member of your team.
- **Merged**: These merge requests merged in the last 14 days. They are your work, or contain a review from you.
- **Search**: Search all merge requests, and filter them as needed.

![The 'Returned to you' section of the Active tab, showing a table with information about three merge requests.](img/homepage_rows_v17_9.png)

- **Status**: The current status of the merge request.
- **Title**: Important metadata about the issue, including:
  - The merge request title.
  - The assignee's avatar.
  - The number of files and lines added and removed (`+` / `-`).
  - Milestone.
- **Author**: The author's avatar.
- **Reviewers**: The reviewers' avatars. Reviewers with a green check mark have approved the merge request.
- **Checks**: A compact assessment of mergeability.
  - A warning ({{< icon name="warning-solid">}}) if merge conflicts exist.
  - Number of unresolved threads, like `0 of 3`.
  - Current required [approval status](approvals/_index.md#in-the-list-of-merge-requests).
  - Most recent pipeline status.
  - Date of last update.

### Set your display preferences

{{< history >}}

- **Show your drafts** preference [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/551475) in GitLab 18.6.

{{< /history >}}

In the upper right of your merge request homepage, select **Display preferences** ({{< icon name="preferences">}}):

- Toggle **Show labels** to show or hide labels for each merge request.
- Sorting preferences: **Workflow** or **Role**.
  - **Workflow** groups merge requests by their status. GitLab shows the merge requests
    needing your attention first, regardless of whether you are the author or the reviewer.
  - **Role** groups merge requests by whether you are the reviewer or the author.
- Toggle **Show your drafts** to show or hide draft merge requests from the **Your merge requests** list.

Active merge requests count toward the total shown on the left sidebar. GitLab excludes **Inactive**
merge requests from your review count.

### Workflow view: active statuses

These merge requests need your attention. They count toward the total shown on the left sidebar:

- **Your merge requests**: You're the merge request author or assignee. Add reviewers to start the review process.
  Statuses:
  - **Draft**: The merge request is a draft.
  - **Reviewers needed**: The merge request is not a draft, but has no reviewers.
- **Review requested**: You're a reviewer. Review the merge request. Provide feedback. Optionally,
  approve or request changes. Statuses:
  - **Changes requested**: A reviewer has requested changes. The change request blocks the merge request,
    but [can be bypassed](reviews/_index.md#bypass-a-request-for-changes).
  - **Reviewer commented**: A reviewer has left comments but not requested changes.
- **Returned to you**: Reviewers have provided feedback, or requested changes. Address reviewer comments,
  and apply suggested changes. Statuses:
  - **Changes requested**: A reviewer has requested changes.
  - **Reviewer commented**: A reviewer has left comments but not requested changes.

### Workflow view: inactive statuses

GitLab excludes these merge requests from the active count, because no action is required from you right now:

- **Waiting for assignee**: If you're the author, the merge request is awaiting review. If you're
  the reviewer, you've requested changes. Statuses:
  - **You requested changes**: You've completed your review and requested changes.
  - **You commented**: You've commented, but have not completed your review.
- **Waiting for approvals**: Your assigned merge requests that are waiting for approvals, and reviews
  you have requested changes for. Statuses:
  - **Approvals required**: Number of required approvals remaining.
  - **Approved**: Either you have approved, or all required approvals are satisfied.
  - **Waiting for approvals**.
- **Approved by you**: Merge requests you've reviewed and approved.
  Statuses:
  - **Approved**: You've approved, and required approvals are satisfied.
  - **Approval required**: You've approved, but not all required approvals are satisfied.
- **Approved by others**: Merge requests that have received approvals from other team members.
  Potentially ready to merge, if all requirements are met. Statuses:
  - **Approved**: Your merge request has received the necessary approvals.

### Role view

The **Role** view groups merge requests you are an assignee or reviewer for:

- **Reviewer (Active)**: Awaiting review from you.
- **Reviewer (Inactive)**: Already reviewed by you.
- **Your merge requests (Active)**
- **Your merge requests (Inactive)**

Merge requests in the **Active** lists count toward the total shown on the left sidebar.

## Related topics

- [Merge request reviews](reviews/_index.md)
