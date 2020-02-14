---
type: reference, concepts
---

# Instance-level merge request approval rules **(PREMIUM ONLY)**

> Introduced in [GitLab Premium](https://gitlab.com/gitlab-org/gitlab/issues/39060) 12.8.

Merge request approvals rules prevent users overriding certain settings on a project
level. When configured, only administrators can change these settings on a project level
if they are enabled at an instance level.

To enable merge request approval rules for an instance:

1. Navigate to **{admin}** **Admin Area >** **{push-rules}** **Push Rules** and expand **Merge
   requests approvals**.
1. Set the required rule.
1. Click **Save changes**.

GitLab administrators can later override these settings in a project’s settings.

## Available rules

Merge request approval rules that can be set at an instance level are:

- **Prevent approval of merge requests by merge request author**. Prevents non-admins
  from allowing merge request authors to merge their own merge requests in individual
  projects.
- **Prevent approval of merge requests by merge request committers**. Prevents
  non-admins from allowing merge request committers to merge merge requests they were
  committing to in individual projects.
- **Prevent users from modifying merge request approvers list**. Prevents non-admins
  from modifying approvers list in project settings and in individual merge requests.
