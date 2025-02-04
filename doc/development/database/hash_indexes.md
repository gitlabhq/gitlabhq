---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Hash Indexes
---

PostgreSQL supports hash indexes besides the regular B-tree
indexes. Hash indexes however are to be avoided at all costs. While they may
_sometimes_ provide better performance the cost of rehashing can be very high.
More importantly: at least until PostgreSQL 10.0 hash indexes are not
WAL-logged, meaning they are not replicated to any replicas. From the PostgreSQL
documentation:

> Hash index operations are not presently WAL-logged, so hash indexes might need
> to be rebuilt with REINDEX after a database crash if there were unwritten
> changes. Also, changes to hash indexes are not replicated over streaming or
> file-based replication after the initial base backup, so they give wrong
> answers to queries that subsequently use them. For these reasons, hash index
> use is presently discouraged.

RuboCop is configured to register an offense when it detects the use of a hash
index.

Instead of using hash indexes you should use regular B-tree indexes.
