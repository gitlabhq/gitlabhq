---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, concepts
---

# Merge Request Approvals **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/580) in GitLab Enterprise Edition 7.2. Available in GitLab Free and higher tiers.
> - Redesign [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1979) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.8 and [feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/10685) in 12.0.

Code review is an essential practice of every successful project. Approving a
merge request is an important part of the review
process, as it clearly communicates the ability to merge the change.
A [merge request approvals API](../../../api/merge_request_approvals.md) is also available.

## Optional Approvals

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27426) in GitLab 13.2.

Any user with Developer or greater [permissions](../../permissions.md) can approve a merge request in GitLab Free and higher tiers.
This provides a consistent mechanism for reviewers to approve merge requests, and ensures
maintainers know a change is ready to merge. Approvals in Free are optional, and do
not prevent a merge request from being merged when there is no approval.

## External approvals **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3869) in GitLab Ultimate 13.10.
> - It's [deployed behind a feature flag](../../feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](../../../api/merge_request_approvals.md#enable-or-disable-external-project-level-mr-approvals). **(ULTIMATE SELF)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

When you create an external approval rule, the following merge request actions sends information
about a merge request to a third party service:

- Create
- Change
- Close

This action enables use-cases such as:

- Integration with 3rd party workflow tools, such as [ServiceNow](https://www.servicenow.co.uk/).
- Integration with custom tools designed to approve merge requests from outside of GitLab.

You can find more information about use-cases, development timelines and the feature discovery in
the [External API approval rules epic](https://gitlab.com/groups/gitlab-org/-/epics/3869).

The intention for this feature is to allow those 3rd party tools to approve a merge request similarly to how users current do.

NOTE:
The lack of an external approval does not block the merging of a merge request.

You can modify external approval rules through the [REST API](../../../api/merge_request_approvals.md#external-project-level-mr-approvals).

## Required Approvals **(PREMIUM)**

> - [Introduced](https://about.gitlab.com/releases/2015/06/22/gitlab-7-12-released/#merge-request-approvers-ee-only) in GitLab Enterprise Edition 7.12.
> - Moved to GitLab Premium in 13.9.

Required approvals enable enforced code review by requiring specified people
to approve a merge request before it can be merged.

Required approvals enable multiple use cases:

- Enforcing review of all code that gets merged into a repository.
- Specifying reviewers for a given proposed code change, as well as a minimum number
  of reviewers, through [Approval rules](#approval-rules).
- Specifying categories of reviewers, such as backend, frontend, quality assurance,
  database, and so on, for all proposed code changes.
- Designating [Code Owners as eligible approvers](#code-owners-as-eligible-approvers),
  determined by the files changed in a merge request.
- [Requiring approval from a security team](#security-approvals-in-merge-requests)
  before merging code that could introduce a vulnerability.**(ULTIMATE)**

### Approval Rules

Approval rules define how many approvals a merge request must receive before it can
be merged, and optionally which users should do the approving. Approvals can be defined:

- [As project defaults](#adding--editing-a-default-approval-rule).
- [Per merge request](#editing--overriding-approval-rules-per-merge-request).

If no approval rules are defined, any user can approve a merge request. However, the default
minimum number of required approvers can still be set in the
[settings for merge request approvals](#approval-settings).

You can opt to define one single rule to approve a merge request among the available rules
or choose more than one with [multiple approval rules](#multiple-approval-rules).

NOTE:
On GitLab.com, you can add a group as an approver if you're a member of that group or the
group is public.

#### Eligible Approvers

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10294) in GitLab 13.3, when an eligible approver comments on a merge request, it appears in the **Commented by** column of the Approvals widget.

The following users can approve merge requests:

- Users who have been added as approvers at the project or merge request levels with
  developer or higher [permissions](../../permissions.md).
- [Code owners](#code-owners-as-eligible-approvers) of the files changed by the merge request
  that have developer or higher [permissions](../../permissions.md).

An individual user can be added as an approver for a project if they are a member of:

- The project.
- The project's immediate parent group.
- A group that has access to the project via a [share](../members/share_project_with_groups.md).

A group of users can also be added as approvers, though they only count as approvers if
they have direct membership to the group. In the future, group approvers may be
[restricted to only groups with share access to the project](https://gitlab.com/gitlab-org/gitlab/-/issues/2048).

If a user is added as an individual approver and is also part of a group approver,
then that user is just counted once. The merge request author, and users who have committed
to the merge request, do not count as eligible approvers,
if [**Prevent author approval**](#allowing-merge-request-authors-to-approve-their-own-merge-requests) (enabled by default)
and [**Prevent committers approval**](#prevent-approval-of-merge-requests-by-their-committers) (disabled by default)
are enabled on the project settings.

When an eligible approver comments on a merge request, it displays in the
**Commented by** column of the Approvals widget. It indicates who participated in
the merge request review. Authors and reviewers can also identify who they should reach out
to if they have any questions about the content of the merge request.

##### Implicit Approvers

If the number of required approvals is greater than the number of assigned approvers,
approvals from other users counts towards meeting the requirement. These would be
users with developer [permissions](../../permissions.md) or higher in the project who
were not explicitly listed in the approval rules.

##### Code Owners as eligible approvers

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/7933) in GitLab 11.5.
> - Moved to GitLab Premium in 13.9.

If you add [Code Owners](../code_owners.md) to your repository, the owners to the
corresponding files become eligible approvers, together with members with Developer
or higher [permissions](../../permissions.md).

To enable this merge request approval rule:

1. Navigate to your project's **Settings > General** and expand
   **Merge request (MR) approvals**.
1. Locate **Any eligible user** and choose the number of approvals required.

![MR approvals by Code Owners](img/mr_approvals_by_code_owners_v12_7.png)

Once set, merge requests can only be merged once approved by the
number of approvals you've set. GitLab accepts approvals from
users with Developer or higher permissions, as well as by Code Owners,
indistinguishably.

Alternatively, you can **require**
[Code Owner's approvals for protected branches](../protected_branches.md#protected-branches-approval-by-code-owners). **(PREMIUM)**

#### Merge Request approval segregation of duties

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40491) in GitLab 13.4.
> - Moved to Premium in 13.9.

Managers or operators with [Reporter permissions](../../permissions.md#project-members-permissions)
to a project sometimes need to be required approvers of a merge request,
before a merge to a protected branch begins. These approvers aren't allowed
to push or merge code to any branches.

To enable this access:

1. [Create a new group](../../group/index.md#create-a-group), and then
   [add the user to the group](../../group/index.md#add-users-to-a-group),
   ensuring you select the Reporter role for the user.
1. [Share the project with your group](../members/share_project_with_groups.md#sharing-a-project-with-a-group-of-users),
   based on the Reporter role.
1. Navigate to your project's **Settings > General**, and in the
   **Merge request (MR) approvals** section, click **Expand**.
1. Select **Add approval rule** or **Update approval rule**.
1. [Add the group](../../group/index.md#create-a-group) to the permission list.

![Update approval rule](img/update_approval_rule_v13_10.png)

#### Adding / editing a default approval rule

To add or edit the default merge request approval rule:

1. Navigate to your project's **Settings > General** and expand **Merge request (MR) approvals**.

1. Click **Add approval rule**, or **Edit**.
   - Add or change the **Rule name**.
   - Set the number of required approvals in **Approvals required**. The minimum value is `0`.
   - (Optional) Search for users or groups that are [eligible to approve](#eligible-approvers)
     merge requests and click the **Add** button to add them as approvers. Before typing
     in the search field, approvers are suggested based on the previous authors of
     the files being changed by the merge request.
   - (Optional) Click the **{remove}** **Remove** button next to a group or user to delete it from
     the rule.
1. Click **Add approval rule** or **Update approval rule**.

When [approval rule overrides](#prevent-overriding-default-approvals) are allowed,
changes to these default rules are not applied to existing merge
requests, except for changes to the [target branch](#scoped-to-protected-branch) of
the rule.

When approval rule overrides are not allowed, all changes to these default rules
are applied to existing merge requests. Any approval rules that had previously been
manually [overridden](#editing--overriding-approval-rules-per-merge-request) during a
period when approval rule overrides where allowed, are not modified.

NOTE:
If a merge request targets a different project, such as from a fork to the upstream project,
the default approval rules are taken from the target (upstream) project, not the
source (fork).

##### Editing / overriding approval rules per merge request

> Introduced in GitLab Enterprise Edition 9.4.

By default, the merge request approval rule listed in each merge request (MR) can be
edited by the MR author or a user with sufficient [permissions](../../permissions.md).
This ability can be disabled in the [merge request approvals settings](#prevent-overriding-default-approvals).

One possible scenario would be to add more approvers than were defined in the default
settings.

When creating or editing a merge request, find the **Approval rules** section, then follow
the same steps as [Adding / editing a default approval rule](#adding--editing-a-default-approval-rule).

#### Set up an optional approval rule

MR approvals can be configured to be optional, which can help if you're working
on a team where approvals are appreciated, but not required.

To configure an approval to be optional, set the number of required approvals in **Approvals required** to `0`.

You can also set an optional approval rule through the [Merge requests approvals API](../../../api/merge_request_approvals.md#update-merge-request-level-rule), by setting the `approvals_required` attribute to `0`.

#### Multiple approval rules **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1979) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.10.

In GitLab Premium, it is possible to have multiple approval rules per merge request,
as well as multiple default approval rules per project.

Adding or editing multiple default rules is identical to
[adding or editing a single default approval rule](#adding--editing-a-default-approval-rule),
except the **Add approval rule** button is available to add more rules, even after
a rule is already defined.

Similarly, editing or overriding multiple approval rules per merge request is identical
to [editing or overriding approval rules per merge request](#editing--overriding-approval-rules-per-merge-request),
except the **Add approval rule** button is available to add more rules, even after
a rule is already defined.

When an [eligible approver](#eligible-approvers) approves a merge request, it
reduces the number of approvals left for all rules that the approver belongs to.

![Approvals premium merge request widget](img/approvals_premium_mr_widget_v13_3.png)

#### Scoped to protected branch **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.8.

Approval rules are often only relevant to specific branches, like `master`.
When configuring [**Default Approval Rules**](#adding--editing-a-default-approval-rule)
these can be scoped to all the protected branches at once by navigating to your project's
**Settings**, expanding **Merge request (MR) approvals**, and selecting **Any branch** from
the **Target branch** dropdown.

Alternatively, you can select a very specific protected branch from the **Target branch** dropdown:

![Scoped to protected branch](img/scoped_to_protected_branch_v13_10.png)

To enable this configuration, see [Code Owner's approvals for protected branches](../protected_branches.md#protected-branches-approval-by-code-owners).

### Adding or removing an approval

When an [eligible approver](#eligible-approvers) visits an open merge request,
one of the following is possible:

- If the required number of approvals has _not_ been yet met, they can approve
  it by clicking the displayed **Approve** button.

  ![Approve](img/approve.png)

- If the required number of approvals has already been met, they can still
  approve it by clicking the displayed **Approve additionally** button.

  ![Add approval](img/approve_additionally.png)

- **They have already approved this merge request**: They can remove their approval.

  ![Remove approval](img/remove_approval.png)

When [approval rule overrides](#prevent-overriding-default-approvals) are allowed,
changes to default approval rules will **not** be applied to existing
merge requests, except for changes to the [target branch](#scoped-to-protected-branch)
of the rule.

NOTE:
The merge request author is not allowed to approve their own merge request if
[**Prevent author approval**](#allowing-merge-request-authors-to-approve-their-own-merge-requests)
is enabled in the project settings.

After the approval rules have been met, the merge request can be merged if there is nothing
else blocking it. Note that the merge request could still be blocked by other conditions,
such as merge conflicts, [pending discussions](../../discussions/index.md#only-allow-merge-requests-to-be-merged-if-all-threads-are-resolved),
or a [failed CI/CD pipeline](merge_when_pipeline_succeeds.md).

### Approval settings

The settings for Merge Request Approvals are found by going to
**Settings > General** and expanding **Merge request (MR) approvals**.

#### Prevent overriding default approvals

Regardless of the approval rules you choose for your project, users can edit them in every merge
request, overriding the rules you set as [default](#adding--editing-a-default-approval-rule).
To prevent that from happening:

1. Select the **Prevent users from modifying MR approval rules in merge requests.** checkbox.
1. Click **Save changes**.

#### Resetting approvals on push

You can force all approvals on a merge request to be removed when new commits are
pushed to the source branch of the merge request. If disabled, approvals persist
even if there are changes added to the merge request. To enable this feature:

1. Check the **Require new approvals when new commits are added to an MR.**
   checkbox.
1. Click **Save changes**.

NOTE:
Approvals do not get reset when [rebasing a merge request](fast_forward_merge.md)
from the UI. However, approvals are reset if the target branch is changed.

#### Allowing merge request authors to approve their own merge requests **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3349) in GitLab 11.3.
> - Moved to GitLab Premium in 13.9.

By default, projects are configured to prevent merge requests from being approved by
their own authors. To change this setting:

1. Go to your project's **Settings > General**, expand **Merge request (MR) approvals**.
1. Uncheck the **Prevent MR approval by the author.** checkbox.
1. Click **Save changes**.

Note that users can edit the approval rules in every merge request and override pre-defined settings unless it's set [**not to allow** overrides](#prevent-overriding-default-approvals).

You can prevent authors from approving their own merge requests
[at the instance level](../../admin_area/merge_requests_approvals.md). When enabled,
this setting is disabled on the project level, and not editable.

#### Prevent approval of merge requests by their committers **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10441) in GitLab 11.10.
> - Moved to GitLab Premium in 13.9.

You can prevent users who have committed to a merge request from approving it,
though code authors can still approve. You can enable this feature
[at the instance level](../../admin_area/merge_requests_approvals.md), which
disables changes to this feature at the project level. If you prefer to manage
this feature at the project level, you can:

1. Check the **Prevent MR approvals from users who make commits to the MR.** checkbox.
   If this check box is disabled, this feature has been disabled
   [at the instance level](../../admin_area/merge_requests_approvals.md).
1. Click **Save changes**.

Read the official Git documentation for an explanation of the
[differences between authors and committers](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History).

#### Require authentication when approving a merge request

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5981) in GitLab 12.0.
> - Moved to GitLab Premium in 13.9.

NOTE:
To require authentication when approving a merge request, you must enable
**Password authentication enabled for web interface** under [sign-in restrictions](../../admin_area/settings/sign_in_restrictions.md#password-authentication-enabled).
in the Admin Area.

You can force the approver to enter a password in order to authenticate before adding
the approval. This enables an Electronic Signature for approvals such as the one defined
by [CFR Part 11](https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfcfr/CFRSearch.cfm?CFRPart=11&showFR=1&subpartNode=21:1.0.1.1.8.3)).
To enable this feature:

1. Check the **Require user password for approvals.** checkbox.
1. Click **Save changes**.

### Security approvals in merge requests **(ULTIMATE)**

Merge Request Approvals can be configured to require approval from a member
of your security team when a vulnerability would be introduced by a merge request.

For more information, see
[Security approvals in merge requests](../../application_security/index.md#security-approvals-in-merge-requests).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
