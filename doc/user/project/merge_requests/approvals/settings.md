---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, concepts
---

# Merge request approval settings

The settings for Merge Request Approvals are found by going to
**Settings > General** and expanding **Merge request (MR) approvals**.

## Prevent overriding default approvals

Regardless of the approval rules you choose for your project, users can edit them in every merge
request, overriding the [rules you set as default](rules.md#adding--editing-a-default-approval-rule).
To prevent that from happening:

1. Select the **Prevent users from modifying MR approval rules in merge requests.** checkbox.
1. Click **Save changes**.

### Resetting approvals on push

You can force all approvals on a merge request to be removed when new commits are
pushed to the source branch of the merge request. If disabled, approvals persist
even if there are changes added to the merge request. To enable this feature:

1. Check the **Require new approvals when new commits are added to an MR.**
   checkbox.
1. Click **Save changes**.

NOTE:
Approvals do not get reset when [rebasing a merge request](../fast_forward_merge.md)
from the UI. However, approvals are reset if the target branch is changed.

### Allowing merge request authors to approve their own merge requests **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3349) in GitLab 11.3.
> - Moved to GitLab Premium in 13.9.

By default, projects are configured to prevent merge requests from being approved by
their own authors. To change this setting:

1. Go to your project's **Settings > General**, expand **Merge request (MR) approvals**.
1. Uncheck the **Prevent MR approval by the author.** checkbox.
1. Click **Save changes**.

Note that users can edit the approval rules in every merge request and override pre-defined settings unless it's set [**not to allow** overrides](#prevent-overriding-default-approvals).

You can prevent authors from approving their own merge requests
[at the instance level](../../../admin_area/merge_requests_approvals.md). When enabled,
this setting is disabled on the project level, and not editable.

### Prevent approval of merge requests by their committers **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10441) in GitLab 11.10.
> - Moved to GitLab Premium in 13.9.

You can prevent users who have committed to a merge request from approving it,
though code authors can still approve. You can enable this feature
[at the instance level](../../../admin_area/merge_requests_approvals.md), which
disables changes to this feature at the project level. If you prefer to manage
this feature at the project level, you can:

1. Check the **Prevent MR approvals from users who make commits to the MR.** checkbox.
   If this check box is disabled, this feature has been disabled
   [at the instance level](../../../admin_area/merge_requests_approvals.md).
1. Click **Save changes**.

Read the official Git documentation for an explanation of the
[differences between authors and committers](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History).

### Require authentication when approving a merge request

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5981) in GitLab 12.0.
> - Moved to GitLab Premium in 13.9.

NOTE:
To require authentication when approving a merge request, you must enable
**Password authentication enabled for web interface** under [sign-in restrictions](../../../admin_area/settings/sign_in_restrictions.md#password-authentication-enabled).
in the Admin Area.

You can force the approver to enter a password in order to authenticate before adding
the approval. This enables an Electronic Signature for approvals such as the one defined
by [CFR Part 11](https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfcfr/CFRSearch.cfm?CFRPart=11&showFR=1&subpartNode=21:1.0.1.1.8.3)).
To enable this feature:

1. Check the **Require user password for approvals.** checkbox.
1. Click **Save changes**.

## Security approvals in merge requests **(ULTIMATE)**

Merge Request Approvals can be configured to require approval from a member
of your security team when a vulnerability would be introduced by a merge request.

For more information, see
[Security approvals in merge requests](../../../application_security/index.md#security-approvals-in-merge-requests).
