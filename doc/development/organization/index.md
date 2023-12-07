---
stage: Data Stores
group: Tenant Scale
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
description: "Development Guidelines: learn about organization when developing GitLab."
---

# Organization

The [Organization initiative](../../user/organization/index.md) focuses on reaching feature parity between
SaaS and self-managed installations.

## Consolidate groups and projects

- [Architecture blueprint](../../architecture/blueprints/consolidating_groups_and_projects/index.md)

One facet of the Organization initiative is to consolidate groups and projects,
addressing the feature disparity between them. Some features, such as epics, are
only available at the group level. Some features, such as issues, are only available
at the project level. Other features, such as milestones, are available to both groups
and projects.

We receive many requests to add features either to the group or project level.
Moving features around to different levels is problematic on multiple levels:

- It requires engineering time to move the features.
- It requires UX overhead to maintain mental models of feature availability.
- It creates redundant code.

When features are copied from one level (project, group, or instance) to another,
the copies often have small, nuanced differences between them. These nuances cause
extra engineering time when fixes are needed, because the fix must be copied to
several locations. These nuances also create different user experiences when the
feature is used in different places.

A solution for this problem is to consolidate groups and projects into a single
entity, `namespace`. The work on this solution is split into several phases and
is tracked in [epic 6473](https://gitlab.com/groups/gitlab-org/-/epics/6473).

## How to plan features that interact with Group and ProjectNamespace

As of now, every Project in the system has a record in the `namespaces` table. This makes it possible to
use common interface to create features that are shared between Groups and Projects. Shared behavior can be added using
a concerns mechanism. Because the `Namespace` model is responsible for `UserNamespace` methods as well, it is discouraged
to use the `Namespace` model for shared behavior for Projects and Groups.

### Resource-based features

To migrate resource-based features, existing functionality will need to be supported. This can be achieved in two Phases.

**Phase 1 - Setup**

- Link into the namespaces table
  - Add a column to the table
  - For example, in issues a `project id` points to the projects table. We need to establish a link to the `namespaces` table.
  - Modify code so that any new record already has the correct data in it
  - Backfill

**Phase 2 - Prerequisite work**

- Investigate the permission model as well as any performance concerns related to that.
  - Permissions need to be checked and kept in place.
- Investigate what other models need to support namespaces for functionality dependent on features you migrate in Phase 1.
- Adjust CRUD services and APIs (REST and GraphQL) to point to the new column you added in Phase 1.
- Consider performance when fetching resources.

Introducing new functionality is very much dependent on every single team and feature.

### Settings-related features

Right now, cascading settings are available for `NamespaceSettings`. By creating `ProjectNamespace`,
we can use this framework to make sure that some settings are applicable on the project level as well.

When working on settings, we need to make sure that:

- They are not used in `join` queries or modify those queries.
- Updating settings is taken into consideration.
- If we want to move from project to project namespace, we follow a similar database process to the one described in Phase 1.

## Related topics

- [Consolidating groups and projects](../../architecture/blueprints/consolidating_groups_and_projects/index.md)
  architecture documentation
- [Organization user documentation](../../user/organization/index.md)
