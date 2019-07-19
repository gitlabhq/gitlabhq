## What does this MR do?

<!--
Describe in detail what your merge request does, why it does that, etc. Merge
requests without an adequate description will not be reviewed until one is
added.

Please also keep this description up-to-date with any discussion that takes
place so that reviewers can understand your intent. This is especially
important if they didn't participate in the discussion.

Make sure to remove this comment when you are done.
-->

Add a description of your merge request here.

## Database checklist

- [ ] Conforms to the [database guides](https://docs.gitlab.com/ee/development/README.html#database-guides)

When adding migrations:

- [ ] Updated `db/schema.rb`
- [ ] Added a `down` method so the migration can be reverted
- [ ] Added the output of the migration(s) to the MR body
- [ ] Added tests for the migration in `spec/migrations` if necessary (e.g. when migrating data)

When adding or modifying queries to improve performance:

- [ ] Included data that shows the performance improvement, preferably in the form of a benchmark
- [ ] Included the output of `EXPLAIN (ANALYZE, BUFFERS)` of the relevant queries

When adding foreign keys to existing tables:

- [ ] Included a migration to remove orphaned rows in the source table before adding the foreign key
- [ ] Removed any instances of `dependent: ...` that may no longer be necessary

When adding tables:

- [ ] Ordered columns based on the [Ordering Table Columns](https://docs.gitlab.com/ee/development/ordering_table_columns.html#ordering-table-columns) guidelines
- [ ] Added foreign keys to any columns pointing to data in other tables
- [ ] Added indexes for fields that are used in statements such as `WHERE`, `ORDER BY`, `GROUP BY`, and `JOIN`s

When removing columns, tables, indexes or other structures:

- [ ] Removed these in a post-deployment migration
- [ ] Made sure the application no longer uses (or ignores) these structures

/label ~database ~"database::review pending"
