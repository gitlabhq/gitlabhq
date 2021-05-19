---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, concepts
disqus_identifier: 'https://docs.gitlab.com/ee/user/project/merge_requests/merge_request_approvals.html'
---

# Merge request approvals **(FREE)**

> Redesign [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1979) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.8 and [feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/10685) in 12.0.

You can configure your merge requests so that they must be approved before
they can be merged. You can do this by creating [rules](rules.md) or by specifying
a list of users who act as [code owners](../../code_owners.md) for specific files.

You can configure merge request approvals for each project. In higher GitLab tiers,
Administrators of self-managed GitLab instances can configure approvals
[for the entire instance](../../../admin_area/merge_requests_approvals.md).

## How approvals work

With [merge request approval rules](rules.md), you can set the minimum number of
required approvals before work can merge into your project. You can also extend these
rules to define what types of users can approve work. Some examples of rules you can create include:

- Users with specific permissions can always approve work.
- [Code owners](../../code_owners.md) can approve work for files they own.
- Users with specific permissions can approve work,
  [even if they don't have merge rights](rules.md#merge-request-approval-segregation-of-duties)
  to the repository.
- Users with specific permissions can be allowed or denied the ability
  to [override approval rules on a specific merge request](rules.md#edit-or-override-merge-request-approval-rules).

You can also configure additional [settings for merge request approvals](settings.md)
for more control of the level of oversight and security your project needs, including:

- [Prevent users from overriding a merge request approval rule.](settings.md#prevent-overrides-of-default-approvals)
- [Reset approvals when new code is pushed.](settings.md#reset-approvals-on-push)
- Allow (or disallow) [authors and committers](settings.md) to approve their own merge requests.
- [Require password authentication when approving.](settings.md#require-authentication-for-approvals)
- [Require security team approval.](settings.md#security-approvals-in-merge-requests)

You can configure your merge request approval rules and settings through the GitLab
user interface or [with the API](../../../../api/merge_request_approvals.md).

## Approve a merge request

When an [eligible approver](rules.md#eligible-approvers) visits an open merge request,
GitLab displays one of these buttons after the body of the merge request:

- **Approve**: The merge request doesn't yet have the required number of approvals.
- **Approve additionally**: The merge request has the required number of approvals.
- **Revoke approval**: The user viewing the merge request has already approved
  the merge request.

Eligible approvers can also use the `/approve`
[quick action](../../../project/quick_actions.md) when adding a comment to
a merge request.

After a merge request receives the [number and type of approvals](rules.md) you configure, it can merge
unless it's blocked for another reason. Merge requests can be blocked by other problems,
such as merge conflicts, [pending discussions](../../../discussions/index.md#only-allow-merge-requests-to-be-merged-if-all-threads-are-resolved),
or a [failed CI/CD pipeline](../merge_when_pipeline_succeeds.md).

To prevent merge request authors from approving their own merge requests,
enable [**Prevent author approval**](settings.md#prevent-authors-from-approving-their-own-work)
in your project's settings.

If you enable [approval rule overrides](settings.md#prevent-overrides-of-default-approvals),
merge requests created before a change to default approval rules are not affected.
The only exceptions are changes to the [target branch](rules.md#approvals-for-protected-branches)
of the rule.

## Optional approvals

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27426) in GitLab 13.2.

GitLab allows all users with Developer or greater [permissions](../../../permissions.md)
to approve merge requests. Approvals in GitLab Free are optional, and don't prevent
a merge request from merging without approval.

## Required approvals **(PREMIUM)**

> Moved to [GitLab Premium](https://about.gitlab.com/pricing/) in 13.9.

Required approvals enforce code reviews by the number and type of users you specify.
Without the approvals, the work cannot merge. Required approvals enable multiple use cases:

- Enforce review of all code that gets merged into a repository.
- Specify reviewers for a given proposed code change, and a minimum number
  of reviewers, through [Approval rules](rules.md).
- Specify categories of reviewers, such as backend, frontend, quality assurance, or
  database, for all proposed code changes.
- Use the [code owners of changed files](rules.md#code-owners-as-eligible-approvers),
  to determine who should review the work.
- [Require approval from a security team](../../../application_security/index.md#security-approvals-in-merge-requests)
  before merging code that could introduce a vulnerability. **(ULTIMATE)**

## Notify external services **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3869) in GitLab Ultimate 13.10.
> - [Deployed behind a feature flag](../../../feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](../../../../api/merge_request_approvals.md#enable-or-disable-external-project-level-mr-approvals). **(ULTIMATE SELF)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

You can create an external approval rule to integrate approvals with third-party tools.
When users create, change, or close merge requests, GitLab sends a notification.
The users of the third-party tools can then approve merge requests from outside of GitLab.

With this integration, you can integrate with third-party workflow tools, like
[ServiceNow](https://www.servicenow.co.uk/), or the custom tool of your choice.
You can modify your external approval rules
[by using the REST API](../../../../api/merge_request_approvals.md#external-project-level-mr-approvals).

The lack of an external approval doesn't block the merging of a merge request.

When [approval rule overrides](settings.md#prevent-overrides-of-default-approvals) are allowed,
changes to default approval rules will **not** be applied to existing
merge requests, except for changes to the [target branch](rules.md#approvals-for-protected-branches)
of the rule.

To learn more about use cases, feature discovery, and development timelines,
see the [External API approval rules epic](https://gitlab.com/groups/gitlab-org/-/epics/3869).

## Related links

- [Merge request approvals API](../../../../api/merge_request_approvals.md)
- [Instance-level approval rules](../../../admin_area/merge_requests_approvals.md) for self-managed installations

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
