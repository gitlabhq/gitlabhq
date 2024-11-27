---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content.
---

# Large tables limitations

GitLab implements some limitations on large database tables to improve manageability for both GitLab and its customers. The list of tables subject to these limitations is defined in [`rubocop/rubocop-migrations.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml).

## Table size restrictions

The following limitations apply to table modifications on GitLab.com:

| Action | Maximum size (including indexes) |
| ------ | ------------------------------- |
| Add an index | 50 GB |
| Add a column with foreign key | 50 GB |
| Add a new column | 100 GB |

These limitations align with our goal to maintain [all tables under 100 GB](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_size_limits/) for improved [stability and performance](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_size_limits/#motivation-gitlabcom-stability-and-performance).

## Exceptions

Exceptions to these size limitations should only granted for the following cases:

- Migrate a table's columns from `int4` to `int8`
- Add a sharding key to support cells
- Modify a table to assist in partitioning or data retention efforts
- Replace an existing index to provide better query performance

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

## Related links

- [Database size limits](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_size_limits/#solutions)
- [Adding database indexes](adding_database_indexes.md)
- [Database layout and access patterns](layout_and_access_patterns.md#data-model-trade-offs)
