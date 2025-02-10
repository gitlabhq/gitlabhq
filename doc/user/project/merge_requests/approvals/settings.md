---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Define approval rules and limits in GitLab with merge request approval settings. Options include preventing author approval, requiring re-authentication, and removing approvals on new commits."
title: Merge request approval settings
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can configure the settings for [merge request approvals](_index.md) to
ensure the approval rules meet your use case. You can also configure
[approval rules](rules.md), which define the number and type of users who must
approve work before it's merged. Merge request approval settings define how
to apply those rules as a merge request moves toward completion.

Use any combination of these settings to configure approval limits for merge requests:

- [**Prevent approval by author**](#prevent-approval-by-author):
  Prevents the author of a merge request from approving it.
- [**Prevent approvals by users who add commits**](#prevent-approvals-by-users-who-add-commits):
  Prevents users who add commits to a merge request from also approving it.
- [**Prevent editing approval rules in merge requests**](#prevent-editing-approval-rules-in-merge-requests):
  Prevents users from overriding project approval rules on merge requests.
- [**Require user re-authentication (password or SAML) to approve**](#require-user-re-authentication-to-approve):
  Force potential approvers to first authenticate with either a password or with SAML.
- Code Owner approval removals: Define what happens to existing approvals when
  commits are added to the merge request.
  - **Keep approvals**: Do not remove any approvals.
  - [**Remove all approvals**](#remove-all-approvals-when-commits-are-added-to-the-source-branch):
    Remove all existing approvals.
  - [**Remove approvals by Code Owners if their files changed**](#remove-approvals-by-code-owners-if-their-files-changed):
    If a Code Owner approves a merge request, and a later commit changes files
    they are a Code Owner for, their approval is removed.

## Edit merge request approval settings

To view or edit merge request approval settings for a single project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Expand **Approvals**.

### Cascade settings from the instance or top-level group

To simplify the management of approval rule settings, configure the approval rules
at the broadest possible level. Rules created:

- [For your instance](../../../../administration/merge_requests_approvals.md) apply to all groups
  and projects on an instance.
- On a [top-level group](../../../group/manage.md#group-merge-request-approval-settings) apply to all subgroups
  and projects.

If a group or project inherits settings, you can't change them in the inheriting group or project.
You must change the settings where they originated: the top-level group or instance.

## Prevent approval by author

By default, the author of a merge request cannot approve it. To change this setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval settings** and
   clear the **Prevent approval by author** checkbox.
1. Select **Save changes**.

Authors can edit the approval rule in an individual merge request and override
this setting, unless you configure one of these options:

- [Prevent overrides of default approvals](#prevent-editing-approval-rules-in-merge-requests) for your project.
- *(GitLab Self-Managed instances only)* Prevent overrides of default approvals
  [for your instance](../../../../administration/merge_requests_approvals.md). When configured
  for your instance, you can't edit this setting on projects or individual
  merge requests.

## Prevent approvals by users who add commits

> - [Feature flag `keep_merge_commits_for_approvals`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127744) added in GitLab 16.3 to also include merge commits in this check.
> - [Feature flag `keep_merge_commits_for_approvals`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131778) removed in GitLab 16.5. This check now includes merge commits.

By default, users who commit to a merge request can still approve it. You can prevent committers
in your project or on your instance from approving merge requests that are partially
their own:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval settings** and
   select **Prevent approvals by users who add commits**.
   If this checkbox is cleared, an administrator has disabled it
   [for your instance](../../../../administration/merge_requests_approvals.md), and
   you can't change it for your project.
1. Select **Save changes**.

[Code owners](../../codeowners/_index.md) who commit to a merge request cannot approve it,
if the merge request affects files they own.

For more information, see the [official Git documentation](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History).

## Prevent editing approval rules in merge requests

By default, users can override the approval rules you [create for a project](rules.md)
on a per-merge-request basis. If you don't want users to change approval rules
on merge requests, you can disable this setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval settings** and
   select **Prevent editing approval rules in merge requests**.
1. Select **Save changes**.

This change affects all open merge requests.

When you change this field, it can affect all open merge requests depending on the setting:

- If users could edit approval rules previously, and you disable this behavior,
  GitLab updates all open merge requests to enforce the approval rules.
- If users could **not** edit approval rules previously, and you enable approval rule
  editing, open merge requests remain unchanged. This preserves any changes already
  made to approval rules in those merge requests.

## Require user re-authentication to approve

> - Requiring re-authentication by using SAML authentication for GitLab.com groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5981) in GitLab 16.6 [with a flag](../../../../administration/feature_flags.md) named `ff_require_saml_auth_to_approve`. Disabled by default.
> - Requiring re-authentication by using SAML authentication for GitLab Self-Managed instances [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/431415) in GitLab 16.7 [with a flag](../../../../administration/feature_flags.md) named `ff_require_saml_auth_to_approve`. Disabled by default.
> - [Enabled `ff_require_saml_auth_to_approve` by default](https://gitlab.com/gitlab-org/gitlab/-/issues/431714) in GitLab 16.8 for GitLab.com and GitLab Self-Managed instances.

FLAG:
On GitLab Self-Managed, by default requiring re-authentication by using SAML authentication is available. To hide the feature, an administrator can
[disable the feature flag](../../../../administration/feature_flags.md) named `ff_require_saml_auth_to_approve`. On GitLab.com and GitLab Dedicated, this feature is available.

You can force potential approvers to first authenticate with SAML or a password.
This permission enables an electronic signature for approvals, such as the one defined by
[Code of Federal Regulations (CFR) Part 11](https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfcfr/CFRSearch.cfm?CFRPart=11&showFR=1&subpartNode=21:1.0.1.1.8.3).

Prerequisites:

- This setting is only available on top-level groups.

1. On the left sidebar, select **Search or go to** and find your project.
1. Enable password authentication and SAML authentication. For more information on:
   - Password authentication, see
     [sign-in restrictions documentation](../../../../administration/settings/sign_in_restrictions.md#password-authentication-enabled).
   - SAML authentication for GitLab.com groups, see
     [SAML SSO for GitLab.com groups documentation](../../../group/saml_sso/_index.md).
   - SAML authentication for GitLab Self-Managed instances, see
     [SAML SSO for GitLab Self-Managed](../../../../integration/saml.md).
1. On the left sidebar, select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval settings** and
   select **Require user re-authentication (password or SAML) to approve**.
1. Select **Save changes**.

## Remove all approvals when commits are added to the source branch

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

By default, an approval on a merge request is removed when you add more changes
after the approval. In GitLab Premium and Ultimate tiers, to keep existing approvals
after more changes are added to the merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval settings** and
   clear the **Remove all approvals** checkbox.
1. Select **Save changes**.

GitLab uses [`git patch-id`](https://git-scm.com/docs/git-patch-id) to identify diffs
in merge requests. This value is a reasonably stable and unique identifier, and it enables
smarter decisions about resetting approvals inside a merge request. When you push new changes
to a merge request, the `patch-id` is evaluated against the previous `patch-id` to determine
if the approvals should be reset. This enables GitLab to make better reset decisions when
you perform commands like `git rebase` or `git merge <target>` on a feature branch.

## Remove approvals by Code Owners if their files changed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90578) in GitLab 15.3.

To remove approvals only from Code Owners whose files change in a new commit:

Prerequisites:

- You must have at least the Maintainer role for a project.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval settings** and
   select **Remove approvals by Code Owners if their files changed**.
1. Select **Save changes**.

## Related topics

- [Merge request approval settings for your instance](../../../../administration/merge_requests_approvals.md)
- [Compliance center](../../../compliance/compliance_center/_index.md)
- [Merge request approvals API](../../../../api/merge_request_approvals.md)
- [Merge request approval settings API](../../../../api/merge_request_approval_settings.md)
