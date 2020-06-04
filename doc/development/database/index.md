# Database guides

## Tooling

- [Understanding EXPLAIN plans](../understanding_explain_plans.md)
- [explain.depesz.com](https://explain.depesz.com/) or [explain.dalibo.com](https://explain.dalibo.com/) for visualizing the output of `EXPLAIN`
- [pgFormatter](http://sqlformat.darold.net/) a PostgreSQL SQL syntax beautifier

## Migrations

- [What requires downtime?](../what_requires_downtime.md)
- [SQL guidelines](../sql.md) for working with SQL queries
- [Migrations style guide](../migration_style_guide.md) for creating safe SQL migrations
- [Testing Rails migrations](../testing_guide/testing_migrations_guide.md) guide
- [Post deployment migrations](../post_deployment_migrations.md)
- [Background migrations](../background_migrations.md)
- [Swapping tables](../swapping_tables.md)
- [Deleting migrations](../deleting_migrations.md)

## Debugging

- Tracing the source of an SQL query using query comments with [Marginalia](../database_query_comments.md)
- Tracing the source of an SQL query in Rails console using [Verbose Query Logs](https://guides.rubyonrails.org/debugging_rails_applications.html#verbose-query-logs)

## Best practices

- [Adding database indexes](../adding_database_indexes.md)
- [Foreign keys & associations](../foreign_keys.md)
- [Adding a foreign key constraint to an existing column](add_foreign_key_to_existing_column.md)
- [Strings and the Text data type](strings_and_the_text_data_type.md)
- [Single table inheritance](../single_table_inheritance.md)
- [Polymorphic associations](../polymorphic_associations.md)
- [Serializing data](../serializing_data.md)
- [Hash indexes](../hash_indexes.md)
- [Storing SHA1 hashes as binary](../sha1_as_binary.md)
- [Iterating tables in batches](../iterating_tables_in_batches.md)
- [Insert into tables in batches](../insert_into_tables_in_batches.md)
- [Ordering table columns](../ordering_table_columns.md)
- [Verifying database capabilities](../verifying_database_capabilities.md)
- [Database Debugging and Troubleshooting](../database_debugging.md)
- [Query Count Limits](../query_count_limits.md)
- [Creating enums](../creating_enums.md)

## Case studies

- [Database case study: Filtering by label](../filtering_by_label.md)
- [Database case study: Namespaces storage statistics](../namespaces_storage_statistics.md)
