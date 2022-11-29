---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Database Dictionary

This page documents the database schema for GitLab, so data analysts and other groups can
locate the feature categories responsible for specific database tables.

## Location

Database dictionary metadata files are stored in the `gitlab` project under `db/docs/` for the `main` and `ci` databases.
For the `geo` database, the dictionary files are stored under `ee/db/docs/`.

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
```

## Schema

| Attribute                  | Type          | Required | Description                                                                       |
|----------------------------|---------------|----------|-----------------------------------------------------------------------------------|
| `table_name` / `view_name` | String        | yes      | Database table name or view name                                                  |
| `classes`                  | Array(String) | no       | List of classes that are associated to this table or view.                        |
| `feature_categories`       | Array(String) | yes      | List of feature categories using this table or view.                              |
| `description`              | String        | no       | Text description of the information stored in the table or view, and its purpose. |
| `introduced_by_url`        | URL           | no       | URL to the merge request or commit which introduced this table or view.           |
| `milestone`                | String        | no       | The milestone that introduced this table or view.                                 |

## Adding tables

When adding a new table, create a new file under `db/docs/` for the `main` and `ci` databases.
For the `geo` database use `ee/db/docs/`.
Name the file as `<table_name>.yml`, containing as much information as you know about the table.

Include this file in the commit with the migration that creates the table.

## Dropping tables

When dropping a table, you must remove the metadata file from `db/docs/` for `main` and `ci` databases.
For the `geo` database, you must remove the file from `ee/db/docs/`.
Use the same commit with the migration that drops the table.

## Adding views

When adding a new view, you should:

1. Create a new file for this view in the appropriate directory:
   - `main` database: `db/docs/views/`
   - `ci` database: `db/docs/views/`
   - `geo` database: `ee/db/docs/views/`
1. Name the file `<view_name>.yml`, and include as much information as you know about the view.
1. Include this file in the commit with the migration that creates the view.

## Dropping views

When dropping a view, you must remove the metadata file from `db/docs/views/`.
For the `geo` database, you must remove the file from `ee/db/docs/views/`.
Use the same commit with the migration that drops the view.
