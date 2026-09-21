### Schema Location

- The database schema is stored as SQL in `db/structure.sql` (there is no `db/schema.rb`); grep it for table definitions and column constraints.

### Index Removal

- Before removing an index, verify queries can use other existing indexes efficiently
- Confirm the index is unused on GitLab.com and Self-Managed
- For investigating index usage, check Grafana dashboards for index usage data
