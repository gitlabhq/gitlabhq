# Before requesting a database review

Maps to GitLab's [database review guidelines](https://docs.gitlab.com/development/database_review/).

1. **List the queries** the change adds or modifies (watch for N+1).
   - CI: the `rspec:merge-auto-explain-logs` job in the MR pipeline records the queries the
     specs run with their plans, and shows which are new compared with the default branch.
   - Locally: load an `ActiveSupport::Notifications` subscriber on `sql.active_record` (for
     example with `rspec -r`) that logs distinct statements, or read `log/test.log`.
2. **Plan each one** on the clone: `joe plan`, then `joe explain` with realistic
   parameters (large project or namespace, not an empty one).
3. **Fix what's slow**: apply the loop in [plan-analysis.md](plan-analysis.md).
4. **Migrations**: test new indexes with `joe exec` (+ `ANALYZE`), then `joe reset`. Check them
   against the [migration guidelines](https://docs.gitlab.com/development/migration_style_guide/)
   (concurrent index creation, naming, need). Time limits for queries and migrations are in the
   database review docs above.
5. **Write up in the MR**: for each query, the SQL, a shareable plan link, and timing/buffers.
   Get the link from the Database Lab console session history, or paste the plan into
   explain.depesz.com or explain.dalibo.com (sanitized first). CLI command IDs are not console URLs.
   Replace real values with placeholders; no production data.
6. Request the review with that evidence attached.
