### Process Reminders

- Ask: "Have you triggered the `db:gitlabcom-database-testing` pipeline?"
- For new or modified queries: raw SQL and query plans should be documented in the MR description
- For creating or dropping tables/views: ensure the Database Dictionary is updated
- Flag all modified or new ActiveRecord scopes as needing a database reviewer

### Verify Before Flagging

When a diff modifies or replaces an existing structure, always verify the current state from an
authoritative source before flagging a discrepancy. Never infer the pre-change state solely from
diff context — check the actual source of truth. For example:

- **Migration `down` methods**: verify the `down` schema against the actual pre-migration schema by
  querying the local PostgreSQL database (`\d tablename`) or, if unavailable, reading the schema
  from the base branch (`git show master:db/structure.sql`).
- **Table or column modifications**: verify what currently exists before claiming something was lost
  or changed incorrectly.
