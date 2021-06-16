---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, concepts
---

# Merge request approval rules **(PREMIUM SELF)**

> Introduced in [GitLab Premium](https://gitlab.com/gitlab-org/gitlab/-/issues/39060) 12.8.

Merge request approval rules prevent users from overriding certain settings on the project
level. When enabled at the instance level, these settings are no longer editable on the
project level.

To enable merge request approval rules for an instance:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **{push-rules}** **Push Rules**, and expand **Merge request (MR) approvals**.
1. Set the required rule.
1. Click **Save changes**.

## Available rules

Merge request approval rules that can be set at an instance level are:

- **Prevent approval of merge requests by merge request author**. Prevents project
maintainers from allowing request authors to merge their own merge requests.
- **Prevent approval of merge requests by merge request committers**. Prevents project
maintainers from allowing users to approve merge requests if they have submitted
any commits to the source branch.
- **Prevent users from modifying merge request approvers list**. Prevents users from
modifying the approvers list in project settings or in individual merge requests.

Also read the [project level merge request approval rules](../project/merge_requests/approvals/index.md), which are affected by instance level rules.
