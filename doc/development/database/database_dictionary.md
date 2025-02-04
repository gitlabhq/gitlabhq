---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database Dictionary
---

This page documents the database schema for GitLab, so data analysts and other groups can
locate the feature categories responsible for specific database tables.

## Location

Database dictionary metadata files are stored in the `gitlab` project under `db/docs/` for the `main`, `ci`, and `sec` databases.
For the `embedding` database, the dictionary files are stored under `ee/db/embedding/docs/`.
For the `geo` database, the dictionary files are stored under `ee/db/geo/docs/`.

## Example dictionary file

```yaml
---
table_name: terraform_states
classes:
- Terraform::State
feature_categories:
- infrastructure_as_code
description: Represents a Terraform state backend
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26619
milestone: '13.0'
gitlab_schema: gitlab_main
table_size: small
```

## Adding tables

### Schema

| Attribute                  | Type          | Required | Description |
|----------------------------|---------------|----------|-------------|
| `table_name`               | String        | yes      | Database table name. |
| `classes`                  | Array(String) | no       | List of classes that are associated to this table. |
| `feature_categories`       | Array(String) | yes      | List of feature categories using this table. |
| `description`              | String        | no       | Text description of the information stored in the table, and its purpose. |
| `introduced_by_url`        | URL           | no       | URL to the merge request or commit which introduced this table. |
| `milestone`                | String        | yes      | The milestone that introduced this table. |
| `gitlab_schema`            | String        | yes      | GitLab schema name. |
| `notes`                    | String        | no       | Use for comments, as Psych cannot parse YAML comments. |
| `table_size`               | String        | yes      | Classification of _current_ table size on GitLab.com[^1]. The size includes indexes. For partitioned tables, the size is the size of the largest partition. Valid options are `unknown`, `small` (< 10 GB), `medium` (< 50 GB), `large` (< 100 GB), `over_limit` (above 100 GB). |

[^1] New tables are usually `small` by default as they contain no data. This attribute is updated automatically monthly.

### Process

When adding a table, you should:

1. Create a new file for this table in the appropriate directory:
   - `gitlab_main` table: `db/docs/`
   - `gitlab_ci` table: `db/docs/`
   - `gitlab_sec` table: `db/docs/`
   - `gitlab_shared` table: `db/docs/`
   - `gitlab_embedding` table: `ee/db/embedding/docs/`
   - `gitlab_geo` table: `ee/db/geo/docs/`
1. Name the file `<table_name>.yml`, and include as much information as you know about the table.
1. Include this file in the commit with the migration that creates the table.

## Dropping tables

### Schema

| Attribute                  | Type          | Required | Description |
|----------------------------|---------------|----------|-------------|
| `table_name`               | String        | yes      | Database table name. |
| `classes`                  | Array(String) | no       | List of classes that are associated to this table. |
| `feature_categories`       | Array(String) | yes      | List of feature categories using this table. |
| `description`              | String        | no       | Text description of the information stored in the table, and its purpose. |
| `introduced_by_url`        | URL           | no       | URL to the merge request or commit which introduced this table. |
| `milestone`                | String        | no       | The milestone that introduced this table. |
| `gitlab_schema`            | String        | yes      | GitLab schema name. |
| `removed_by_url`           | String        | yes      | URL to the merge request or commit which removed this table. |
| `removed_in_milestone`     | String        | yes      | The milestone that removes this table. |

### Process

When dropping a table, you should:

1. Move the dictionary file for this table to the `deleted_tables` directory:
   - `gitlab_main` table: `db/docs/deleted_tables/`
   - `gitlab_ci` table: `db/docs/deleted_tables/`
   - `gitlab_sec` table: `db/docs/deleted_tables/`
   - `gitlab_shared` table: `db/docs/deleted_tables/`
   - `gitlab_embedding` table: `ee/db/embedding/docs/deleted_tables/`
   - `gitlab_geo` table: `ee/db/geo/docs/deleted_tables/`
1. Add the fields `removed_by_url` and `removed_in_milestone` to the dictionary file.
1. Include this change in the commit with the migration that drops the table.

## Adding views

### Schema

| Attribute                  | Type          | Required | Description |
|----------------------------|---------------|----------|-------------|
| `table_name`               | String        | yes      | Database view name. |
| `classes`                  | Array(String) | no       | List of classes that are associated to this view. |
| `feature_categories`       | Array(String) | yes      | List of feature categories using this view. |
| `description`              | String        | no       | Text description of the information stored in the view, and its purpose. |
| `introduced_by_url`        | URL           | no       | URL to the merge request or commit which introduced this view. |
| `milestone`                | String        | no       | The milestone that introduced this view. |
| `gitlab_schema`            | String        | yes      | GitLab schema name. |

### Process

When adding a new view, you should:

1. Create a new file for this view in the appropriate directory:
   - `gitlab_main` view: `db/docs/views/`
   - `gitlab_ci` view: `db/docs/views/`
   - `gitlab_sec` view: `db/docs/views/`
   - `gitlab_shared` view: `db/docs/views/`
   - `gitlab_embedding` view: `ee/db/embedding/docs/views/`
   - `gitlab_geo` view: `ee/db/geo/docs/views/`
1. Name the file `<view_name>.yml`, and include as much information as you know about the view.
1. Include this file in the commit with the migration that creates the view.

## Dropping views

## Schema

| Attribute                  | Type          | Required | Description |
|----------------------------|---------------|----------|-------------|
| `view_name`                | String        | yes      | Database view name. |
| `classes`                  | Array(String) | no       | List of classes that are associated to this view. |
| `feature_categories`       | Array(String) | yes      | List of feature categories using this view. |
| `description`              | String        | no       | Text description of the information stored in the view, and its purpose. |
| `introduced_by_url`        | URL           | no       | URL to the merge request or commit which introduced this view. |
| `milestone`                | String        | no       | The milestone that introduced this view. |
| `gitlab_schema`            | String        | yes      | GitLab schema name. |
| `removed_by_url`           | String        | yes      | URL to the merge request or commit which removed this view. |
| `removed_in_milestone`     | String        | yes      | The milestone that removes this view. |

### Process

When dropping a view, you should:

1. Move the dictionary file for this table to the `deleted_views` directory:
   - `gitlab_main` view: `db/docs/deleted_views/`
   - `gitlab_ci` view: `db/docs/deleted_views/`
   - `gitlab_sec` view: `db/docs/deleted_views/`
   - `gitlab_shared` view: `db/docs/deleted_views/`
   - `gitlab_embedding` view: `ee/db/embedding/docs/deleted_views/`
   - `gitlab_geo` view: `ee/db/geo/docs/deleted_views/`
1. Add the fields `removed_by_url` and `removed_in_milestone` to the dictionary file.
1. Include this change in the commit with the migration that drops the view.
