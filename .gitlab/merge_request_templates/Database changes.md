Add a description of your merge request here. Merge requests without an adequate
description will not be reviewed until one is added.

## Database checklist

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

## General checklist

- [ ] [Changelog entry](https://docs.gitlab.com/ee/development/changelog.html) added, if necessary
- [ ] [Documentation created/updated](https://docs.gitlab.com/ee/development/documentation/index.html#contributing-to-docs)
- [ ] [API support added](https://docs.gitlab.com/ee/development/api_styleguide.html)
- [ ] [Tests added for this feature/bug](https://docs.gitlab.com/ee/development/testing_guide/index.html)
- Conforms to the [code review guidelines](https://docs.gitlab.com/ee/development/code_review.html)
  - [ ] Has been reviewed by a Backend [maintainer](https://about.gitlab.com/handbook/engineering/#maintainer)
  - [ ] Has been reviewed by a Database [specialist](https://about.gitlab.com/team/structure/#specialist)
- [ ] Conforms to the [merge request performance guidelines](https://docs.gitlab.com/ee/development/merge_request_performance_guidelines.html)
- [ ] Conforms to the [style guides](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/CONTRIBUTING.md#style-guides)
- [ ] If you have multiple commits, please combine them into a few logically organized commits by [squashing them](https://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
- [ ] [Internationalization required/considered](https://docs.gitlab.com/ee/development/i18n/index.html)
- [ ] For a paid feature, have we considered GitLab.com plans, how it works for groups, and is there a design for promoting it to users who aren't on the correct plan?
- [ ] [End-to-end tests](https://docs.gitlab.com/ee/development/testing_guide/end_to_end_tests.html#testing-code-in-merge-requests) pass (`package-and-qa` manual pipeline job)

/label ~database
