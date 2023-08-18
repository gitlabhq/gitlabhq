---
stage: enablement
group: Tenant Scale
description: 'Cells: Database Sequences'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Database Sequences

GitLab today ensures that every database row create has a unique ID, allowing to access a merge request, CI Job or Project by a known global ID.
Cells will use many distinct and not connected databases, each of them having a separate ID for most entities.
At a minimum, any ID referenced between a Cell and the shared schema will need to be unique across the cluster to avoid ambiguous references.
Further to required global IDs, it might also be desirable to retain globally unique IDs for all database rows to allow migrating resources between Cells in the future.

## 1. Definition

## 2. Data flow

## 3. Proposal

These are some preliminary ideas how we can retain unique IDs across the system.

### 3.1. UUID

Instead of using incremental sequences, use UUID (128 bit) that is stored in the database.

- This might break existing IDs and requires adding a UUID column for all existing tables.
- This makes all indexes larger as it requires storing 128 bit instead of 32/64 bit in index.

### 3.2. Use Cell index encoded in ID

Because a significant number of tables already use 64 bit ID numbers we could use MSB to encode the Cell ID:

- This might limit the amount of Cells that can be enabled in a system, as we might decide to only allocate 1024 possible Cell numbers.
- This would make it possible to migrate IDs between Cells, because even if an entity from Cell 1 is migrated to Cell 100 this ID would still be unique.
- If resources are migrated the ID itself will not be enough to decode the Cell number and we would need a lookup table.
- This requires updating all IDs to 32 bits.

### 3.3. Allocate sequence ranges from central place

Each Cell might receive its own range of sequences as they are consumed from a centrally managed place.
Once a Cell consumes all IDs assigned for a given table it would be replenished and a next range would be allocated.
Ranges would be tracked to provide a faster lookup table if a random access pattern is required.

- This might make IDs migratable between Cells, because even if an entity from Cell 1 is migrated to Cell 100 this ID would still be unique.
- If resources are migrated the ID itself will not be enough to decode the Cell number and we would need a much more robust lookup table as we could be breaking previously assigned sequence ranges.
- This does not require updating all IDs to 64 bits.
- This adds some performance penalty to all `INSERT` statements in Postgres or at least from Rails as we need to check for the sequence number and potentially wait for our range to be refreshed from the ID server.
- The available range will need to be stored and incremented in a centralized place so that concurrent transactions cannot possibly get the same value.

### 3.4. Define only some tables to require unique IDs

Maybe it is acceptable only for some tables to have a globally unique IDs. It could be Projects, Groups and other top-level entities.
All other tables like `merge_requests` would only offer a Cell-local ID, but when referenced outside it would rather use an IID (an ID that is monotonic in context of a given resource, like a Project).

- This makes the ID 10000 for `merge_requests` be present on all Cells, which might be sometimes confusing regarding the uniqueness of the resource.
- This might make random access by ID (if ever needed) impossible without using a composite key, like: `project_id+merge_request_id`.
- This would require us to implement a transformation/generation of new ID if we need to migrate records to another Cell. This can lead to very difficult migration processes when these IDs are also used as foreign keys for other records being migrated.
- If IDs need to change when moving between Cells this means that any links to records by ID would no longer work even if those links included the `project_id`.
- If we plan to allow these IDs to not be unique and change the unique constraint to be based on a composite key then we'd need to update all foreign key references to be based on the composite key.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
