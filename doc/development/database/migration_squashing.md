---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Migration Squashing
---

## Migration squashing

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105553) in GitLab 16.3.

{{< /history >}}

Migration squashing combines multiple database migrations into a single schema definition to improve database setup performance and maintain a manageable migration history.

## When to use migration squashing

Use migration squashing at the following times:

- At the start of each major release cycle
- After a required stop
- When the number of migrations has grown significantly (typically more than 200 migrations)

## Squash migrations

To squash migrations from a previous version (such as 16.10), run:

```shell
bundle exec rake "gitlab:db:squash[origin/16-10-stable-ee]"
```

This Rake task:

1. Removes all migrations from the previous version
1. Updates the schema version references in relevant files
1. Cleans up finalized batched background migrations

### Parameters

| Parameter | Description |
|-----------|-------------|
| `[origin/16-10-stable-ee]` | The Git reference to use as a baseline for migration squashing. This should be the stable branch of the previous version. |

## Update CI configuration for database rollbacks

After squashing the migrations, we need to update the migration version used in the CI job that tests migration rollbacks.

To find the first migration version after the `InitSchema` migration, run:

```shell
bundle exec rake db:migrate:status | grep '^\s*up' | awk 'NR==2 {print $2}'
```

Update [the CI script](https://gitlab.com/gitlab-org/gitlab/-/blob/6fff0bc1bbe823af4b7bf6dc093c5a131897797b/.gitlab/ci/database.gitlab-ci.yml#L97) with this version.

## Troubleshooting

### Missing schema references

If you encounter errors related to missing schema references, check:

- Migration spec files that might reference old migrations
- Background migration files that might need manual updates
- Documentation that references specific migration versions

## Related documentation

- [Migration style guide](../migration_style_guide.md)
- [Required stops](required_stops.md)
