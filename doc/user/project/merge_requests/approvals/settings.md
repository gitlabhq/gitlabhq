---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge request approval settings **(PREMIUM)**

You can configure the settings for [merge request approvals](index.md) to
ensure the approval rules meet your use case. You can also configure
[approval rules](rules.md), which define the number and type of users who must
approve work before it's merged. Merge request approval settings define how
those rules are applied as a merge request moves toward completion.

## Edit merge request approval settings

To view or edit merge request approval settings:

1. Go to your project and select **Settings > General**.
1. Expand **Merge request (MR) approvals**.

In this section of general settings, you can configure the following settings:

| Setting | Description |
| ------ | ------ |
| [Prevent approval by author](#prevent-approval-by-author)  | When enabled, the author of a merge request cannot approve it. |
| [Prevent approvals by users who add commits](#prevent-approvals-by-users-who-add-commits) | When enabled, users who have committed to a merge request cannot approve it. |
| [Prevent editing approval rules in merge requests](#prevent-editing-approval-rules-in-merge-requests) | When enabled, users can't override the project's approval rules on merge requests.  |
| [Require user password to approve](#require-user-password-to-approve) | Force potential approvers to first authenticate with a password. |
| [Remove all approvals when commits are added to the source branch](#remove-all-approvals-when-commits-are-added-to-the-source-branch) | When enabled, remove all existing approvals on a merge request when more changes are added to it. |

## Prevent approval by author

> Moved to GitLab Premium in 13.9.

By default, the author of a merge request cannot approve it. To change this setting:

1. Go to your project and select **Settings > General**.
1. Expand **Merge request (MR) approvals**.
1. Clear the **Prevent approval by author** checkbox.
1. Select **Save changes**.

Authors can edit the approval rule in an individual merge request and override
this setting, unless you configure one of these options:

- [Prevent overrides of default approvals](#prevent-editing-approval-rules-in-merge-requests) at
  the project level.
- *(Self-managed instances only)* Prevent overrides of default approvals
  [at the instance level](../../../admin_area/merge_requests_approvals.md). When configured
  at the instance level, you can't edit this setting at the project or individual
  merge request levels.

## Prevent approvals by users who add commits

> Moved to GitLab Premium in 13.9.

By default, users who commit to a merge request can still approve it. At both
the project level or [instance level](../../../admin_area/merge_requests_approvals.md),
you can prevent committers from approving merge requests that are partially
their own. To do this:

1. Go to your project and select **Settings > General**.
1. Expand **Merge request (MR) approvals**.
1. Select the **Prevent approvals by users who add commits** checkbox.
   If this checkbox is cleared, an administrator has disabled it
   [at the instance level](../../../admin_area/merge_requests_approvals.md), and
   it can't be changed at the project level.
1. Select **Save changes**.

Depending on your version of GitLab, [code owners](../../code_owners.md) who commit
to a merge request may or may not be able to approve the work:

- In GitLab 13.10 and earlier, [code owners](../../code_owners.md) who commit
  to a merge request can approve it, even if the merge request affects files they own.
- In [GitLab 13.11 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/331548),
  [code owners](../../code_owners.md) who commit
  to a merge request cannot approve it, when the merge request affects files they own.

To learn more about the [differences between authors and committers](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History),
read the official Git documentation for an explanation.

## Prevent editing approval rules in merge requests

By default, users can override the approval rules you [create for a project](rules.md)
on a per-merge-request basis. If you don't want users to change approval rules
on merge requests, you can disable this setting:

1. Go to your project and select **Settings > General**.
1. Expand **Merge request (MR) approvals**.
1. Select the **Prevent editing approval rules in merge requests** checkbox.
1. Select **Save changes**.

This change affects all open merge requests.

## Require user password to approve

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5981) in GitLab 12.0.
> - Moved to GitLab Premium in 13.9.

You can force potential approvers to first authenticate with a password. This
permission enables an electronic signature for approvals, such as the one defined by
[Code of Federal Regulations (CFR) Part 11](https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfcfr/CFRSearch.cfm?CFRPart=11&showFR=1&subpartNode=21:1.0.1.1.8.3)):

1. Enable password authentication for the web interface, as described in the
   [sign-in restrictions documentation](../../../admin_area/settings/sign_in_restrictions.md#password-authentication-enabled).
1. Go to your project and select **Settings > General**.
1. Expand **Merge request (MR) approvals**.
1. Select the **Require user password to approve** checkbox.
1. Select **Save changes**.

## Remove all approvals when commits are added to the source branch

By default, an approval on a merge request remains in place, even if you add more changes
after the approval. If you want to remove all existing approvals on a merge request
when more changes are added to it:

1. Go to your project and select **Settings > General**.
1. Expand **Merge request (MR) approvals**.
1. Select the **Remove all approvals when commits are added to the source branch** checkbox.
1. Select **Save changes**.

Approvals aren't reset when a merge request is [rebased from the UI](../methods/index.md#rebasing-in-semi-linear-merge-methods).
However, approvals are reset if the target branch is changed.

## Code coverage check approvals

You can require specific approvals if a merge request would result in a decline in code test
coverage.

To learn more, see [Coverage check approval rule](../../../../ci/pipelines/settings.md#coverage-check-approval-rule).

## Settings cascading

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285410) in GitLab 14.4. [Deployed behind the `group_merge_request_approval_settings_feature_flag` flag](../../../../administration/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/285410) in GitLab 14.5.
> - [Feature flag `group_merge_request_approval_settings_feature_flag`](https://gitlab.com/gitlab-org/gitlab/-/issues/343872) removed in GitLab 14.9.

You can also enforce merge request approval settings:

- At the [instance level](../../../admin_area/merge_requests_approvals.md), which apply to all groups
  on an instance and, therefore, all projects.
- On a [top-level group](../../../group/manage.md#group-merge-request-approval-settings), which apply to all subgroups
  and projects.

If the settings are inherited by a group or project, they cannot be changed in the group or project
that inherited them.

## Related topics

- [Instance-level merge request approval settings](../../../admin_area/merge_requests_approvals.md)
- [Compliance report](../../../compliance/compliance_report/index.md)
- [Merge request approvals API](../../../../api/merge_request_approvals.md)
