### Verify Before Flagging

When a diff modifies or replaces an existing structure, always verify the current state from an
authoritative source before flagging a discrepancy. Never infer the pre-change state solely from
diff context — check the actual source of truth. For example:

- **Migration `down` methods**: verify the `down` schema against the actual pre-migration schema by
  querying the local ClickHouse database (`SHOW CREATE TABLE tablename`) or, if unavailable, reading
  the schema from the base branch (`git show master:db/click_house/main.sql`). Compare
  column-by-column: names, types, defaults, engine, primary key, ORDER BY, and SETTINGS.
- **Table recreation** (`DROP TABLE IF EXISTS` + `CREATE TABLE`): verify the old table definition
  the same way before claiming columns or settings are missing.

### Schema Migration Files

- Files in `db/click_house/schema_migrations/` are auto-generated and do not require a newline at the end — do not flag missing newlines
