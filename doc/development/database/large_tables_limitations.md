---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content.
title: Large tables limitations
---

GitLab enforces some limitations on large database tables schema changes to improve manageability for both GitLab and its customers. The list of tables subject to these limitations is defined in [`rubocop/rubocop-migrations.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml).

## Table size restrictions

The following limitations apply to table schema changes on GitLab.com:

| Limitation | Maximum size after the action (including indexes and column size) |
| ------ | ------------------------------- |
| Can not add an index | 50 GB |
| Can not add a column with foreign key | 50 GB |
| Can not add a new column | 100 GB |

These limitations align with our goal to maintain [all tables under 100 GB](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_size_limits/) for improved [stability and performance](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_size_limits/#motivation-gitlabcom-stability-and-performance).

## Exceptions

Exceptions to these size limitations should only granted for the following cases:

- Migrate a table's columns from `int4` to `int8`
- Add a sharding key to support cells
- Modify a table to assist in partitioning or data retention efforts
- Replace an existing index to provide better query performance

### Requesting an exception

To request an exception to these limitations:

1. Create a new issue using the [Database Team Tasks template](https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/new?issuable_template=schema_change_exception)
1. Select the `schema_change_exception` template
1. Provide detailed justification for why your case requires an exception
1. Wait for review and approval from the Database team before proceeding
1. Link the approval issue when disabling the cop for your migration

## Techniques to reduce table size

Before requesting an exception, consider these approaches to manage table size:

### Archiving data

- Move old, infrequently accessed data to archive tables
- Implement archiving workers for automated data migration
- Consider using partitioning by date to facilitate archiving, see [date range partitioning](partitioning/date_range.md)

### Data retention

- Implement retention policies to remove old data
- Configure automated cleanup jobs for expired data, see [deleting old pipelines](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171142)

### Table partitioning

- [Partition large tables by date](scalability/patterns/time_decay.md#time-decay-data-strategies), ID ranges, or other criteria
- Consider [range](partitioning/date_range.md) or [list](partitioning/list.md) partitioning based on access patterns

### Column optimization

- Use appropriate data types (for example, `smallint` instead of `integer` when possible)
- Remove unused or redundant indexes
- Consider using `NULL` instead of empty strings or zeros
- Use `text` instead of `varchar` to [avoid storage overhead](ordering_table_columns.md)

### Normalization

- Split large tables into related smaller tables
- Move rarely used columns to [separate tables](layout_and_access_patterns.md#data-model-trade-offs)
- Use junction tables for many-to-many relationships
- Consider vertical partitioning for [wide tables](layout_and_access_patterns.md#wide-tables)

### External storage

- Move large text or binary data to object storage
- Store only metadata in the database
- Use [Elasticsearch](../../user/search/advanced_search.md) for search-specific data
- Consider using Redis for temporary or cached data

## Alternatives to table modifications

Consider these alternatives when working with large tables:

1. Creates a separate table for new columns, especially if the column is not present in all rows. The new table references the original table through a foreign key.
1. Work with the Global Search team to add your data to Elasticsearch for enhanced filter/search functionality.
1. Simplify filtering/sorting options (for example, use `id` instead of `created_at` for sorting).

## Benefits of table size limitations

Table size limitations provide several advantages:

- Enable separate vacuum operations with different frequencies
- Generate less Write-Ahead Log (WAL) data for column updates
- Prevent unnecessary data copying during row updates

For more information about data model trade-offs, see the [database documentation](layout_and_access_patterns.md#data-model-trade-offs).

## Using `has_one` relationships

When a table becomes too large for new columns, create a new table with a `has_one` relation. For example, in [merge request !170371](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170371), we track the total weight count of an issue in a separate table.

Benefits of this approach:

1. Keeps the main table narrower, reducing data load from PostgreSQL
1. Creates an efficient narrow table for specific queries
1. Allows selective population of the new table as needed

This approach is particularly effective when:

- The new column applies to a subset of the main table
- Only specific queries need the new data

Disadvantages

1. More tables may result in more "joins" which will complicate queries
1. Queries with multiple joins may end up being hard to optimize

## Related links

- [Database size limits](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_size_limits/#solutions)
- [Adding database indexes](adding_database_indexes.md)
- [Database layout and access patterns](layout_and_access_patterns.md#data-model-trade-offs)
