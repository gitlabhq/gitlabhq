---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merge request approval rules **(PREMIUM)**

Approval rules define how many [approvals](index.md) a merge request must receive before it can
be merged, and which users should do the approving. They can be used in conjunction
with [Code owners](#code-owners-as-eligible-approvers) to ensure that changes are
reviewed both by the group maintaining the feature, and any groups responsible
for specific areas of oversight.

You can define approval rules:

- [As project defaults](#add-an-approval-rule).
- [Per merge request](#edit-or-override-merge-request-approval-rules).
- [At the instance level](../../../admin_area/merge_requests_approvals.md)

If you don't define a [default approval rule](#add-an-approval-rule),
any user can approve a merge request. Even if you don't define a rule, you can still
enforce a [minimum number of required approvers](settings.md) in the project's settings.

You can define a single rule to approve merge requests from among the available
rules, or you can select [multiple approval rules](#add-multiple-approval-rules).

Merge requests that target a different project, such as from a fork to the upstream project,
use the default approval rules from the target (upstream) project, not the source (fork).

## Add an approval rule

To add a merge request approval rule:

1. Go to your project and select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval rules**.
1. Select **Add approval rule**.
1. Add a human-readable **Rule name**.
1. Select a **Target branch**:
   - To apply the rule to all branches, select **All branches**.
   - To apply the rule to all protected branches, select **All protected branches** (GitLab 15.3 and later).
   - To apply the rule to a specific branch, select it from the list.
1. Set the number of required approvals in **Approvals required**. A value of `0` makes
   [the rule optional](#configure-optional-approval-rules), and any number greater than `0`
   creates a required rule.
1. To add users or groups as approvers, search for users or groups that are
   [eligible to approve](#eligible-approvers), and select **Add**. GitLab suggests approvers based on
   previous authors of the files changed by the merge request.

     NOTE:
     On GitLab.com, you can add a group as an approver if you're a member of that group or the
     group is public.

1. Select **Add approval rule**.

Users of GitLab Premium and Ultimate tiers can create [additional approval rules](#add-multiple-approval-rules).

Your configuration for approval rule overrides determines if the new rule is applied
to existing merge requests:

- If [approval rule overrides](settings.md#prevent-editing-approval-rules-in-merge-requests) are allowed,
  changes to these default rules are not applied to existing merge requests, except for
  changes to the [target branch](#approvals-for-protected-branches) of the rule.
- If approval rule overrides are not allowed, all changes to default rules
  are applied to existing merge requests. Any approval rules that were previously
  manually [overridden](#edit-or-override-merge-request-approval-rules) during the
  period when approval rule overrides where allowed, are not modified.

## Edit an approval rule

To edit a merge request approval rule:

1. Go to your project and select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval rules**.
1. Select **Edit** next to the rule you want to edit.
1. Optional. Change the **Rule name**.
1. Set the number of required approvals in **Approvals required**. The minimum value is `0`.
1. Add or remove eligible approvers, as needed:
   - *To add users or groups as approvers,* search for users or groups that are
     [eligible to approve](#eligible-approvers), and select **Add**.

     NOTE:
     On GitLab.com, you can add a group as an approver if you're a member of that group or the
     group is public.

   - *To remove users or groups,* identify the group or user to remove, and
     select **{remove}** **Remove**.
1. Select **Update approval rule**.

## Add multiple approval rules

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1979) in GitLab 11.10.

In GitLab Premium and Ultimate tiers, you can enforce multiple approval rules on a
merge request, and multiple default approval rules for a project. If your tier
supports multiple default rules:

- When [adding](#add-an-approval-rule) or [editing](#edit-an-approval-rule) an approval rule
  for a project, GitLab displays the **Add approval rule** button even after a rule is defined.
- When editing or overriding multiple approval rules
  [on a merge request](#edit-or-override-merge-request-approval-rules), GitLab
  displays the **Add approval rule** button even after a rule is defined.

When an [eligible approver](#eligible-approvers) approves a merge request, it
reduces the number of approvals left (the **Approvals** column) for all rules that the approver belongs to:

![Approvals premium merge request widget](img/approvals_premium_mr_widget_v13_3.png)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Multiple Approvers](https://www.youtube.com/watch?v=8JQJ5821FrA).

## Eligible approvers

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10294) in GitLab 13.3, when an eligible approver comments on a merge request, it appears in the **Commented by** column of the Approvals widget.

To be eligible as an approver for a project, a user must be a member of one or
more of these:

- The project.
- The project's immediate parent [group](#group-approvers).
- A group that has access to the project via a [share](../../members/share_project_with_groups.md).
- A [group added as approvers](#group-approvers).

The following users can approve merge requests if they have Developer or
higher [permissions](../../../permissions.md):

- Users added as approvers at the project or merge request level.
- Users who are [Code owners](#code-owners-as-eligible-approvers) of the files
  changed in the merge request.

To show who has participated in the merge request review, the Approvals widget in
a merge request displays a **Commented by** column. This column lists eligible approvers
who commented on the merge request. It helps authors and reviewers identify who to
contact with questions about the merge request's content.

If the number of required approvals is greater than the number of assigned approvers,
approvals from other users with at least the Developer [role](../../../permissions.md)
in the project counts toward meeting the required number of approvals, even if the
users were not explicitly listed in the approval rules.

### Group approvers

You can add a group of users as approvers, but those users count as approvers only if
they have **direct membership** to the group. Inherited members do not count. Group approvers are
restricted to only groups [with share access to the project](../../members/share_project_with_groups.md).

A user's membership in an approvers group affects their individual ability to
approve in these ways:

- A user already part of a group approver who is later added as an individual approver
  counts as one approver, and not two.
- Merge request authors do not count as eligible approvers on their own merge requests by default.
  To change this behavior, disable the
  [**Prevent author approval**](settings.md#prevent-approval-by-author)
  project setting.
- Committers to merge requests can approve a merge request. To change this behavior, enable the
  [**Prevent committers approval**](settings.md#prevent-approvals-by-users-who-add-commits)
  project setting.

### Code owners as eligible approvers

> Moved to GitLab Premium in 13.9.

If you add [code owners](../../codeowners/index.md) to your repository, the owners of files
become eligible approvers in the project. To enable this merge request approval rule:

1. Go to your project and select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval rules**.
1. Locate the **All eligible users** rule, and select the number of approvals required:

   ![MR approvals by Code Owners](img/mr_approvals_by_code_owners_v15_2.png)

You can also
[require code owner approval](../../protected_branches.md#require-code-owner-approval-on-a-protected-branch)
for protected branches.

## Merge request approval segregation of duties

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40491) in GitLab 13.4.
> - Moved to GitLab Premium in 13.9.

You may have to grant users with the Reporter role
permission to approve merge requests before they can merge to a protected branch.
Some users (like managers) may not need permission to push or merge code, but still need
oversight on proposed work. To enable approval permissions for these users without
granting them push access:

1. [Create a protected branch](../../protected_branches.md)
1. [Create a new group](../../../group/manage.md#create-a-group).
1. [Add the user to the group](../../../group/manage.md#add-users-to-a-group),
   and select the Reporter role for the user.
1. [Share the project with your group](../../members/share_project_with_groups.md#share-a-project-with-a-group),
   based on the Reporter role.
1. Go to your project and select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval rules**, and either:
   - For a new rule, select **Add approval rule** and target the protected branch.
   - For an existing rule, select **Edit** and target the protected branch.
1. [Add the group](../../../group/manage.md#create-a-group) to the permission list.

   ![Update approval rule](img/update_approval_rule_v13_10.png)

### Edit or override merge request approval rules

By default, the merge request author (or a user with sufficient [permissions](../../../permissions.md))
can edit the approval rule listed in a merge request. When editing an approval rule
on a merge request, you can either add or remove approvers:

1. In the merge request, find the **Approval rules section**.
1. When creating a new merge request, scroll to the **Approval Rules** section,
   and add or remove your desired approval rules before selecting **Create merge request**.
1. When viewing an existing merge request:
   1. Select **Edit**.
   1. Scroll to the **Approval Rules** section.
   1. Add or remove your desired approval rules.
   1. Select **Save changes**.

Administrators can change the [merge request approvals settings](settings.md#prevent-editing-approval-rules-in-merge-requests)
to prevent users from overriding approval rules for merge requests.

## Configure optional approval rules

Merge request approvals can be optional for projects where approvals are
appreciated, but not required. To make an approval rule optional:

- When you [create or edit a rule](#edit-an-approval-rule), set **Approvals required** to `0`.
- Use the [Merge requests approvals API](../../../../api/merge_request_approvals.md#update-merge-request-level-rule)
  to set the `approvals_required` attribute to `0`.

## Approvals for protected branches

> **All protected branches** target branch option [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360930) in GitLab 15.3.

Approval rules are often relevant only to specific branches, like your
[default branch](../../repository/branches/default.md). To configure an
approval rule for certain branches:

1. [Create an approval rule](#add-an-approval-rule).
1. Go to your project and select **Settings > Merge requests**.
1. In the **Merge request approvals** section, scroll to **Approval rules**.
1. For **Target branch**:
   - To apply the rule to all protected branches, select **All protected branches** (GitLab 15.3 and later).
   - To apply the rule to a specific branch, select it from the list.

1. To enable this configuration, read
   [Code Owner's approvals for protected branches](../../protected_branches.md#require-code-owner-approval-on-a-protected-branch).

## Code coverage check approval

You can require specific approvals in the case that a merge request would reduce code test
coverage.

For more information, see [Coverage check approval rule](../../../../ci/testing/code_coverage.md#coverage-check-approval-rule).

## Security Approvals **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357021) in GitLab 15.0.

You can use [scan result policies](../../../application_security/policies/scan-result-policies.md#scan-result-policy-editor) to define security approvals based on the status of vulnerabilities in the merge request and the default branch.
Details for each security policy is shown in the Security Approvals section of your Merge Request configuration.

The security approval rules are applied to all merge requests until the pipeline is complete. The application of the
security approval rules prevents users from merging in code before the security scans run. After the pipeline is
complete, the security approval rules are checked to determine if the security approvals are still required.

![Security Approvals](img/security_approvals_v15_0.png)

These policies are both created and edited in the [security policy editor](../../../application_security/policies/index.md#policy-editor).

## Troubleshooting

### Approval rule name can't be blank

As a workaround for this validation error, you can delete the approval rule through
the API.

1. [GET a project-level rule](../../../../api/merge_request_approvals.md#get-a-single-project-level-rule).
1. [DELETE the rule](../../../../api/merge_request_approvals.md#delete-project-level-rule).

For more information about this validation error, read
[issue 285129](https://gitlab.com/gitlab-org/gitlab/-/issues/285129).

### Groups need explicit or inherited Developer role on a project

A group created to handle approvals may be created in a different area of the
project hierarchy than the project requiring review. If this happens, the approvals group
isn't recognized as a valid Code Owner for the project, nor does it display in the
project's **Approvals** list. To fix this problem, add the approval group as a shared group
high enough in the shared hierarchy so the project requiring review inherits this
group of users.
