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

## Merge request controls **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/207250) in GitLab 13.0.

Merge request approval settings, by default, are inherited by all projects in an instance.

However, organizations with regulated projects may also have unregulated projects
that should not inherit these same controls.

Project-level merge request approval rules can now be edited by administrators.
Project owners and maintainers can still view project-level merge request approval rules.

In upcoming releases, we plan to provide a more holistic experience to scope instance-level merge request settings.
For more information, review our plans to provide custom [approval settings for compliance-
labeled projects](https://gitlab.com/gitlab-org/gitlab/-/issues/213601).

## Available rules

Merge request approval rules that can be set at an instance level are:

- **Prevent approval of merge requests by merge request author**. Prevents project
  maintainers from allowing request authors to merge their own merge requests.
- **Prevent approval of merge requests by merge request committers**. Prevents project
  maintainers from allowing users to approve merge requests if they have submitted
  any commits to the source branch.
- **Prevent users from modifying merge request approvers list**. Prevents project
  maintainers from allowing users to modify the approvers list in project settings
  or in individual merge requests.
