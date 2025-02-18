---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database migration pipeline
---

With the [automated migration testing pipeline](https://gitlab.com/gitlab-org/database-team/gitlab-com-database-testing)
we can automatically test migrations in a production-like environment (using [Database Lab](database_lab.md)).
It is based on an [architecture design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/database_testing/).

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

### Database size increase

Occasionally, a migration shows a +8.00 KiB size increase, even if the migration was not
expected to result in a size increase. Completing any migration adds a row to the
`schema_migrations` table, which may require a new disk page to be created.
If a new disk page is created, the size of the database will grow by exactly 8 KiB.

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

## Test changes to the database testing pipeline

To test a change to the database testing pipeline itself, you need:

1. A merge request against GitLab Org.
1. The change to be tested must be present on a branch on GitLab Ops.

Use this self-documented script to test a merge request on GitLab Org against an arbitrary branch on GitLab Ops:

```shell
#! /usr/bin/env bash

# The following must be set on a per-invocation basis:
TESTING_TRIGGER_TOKEN='[REDACTED]'              # Testing trigger token created in the CI section of the project
CI_COMMIT_REF_NAME='55-post-notice-on-failure'  # The branch on ops that you want to run against
CI_MERGE_REQUEST_IID='117901'                   # Merge request ID of the MR on gitlab.com that you want to test
SHA="fed6dd8a58d75a0e053a4972765b4fc08c5814a3"  # The commit SHA of the HEAD of the branch you want to test on gitlab-org/gitlab

# The following should not be changed between invocations:
CI_JOB_URL='https://gitlab.com/gitlab-org/database-team/gitlab-com-database-testing/-/jobs/1590162939'
# It doesn't appear that CI_JOB_URL has to be set to anything in particular for the pipeline to run
# successfully, but this would normally be the URL to the upstream job that invokes the DB testing pipeline.
CI_MERGE_REQUEST_PROJECT_ID='278964'    # gitlab-org/gitlab numeric ID. Shouldn't change.
CI_PROJECT_ID="gitlab-org/gitlab"       # The slug identifying gitlab-org/gitlab.

curl --verbose --request POST \
     --form "token=$TESTING_TRIGGER_TOKEN" \
     --form "ref=$CI_COMMIT_REF_NAME" \
     --form "variables[TOP_UPSTREAM_MERGE_REQUEST_IID]=$CI_MERGE_REQUEST_IID" \
     --form "variables[TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID]=$CI_MERGE_REQUEST_PROJECT_ID" \
     --form "variables[TOP_UPSTREAM_SOURCE_JOB]=$CI_JOB_URL" \
     --form "variables[TOP_UPSTREAM_SOURCE_PROJECT]=$CI_PROJECT_ID" \
     --form "variables[VALIDATION_PIPELINE]=true" \
     --form "variables[GITLAB_COMMIT_SHA]=$SHA" \
     --form "variables[TRIGGER_SOURCE]=$CI_JOB_URL" \
     "https://ops.gitlab.net/api/v4/projects/429/trigger/pipeline"
```
