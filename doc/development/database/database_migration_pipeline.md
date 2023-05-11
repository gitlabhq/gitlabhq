---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Database migration pipeline

> [Introduced](https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/171) in GitLab 14.2.

With the [automated migration testing pipeline](https://gitlab.com/gitlab-org/database-team/gitlab-com-database-testing)
we can automatically test migrations in a production-like environment (using [Database Lab](database_lab.md)).
It is based on an [architecture blueprint](../../architecture/blueprints/database_testing/index.md).

Migration testing is enabled in the [GitLab project](https://gitlab.com/gitlab-org/gitlab)
for changes that add a new database migration. Trigger this job manually by running the
`db:gitlabcom-database-testing` job within in `test` stage. To avoid wasting resources,
only run this job when your MR is ready for review. Additionally, ensure that the MR has the "database" label for the pipeline to appear in the test stage.

The job starts a pipeline on the [ops GitLab instance](https://ops.gitlab.net/).
For security reasons, access to the pipeline is restricted to database maintainers.

When the pipeline starts, a bot notifies you with a comment in the merge request.
When it finishes, the comment gets updated with the test results.

The comment contains testing information for both the `main` and `ci` databases.
Each database tested has four sections which are described below.

## Summary

The first section of the comment contains a summary of the test results, including:

- **Warnings** - Highlights critical issues such as exceptions or long-running queries.
- **Migrations** - The time each migration took to complete, whether it was successful,
  and the increment in the size of the database.
- **Runtime histogram** - Expand this section to see a histogram of query runtimes across all migrations.

## Migration details

The next section of the comment contains detailed information for each migration, including:

- **Details** - The type of migration, total duration, and database size change.
- **Queries** - Every query executed during the migration, along with the number of
  calls, timings, and the number of the changed rows.
- **Runtime histogram** - Indicates the distribution of query times for the migration.

## Background migration details

The next section of the comment contains detailed information about each batched background migration, including:

- **Sampling information** - The number of batches sampled during this test run.
  Sampled batches are chosen uniformly across the table's ID range. Sampling runs
  for 30 minutes, split evenly across each background migration to test.
- **Aggregated query information** - Aggregate data about each query executed across
  all the sampled batches, along with the number of calls, timings, and the number of changed rows.
- **Batch runtime histogram** - A histogram of timings for each sampled batch
  from the background migration.
- **Query runtime histogram** - A histogram of timings for all queries executed
  in any batch of this background migration.

## Clone details and artifacts

Some additional information is included at the bottom of the comment:

- **Migrations pending on GitLab.com** - A summary of migrations not deployed yet
  to GitLab.com. This information is useful when testing a migration that was merged
  but not deployed yet.
- **Clone details** - A link to the `Postgres.ai` thin clone created for this
  testing pipeline, along with information about its expiry. This can be used to
  further explore the results of running the migration. Only accessible by
  database maintainers or with an access request.
- **Artifacts** - A link to the pipeline's artifacts. Full query logs for each
  migration (ending in `.log`) are available there, and only accessible by
  database maintainers or with an access request. Details of the specific
  batched background migration batches sampled are also available.
