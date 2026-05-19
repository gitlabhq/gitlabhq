### ActiveRecord Scopes

- New or modified scopes should have appropriate indexes for filtered columns
- Scopes should avoid expensive operations like subqueries on large tables
- Default scopes are avoided unless absolutely necessary (they can cause unexpected query behavior)

### Partitioned Tables

- Leverage partition pruning wherever possible when querying partitioned tables to minimize LWLock contention

### Query Plan Analysis

- Analyze query plans in the MR description for:
  - Sequential scans on large tables
  - Nested loops with large datasets
  - Missing or inefficient index usage
  - High-cost operations
  - Unexpected sort operations
  - Verify the query returns expected records (not zero rows)
  - Check that maximum query execution time is under 100ms
  - Ensure the query plan reflects the complete query as executed (including all chained scopes, pagination, ordering)
