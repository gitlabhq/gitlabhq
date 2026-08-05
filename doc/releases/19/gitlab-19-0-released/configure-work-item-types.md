---
title: Configure work item types
stage: plan
level: primary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/work_items/configurable_work_item_types/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/9365"
categories: [ Team Planning ]
weight: 20
---

Previously, work item types could be either an **Issue** or a **Task**. You can now configure custom work item types in a project to match the way your team plans and tracks work.

You can create or rename types to **User Story**, **Bug**, or **Maintenance**. Each work item displays with its type name and a unique icon. The new types support custom fields and status lifecycles, and appear in your saved views and issue boards. Type configuration in the top-level group (GitLab.com) or organization (GitLab Self-Managed) cascades down to all projects.

You can also control which types are available for each project. Enable or disable a type across all projects at once, or let individual projects manage their own type visibility. When you disable a type in a project, existing work items are not affected.
