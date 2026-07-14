---
title: Disable built-in project templates
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
documentation_link: "../../../administration/project_templates#built-in-project-templates"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21356
categories: [ Source Code Management ]
level: secondary
weight: 50
---


When organizations rely on custom project templates, GitLab's built-in vendor
templates can add noise to the template selection experience and, in some cases,
bypass server-side hooks or other repository controls.

Administrators can now disable built-in project templates globally from the
**Admin** area, or at the group level for subgroups. The setting cascades
automatically so you do not need to configure it for every group individually.
Administrators can enforce the value of the setting to ensure groups or subgroups cannot override it.
Both the instance and group settings are also manageable with the
[REST and GraphQL APIs](../../../user/group/manage#control-built-in-project-templates).
On GitLab.com, only the group-level setting is available.
