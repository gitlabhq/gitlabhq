---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Hash Partitioning
---

Hash partitioning is a method of dividing a large table into smaller, more manageable partitions based on a hash function applied to a specified column, typically the ID column. It offers unique advantages for certain use cases, but it also comes with limitations.

Key points:

- Data distribution: Rows are assigned to partitions based on the hash value of their ID and a modulus-remainder calculation.
  For example, if partitioning by `HASH(ID)` with `MODULUS 64` and `REMAINDER 1`, rows with `hash(ID) % 64 == 1` would go into the corresponding partition.

- Query requirements: Hash partitioning works best when most queries include a `WHERE hashed_column = ?` condition,
  as this allows PostgreSQL to quickly identify the relevant partition.

- ID uniqueness: It's the only partitioning method (aside from complex list partitioning) that can guarantee ID uniqueness across multiple partitions at the database level.

Upfront decisions:

- The number of partitions must be chosen before table creation and cannot be easily added later. This makes it crucial to anticipate future data growth.

Unsupported query types:

- Range queries `(WHERE id BETWEEN ? AND ?)` and lookups by other keys `(WHERE other_id = ?)` are not directly supported on hash-partitioned tables.

Considerations:

- Choose a large number of partitions to accommodate future growth.
- Ensure application queries align with hash partitioning requirements.
- Evaluate alternatives like range partitioning or list partitioning if range queries or lookups by other keys are essential.

In summary, hash partitioning is a valuable tool for specific scenarios, particularly when ID uniqueness across partitions is crucial. However, it's essential to carefully consider its limitations and query patterns before implementation.
