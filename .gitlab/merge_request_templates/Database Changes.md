Add a description of your merge request here. Merge requests without an adequate
description will not be reviewed until one is added.

## Database Checklist

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
- [ ] Added indexes for fields that are used in statements such as WHERE, ORDER BY, GROUP BY, and JOINs

When removing columns, tables, indexes or other structures:

- [ ] Removed these in a post-deployment migration
- [ ] Made sure the application no longer uses (or ignores) these structures

## General Checklist

- [ ] [Changelog entry](https://docs.gitlab.com/ee/development/changelog.html) added, if necessary
- [ ] [Documentation created/updated](https://docs.gitlab.com/ee/development/doc_styleguide.html)
- [ ] API support added
- [ ] Tests added for this feature/bug
- Review
  - [ ] Has been reviewed by Backend
  - [ ] Has been reviewed by Database
- [ ] Conform by the [merge request performance guides](https://docs.gitlab.com/ee/development/merge_request_performance_guidelines.html)
- [ ] Conform by the [style guides](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/CONTRIBUTING.md#style-guides)
- [ ] [Squashed related commits together](https://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
- [ ] Internationalization required/considered
- [ ] If paid feature, have we considered GitLab.com plan and how it works for groups and is there a design for promoting it to users who aren't on the correct plan
- [ ] End-to-end tests pass (`package-qa` manual pipeline job)
