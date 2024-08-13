---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "To ensure all changes are reviewed, configure optional or required approvals for merge requests in your project."
---

# Merge request approvals

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can configure your merge requests to allow (or require) approval before
they merge. While [GitLab Free](https://about.gitlab.com/pricing/) allows
all users with Developer or greater [permissions](../../../permissions.md) to
approve merge requests, these approvals are [optional](#optional-approvals).
[GitLab Premium](https://about.gitlab.com/pricing/) and
[GitLab Ultimate](https://about.gitlab.com/pricing/) give you more
flexibility:

- Create required [rules](rules.md) about the number and type of approvers before work can merge.
- Build a list of users who act as [code owners](../../codeowners/index.md) for specific files,
  and require their approval before work can merge.
- For GitLab Premium and GitLab Ultimate, configure approvals
  [for the entire instance](../../../../administration/merge_requests_approvals.md).

You can configure merge request approvals on a per-project basis, and configure some approvals
[at the group level](../../../group/manage.md#group-merge-request-approval-settings). Support for
group-level settings for merge request approval rules is tracked in
[epic 4367](https://gitlab.com/groups/gitlab-org/-/epics/4367).

## View approval status

You can see the approval status of a merge request both on the merge request itself,
and the list of merge requests for your project or group.

### For a single merge request

When an [eligible approver](rules.md#eligible-approvers) visits an open merge request,
GitLab shows one of these statuses after the body of the merge request. To see it:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Select the title of the merge request to view it.
1. Scroll to the [merge request widget](../widgets.md) to see the mergeability and
   approval status for the merge request. In this example, you can approve the
   merge request:

   ![You can approve this merge request. It needs approval before it becomes mergeable.](img/approval_and_merge_status_v17_3.png)

   The text shown in the widget explains its approval status:

   - **Approve**: The merge request doesn't yet have the required number of approvals.
   - **Approve additionally**: The merge request has the required number of approvals.
   - **Revoke approval**: The user viewing the merge request has already approved
     the merge request.

1. To see if your approval satisfies the Code Owner requirements, select
   **Expand eligible approvers** (**{chevron-lg-down}**).

To see the individual review and approval status for each reviewer, check the right sidebar
of a merge request. Each **Reviewer** shows the status to the right of the user's name, like this:

![This reviewer has requested changes, and blocked this merge request.](img/reviewer_blocks_mr_v17_3.png)

- **{dash-circle}** Awaiting review from this user.
- **{status_running}** The user's review is in progress.
- **{check-circle}** Approved by this user.
- **{comment-lines}** User has requested changes, and
  [blocked this merge request](../reviews/index.md#prevent-merge-when-you-request-changes).
  (If needed, you can [bypass this block](../reviews/index.md#prevent-merge-when-you-request-changes).)

To [re-request a review](../reviews/index.md#re-request-a-review), select the
**Re-request a review** icon (**{redo}**) next to the user.

### In the list of merge requests

The list of merge requests for [your project or group](../index.md#view-merge-requests)
shows the approval status for each merge request:

| Example | Description |
| :-----: | :---------- |
| ![Approvals not yet satisfied](img/approvals_unsatisfied_v17_1.png) | Required approvals are missing. (**{approval}**) |
| ![Approvals are satisfied](img/approvals_satisfied_v17_1.png) | Approvals are satisfied. (**{check}**) |
| ![Approvals are satisfied, and you approved](img/you_approvals_satisfied_v17_1.png) | Approvals are satisfied, and you are one of the approvers. (**{approval-solid}**) |

## Configuration options for approvals

Use [merge request approval rules](rules.md) to set the minimum number of
required approvals before work can merge into your project. You can also extend these
rules to define what types of users can approve work. Some examples of rules you can create include:

- Users with specific permissions can always approve work.
- [Code owners](../../codeowners/index.md) can approve work for files they own.
- Users with specific permissions can approve work,
  [even if they don't have merge rights](rules.md#enable-approval-permissions-for-users-with-the-reporter-role)
  to the repository.
- Users with specific permissions can be allowed or denied the ability
  to [override approval rules on a specific merge request](rules.md#edit-or-override-merge-request-approval-rules).

You can also configure:

- Additional [settings for merge request approvals](settings.md) for more control of the
  level of oversight and security your project needs.
- Merge request approval rules and settings through the GitLab UI or with the
  [Merge request approvals API](../../../../api/merge_request_approvals.md).

You can't change the approvals on a merge request after it merges.

### Optional approvals

GitLab allows all users with Developer or greater [permissions](../../../permissions.md)
to approve merge requests. Approvals in GitLab Free are optional, and don't prevent
a merge request from merging without approval.

### Required approvals

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Moved to GitLab Premium in 13.9.

Required approvals enforce code reviews by the number and type of users you specify.
Without the approvals, the work cannot merge. Required approvals enable multiple use cases:

- Enforce review of all code that gets merged into a repository.
- Specify reviewers for a given proposed code change, and a minimum number
  of reviewers, through [Approval rules](rules.md).
- Specify categories of reviewers, such as backend, frontend, quality assurance, or
  database, for all proposed code changes.
- Use the [code owners of changed files](rules.md#code-owners-as-eligible-approvers),
  to determine who should review the work.
- Require an [approval before merging code that causes test coverage to decline](../../../../ci/testing/code_coverage.md#coverage-check-approval-rule).
- Users on GitLab Ultimate can also [require approval from a security team](../../../application_security/index.md#security-approvals-in-merge-requests)
  before merging code that could introduce a vulnerability.

## Approve a merge request

Eligible approvers can also use the `/approve`
[quick action](../../../project/quick_actions.md) when adding a comment to
a merge request. Users in the reviewer list who have approved a merge request display
a green check mark (**{check-circle-filled}**) next to their name.

After a merge request receives the [number and type of approvals](rules.md) you configure, it can merge
unless it's blocked for another reason. Merge requests can be blocked by other problems,
such as merge conflicts, [unresolved threads](../index.md#prevent-merge-unless-all-threads-are-resolved),
or a [failed CI/CD pipeline](../merge_when_pipeline_succeeds.md).

To prevent merge request authors from approving their own merge requests,
enable [**Prevent author approval**](settings.md#prevent-approval-by-author)
in your project's settings.

If you enable [approval rule overrides](settings.md#prevent-editing-approval-rules-in-merge-requests),
merge requests created before a change to default approval rules are not affected.
The only exceptions are changes to the [target branch](rules.md#approvals-for-protected-branches)
of the rule.

## Invalid rules

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334698) in GitLab 15.1.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/389905) in GitLab 15.11 [with a flag](../../../../administration/feature_flags.md) named `invalid_scan_result_policy_prevents_merge`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/405023) in GitLab 16.2. Feature flag `invalid_scan_result_policy_prevents_merge` removed.

When an approval rule is impossible to satisfy, GitLab shows the rule as
**Auto approved**. This happens when:

- The only eligible approver is also the merge request author.
- No eligible approvers (either groups or users) are assigned to the approval rule.
- The number of required approvals is greater than the number of eligible approvers.

These rules are automatically approved to unblock their respective merge requests, unless you
created them through a [merge request approval policy](../../../application_security/policies/scan-result-policies.md).
Invalid approval rules created through a merge request approval policy are:

- Shown with **Action required**.
- Not automatically approved.
- Blockers for merge requests they affect.

## Related topics

- [Merge request approvals API](../../../../api/merge_request_approvals.md)
- [Instance-level approval rules](../../../../administration/merge_requests_approvals.md) for self-managed installations
