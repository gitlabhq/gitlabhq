---
stage: Tenant Scale
group: Organizations
info: 'See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines'
description: 'Development Guidelines: learn about organization when developing GitLab.'
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

### Defining a sharding key for all organizational tables

All tables with the following [`gitlab_schema`](../cells/_index.md#available-cells--organization-schemas) are considered organization level:

- `gitlab_main_org`
- `gitlab_ci`
- `gitlab_sec`
- `gitlab_main_user`

All newly created organization-level tables are required to have a `sharding_key`
defined in the corresponding `db/docs/` file for that table.

The purpose of the sharding key is documented in the
[Organization isolation blueprint](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/isolation/),
but in short this column is used to provide a standard way of determining which
Organization owns a particular row in the database. The column will be used in
the future to enforce constraints on data not cross Organization boundaries. It
will also be used in the future to provide a uniform way to migrate data
between Cells.

The actual name of the foreign key can be anything but it must reference a row
in `projects` or `groups`. The chosen `sharding_key` column must be non-nullable.

Setting multiple `sharding_key`, with nullable columns are also allowed, provided that
the table has a check constraint that correctly ensures exactly one of the keys must be non-nullable for a row in the table.
See [`NOT NULL` constraints for multiple columns](../database/not_null_constraints.md#not-null-constraints-for-multiple-columns)
for instructions on creating these constraints. The reasoning for adding sharding keys, and which keys to add to a table/row, goes like this:

- In order to move organizations across cells, we want `organization_id` on all rows of all tables
- But `organization_id` on rows that are actually owned by a top-level group (or its subgroups or projects) makes top-level group
  transfer inefficient (due to `organization_id` rewrites) to the point of being impractical
- Compromise: Add `organization_id` or `namespace_id` to all rows of all tables
- But `namespace_id` on rows of tables that are actually owned by projects makes project transfer (and certain subgroup transfers) inefficient
  (due to `namespace_id` rewrites) to the point of being impractical
- Compromise: Add `organization_id` or `namespace_id` or `project_id` to all rows of all tables, which ever is the most specific

#### Conclusions

There is no benefit of filling `namespace_id` if a row is also owned by `project_id`

There is a performance impact on group/project transfer to filling `namespace_id` if a row is also owned by `project_id`.
Though if your table is small then the performance impact is small.
It can be confusing to have 2 sharding key values on some rows.

#### Guideline

Every row must have exactly 1 sharding key, and it should be as specific as possible. Exceptions cannot be made on large tables.

The following are examples of valid sharding keys:

- The table entries belong to a project only:

  ```yaml
  sharding_key:
    project_id: projects
  ```

- The table entries belong to a project and the foreign key is `target_project_id`:

  ```yaml
  sharding_key:
    target_project_id: projects
  ```

- The table entries belong to a namespace/group only:

  ```yaml
  sharding_key:
    namespace_id: namespaces
  ```

- The table entries belong to a namespace/group only and the foreign key is `group_id`:

  ```yaml
  sharding_key:
    group_id: namespaces
  ```

- The table entries belong to a namespace or a project:

  ```yaml
  sharding_key:
    project_id: projects
    namespace_id: namespaces
  ```

- (Only for `gitlab_main_user`) The table entries belong to a user only:

  ```yaml
  sharding_key:
    user_id: users
  ```

#### The sharding key must be immutable

The choice of a `sharding_key` should always be immutable. This is because the
sharding key column will be used as an index for the planned
[Org Mover](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/migration/),
and also the
[enforcement of isolation](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/isolation/)
of Organization data.
Any mutation of the `sharding_key` could result in in-consistent data being read.

Therefore, if your feature requires a user experience which allows data to be
moved between projects or groups/namespaces, then you may need to redesign the
move feature to create new rows.
An example of this can be seen in the
[move an issue feature](../../user/project/issues/managing_issues.md#move-an-issue).
This feature does not actually change the `project_id` column for an existing
`issues` row but instead creates a new `issues` row and creates a link in the
database from the original `issues` row.
If there is a particularly challenging
existing feature that needs to allow moving data you will need to reach out to
the Tenant Scale team early on to discuss options for how to manage the
sharding key.

#### Using `namespace_id` as sharding key

The `namespaces` table has rows that can refer to a `Group`, a `ProjectNamespace`,
or a `UserNamespace`. The `UserNamespace` type is also known as a personal namespace.

Using a `namespace_id` as a sharding key is a good option, except when `namespace_id`
refers to a `UserNamespace`. Because a user does not necessarily have a related
`namespace` record, this sharding key can be `NULL`. A sharding key should not
have `NULL` values.

#### Using the same sharding key for projects and namespaces

Developers may also choose to use `namespace_id` only for tables that can
belong to a project where the feature used by the table is being developed
following the
[Consolidating Groups and Projects blueprint](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/consolidating_groups_and_projects/).
In that case the `namespace_id` would need to be the ID of the
`ProjectNamespace` and not the group that the namespace belongs to.

#### Using `organization_id` as sharding key

Usually, `project_id` or `namespace_id` are the most common sharding keys.
However, there are cases where a table does not belong to a project or a namespace.

In such cases, `organization_id` is an option for the sharding key, provided the below guidelines are followed:

- The `sharding_key` column still needs to be [immutable](#the-sharding-key-must-be-immutable).
- Only add `organization_id` for root level models (for example, `namespaces`), and not leaf-level models (for example, `issues`).
- Ensure such tables do not contain data related to groups, or projects (or records that belong to groups / projects).
  Instead, use `project_id`, or `namespace_id`.
- Tables with lots of rows are not good candidates because we would need to re-write every row if we move the entity to a different organization which can be expensive.
- When there are other tables referencing this table, the application should continue to work if the referencing table records are moved to a different organization.

If you believe that the `organization_id` is the best option for the sharding key, seek approval from the Tenant Scale group.
This is crucial because it has implications for data migration and may require reconsideration of the choice of sharding key.

As an example, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/462758), which added `organization_id` as a sharding key to an existing table.

For more information about development with organizations, see [Organization](../organization)

#### Add a sharding key to a pre-existing table

See the following [guidance](sharding/_index.md).

#### Define a `desired_sharding_key` to automatically backfill a `sharding_key`

We need to backfill a `sharding_key` to hundreds of tables that do not have one.
This process will involve creating a merge request like
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136800> to add the new
column, backfill the data from a related table in the database, and then create
subsequent merge requests to add indexes, foreign keys and not-null
constraints.

In order to minimize the amount of repetitive effort for developers we've
introduced a concise declarative way to describe how to backfill the
`sharding_key` for this specific table. This content will later be used in
automation to create all the necessary merge requests.

An example of the `desired_sharding_key` was added in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139336> and it looks like:

```yaml
--- # db/docs/security_findings.yml
table_name: security_findings
classes:
- Security::Finding

# ...

desired_sharding_key:
  project_id:
    references: projects
    backfill_via:
      parent:
        foreign_key: scanner_id
        table: vulnerability_scanners
        table_primary_key: id # Optional. Defaults to 'id'
        sharding_key: project_id
        belongs_to: scanner
```

To understand best how this YAML data will be used you can map it onto
the merge request we created manually in GraphQL
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136800>. The idea
will be to automatically create this. The content of the YAML specifies
the parent table and its `sharding_key` to backfill from in the batched
background migration. It also specifies a `belongs_to` relation which
will be added to the model to automatically populate the `sharding_key` in
the `before_save`.

##### Define a `desired_sharding_key` when the parent table also has one

By default, a `desired_sharding_key` configuration will validate that the chosen `sharding_key`
exists on the parent table. However, if the parent table also has a `desired_sharding_key` configuration
and is itself waiting to be backfilled, you need to include the `awaiting_backfill_on_parent` field.
For example:

```yaml
desired_sharding_key:
  project_id:
    references: projects
    backfill_via:
      parent:
        foreign_key: package_file_id
        table: packages_package_files
        table_primary_key: id # Optional. Defaults to 'id'
        sharding_key: project_id
        belongs_to: package_file
    awaiting_backfill_on_parent: true
```

There are likely edge cases where this `desired_sharding_key` structure is not
suitable for backfilling a `sharding_key`. In such cases the team owning the
table will need to create the necessary merge requests to add the
`sharding_key` manually.

### Ensure sharding key presence on application level

When you define your sharding key you must make sure it's filled on application level.
Every `ApplicationRecord` model includes a helper `populate_sharding_key`, which
provides a convenient way of defining sharding key logic,
and also a corresponding matcher to test your sharding key logic. For example:

```ruby
# in model.rb
populate_sharding_key :project_id, source: :merge_request, field: :target_project_id

# in model_spec.rb
it { is_expected.to populate_sharding_key(:project_id).from(:merge_request, :target_project_id) }
```

See more [helper examples](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/populates_sharding_key.rb)
and [RSpec matcher examples](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/matchers/populate_sharding_key_matcher.rb).

### Map a request to an organization with `Current.organization`

The application needs to know how to map incoming requests to an organization. The mapping logic is encapsulated in [`Gitlab::Current::Organization`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/current/organization.rb). The outcome of this mapping is stored in a [`ActiveSupport::CurrentAttributes`](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) instance called `Current`. You can then access the current organization using the `Current.organization` method.

### Availability of `Current.organization`

Since this mapping depends on HTTP requests, `Current.organization` is available only in the request layer. You can use it in:

- Rails controllers that inherit from `ApplicationController`
- GraphQL queries and mutations
- Grape API endpoints (requires [usage of a helper](#usage-in-grape-api)

In these request layers, it is safe to assume that `Current.organization` is not `nil`.

You cannot use `Current.organization` in:

- Rake tasks
- Cron jobs
- Sidekiq workers

This restriction is enforced by a RuboCop rule. For these cases, derive the organization ID from related data or pass it as an argument.

### Writing tests for code that depends on `Current.organization`

If you need a `current_organization` for RSpec, you can use the [`with_current_organization`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/shared_contexts/current_organization_context.rb) shared context. This will create a `current_organization` method that will be returned by `Gitlab::Current::Organization` class

```ruby
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe MyController, :with_current_organization do
  let(:project) { create(:project, organization: current_organization) }

  subject { project.organization }

  it {is_expected.to eq(current_organization) }
end
```

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
