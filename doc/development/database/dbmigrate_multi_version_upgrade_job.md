---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'db:migrate:multi-version-upgrade job'
---

> - [Introduced](https://gitlab.com/groups/gitlab-org/quality/quality-engineering/-/epics/19) in GitLab 16.11.

This job runs on the test stage of a merge request pipeline. It validates that migrations pass
for multi-version upgrade from the latest [required upgrade stop](../../update/upgrade_paths.md)
to the author's working branch. It achieves it by running `gitlab:db:configure` against PostgreSQL
dump created from the latest known [GitLab version stop](../../update/upgrade_paths.md) with test data.

The database dump is generated and maintained with [PostgreSQL Dump Generator](https://gitlab.com/gitlab-org/quality/pg-dump-generator).
To seed database with data, the tool uses Data Seeder with [`bulk_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/seeds/data_seeder/bulk_data.rb)
configuration to seed all factories and uses `db:seed_fu` to seed all [`db/fixtures`](../development_seed_files.md).
Latest dump is generated automatically in scheduled pipelines for the latest patch
release of the required stop.

## Troubleshooting

### Database reconfigure failures

This failure usually happens due to an actual migration error in your working branch.
To reproduce the failure locally follow [Migration upgrade testing](https://gitlab.com/gitlab-org/quality/pg-dump-generator#migration-upgrade-testing)
guidance. It outlines the steps how to import the latest PostgreSQL dump
in your local GitLab Development Kit or GitLab Docker instance.

For a real-life example, refer to
[this failed job](https://gitlab.com/gitlab-org/gitlab/-/jobs/6418619509#L4970).

#### Broken master

When a new required upgrade stop is added (every three or four milestones), it triggers the build of a new PostgreSQL Dump.
In some cases, this might cause the `db:migrate:multi-version-upgrade` job to fail in `master` pipeline.
For example, if new additional tables are seeded, it helps detect migration errors that might have been missed in older dumps without these seeded tables.

Workflow for the [broken master](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master) case:

1. Identify the root cause MR by searching for the migration that caused the error. For instance, [`db/migrate/20240416123401_add_security_policy_management_project_id_to_security_policies.rb` in failing job](https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/6671417979#L1547)
   - Debug locally if needed as described in the [Database reconfigure failures](#database-reconfigure-failures)
1. Reach out to the relevant team that introduced the migration to discuss whether the MR should be reverted or if a fix will be worked on
   - If the team isn't available, post about it in the `#database` Slack channel
1. While a fix or revert is being worked on, `master` pipeline can be unblocked by disabling the job temporarily by setting `DISABLE_DB_MULTI_VERSION_UPGRADE=true` in [CI/CD Settings page](https://gitlab.com/gitlab-org/gitlab/-/settings/ci_cd)
   - When disabling the job, announce it in the `#master-broken` Slack channel
1. Add a note to [job stability tracking issue#458402](https://gitlab.com/gitlab-org/gitlab/-/issues/458402)
1. Reinstate the job by removing `DISABLE_DB_MULTI_VERSION_UPGRADE` from CI/CD Settings

### Database import failures

If job is failing on setup stage prior to `gitlab:db:configure`
due to external dependencies, the job can be disabled by setting
`DISABLE_DB_MULTI_VERSION_UPGRADE=true` in GitLab project CI variables
to unblock the [broken master](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master).

Reach out to [Self-Managed Platform team](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/self-managed-platform-team/) to expedite debugging.
