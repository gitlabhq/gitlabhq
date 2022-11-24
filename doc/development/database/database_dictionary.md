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

| Attribute            | Type          | Required | Description                                                              |
|----------------------|---------------|----------|--------------------------------------------------------------------------|
| `table_name`         | String        | yes      | Database table name                                                      |
| `classes`            | Array(String) | no       | List of classes that respond to `.table_name` with the `table_name`      |
| `feature_categories` | Array(String) | yes      | List of feature categories using this table                              |
| `description`        | String        | no       | Text description of the information stored in the table and it's purpose |
| `introduced_by_url`  | URL           | no       | URL to the merge request or commit which introduced this table           |
| `milestone`          | String        | no       | The milestone that introduced this table                                 |

## Adding tables

When adding a new table, create a new file under `db/docs/` for the `main` and `ci` databases.
For the `geo` database use `ee/db/docs/`.
Name the file as `<table_name>.yml`, containing as much information as you know about the table.

Include this file in the commit with the migration that creates the table.

## Dropping tables

When dropping a table, you must remove the metadata file from `db/docs/` for `main` and `ci` databases.
For the `geo` database, you must remove the file from `ee/db/docs/`.
Use the same commit with the migration that drops the table.
