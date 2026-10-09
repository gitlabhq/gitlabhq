---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Automatically assign Code Owners as reviewers, or get reviewer recommendations from the Recommend Reviewers Flow.
title: Automatic reviewer assignment and recommendations
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab can assign or recommend reviewers for your merge requests, so you don't have to select them by hand:

- Use automatic reviewer assignment to assign the Code Owners of changed files as reviewers.
- Use the Recommend Reviewers Flow to get reviewer recommendations based on your approval rules, including Code Owner rules.

## Automatic reviewer assignment

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175) in GitLab 18.10 [with a feature flag](../../../../administration/feature_flags/_index.md) named `auto_assign_code_owner_reviewers`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239965) in GitLab 19.1. Feature flag `auto_assign_code_owner_reviewers` removed.

{{< /history >}}

When you enable automatic reviewer assignment, GitLab assigns the
[Code Owners](../../codeowners/_index.md) of changed files as reviewers on a merge request.

Prerequisites:

- The project must have a `CODEOWNERS` file.
- The Maintainer or Owner role for the project.

### Enable automatic reviewer assignment

To turn on automatic reviewer assignment for a project:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **Merge requests**.
1. Go to the **Automatic reviewer assignment** section.
1. Select **Automatically assign all code owners as reviewers**.
1. Select **Save changes**.

### When GitLab assigns reviewers

After you turn on the setting, GitLab assigns Code Owners as reviewers when:

- A merge request is created in a ready state.
- A draft merge request is marked as ready.

GitLab assigns every Code Owner that matches the files changed in the merge request.

GitLab skips auto-assignment when:

- The merge request is a draft.
- The merge request already has a reviewer. [`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code) is excluded from this check.
- No code owner matches the files changed in the merge request.
- The merge request author does not have permission to set merge request metadata.

## Recommend Reviewers Flow

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236211) in GitLab 19.0 as a [beta](../../../../policy/development_stages_support.md#beta) project setting [with a feature flag](../../../../administration/feature_flags/_index.md) named `dap_powered_recommend_reviewers`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/607677) in GitLab 19.4 to use a flow trigger instead of a project setting. Feature flag `dap_powered_recommend_reviewers` removed.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257534) in GitLab 19.5 to create a trigger that runs when a merge request is created.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257235) in GitLab 19.5 to recommend reviewers in the merge request sidebar instead of assigning them.
- Requesting recommendations for existing merge requests [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/260988) in GitLab 19.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/261192) in GitLab 19.5.

{{< /history >}}

The Recommend Reviewers Flow recommends the reviewers best suited to review your merge
request.
It recommends the minimum number of reviewers needed to satisfy each approval rule, and chooses
reviewers based on availability, workload, and time zone.

Recommended reviewers appear in the merge request sidebar and you choose which of the reviewers to assign.

This feature runs on the [GitLab Duo Agent Platform](../../../duo_agent_platform/_index.md).

This flow replaces the **Reviewer assignment strategy** project setting used in GitLab 19.3 and
earlier.

Prerequisites:

- The Owner role for the top-level group, and the Maintainer or Owner role for the
  project.
- The [prerequisites for the GitLab Duo Agent Platform](../../../duo_agent_platform/_index.md#prerequisites).
- **Allow flow execution**, **Allow foundational flows**, and **Recommend Reviewers** on
  [for the top-level group](../../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).

### Use the flow

When you turn on the Recommend Reviewers Flow for the top-level group, GitLab creates a flow
trigger in each project. This trigger runs the flow when a merge request is created, including
merge requests created as drafts and merge requests created in a ready state. For a draft merge
request, the flow recommends reviewers when the merge request is created, not when it is marked
as ready.

This trigger appears on the **AI** > **Triggers** page of the project, where you can turn it off.

To run the flow when a draft merge request is marked as ready instead, turn off this trigger,
then create a trigger:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. Select **New flow trigger**.
1. In **Description**, enter a description for the trigger.
1. If **Configuration source** is shown, select **Flow or external agent**, then select **Recommend Reviewers** from the flow list.
1. In the **Conditions** section:
   1. Select **Add condition**, then select **On an event**.
   1. From the **Event** dropdown list, select **Merge request**.
   1. From the **Run when** dropdown list, select **Marked ready**.
   1. Select **Add event**.
1. Select **Create flow trigger**.

The flow runs when a person with at least the Developer role marks a draft merge request as ready.

For more information about creating and editing triggers, see
[triggers](../../../duo_agent_platform/triggers/_index.md).

### Request recommendations for an existing merge request

If a merge request existed before you turned on the flow, you must start the flow manually.

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.

To request recommendations for a merge request where the flow has not run:

- In the right sidebar, under **Reviewers** > **Recommended**, select **Fetch**.

**Fetch** is unavailable while the flow runs.

### Assign a recommended reviewer

After the flow runs, recommended reviewers appear in the **Recommended** section under
**Reviewers** in the right sidebar, grouped by approval rule.
The section appears when there is at least one recommendation.

To see why the flow recommended a user, and when, hover over the user.

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.

To assign a recommended reviewer to your merge request:

- Under **Recommended**, next to the user you want to assign, select **Add reviewer** ({{< icon name="plus" >}}).

After you assign a reviewer, they no longer appear in the **Recommended** section.

To run the flow again and get new recommendations:

- In the **Recommended** section, select
**Recommended reviewer actions** ({{< icon name="ellipsis_v" >}}) > **Refresh**.

GitLab removes the recommendations when the merge request is merged or closed.

### Exceptions

- The person who creates the merge request, or marks it as ready, must have at least the
  Developer role for the project. The flow does not recommend reviewers when the person has a
  lower role.

### Reviewer selection

The Recommend Reviewers Flow reads the required approval rules and the optional approval rules on the merge request.
An optional approval rule is a rule that requires zero approvals.
The flow skips an optional **All Members** rule, and optional rules created by merge request approval policies.
For each rule that the current reviewers do not already satisfy, the flow recommends the minimum number of reviewers needed to satisfy the rule.
The flow never recommends a user who is already a reviewer.
For each recommended reviewer, the flow saves a short reason for the recommendation.

To choose between the eligible approvers for a rule, the flow considers the
following for each approver:

- Availability, based on their [status](../../../profile/_index.md#set-your-status).
- Review workload, based on the number of open merge requests waiting for their review.
- Local time, based on the time zone in their profile.
- Most recent activity.

For the default **All Members** rule, which lists no approvers, the flow chooses
from the direct members of the project who can both approve the merge request and merge into the
target branch. When no role can merge into the target branch, the candidates are all direct members
who can approve. Members who get their access from a parent group or an invited group are not
candidates, so a project without direct members gets no recommendation for this rule.

The recommendation runs in the background, so the recommended reviewers might take a moment to appear.
The flow runs as the [service account](../../../duo_agent_platform/flows/foundational_flows/_index.md#service-accounts) that is set up when you turn the flow on for the top-level group.

## Related topics

- [Code Owners](../../codeowners/_index.md)
- [Merge request reviews](_index.md)
- [Merge request approval rules](../approvals/rules.md)
