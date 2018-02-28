Remove this section and replace it with a description of your MR. Also follow the
checklist below and check off any tasks that are done. If a certain task can not
be done you should explain so in the MR body. You are free to remove any
sections that do not apply to your MR.

When gathering statistics (e.g. the output of `EXPLAIN ANALYZE`) you should make
sure your database has enough data. Having around 10 000 rows in the tables
being queries should provide a reasonable estimate of how a query will behave.
Also make sure that PostgreSQL uses the following settings:

* `random_page_cost`: `1`
* `work_mem`: `16MB`
* `maintenance_work_mem`: at least `64MB`
* `shared_buffers`: at least `256MB`

If you have access to GitLab.com's staging environment you should also run your
measurements there, and include the results in this MR.

## Database Checklist

When adding migrations:

- [ ] Updated `db/schema.rb`
- [ ] Added a `down` method so the migration can be reverted
- [ ] Added the output of the migration(s) to the MR body
- [ ] Added the execution time of the migration(s) to the MR body
- [ ] Added tests for the migration in `spec/migrations` if necessary (e.g. when
  migrating data)
- [ ] Made sure the migration won't interfere with a running GitLab cluster,
  for example by disabling transactions for long running migrations

When adding or modifying queries to improve performance:

- [ ] Included the raw SQL queries of the relevant queries
- [ ] Included the output of `EXPLAIN ANALYZE` and execution timings of the
  relevant queries
- [ ] Added tests for the relevant changes

When adding indexes:

- [ ] Described the need for these indexes in the MR body
- [ ] Made sure existing indexes can not be reused instead

When adding foreign keys to existing tables:

- [ ] Included a migration to remove orphaned rows in the source table
- [ ] Removed any instances of `dependent: ...` that may no longer be necessary

When adding tables:

- [ ] Ordered columns based on their type sizes in descending order
- [ ] Added foreign keys if necessary
- [ ] Added indexes if necessary

When removing columns, tables, indexes or other structures:

- [ ] Removed these in a post-deployment migration
- [ ] Made sure the application no longer uses (or ignores) these structures

## General Checklist

- [ ] [Changelog entry](https://docs.gitlab.com/ce/development/changelog.html) added, if necessary
- [ ] [Documentation created/updated](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/development/doc_styleguide.md)
- [ ] API support added
- [ ] Tests added for this feature/bug
- Review
  - [ ] Has been reviewed by UX
  - [ ] Has been reviewed by Frontend
  - [ ] Has been reviewed by Backend
  - [ ] Has been reviewed by Database
- [ ] Conform by the [merge request performance guides](http://docs.gitlab.com/ce/development/merge_request_performance_guidelines.html)
- [ ] Conform by the [style guides](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#style-guides)
- [ ] [Squashed related commits together](https://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
