# Using this at GitLab

- Targets: `gitlab-production-main` (main DB) and `gitlab-production-ci` (CI DB); `gitlab-production-registry` for container-registry queries. Other
  databases are listed by `postgresai projects`; skip `*-deprecated` entries.
- Pick the target by table ownership, not by whether `describe` or `plan` succeeds: main holds
  empty copies of some CI tables (e.g. partitioned `p_ci_*`), so plans there look cheap and
  are wrong. `ci_*` and `p_ci_*` tables belong on `gitlab-production-ci`. The source of truth is
  `gitlab_schema` in `db/docs/<table>.yml` in the GitLab repo (`gitlab_ci` means the CI DB).
- Docs: [Database Lab](https://docs.gitlab.com/development/database/database_lab/#use-the-postgresai-cli).
- Local GDK databases: use the `gitlab-psql` skill instead; this skill is for production-sized data.
- Before requesting a database review: [db-review-flow.md](db-review-flow.md).
