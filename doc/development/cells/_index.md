---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GitLab Cells Development Guidelines
---

For background of GitLab Cells, refer to the [design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/).

## Available Cells / Organization schemas

Below are available schemas related to Cells and Organizations:

| Schema | Description |
| ------ | ----------- |
| `gitlab_main` (deprecated) | This is being replaced with `gitlab_main_org`, for the purpose of building the [Cells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/) architecture. |
| `gitlab_main_cell` (deprecated) | All `gitlab_main_cell` tables are being moved to `gitlab_main_org`. `gitlab_main_org` is a better name for `gitlab_main_cell` - there is no functional difference between the two. |
| `gitlab_main_org`| Use for all tables in the `main:` database that are for an Organization. For example, `projects` and `groups` |
| `gitlab_main_cell_setting` | All tables in the `main:` database related to cell settings. For example, `application_settings`. These cell-local tables should not have any foreign key references from/to organization tables. |
| `gitlab_main_clusterwide` (deprecated) | All tables in the `main:` database where all rows, or a subset of rows needs to be present across the cluster, in the [Cells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/) architecture. For example, `plans`. For the [Cells 1.0 architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.0/), there are no real clusterwide tables as each cell will have its own database. In effect, these tables will still be stored locally in each cell. |
| `gitlab_main_cell_local` | For tables in the `main:` database that are related to features that is distinct for each cell. For example, `zoekt_nodes`, or `shards`. These cell-local tables should not have any foreign key references from/to organization tables. |
| `gitlab_ci` | Use for all tables in the `ci:` database that are for an Organization. For example, `ci_pipelines` and `ci_builds` |
| `gitlab_ci_cell_local` | For tables in the `ci:` database that are related to features that is distinct for each cell. For example, `instance_type_ci_runners`, or `ci_cost_settings`. These cell-local tables should not have any foreign key references from/to organization tables. |
| `gitlab_main_user` | Schema for all User-related tables, ex. `users`, `emails`, etc. Most user functionality is organizational level so should use `gitlab_main_org` instead (e.g. commenting on an issue). For user functionality that is not organizational level, use this schema. Tables on this schema must strictly belong to a user. |
| `gitlab_shared_org` | Schema for tables with data across multiple databases and has `organization_id` for sharding. These tables inherit from `Gitlab::Database::SharedModel`. |
| `gitlab_shared_cell_local` | Schema for cell local shared tables that do not require sharding and exist across multiple databases. For example, `loose_foreign_keys_deleted_records`. These tables also inherit from `Gitlab::Database::SharedModel`. |

