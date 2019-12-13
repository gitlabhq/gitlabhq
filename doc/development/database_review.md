# Database Review Guidelines

This page is specific to database reviews. Please refer to our
[code review guide](code_review.md) for broader advice and best
practices for code review in general.

## General process

A database review is required for:

- Changes that touch the database schema or perform data migrations,
  including files in:
  - `db/`
  - `lib/gitlab/background_migration/`
- Changes to the database tooling, e.g.:
  - migration or ActiveRecord helpers in `lib/gitlab/database/`
  - load balancing
- Changes that produce SQL queries that are beyond the obvious. It is
  generally up to the author of a merge request to decide whether or
  not complex queries are being introduced and if they require a
  database review.

A database reviewer is expected to look out for obviously complex
queries in the change and review those closer. If the author does not
point out specific queries for review and there are no obviously
complex queries, it is enough to concentrate on reviewing the
migration only.

It is preferable to review queries in SQL form and generally accepted
to ask the author to translate any ActiveRecord queries in SQL form
for review.

### Roles and process

A Merge Request author's role is to:

- Decide whether a database review is needed.
- If database review is needed, add the ~database label.
- Use the [database changes](https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab/merge_request_templates/Database%20changes.md)
  merge request template, or include the appropriate items in the MR description.
- [Prepare the merge request for a database review](#how-to-prepare-the-merge-request-for-a-database-review).

A database **reviewer**'s role is to:

- Perform a first-pass review on the MR and suggest improvements to the author.
- Once satisfied, relabel the MR with ~"database::reviewed", approve it, and
  reassign MR to the database **maintainer** suggested by Reviewer
  Roulette.

#### When there are no database maintainers available

Currently we have a [critical shortage of database maintainers](https://gitlab.com/gitlab-org/gitlab/issues/29717). Until we are able to increase the number of database maintainers to support the volume of reviews, we have implemented this temporary solution. If the database **reviewer** cannot find an available database **maintainer** then:

1. Assign the MR for a second review by a **database trainee maintainer** for further review.
1. Once satisfied with the review process, and if the database **maintainer** is still not available, skip the database maintainer approval step and assign the merge request to a backend maintainer for final review and approval.

A database **maintainer**'s role is to:

- Perform the final database review on the MR.
- Discuss further improvements or other relevant changes with the
  database reviewer and the MR author.
- Finally approve the MR and relabel the MR with ~"database::approved"
- Merge the MR if no other approvals are pending or pass it on to
  other maintainers as required (frontend, backend, docs).

### Distributing review workload

Review workload is distributed using [reviewer roulette](code_review.md#reviewer-roulette)
([example](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/25181#note_147551725)).
The MR author should then co-assign the suggested database
**reviewer**. When they give their sign-off, they will hand over to
the suggested database **maintainer**.

If reviewer roulette didn't suggest a database reviewer & maintainer,
make sure you have applied the ~database label and rerun the
`danger-review` CI job, or pick someone from the
[`@gl-database` team](https://gitlab.com/groups/gl-database/-/group_members).

### How to prepare the merge request for a database review

In order to make reviewing easier and therefore faster, please consider preparing a comment
and details for a database reviewer:

- Provide queries in SQL form rather than ActiveRecord.
- Format any queries with a SQL query formatter, for example with [sqlformat.darold.net](http://sqlformat.darold.net).
- Consider providing query plans via a link to [explain.depesz.com](https://explain.depesz.com) or another tool instead of textual form.
- For query changes, it is best to provide the SQL query along with a plan *before* and *after* the change. This helps to spot differences quickly.
- When providing query plans, make sure to use good parameter values, so that the query executed is a good example and also hits enough data.
  - Usually, the `gitlab-org` namespace (`namespace_id = 9970`) and the `gitlab-org/gitlab-foss` (`project_id = 13083`) or the `gitlab-org/gitlab` (`project_id = 278964`) projects provide enough data to serve as a good example.

### How to review for database

- Check migrations
  - Review relational modeling and design choices
  - Review migrations follow [database migration style guide](migration_style_guide.md),
    for example
    - [Check ordering of columns](ordering_table_columns.md)
    - [Check indexes are present for foreign keys](migration_style_guide.md#adding-foreign-key-constraints)
  - Ensure that migrations execute in a transaction or only contain
    concurrent index/foreign key helpers (with transactions disabled)
  - Check consistency with `db/schema.rb` and that migrations are [reversible](migration_style_guide.md#reversibility)
  - Check queries timing (If any): Queries executed in a migration
    need to fit comfortably within `15s` - preferably much less than that - on GitLab.com.
  - For column removals, make sure the column has been [ignored in a previous release](what_requires_downtime.md#dropping-columns)
- Check [background migrations](background_migrations.md):
  - Establish a time estimate for execution on GitLab.com. For historical purposes,
    it's highly recommended to include this estimation on the merge request description.
  - If a single `update` is below than `1s` the query can be placed
      directly in a regular migration (inside `db/migrate`).
  - Background migrations are normally used, but not limited to:
    - Migrating data in larger tables.
    - Making numerous SQL queries per record in a dataset.
  - Review queries (for example, make sure batch sizes are fine)
  - Because execution time can be longer than for a regular migration,
    it's suggested to treat background migrations as post migrations:
    place them in `db/post_migrate` instead of `db/migrate`. Keep in mind
    that post migrations are executed post-deployment in production.
- Check [timing guidelines for migrations](#timing-guidelines-for-migrations)
- Check migrations are reversible and implement a `#down` method
- Check data migrations:
  - Establish a time estimate for execution on GitLab.com.
  - Depending on timing, data migrations can be placed on regular, post-deploy or background migrations.
  - Data migrations should be reversible too or come with a description of how to reverse, when possible.
    This applies to all types of migrations (regular, post-deploy, background).
- Query performance
  - Check for any obviously complex queries and queries the author specifically
    points out for review (if any)
  - If not present yet, ask the author to provide SQL queries and query plans
    (e.g. by using [chatops](understanding_explain_plans.md#chatops) or direct
    database access)
  - For given queries, review parameters regarding data distribution
  - [Check query plans](understanding_explain_plans.md) and suggest improvements
    to queries (changing the query, schema or adding indexes and similar)
  - General guideline is for queries to come in below 100ms execution time
  - If queries rely on prior migrations that are not present yet on production
    (eg indexes, columns), you can use a [one-off instance from the restore
    pipeline](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd)
    in order to establish a proper testing environment.

### Timing guidelines for migrations

In general, migrations for a single deploy shouldn't take longer than
1 hour for GitLab.com. The following guidelines are not hard rules, they were
estimated to keep migration timing to a minimum.

NOTE: **Note:** Keep in mind that all runtimes should be measured against GitLab.com.

| Migration Type | Execution Time Recommended | Notes |
|----|----|---|
| Regular migrations on `db/migrate` | `3 minutes` | A valid exception  are index creation as this can take a long time. |
| Post migrations on `db/post_migrate` | `10 minutes` | |
| Background migrations | --- | Since these are suitable for larger tables, it's not possible to set a precise timing guideline, however, any query must stay well below `10s` of execution time. |
