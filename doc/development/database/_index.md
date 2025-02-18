---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database development guidelines
---

## Database Reviews

- During the design phase of the feature you're working on, be mindful if you are adding any database-related changes. If you're adding or modifying a query, start looking at the `explain` plan early to avoid surprises late in the review phase.
- If, at any time, you need help optimizing a query or understanding an `explain` plan, ask for assistance in `#database`.
- If you're creating a database MR for review, check out our [Database review guidelines](../database_review.md).

  It provides an introduction on database-related changes, migrations, and complex SQL queries.

- If you're a database reviewer or want to become one, check out our [introduction to reviewing database changes](database_reviewer_guidelines.md).

## Tooling

- [Understanding EXPLAIN plans](understanding_explain_plans.md)
- [explain.depesz.com](https://explain.depesz.com/) or [explain.dalibo.com](https://explain.dalibo.com/) for visualizing the output of `EXPLAIN`
- [pgFormatter](https://sqlformat.darold.net/) a PostgreSQL SQL syntax beautifier
- [db:check-migrations job](dbcheck-migrations-job.md)
- [Database migration pipeline](database_migration_pipeline.md)

## Migrations

- [Adding required stops](required_stops.md)
- [Avoiding downtime in migrations](avoiding_downtime_in_migrations.md)
- [Batched background migrations guidelines](batched_background_migrations.md)
- [Create a regular migration](../migration_style_guide.md#create-a-regular-schema-migration), including creating new models
- [Deleting migrations](deleting_migrations.md)
- [Different types of migrations](../migration_style_guide.md#choose-an-appropriate-migration-type)
- [Migrations for multiple databases](migrations_for_multiple_databases.md)
- [Migrations style guide](../migration_style_guide.md) for creating safe SQL migrations
- [Partitioning tables](partitioning/_index.md)
- [Post-deployment migrations guidelines](post_deployment_migrations.md) and [how to create one](post_deployment_migrations.md#creating-migrations)
- [Running database migrations](database_debugging.md#migration-wrangling)
- [SQL guidelines](../sql.md) for working with SQL queries
- [Swapping tables](swapping_tables.md)
- [Testing Rails migrations](../testing_guide/testing_migrations_guide.md) guide
- [When and how to write Rails migrations tests](../testing_guide/testing_migrations_guide.md)
- [Deduplicate database records](deduplicate_database_records.md)

## Partitioning tables

- [Overview](partitioning/_index.md)
- [Date range](partitioning/date_range.md)
- [Hash](partitioning/hash.md)
- [Int range](partitioning/int_range.md)
- [List](partitioning/list.md)

## Debugging

- [Accessing the database](database_debugging.md#manually-access-the-database)
- [Resetting the database](database_debugging.md#delete-everything-and-start-over)
- [Troubleshooting and debugging the database](database_debugging.md)
- Tracing the source of an SQL query:
  - In Rails console using [Verbose Query Logs](https://guides.rubyonrails.org/debugging_rails_applications.html#verbose-query-logs)
  - Using query comments with [Marginalia](database_query_comments.md)

## Best practices

- [Adding database indexes](adding_database_indexes.md)
- [Adding a foreign key constraint to an existing column](add_foreign_key_to_existing_column.md)
- [Check for background migrations before upgrading](../../update/background_migrations.md)
- [Client-side connection-pool](client_side_connection_pool.md)
- [Constraints naming conventions](constraint_naming_convention.md)
- [Creating enums](creating_enums.md)
- [Data layout and access patterns](layout_and_access_patterns.md)
- [Efficient `IN` operator queries](efficient_in_operator_queries.md)
- [Foreign keys & associations](foreign_keys.md)
- [Hash indexes](hash_indexes.md)
- [Insert into tables in batches](insert_into_tables_in_batches.md)
- [Batching guidelines](batching_best_practices.md)
- [Iterating tables in batches](iterating_tables_in_batches.md)
- [Load balancing](load_balancing.md)
- [`NOT NULL` constraints](not_null_constraints.md)
- [Ordering table columns](ordering_table_columns.md)
- [Pagination guidelines](pagination_guidelines.md)
  - [Pagination performance guidelines](pagination_performance_guidelines.md)
  - [Offset pagination optimization](offset_pagination_optimization.md)
- [Polymorphic associations](polymorphic_associations.md)
- [Query count limits](query_count_limits.md)
- [Query performance guidelines](query_performance.md)
- [Serializing data](serializing_data.md)
- [Single table inheritance](single_table_inheritance.md)
- [Storing SHA1 hashes as binary](sha1_as_binary.md)
- [Strings and the Text data type](strings_and_the_text_data_type.md)
- [Updating multiple values](setting_multiple_values.md)
- [Verifying database capabilities](verifying_database_capabilities.md)

## Case studies

- [Database case study: Filtering by label](filtering_by_label.md)
- [Database case study: Namespaces storage statistics](namespaces_storage_statistics.md)

## PostgreSQL information for GitLab administrators

- [Configure GitLab using an external PostgreSQL service](../../administration/postgresql/external.md)
- [Configuring PostgreSQL for scaling](../../administration/postgresql/_index.md)
- [Database Load Balancing](../../administration/postgresql/database_load_balancing.md)
- [Moving GitLab databases to a different PostgreSQL instance](../../administration/postgresql/moving.md)
- [Replication and failover with Omnibus GitLab](../../administration/postgresql/replication_and_failover.md)
- [Standalone PostgreSQL using Omnibus GitLab](../../administration/postgresql/standalone.md)
- [Troubleshooting PostgreSQL](../../administration/troubleshooting/postgresql.md)
- [Working with the bundled PgBouncer service](../../administration/postgresql/pgbouncer.md)

## User information for scaling

For GitLab administrators, information about
[configuring PostgreSQL for scaling](../../administration/postgresql/_index.md) is available,
including the major methods:

- [Standalone PostgreSQL](../../administration/postgresql/standalone.md)
- [External PostgreSQL instances](../../administration/postgresql/external.md)
- [Replication and failover](../../administration/postgresql/replication_and_failover.md)

## ClickHouse

- [Introduction](clickhouse/_index.md)
- [ClickHouse within GitLab](clickhouse/clickhouse_within_gitlab.md)
- [Optimizing query execution](clickhouse/optimization.md)
- [Rebuild GitLab features using ClickHouse 1: Activity data](clickhouse/gitlab_activity_data.md)
- [Rebuild GitLab features using ClickHouse 2: Merge Request analytics](clickhouse/merge_request_analytics.md)
- [Tiered Storage in ClickHouse](clickhouse/tiered_storage.md)

## Miscellaneous

- [Maintenance operations](maintenance_operations.md)
- [Update multiple database objects](setting_multiple_values.md)
- [Batch iteration in a tree hierarchy proof of concept](poc_tree_iterator.md)
- [Scalability Patterns](scalability/patterns/_index.md)
