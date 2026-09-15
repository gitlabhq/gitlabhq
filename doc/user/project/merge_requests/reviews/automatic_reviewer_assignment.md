---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Automatically assign Code Owners as reviewers when a merge request is ready.
title: Automatic reviewer assignment
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175) in GitLab 18.10 [with a feature flag](../../../../administration/feature_flags/_index.md) named `auto_assign_code_owner_reviewers`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239965) in GitLab 19.1. Feature flag `auto_assign_code_owner_reviewers` removed.

{{< /history >}}

When you enable automatic reviewer assignment, GitLab assigns the
[Code Owners](../../codeowners/_index.md) of changed files as reviewers on a merge request.
You don't have to select reviewers from the `CODEOWNERS` file by hand.

## Prerequisites

- The project must have a [`CODEOWNERS` file](../../codeowners/_index.md).
- The Maintainer or Owner role for the project.

## Enable automatic reviewer assignment

To turn on automatic reviewer assignment for a project:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **Merge requests**.
1. Go to the **Automatic reviewer assignment** section.
1. Select **Automatically assign all code owners as reviewers**.
1. Select **Save changes**.

## When GitLab assigns reviewers

After you turn on the setting, GitLab assigns Code Owners as reviewers when:

- A merge request is created in a ready state.
- A draft merge request is marked as ready.

GitLab assigns every Code Owner that matches the files changed in the merge request.

GitLab skips auto-assignment when:

- The merge request is a draft.
- The merge request already has a reviewer. [`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code) is excluded from this check.
- No code owner matches the files changed in the merge request.
- The merge request author does not have permission to set merge request metadata.

## Assign reviewers with the Recommend Reviewers flow

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236211) in GitLab 19.0 as a project setting [with a feature flag](../../../../administration/feature_flags/_index.md) named `dap_powered_recommend_reviewers`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/607677) in GitLab 19.4 to use a flow trigger instead of a project setting. Feature flag `dap_powered_recommend_reviewers` removed.

{{< /history >}}

The Recommend Reviewers flow recommends and assigns reviewers best suited to review your merge
request.

Instead of assigning every Code Owner, it assigns the minimum number of reviewers needed to satisfy
each approval rule, based on availability, workload, and time zone.

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

To use the Recommend Reviewers flow, create a trigger:

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

### Exceptions

- Reviewers are assigned only when a draft merge request is marked as ready.
  The flow does not assign reviewers when a merge request is opened directly in a ready state.
  For more information, see [issue 592452](https://gitlab.com/gitlab-org/gitlab/-/issues/592452).
- The person who marks the merge request as ready must have at least the Developer role for the
  project. The flow does not assign reviewers when the person has a lower role.

### Reviewer selection

The Recommend Reviewers flow reads the required approval rules on the merge request.
For each rule, it recommends and assigns the minimum number of reviewers needed to satisfy the rule.
It then adds a note to explain the recommendations.
The flow ignores optional approval rules.

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

The recommendation runs in the background, so the reviewers might take a moment to appear.
The flow attributes the reviewer assignments and the note to the [service account](../../../duo_agent_platform/flows/foundational_flows/_index.md#service-accounts) that is set up when you turn the flow on for the top-level group.
They are not attributed to the person who marked the merge request as ready.

## Related topics

- [Code Owners](../../codeowners/_index.md)
- [Merge request reviews](_index.md)
- [Merge request approval rules](../approvals/rules.md)
