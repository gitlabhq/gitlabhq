---
stage: Tenant Scale
group: Organizations
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
description: "Development Guidelines: learn about organization when developing GitLab."
title: Organization
---

The [Organization initiative](../../user/organization/_index.md) focuses on reaching feature parity between
GitLab.com and GitLab Self-Managed.

## Consolidate groups and projects

- [Architecture design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/consolidating_groups_and_projects/)

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

## Organizations & cells

For the [Cells](../cells) project, GitLab will rely on organizations. A cell will host one or more organizations. When a request is made, the [HTTP Router Service](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/http_routing_service/) will route it to the correct cell.

### Map a request to an organization with `Current.organization`

The application needs to know how to map incoming requests to an organization. The mapping logic is encapsulated in [`Gitlab::Current::Organization`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/current/organization.rb). The outcome of this mapping is stored in a [`ActiveSupport::CurrentAttributes`](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) instance called `Current`. You can then access the current organization using the `Current.organization` method.

Since this mapping depends on HTTP requests, `Current.organization` is only available in the request layer (Rails controllers,
Grape API, and GraphQL). It cannot be used in Rake tasks, cron jobs or Sidekiq workers. This is enforced by a RuboCop rule. In
those cases, the organization ID should be derived from something else (related data) or passed as an argument.

### Availability of `Current.organization`

Since this mapping depends on HTTP requests, `Current.organization` is available only in the request layer. You can use it in:

- Rails controllers that inherit from `ApplicationController`
- GraphQL queries and mutations
- Grape API endpoints (requires [usage of a helper](#usage-in-grape-api)

You cannot use `Current.organization` in:

- Rake tasks
- Cron jobs
- Sidekiq workers

This restriction is enforced by a RuboCop rule. For these cases, derive the organization ID from related data or pass it as an argument.

### Usage in Grape API

`Current.organization` is not available in all Grape API endpoints. Use the `set_current_organization` helper to set `Current.organization`:

```ruby
module API
  class SomeAPIEndpoint < ::API::Base
    before do
      set_current_organization # This will set Current.organization
    end

    # ... api logic ...
  end
end
```

### The default organization

Do not rely on a default organization. Only one cell can access the default organization, and other cells cannot access it.

Default organizations were initially used to assign existing data when introducing the Organization data structure. However, the application no longer depends on default organizations. Do not create or assign default organization objects.

The default organization remains available on GitLab.com only until all data is assigned to new organizations. Hard-coded dependencies on the default organization do not work in cells. All cells should be treated the same.

### Organization data sources

An organization serves two purposes:

- A logical grouping of data (for example: an User belongs to one or more Organizations)
- [Sharding key](../cells) for Cells

For data modeling purposes, there is no need to have redundant `organization_id` attributes. For example, the projects table has an `organization_id` column. From a normalization point of view, this is not needed because a project belongs to a namespace and a namespace belongs to an organization.

However, for sharding purposes, we violate this normalization rule. Tables that have a parent-child relationship still define `organization_id` on both the parent table and the child.

To populate the `organization_id` column, use these methods in order of preference:

1. Derive from related data. For example, a subgroup can use the organization that is assigned to the parent group.
1. `Current.organization`. This is available in the request layer and can be passed into Sidekiq workers.
1. Ask the user. In some cases, the UI needs to be updated and should include a way of selecting an organization.

## Related topics

- [Consolidating groups and projects](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/consolidating_groups_and_projects/)
  architecture documentation
- [Organization user documentation](../../user/organization/_index.md)