Most tables will require a [sharding key](../organization/_index.md#defining-a-sharding-key-for-all-organizational-tables) to be defined.

To understand how existing tables are classified, you can use [this dashboard](https://cells-progress-tracker-gitlab-org-tenant-scale-g-f4ad96bf01d25f.gitlab.io/schema_migration).

After a schema has been assigned, the merge request pipeline might fail due to one or more of the following reasons, which can be rectified by following the linked guidelines:

- [Cross-database joins](../database/multiple_databases.md#suggestions-for-removing-cross-database-joins)
- [Cross-database transactions](../database/multiple_databases.md#fixing-cross-database-transactions)
- [Cross-database foreign keys](../database/multiple_databases.md#foreign-keys-that-cross-databases)

## What schema to choose if the feature can be cluster-wide?

The `gitlab_main_clusterwide` schema is now deprecated.
We will ask teams to update tables from `gitlab_main_clusterwide` to `gitlab_main_org` as required.
This requires adding sharding keys to these tables, and may require
additional changes to related features to scope them to the Organizational level.

Clusterwide features are
[heavily discouraged](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/#how-do-i-decide-whether-to-move-my-feature-to-the-cluster-cell-or-organization-level),
and there are [no plans to perform any cluster-wide synchronization](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/decisions/014_clusterwide_syncing_in_cells_1_0/).

Choose a different schema from the list of available GitLab [schemas](#available-cells--organization-schemas) instead.
We expect most tables to use the `gitlab_main_org` schema, especially if the
table in the table is related to `projects`, or `namespaces`.
Another alternative is the `gitlab_main_cell_local` schema.

Consult with the [Tenant Scale group](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/tenant-scale/):
If you believe you require a clusterwide feature, seek design input from the
Tenant Scale group.
Here are some considerations to think about:

- Can the feature to be scoped per Organization (or lower) instead ?
- The related feature must work on multiple cells, not just the legacy cell.
- How would the related feature scale across many Organizations and Cells ?
- How will data be stored ?
- How will organizations reference the data consistently ?
  Can you use globally unique identifiers ?
- Does the data need to be consistent across different cells ?
- Do not use database tables to store [static data](#static-data).

## Creating a new schema

Schemas should default to require a sharding key, as features should be scoped to an Organization by default.

```yaml
# db/gitlab_schemas/gitlab_ci.yaml
require_sharding_key: true
sharding_root_tables:
  - projects
  - namespaces
  - organizations
```

Setting `require_sharding_key` to `true` means that tables assigned to that
schema will require a `sharding_key` to be set.
You will also need to configure the list of allowed `sharding_root_tables` that can be used as sharding keys for tables in this schema.

## Database sequences

We ensure uniqueness of database sequences, across all cells.
This means the `id` columns of most tables will be unique.

For technical implementation and architecture decisions, refer to:

- [Cells: Cluster wide unique database sequences](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/decisions/008_database_sequences)
- [Topology Service: Sequence Service](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/topology_service/#sequence-service)

## Unique constraints

If you require data to be unique, it should be scoped to be unique per
Organization, Group, Project, or User.
With the existence of multiple cells which each has its own independent
database, you can no longer rely on `UNIQUE` constraints.

You have two options:

1. Ensure the index is scoped to include their `sharding_key` as one of
   the columns present in the index.
1. For the rare case where an attribute must be unique globally, across all
   organizations, use the upcoming
   [Claim service](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/topology_service/#claim-service).

## Static data

Problem: A database table is used to store static data.
However, the primary key is not static because it uses an auto-incrementing sequence.
This means the primary key is not globally consistent.

References to this inconsistent primary key will create problems because the
reference clashes across cells / organizations.

Example: The `plans` table on a given Cell has the following data:

```shell
 id |             name             |              title
----+------------------------------+----------------------------------
  1 | default                      | Default
  2 | bronze                       | Bronze
  3 | silver                       | Silver
  5 | gold                         | Gold
  7 | ultimate_trial               | Ultimate Trial
  8 | premium_trial                | Premium Trial
  9 | opensource                   | Opensource
  4 | premium                      | Premium
  6 | ultimate                     | Ultimate
 10 | ultimate_trial_paid_customer | Ultimate Trial for Paid Customer
(10 rows)
```

On another cell, the `plans` table has differing ids for the same `name`:

```shell
 id |             name             |            title
----+------------------------------+------------------------------
  1 | default                      | Default
  2 | bronze                       | Bronze
  3 | silver                       | Silver
  4 | premium                      | Premium
  5 | gold                         | Gold
  6 | ultimate                     | Ultimate
  7 | ultimate_trial               | Ultimate Trial
  8 | ultimate_trial_paid_customer | Ultimate Trial Paid Customer
  9 | premium_trial                | Premium Trial
 10 | opensource                   | Opensource
 ```

This `plans.id` column is then used as a reference in the `hosted_plan_id`
column of `gitlab_subscriptions` table.

Solution: Use globally unique references, not a database sequence.
If possible, hard-code static data in application code, instead of using the
database.

In this case, the `plans` table can be dropped, and replaced with a fixed model
(details can be found in the [configurable status design doc](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items_custom_status/#fixed-items-models-and-associations)):

```ruby
class Plan
  include ActiveRecord::FixedItemsModel::Model

  ITEMS = [
    {:id=>1, :name=>"default", :title=>"Default"},
    {:id=>2, :name=>"bronze", :title=>"Bronze"},
    {:id=>3, :name=>"silver", :title=>"Silver"},
    {:id=>4, :name=>"premium", :title=>"Premium"},
    {:id=>5, :name=>"gold", :title=>"Gold"},
    {:id=>6, :name=>"ultimate", :title=>"Ultimate"},
    {:id=>7, :name=>"ultimate_trial", :title=>"Ultimate Trial"},
    {:id=>8, :name=>"ultimate_trial_paid_customer", :title=>"Ultimate Trial Paid Customer"},
    {:id=>9, :name=>"premium_trial", :title=>"Premium Trial"},
    {:id=>10, :name=>"opensource", :title=>"Opensource"}
  ]

  attribute :name, :string
  attribute :title, :string
end
```

You can use model validations and use ActiveRecord-like methods like `all`, `where`, `find_by` and `find`:

```ruby
Plan.find(4)
Plan.find_by(name: 'premium')
Plan.where(name: 'gold').first
```

The `hosted_plan_id` column will also be updated to refer to the fixed model's
`id` value.

You can also store associations with other models. For example:

```ruby
class CurrentStatus < ApplicationRecord
  belongs_to_fixed_items :system_defined_status, fixed_items_class: WorkItems::Statuses::SystemDefined::Status
end
```

Examples of hard-coding static data include:

- [VisibilityLevel](https://gitlab.com/gitlab-org/gitlab/-/blob/5ae43dface737373c50798ccd909174bcdd9b664/lib/gitlab/visibility_level.rb#L25-27)
- [Static defaults for work item statuses](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178180)
- [`Ai::Catalog::BuiltInTool`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197300)
- [`WorkItems::SystemDefined::RelatedLinkRestriction`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199664)

## Cells Routing

Coming soon, guide on how to route your request to your organization's cell.
