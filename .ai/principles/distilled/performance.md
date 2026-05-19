---
source_checksum: 2e6df0de94d1c44f
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Performance Principles

## Checklist

### Impact Analysis

- Consider whether queries could take down critical services or allow abuse by malicious users
- Document the expected data set size and potential problems for each feature
- Consider how users might abuse or stress the feature with unconventional usage patterns
- Validate query behavior against both small (hundreds) and large (100,000+) data sets
- Request a performance specialist review when impact is unclear

### Query Counts

- DO NOT increase the total number of executed SQL queries unless absolutely necessary
- DO NOT execute SQL queries in a loop; use bulk operations like `update_all` instead
- Use [QueryRecorder](https://docs.gitlab.com/development/database/query_recorder/) tests to detect N+1 regressions and prevent them
- DO NOT execute duplicated cached queries — use `ActiveRecord::Associations::Preloader` to share in-memory objects across associations
- Pass `skip_cached: false` to QueryRecorder to detect and prevent cached query regressions
- Ensure the number of executed queries (including cached) does not depend on collection size

### Database Replicas

- Use `without_sticky_writes` to prevent primary stickiness after trivial or insignificant writes
- Use `use_replicas_for_read_queries` to force read-only queries to replicas when replication lag is tolerable
- Use `fallback_to_replicas_for_ambiguous_queries` for read-only transactions and other ambiguous queries
- Use `select_all` instead of `execute` for custom read-only SQL so queries route to read replicas and preserve the query cache

### CTEs

- DO NOT use hierarchical recursive CTEs for new features requiring hierarchical structures — they do not scale and are difficult to optimize
- Use `Gitlab::SQL::CTE` class when building CTE statements; it forces materialization via the `MATERIALIZED` keyword by default

### Eager Loading

- Eager load associations whenever retrieving more than one row that uses associations (use `includes`)
- `QueryRecorder` tests used to prevent regressions when eager loading

### Memory Usage

- DO NOT increase memory usage beyond the absolute minimum required
- Parse large documents as streams rather than loading entire input into memory

### Batch Processing

- Execute operations against external services (PostgreSQL, Redis, Object Storage) in batch style to reduce connection overhead
- Use `FastDestroyAll` module when removing many database rows and their associated data

### Timeouts

- Set a reasonable timeout for all HTTP calls to external services
- Execute external service calls in Sidekiq, not in Puma threads
- Use `ReactiveCaching` for fetching external data
- Gracefully handle timeout exceptions and surface errors in UI or logs

### Database Transactions

- DO NOT access external services like Gitaly inside database transactions
- Use `AfterCommitQueue` module or `after_commit` AR hook to keep transactions minimal

### Caching

- Cache data in memory using `Gitlab::SafeRequestStore` when reused multiple times within a single transaction
- Cache data in Redis when it must persist beyond the duration of a single transaction

### Pagination

- Include pagination for every feature that renders a list of items as a table
- Prefer keyset-based or infinite scrolling pagination over offset-based pagination for scalability
- DO NOT calculate exact counts for paginated collections when it can cause timeouts

### Badge Counters

- Truncate badge counters at a threshold (for example, `1000+`) using `NumbersHelper.limited_counter_with_delimiter`
- Load badge counters asynchronously where possible to improve initial page load

### UI Rendering

- Render UI elements lazily — only when actually needed, not unconditionally on every page load

### Feature Flags

- Add a feature flag to disable any feature with performance-critical elements or known performance deficiencies

### Storage

- Use local temporary storage (`Dir.mktmpdir`) for temporary file manipulation, especially in Kubernetes deployments
- DO NOT use more than `100MB` of temporary storage without consulting a maintainer
- Ensure all features holding persistent files support Object Storage via the `ObjectStorage` concern
- DO NOT perform file uploads or downloads via Puma; implement [Workhorse direct upload](https://docs.gitlab.com/development/uploads/) for all file uploads and downloads

## Authoritative sources

For the full picture, see:

- doc/development/merge_request_concepts/performance.md

