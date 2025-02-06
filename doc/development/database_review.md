---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database Review Guidelines
---

This page is specific to database reviews. Refer to our
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
- Changes in Service Data metrics that use `count`, `distinct_count`, `estimate_batch_distinct_count` and `sum`.
  These metrics could have complex queries over large tables.
  See the [Analytics Instrumentation Guide](https://handbook.gitlab.com/handbook/product/product-processes/analytics-instrumentation-guide/)
  for implementation details.
- Changes that use [`update`, `upsert`, `delete`, `update_all`, `upsert_all`, `delete_all` or `destroy_all`](#preparation-when-using-bulk-update-operations)
  methods on an ActiveRecord object.

A database reviewer is expected to look out for overly complex
queries in the change and review those closer. If the author does not
point out specific queries for review and there are no overly
complex queries, it is enough to concentrate on reviewing the
migration only.

### Required

You must provide the following artifacts when you request a ~database review.
If your merge request description does not include these items, the review is reassigned back to the author.

#### Migrations

If new migrations are introduced, database reviewers must review the output of both migrating (`db:migrate`)
and rolling back (`db:rollback`) for all migrations.

We have automated tooling for
[GitLab](https://gitlab.com/gitlab-org/gitlab) (provided by the
[`db:check-migrations`](database/dbcheck-migrations-job.md) pipeline job) that provides this output in the CI job logs.
It is not required for the author to provide this output in the merge request description,
but doing so may be helpful for reviewers. The bot also checks that migrations are correctly
reversible.

#### Queries

If new queries have been introduced or existing queries have been updated, **you are required to provide**:

- [Query plans](#query-plans) for each raw SQL query included in the merge request along with the link to the query plan following each raw SQL snippet.
- [Raw SQL](#raw-sql) for all changed or added queries (as translated from ActiveRecord queries).
  - In case of updating an existing query, the raw SQL of both the old and the new version of the query should be provided together with their query plans.

Refer to [Preparation when adding or modifying queries](#preparation-when-adding-or-modifying-queries) for how to provide this information.

### Roles and process

A merge request **author**'s role is to:

- Decide whether a database review is needed.
- If database review is needed, add the `~database` label.
- [Prepare the merge request for a database review](#how-to-prepare-the-merge-request-for-a-database-review).
- Provide the [required](#required) artifacts prior to submitting the MR.

A database **reviewer**'s role is to:

- Ensure the [required](#required) artifacts are provided and in the proper format. If they are not, reassign the merge request back to the author.
- Perform a first-pass review on the MR and suggest improvements to the author.
- Once satisfied, relabel the MR with ~"database::reviewed", approve it, and
  request a review from the database **maintainer** suggested by Reviewer
  Roulette.

A database **maintainer**'s role is to:

- Perform the final database review on the MR.
- Discuss further improvements or other relevant changes with the
  database reviewer and the MR author.
- Finally approve the MR and relabel the MR with ~"database::approved"
- Merge the MR if no other approvals are pending or pass it on to
  other maintainers as required (frontend, backend, documentation).

### Distributing review workload

Review workload is distributed using [reviewer roulette](code_review.md#reviewer-roulette)
([example](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25181#note_147551725)).
The MR author should request a review from the suggested database
**reviewer**. When they sign off, they hand over to
the suggested database **maintainer**.

If reviewer roulette didn't suggest a database reviewer & maintainer,
make sure you have applied the `~database` label and rerun the
`danger-review` CI job, or pick someone from the
[`@gl-database` team](https://gitlab.com/groups/gl-database/-/group_members).

### How to prepare the merge request for a database review

To make reviewing easier and therefore faster, take
the following preparations into account.

#### Preparation when adding migrations

- Ensure `db/structure.sql` is updated as [documented](migration_style_guide.md#schema-changes), and additionally ensure that the relevant version files under
  `db/schema_migrations` were added or removed.
- Ensure that the Database Dictionary is updated as [documented](database/database_dictionary.md).
- Make migrations reversible by using the `change` method or include a `down` method when using `up`.
  - Include either a rollback procedure or describe how to rollback changes.
- Check that the [`db:check-migrations`](database/dbcheck-migrations-job.md) pipeline job has run successfully and the migration rollback behaves as expected.
  - Ensure the `db:check-schema` job has run successfully and no unexpected schema changes are introduced in a rollback. This job may only trigger a warning if the schema was changed.
  - Verify that the previously mentioned jobs continue to succeed whenever you modify the migrations during the review process.
- Add tests for the migration in `spec/migrations` if necessary. See [Testing Rails migrations at GitLab](testing_guide/testing_migrations_guide.md) for more details.
- [Lock retries](migration_style_guide.md#retry-mechanism-when-acquiring-database-locks) are enabled by default for all transactional migrations. For non-transactional migrations review the relevant [documentation](migration_style_guide.md#usage-with-non-transactional-migrations) for use cases and solutions.
- Ensure RuboCop checks are not disabled unless there's a valid reason to.
- When adding an index to a [large table](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3),
  test its execution using `CREATE INDEX CONCURRENTLY` in [Database Lab](database/database_lab.md) and add the execution time to the MR description:
  - Execution time largely varies between Database Lab and GitLab.com, but an elevated execution time from Database Lab
    can give a hint that the execution on GitLab.com is also considerably high.
  - If the execution from Database Lab is longer than `10 minutes`, the [index](database/adding_database_indexes.md) should be moved to a [post-migration](database/post_deployment_migrations.md).
    Keep in mind that in this case you may need to split the migration and the application changes in separate releases to ensure the index
    is in place when the code that needs it is deployed.
- Manually trigger the [database testing](database/database_migration_pipeline.md) job (`db:gitlabcom-database-testing`) in the `test` stage.
  - This job runs migrations in a [Database Lab](database/database_lab.md) clone and posts to the MR its findings (queries, runtime, size change).
  - Review migration runtimes and any warnings.

#### Preparation when adding data migrations

Data migrations are inherently risky. Additional actions are required to reduce the possibility
of error that would result in corruption or loss of production data.

Include in the MR description:

- If the migration itself is not reversible, details of how data changes could be reverted in the event of an incident. For example, in the case of a migration that deletes records (an operation that most of the times is not automatically reversible), how _could_ the deleted records be recovered.
- If the migration deletes data, apply the label `~data-deletion`.
- Concise descriptions of possible user experience impact of an error; for example, "Issues would unexpectedly go missing from Epics".
- Relevant data from the [query plans](#query-plans) that indicate the query works as expected; such as the approximate number of records that are modified or deleted.

#### Preparation when adding or modifying queries

##### Raw SQL

- Write the raw SQL in the MR description. Preferably formatted
  nicely with [pgFormatter](https://sqlformat.darold.net) or
  <https://paste.depesz.com> and using regular quotes
  (for example, `"projects"."id"`) and avoiding smart quotes (for example, `“projects”.“id”`).
- In case of queries generated dynamically by using parameters, there should be one raw SQL query for each variation.

  For example, a finder for issues that may take as a parameter an optional filter on projects,
  should include both the version of the query over issues and the one that joins issues
  and projects and applies the filter.

  There are finders or other methods that can generate a very large amount of permutations.
  There is no need to exhaustively add all the possible generated queries, just the one with
  all the parameters included and one for each type of queries generated.

  For example, if joins or a group by clause are optional, the versions without the group by clause
  and with less joins should be also included, while keeping the appropriate filters for the remaining tables.

- If a query is always used with a limit and an offset, those should always be
  included with the maximum allowed limit used and a non 0 offset.

##### Query Plans

- The query plan for each raw SQL query included in the merge request along with the link to the query plan following each raw SQL snippet.
- Provide a link to the plan generated using the `explain` command in the [postgres.ai](database/database_lab.md) chatbot. The `explain` command runs
  `EXPLAIN ANALYZE`.
  - If it's not possible to get an accurate picture in Database Lab, you may need to
    seed a development environment, and instead provide output
    from `EXPLAIN ANALYZE`. Create links to the plan using [explain.depesz.com](https://explain.depesz.com) or [explain.dalibo.com](https://explain.dalibo.com). Be sure to paste both the plan and the query used in the form.
- When providing query plans, make sure it hits enough data:
  - To produce a query plan with enough data, you can use the IDs of:
    - The `gitlab-org` namespace (`namespace_id = 9970`), for queries involving a group.
    - The `gitlab-org/gitlab-foss` (`project_id = 13083`) or the `gitlab-org/gitlab` (`project_id = 278964`) projects, for queries involving a project.
      - For queries involving membership of projects, `project_namespace_id` of these projects may be required to create a query plan. These are `15846663` (for `gitlab-org/gitlab`) and `15846626` (for `gitlab-org/gitlab-foss`)
    - The `gitlab-qa` user (`user_id = 1614863`), for queries involving a user.
      - Optionally, you can also use your own `user_id`, or the `user_id` of a user with a long history within the project or group being used to generate the query plan.
  - That means that no query plan should return 0 records or less records than the provided limit (if a limit is included). If a query is used in batching, a proper example batch with adequate included results should be identified and provided.

    NOTE: The `UPDATE` statement always returns 0 records. To identify the rows it updates, we need to check the following lines below.

    For example, the `UPDATE` statement returns 0 records, but we can see that it updates 1 row from the line starting with `-> Index scan`.:

    ```sql
    EXPLAIN UPDATE p_ci_pipelines SET updated_at = current_timestamp WHERE id = 1606117348;

     ModifyTable on public.p_ci_pipelines  (cost=0.58..3.60 rows=0 width=0) (actual time=5.977..5.978 rows=0 loops=1)
      Buffers: shared hit=339 read=4 dirtied=4
      WAL: records=20 fpi=4 bytes=21800
      I/O Timings: read=4.920 write=0.000
      ->  Index Scan using ci_pipelines_pkey on public.ci_pipelines p_ci_pipelines_1  (cost=0.58..3.60 rows=1 width=18) (actual time=0.041..0.044 rows=1 loops=1)
            Index Cond: (p_ci_pipelines_1.id = 1606117348)
            Buffers: shared hit=8
            I/O Timings: read=0.000 write=0.000
    ```

  - If your queries belong to a new feature in GitLab.com and thus they don't return data in production:
    - You may analyze the query and to provide the plan from a local environment.
    - [postgres.ai](https://postgres.ai/) allows updates to data (`exec UPDATE issues SET ...`) and creation of new tables and columns (`exec ALTER TABLE issues ADD COLUMN ...`).
  - More information on how to find the number of actual returned records in [Understanding EXPLAIN plans](database/understanding_explain_plans.md)
- For query changes, it is best to provide both the SQL queries along with the
  plan _before_ and _after_ the change. This helps spot differences quickly.
- Include data that shows the performance improvement, preferably in
  the form of a benchmark.
- When evaluating a query plan, we need the final query to be
  executed against the database. We don't need to analyze the intermediate
  queries returned as `ActiveRecord::Relation` from finders and scopes.
  PostgreSQL query plans are dependent on all the final parameters,
  including limits and other things that may be added before final execution.
  One way to be sure of the actual query executed is to check
  `log/development.log`.

#### Preparation when adding foreign keys to existing tables

- Include a migration to remove orphaned rows in the source table **before** adding the foreign key.
- Remove any instances of `dependent: ...` that may no longer be necessary.

#### Preparation when adding tables

- Order columns based on the [Ordering Table Columns](database/ordering_table_columns.md) guidelines.
- Add foreign keys to any columns pointing to data in other tables, including [an index](migration_style_guide.md#adding-foreign-key-constraints).
- Add indexes for fields that are used in statements such as `WHERE`, `ORDER BY`, `GROUP BY`, and `JOIN`s.
- New tables must be seeded by a file in `db/fixtures/development/`. These fixtures are also used
  to ensure that [upgrades complete successfully](database/dbmigrate_multi_version_upgrade_job.md),
  so it's important that new tables are always populated.
- New tables and columns are not necessarily risky, but over time some access patterns are inherently
  difficult to scale. To identify these risky patterns in advance, we must document expectations for
  access and size. Include in the MR description answers to these questions:
  - What is the anticipated growth for the new table over the next 3 months, 6 months, 1 year? What assumptions are these based on?
  - How many reads and writes per hour would you expect this table to have in 3 months, 6 months, 1 year? Under what circumstances are rows updated? What assumptions are these based on?
  - Based on the anticipated data volume and access patterns, does the new table pose an availability risk to GitLab.com or GitLab Self-Managed instances? Does the proposed design scale to support the needs of GitLab.com and GitLab Self-Managed customers?

#### Preparation when removing columns, tables, indexes, or other structures

- Follow the [guidelines on dropping columns](database/avoiding_downtime_in_migrations.md#dropping-columns).
- Generally it's best practice (but not a hard rule) to remove indexes and foreign keys in a post-deployment migration.
  - Exceptions include removing indexes and foreign keys for small tables.
- If you're adding a composite index, another index might become redundant, so remove that in the same migration.
  For example adding `index(column_A, column_B, column_C)` makes the indexes `index(column_A, column_B)` and `index(column_A)` redundant.

#### Preparation when using bulk update operations

Using `update`, `upsert`, `delete`, `update_all`, `upsert_all`, `delete_all` or `destroy_all`
ActiveRecord methods requires extra care because they modify data and can perform poorly, or they
can destroy data if improperly scoped. These methods are also
[incompatible with Common Table Expression (CTE) statements](sql.md#when-to-use-common-table-expressions).
Danger will comment on a merge request diff when these methods are used.

Follow documentation for [preparation when adding or modifying queries](#preparation-when-adding-or-modifying-queries)
to add the raw SQL query and query plan to the merge request description, and request a database review.

### How to review for database

- Check migrations
  - Review relational modeling and design choices
    - Consider [access patterns and data layout](database/layout_and_access_patterns.md) if new tables or columns are added.
  - Review migrations follow [database migration style guide](migration_style_guide.md),
    for example
    - [Check ordering of columns](database/ordering_table_columns.md)
    - [Check indexes are present for foreign keys](migration_style_guide.md#adding-foreign-key-constraints)
  - Ensure that migrations execute in a transaction or only contain
    concurrent index/foreign key helpers (with transactions disabled)
  - If an index to a large table is added and its execution time was elevated (more than 1h) on [Database Lab](database/database_lab.md):
    - Ensure it was added in a post-migration.
    - Maintainer: After the merge request is merged, notify Release Managers about it on `#f_upcoming_release` Slack channel.
  - Check consistency with `db/structure.sql` and that migrations are [reversible](migration_style_guide.md#reversibility)
  - Check that the relevant version files under `db/schema_migrations` were added or removed.
  - Check queries timing (If any): In a single transaction, cumulative query time executed in a migration
    needs to fit comfortably in `15s` - preferably much less than that - on GitLab.com.
  - For column removals, make sure the column has been [ignored in a previous release](database/avoiding_downtime_in_migrations.md#dropping-columns)
- Check [batched background migrations](database/batched_background_migrations.md):
  - Establish a time estimate for execution on GitLab.com. For historical purposes,
    it's highly recommended to include this estimation on the merge request description.
    This can be the number of expected batches times the delay interval.
  - Manually trigger the [database testing](database/database_migration_pipeline.md) job (`db:gitlabcom-database-testing`) in the `test` stage.
  - If a single `update` is below than `1s` the query can be placed
    directly in a regular migration (inside `db/migrate`).
  - Background migrations are usually used, but not limited to:
    - Migrating data in larger tables.
    - Making numerous SQL queries per record in a dataset.
  - Review queries (for example, make sure batch sizes are fine)
  - Because execution time can be longer than for a regular migration,
    it's suggested to treat background migrations as
    [post migrations](migration_style_guide.md#choose-an-appropriate-migration-type):
    place them in `db/post_migrate` instead of `db/migrate`.
- Check [timing guidelines for migrations](migration_style_guide.md#how-long-a-migration-should-take)
- Check migrations are reversible and implement a `#down` method
- Check new table migrations:
  - Are the stated access patterns and volume reasonable? Do the assumptions they're based on seem sound? Do these patterns pose risks to stability?
  - Are the columns [ordered to conserve space](database/ordering_table_columns.md)?
  - Are there foreign keys for references to other tables?
  - Does the table have a fixture in `db/fixtures/development/`?
- Check data migrations:
  - Establish a time estimate for execution on GitLab.com.
  - Depending on timing, data migrations can be placed on regular, post-deploy, or background migrations.
  - Data migrations should be reversible too or come with a description of how to reverse, when possible.
    This applies to all types of migrations (regular, post-deploy, background).
- Query performance
  - Check for any overly complex queries and queries the author specifically
    points out for review (if any)
  - If not present, ask the author to provide SQL queries and query plans
    using [Database Lab](database/database_lab.md)
  - For given queries, review parameters regarding data distribution
  - [Check query plans](database/understanding_explain_plans.md) and suggest improvements
    to queries (changing the query, schema or adding indexes and similar)
  - General guideline is for queries to come in below [100ms execution time](database/query_performance.md#timing-guidelines-for-queries)
  - Avoid N+1 problems and minimize the [query count](merge_request_concepts/performance.md#query-counts).

### Useful tips

- If you often find yourself applying and reverting migrations from a specific branch, you might want to try out
[`scripts/database/migrate.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/database/migrate.rb)
to make this process more efficient.
