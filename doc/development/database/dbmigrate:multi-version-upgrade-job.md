---
stage: Data Stores
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# db:migrate:multi-version-upgrade job

> - [Introduced](https://gitlab.com/groups/gitlab-org/quality/quality-engineering/-/epics/19) in GitLab 16.11.

This job runs on the test stage of a merge request pipeline. It validates that migrations pass
for multi-version upgrade from the latest [required upgrade stop](../../update/index.md#required-upgrade-stops)
to the author's working branch. It achieves it by running `gitlab:db:configure` against PostgreSQL
dump created from the latest known [GitLab version stop](../../update/index.md#upgrade-paths) with test data.

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

### Database import failures

If job is failing on setup stage prior to `gitlab:db:configure`
due to external dependencies, the job can be disabled by setting
`DISABLE_DB_MULTI_VERSION_UPGRADE=true` in GitLab project CI variables
to unblock the [broken master](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master).

Reach out to [Self-Managed Platform team](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/self-managed-platform-team/) to expedite debugging.
