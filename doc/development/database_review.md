---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

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
- Changes to the database tooling. For example:
  - migration or ActiveRecord helpers in `lib/gitlab/database/`
  - load balancing
- Changes that produce SQL queries that are beyond the obvious. It is
  generally up to the author of a merge request to decide whether or
  not complex queries are being introduced and if they require a
  database review.
- Changes in Service Data metrics that use `count`, `distinct_count` and `estimate_batch_distinct_count`.
  These metrics could have complex queries over large tables.
  See the [Product Intelligence Guide](https://about.gitlab.com/handbook/product/product-intelligence-guide/)
  for implementation details.

A database reviewer is expected to look out for overly complex
queries in the change and review those closer. If the author does not
point out specific queries for review and there are no overly
complex queries, it is enough to concentrate on reviewing the
migration only.

### Required

The following artifacts are required prior to submitting for a ~database review.
If your merge request description does not include these items, the review will be reassigned back to the author.

If new migrations are introduced, in the MR **you are required to provide**:

- The output of both migrating (`db:migrate`) and rolling back (`db:rollback`) for all migrations.

If new queries have been introduced or existing queries have been updated, **you are required to provide**:

- [Query plans](#query-plans) for each raw SQL query included in the merge request along with the link to the query plan following each raw SQL snippet.
- [Raw SQL](#raw-sql) for all changed or added queries (as translated from ActiveRecord queries).
  - In case of updating an existing query, the raw SQL of both the old and the new version of the query should be provided together with their query plans.

Refer to [Preparation when adding or modifying queries](#preparation-when-adding-or-modifying-queries) for how to provide this information.

### Roles and process

A Merge Request **author**'s role is to:

- Decide whether a database review is needed.
- If database review is needed, add the ~database label.
- [Prepare the merge request for a database review](#how-to-prepare-the-merge-request-for-a-database-review).
- Provide the [required](#required) artifacts prior to submitting the MR.

A database **reviewer**'s role is to:

- Ensure the [required](#required) artifacts are provided and in the proper format. If they are not, reassign the merge request back to the author.
- Perform a first-pass review on the MR and suggest improvements to the author.
- Once satisfied, relabel the MR with ~"database::reviewed", approve it, and
  request a review from the database **maintainer** suggested by Reviewer
  Roulette. Remove yourself as a reviewer once this has been done.

A database **maintainer**'s role is to:

- Perform the final database review on the MR.
- Discuss further improvements or other relevant changes with the
  database reviewer and the MR author.
- Finally approve the MR and relabel the MR with ~"database::approved"
- Merge the MR if no other approvals are pending or pass it on to
  other maintainers as required (frontend, backend, docs).
  - If not merging, remove yourself as a reviewer.

### Distributing review workload

Review workload is distributed using [reviewer roulette](code_review.md#reviewer-roulette)
([example](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25181#note_147551725)).
The MR author should request a review from the suggested database
**reviewer**. When they give their sign-off, they will hand over to
the suggested database **maintainer**.

If reviewer roulette didn't suggest a database reviewer & maintainer,
make sure you have applied the ~database label and rerun the
`danger-review` CI job, or pick someone from the
[`@gl-database` team](https://gitlab.com/groups/gl-database/-/group_members).

### How to prepare the merge request for a database review

In order to make reviewing easier and therefore faster, please take
the following preparations into account.

#### Preparation when adding migrations

- Ensure `db/structure.sql` is updated as [documented](migration_style_guide.md#schema-changes), and additionally ensure that the relevant version files under
`db/schema_migrations` were added or removed.
- Make migrations reversible by using the `change` method or include a `down` method when using `up`.
  - Include either a rollback procedure or describe how to rollback changes.
- Add the output of both migrating (`db:migrate`) and rolling back (`db:rollback`) for all migrations into the MR description.
  - Ensure the down method reverts the changes in `db/structure.sql`.
  - Update the migration output whenever you modify the migrations during the review process.
- Add tests for the migration in `spec/migrations` if necessary. See [Testing Rails migrations at GitLab](testing_guide/testing_migrations_guide.md) for more details.
- When [high-traffic](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3) tables are involved in the migration, use the [`with_lock_retries`](migration_style_guide.md#retry-mechanism-when-acquiring-database-locks) helper method. Review the relevant [examples in our documentation](migration_style_guide.md#examples) for use cases and solutions.
- Ensure RuboCop checks are not disabled unless there's a valid reason to.
- When adding an index to a [large table](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3),
test its execution using `CREATE INDEX CONCURRENTLY` in the `#database-lab` Slack channel and add the execution time to the MR description:
  - Execution time largely varies between `#database-lab` and GitLab.com, but an elevated execution time from `#database-lab`
    can give a hint that the execution on GitLab.com will also be considerably high.
  - If the execution from `#database-lab` is longer than `1h`, the index should be moved to a [post-migration](post_deployment_migrations.md).
    Keep in mind that in this case you may need to split the migration and the application changes in separate releases to ensure the index
    will be in place when the code that needs it will be deployed.
- Trigger the [database testing](../architecture/blueprints/database_testing/index.md) job (`db:gitlabcom-database-testing`) in the `test` stage.
  - This job runs migrations in a production-like environment (similar to `#database_lab`) and posts to the MR its findings (queries, runtime, size change).
  - Review migration runtimes and any warnings.

#### Preparation when adding or modifying queries

##### Raw SQL

- Write the raw SQL in the MR description. Preferably formatted
  nicely with [pgFormatter](https://sqlformat.darold.net) or
  [paste.depesz.com](https://paste.depesz.com) and using regular quotes
  (e.g. `"projects"."id"`) and avoiding smart quotes (e.g. `“projects”.“id”`).
- In case of queries generated dynamically by using parameters, there should be one raw SQL query for each variation.

  For example, a finder for issues that may take as a parameter an optional filter on projects,
  should include both the version of the simple query over issues and the one that joins issues
  and projects and applies the filter.

  There are finders or other methods that can generate a very large amount of permutations.
  There is no need to exhaustively add all the possible generated queries, just the one with
  all the parameters included and one for each type of queries generated.

  For example, if joins or a group by clause are optional, the versions without the group by clause
  and with less joins should be also included, while keeping the appropriate filters for the remaining tables.

- If a query is going to be always used with a limit and an offset, those should always be
  included with the maximum allowed limit used and a non 0 offset.

##### Query Plans

- The query plan for each raw SQL query included in the merge request along with the link to the query plan following each raw SQL snippet.
- Provide a public link to the plan from either:
  - [postgres.ai](https://postgres.ai/): Follow the link in `#database-lab` and generate a shareable, public link
    by clicking the **Share** button in the upper right corner.
  - [explain.depesz.com](https://explain.depesz.com): Paste both the plan and the query used in the form.
- When providing query plans, make sure it hits enough data:
  - You can use a GitLab production replica to test your queries on a large scale,
  through the `#database-lab` Slack channel or through [ChatOps](understanding_explain_plans.md#chatops).
  - Usually, the `gitlab-org` namespace (`namespace_id = 9970`) and the
  `gitlab-org/gitlab-foss` (`project_id = 13083`) or the `gitlab-org/gitlab` (`project_id = 278964`)
   projects provide enough data to serve as a good example.
  - That means that no query plan should return 0 records or less records than the provided limit (if a limit is included). If a query is used in batching, a proper example batch with adequate included results should be identified and provided.
  - If your queries belong to a new feature in GitLab.com and thus they don't return data in production, it's suggested to analyze the query and to provide the plan from a local environment.
  - More information on how to find the number of actual returned records in [Understanding EXPLAIN plans](understanding_explain_plans.md)
- For query changes, it is best to provide both the SQL queries along with the
  plan _before_ and _after_ the change. This helps spot differences quickly.
- Include data that shows the performance improvement, preferably in
  the form of a benchmark.

#### Preparation when adding foreign keys to existing tables

- Include a migration to remove orphaned rows in the source table **before** adding the foreign key.
- Remove any instances of `dependent: ...` that may no longer be necessary.

#### Preparation when adding tables

- Order columns based on the [Ordering Table Columns](ordering_table_columns.md) guidelines.
- Add foreign keys to any columns pointing to data in other tables, including [an index](migration_style_guide.md#adding-foreign-key-constraints).
- Add indexes for fields that are used in statements such as `WHERE`, `ORDER BY`, `GROUP BY`, and `JOIN`s.

#### Preparation when removing columns, tables, indexes, or other structures

- Follow the [guidelines on dropping columns](avoiding_downtime_in_migrations.md#dropping-columns).
- Generally it's best practice (but not a hard rule) to remove indexes and foreign keys in a post-deployment migration.
  - Exceptions include removing indexes and foreign keys for small tables.
- If you're adding a composite index, another index might become redundant, so remove that in the same migration.
  For example adding `index(column_A, column_B, column_C)` makes the indexes `index(column_A, column_B)` and `index(column_A)` redundant.

### How to review for database

- Check migrations
  - Review relational modeling and design choices
  - Review migrations follow [database migration style guide](migration_style_guide.md),
    for example
    - [Check ordering of columns](ordering_table_columns.md)
    - [Check indexes are present for foreign keys](migration_style_guide.md#adding-foreign-key-constraints)
  - Ensure that migrations execute in a transaction or only contain
    concurrent index/foreign key helpers (with transactions disabled)
  - If an index to a large table is added and its execution time was elevated (more than 1h) on `#database-lab`:
    - Ensure it was added in a post-migration.
    - Maintainer: After the merge request is merged, notify Release Managers about it on `#f_upcoming_release` Slack channel.
  - Check consistency with `db/structure.sql` and that migrations are [reversible](migration_style_guide.md#reversibility)
  - Check that the relevant version files under `db/schema_migrations` were added or removed.
  - Check queries timing (If any): In a single transaction, cumulative query time executed in a migration
    needs to fit comfortably within `15s` - preferably much less than that - on GitLab.com.
  - For column removals, make sure the column has been [ignored in a previous release](avoiding_downtime_in_migrations.md#dropping-columns)
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
  - Depending on timing, data migrations can be placed on regular, post-deploy, or background migrations.
  - Data migrations should be reversible too or come with a description of how to reverse, when possible.
    This applies to all types of migrations (regular, post-deploy, background).
- Query performance
  - Check for any overly complex queries and queries the author specifically
    points out for review (if any)
  - If not present yet, ask the author to provide SQL queries and query plans
    (for example, by using [ChatOps](understanding_explain_plans.md#chatops) or direct
    database access)
  - For given queries, review parameters regarding data distribution
  - [Check query plans](understanding_explain_plans.md) and suggest improvements
    to queries (changing the query, schema or adding indexes and similar)
  - General guideline is for queries to come in below [100ms execution time](query_performance.md#timing-guidelines-for-queries)
  - Avoid N+1 problems and minimize the [query count](merge_request_performance_guidelines.md#query-counts).

### Timing guidelines for migrations

In general, migrations for a single deploy shouldn't take longer than
1 hour for GitLab.com. The following guidelines are not hard rules, they were
estimated to keep migration timing to a minimum.

NOTE:
Keep in mind that all runtimes should be measured against GitLab.com.

| Migration Type | Execution Time Recommended | Notes |
|----|----|---|
| Regular migrations on `db/migrate` | `3 minutes` | A valid exception are index creation as this can take a long time. |
| Post migrations on `db/post_migrate` | `10 minutes` | |
| Background migrations | --- | Since these are suitable for larger tables, it's not possible to set a precise timing guideline, however, any single query must stay below [`1 second` execution time](query_performance.md#timing-guidelines-for-queries) with cold caches. |
