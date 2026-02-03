---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Migration Squashing
---

## Migration squashing

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105553) in GitLab 16.3.
- [Automated](https://gitlab.com/gitlab-org/gitlab/-/work_items/438587) in GitLab 18.9.

{{< /history >}}

Migration squashing combines multiple database migrations into a single schema definition to improve database setup performance and maintain a manageable migration history.

## Automation

Migration squashing is automated through `GitLab Housekeeper`. The [`Keeps::SquashMigrations`](https://gitlab.com/gitlab-org/gitlab/-/blob/d00a116c765eb7968d925dbd86bf8ca6e21c300b/keeps/squash_migrations.rb) keep creates MRs automatically at scheduled milestones.

The automation runs via a [scheduled pipeline job](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/blob/main/.gitlab-ci.yml#L153-164) in the Engineering Productivity team's CI configuration.

### Schedule

Squashing occurs at milestones ending in `.2`, `.5`, `.8`, and `.11`. These align with [required stops](required_stops.md).

The target branch is two required stops prior to the current milestone:

| Current milestone | Squashes up to |
|-------------------|----------------|
| X.2 | (X-1).8 |
| X.5 | (X-1).11 |
| X.8 | X.2 |
| X.11 | X.5 |

For example, at the 18.8 required stop, migrations are squashed up to `origin/18-2-stable-ee`.

## Manual execution

To squash migrations manually from a previous version (such as 16.10), run:

```shell
bundle exec rake "gitlab:db:squash[origin/16-10-stable-ee]"
```

This Rake task:

1. Removes all migrations from the previous version
1. Updates `db/init_structure.sql` with the squashed schema
1. Updates schema version references in relevant files
1. Removes associated migration specs and RuboCop TODOs
1. Cleans up finalized batched background migrations

### Parameters

| Parameter | Description |
|-----------|-------------|
| `[origin/16-10-stable-ee]` | The Git reference to use as a baseline for migration squashing. This should be the stable branch of the target version. |

## Troubleshooting

### Missing schema references

If you encounter errors related to missing schema references, check:

- Migration spec files that might reference old migrations
- Background migration files that might need manual updates
- Documentation that references specific migration versions

## Related documentation

- [Migration style guide](../migration_style_guide.md)
- [Required stops](required_stops.md)
