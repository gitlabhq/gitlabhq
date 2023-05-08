---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference, concepts
---

# Merge request approvals **(FREE)**

You can configure your merge requests so that they must be approved before
they can be merged. While [GitLab Free](https://about.gitlab.com/pricing/) allows
all users with Developer or greater [permissions](../../../permissions.md) to
approve merge requests, these approvals are [optional](#optional-approvals).
[GitLab Premium](https://about.gitlab.com/pricing/) and
[GitLab Ultimate](https://about.gitlab.com/pricing/) provide additional
flexibility:

- Create required [rules](rules.md) about the number and type of approvers before work can merge.
- Specify a list of users who act as [code owners](../../codeowners/index.md) for specific files,
  and require their approval before work can merge.

You can configure merge request approvals on a per-project basis, and some approvals can be configured
[on the group level](../../../group/manage.md#group-merge-request-approval-settings). Support for
group-level settings for merge request approval rules is tracked in this
[epic](https://gitlab.com/groups/gitlab-org/-/epics/4367). Administrators of
[GitLab Premium](https://about.gitlab.com/pricing/) and
[GitLab Ultimate](https://about.gitlab.com/pricing/) self-managed GitLab instances
can also configure approvals
[for the entire instance](../../../admin_area/merge_requests_approvals.md).

## How approvals work

With [merge request approval rules](rules.md), you can set the minimum number of
required approvals before work can merge into your project. You can also extend these
rules to define what types of users can approve work. Some examples of rules you can create include:

- Users with specific permissions can always approve work.
- [Code owners](../../codeowners/index.md) can approve work for files they own.
- Users with specific permissions can approve work,
  [even if they don't have merge rights](rules.md#merge-request-approval-segregation-of-duties)
  to the repository.
- Users with specific permissions can be allowed or denied the ability
  to [override approval rules on a specific merge request](rules.md#edit-or-override-merge-request-approval-rules).

You can also configure:

- Additional [settings for merge request approvals](settings.md) for more control of the
  level of oversight and security your project needs.
- Merge request approval rules and settings through the GitLab UI or with the
  [Merge request approvals API](../../../../api/merge_request_approvals.md).

## Approve a merge request

When an [eligible approver](rules.md#eligible-approvers) visits an open merge request,
GitLab displays one of these buttons after the body of the merge request:

- **Approve**: The merge request doesn't yet have the required number of approvals.
- **Approve additionally**: The merge request has the required number of approvals.
- **Revoke approval**: The user viewing the merge request has already approved
  the merge request.

Eligible approvers can also use the `/approve`
[quick action](../../../project/quick_actions.md) when adding a comment to
a merge request.  [In GitLab 13.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/292936),
if a user approves a merge request and is shown in the reviewer list, a green check mark
(**{check-circle-filled}**) displays next to their name.

After a merge request receives the [number and type of approvals](rules.md) you configure, it can merge
unless it's blocked for another reason. Merge requests can be blocked by other problems,
such as merge conflicts, [unresolved threads](../../../discussions/index.md#prevent-merge-unless-all-threads-are-resolved),
or a [failed CI/CD pipeline](../merge_when_pipeline_succeeds.md).

To prevent merge request authors from approving their own merge requests,
enable [**Prevent author approval**](settings.md#prevent-approval-by-author)
in your project's settings.

If you enable [approval rule overrides](settings.md#prevent-editing-approval-rules-in-merge-requests),
merge requests created before a change to default approval rules are not affected.
The only exceptions are changes to the [target branch](rules.md#approvals-for-protected-branches)
of the rule.

## Optional approvals

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27426) in GitLab 13.2.

GitLab allows all users with Developer or greater [permissions](../../../permissions.md)
to approve merge requests. Approvals in GitLab Free are optional, and don't prevent
a merge request from merging without approval.

## Required approvals **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

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

## Invalid rules

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334698) in GitLab 15.1.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/389905) in GitLab 15.11 [with a flag](../../../../administration/feature_flags.md) named `invalid_scan_result_policy_prevents_merge`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/405023) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flag](../../../../administration/feature_flags.md) named `invalid_scan_result_policy_prevents_merge`.
On GitLab.com, this feature is enabled by default.

Whenever an approval rule cannot be satisfied, the rule is displayed as **(!) Auto approved**. This applies to the following conditions:

- The only eligible approver is the author of the merge request.
- No eligible approvers (either groups or users) have been assigned to the approval rule.
- The number of required approvals is more than the number of eligible approvers.

These rules are automatically approved to unblock their respective merge requests,
unless they were created through a security policy.

Invalid approval rules created through a security policy are presented with **(!) Action Required**
and are not automatically approved, blocking their respective merge requests.

## Related topics

- [Merge request approvals API](../../../../api/merge_request_approvals.md)
- [Instance-level approval rules](../../../admin_area/merge_requests_approvals.md) for self-managed installations

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example, `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
