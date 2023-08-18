---
stage: enablement
group: Tenant Scale
description: 'Cells: Data migration'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Data migration

It is essential for a Cells architecture to provide a way to migrate data out of big Cells into smaller ones.
This document describes various approaches to provide this type of split.

We also need to handle cases where data is already violating the expected isolation constraints of Cells, for example references cannot span multiple Organizations.
We know that existing features like linked issues allowed users to link issues across any Projects regardless of their hierarchy.
There are many similar features.
All of this data will need to be migrated in some way before it can be split across different Cells.
This may mean some data needs to be deleted, or the feature needs to be changed and modelled slightly differently before we can properly split or migrate Organizations between Cells.

Having schema deviations across different Cells, which is a necessary consequence of different databases, will also impact our ability to migrate data between Cells.
Different schemas impact our ability to reliably replicate data across Cells and especially impact our ability to validate that the data is correctly replicated.
It might force us to only be able to move data between Cells when the schemas are all in sync (slowing down deployments and the rebalancing process) or possibly only migrate from newer to older schemas which would be complex.

## 1. Definition

## 2. Data flow

## 3. Proposal

### 3.1. Split large Cells

A single Cell can only be divided into many Cells.
This is based on the principle that it is easier to create an exact clone of an existing Cell in many replicas out of which some will be made authoritative once migrated.
Keeping those replicas up-to-date with Cell 0 is also much easier due to pre-existing replication solutions that can replicate the whole systems: Geo, PostgreSQL physical replication, etc.

1. All data of an Organization needs to not be divided across many Cells.
1. Split should be doable online.
1. New Cells cannot contain pre-existing data.
1. N Cells contain exact replica of Cell 0.
1. The data of Cell 0 is live replicated to as many Cells it needs to be split.
1. Once consensus is achieved between Cell 0 and N-Cells, the Organizations to be migrated away are marked as read-only cluster-wide.
1. The `routes` is updated on for all Organizations to be split to indicate an authoritative Cell holding the most recent data, like `gitlab-org` on `cell-100`.
1. The data for `gitlab-org` on Cell 0, and on other non-authoritative N-Cells are dormant and will be removed in the future.
1. All accesses to `gitlab-org` on a given Cell are validated about `cell_id` of `routes` to ensure that given Cell is authoritative to handle the data.

#### More challenges of this proposal

1. There is no streaming replication capability for Elasticsearch, but you could
   snapshot the whole Elasticsearch index and recreate, but this takes hours.
   It could be handled by pausing Elasticsearch indexing on the initial Cell during
   the migration as indexing downtime is not a big issue, but this still needs
   to be coordinated with the migration process.
1. Syncing Redis, Gitaly, CI Postgres, Main Postgres, registry Postgres, other
   new data stores snapshots in an online system would likely lead to gaps
   without a long downtime. You need to choose a sync point and at the sync
   point you need to stop writes to perform the migration. The more data stores
   there are to migrate at the same time the longer the write downtime for the
   failover. We would also need to find a reliable place in the application to
   actually block updates to all these systems with a high degree of
   confidence. In the past we've only been confident by shutting down all Rails
   services because any Rails process could write directly to any of these at
   any time due to async workloads or other surprising code paths.
1. How to efficiently delete all the orphaned data. Locating all `ci_builds`
   associated with half the Organizations would be very expensive if we have to
   do joins. We haven't yet determined if we'd want to store an `organization_id`
   column on every table, but this is the kind of thing it would be helpful for.

### 3.2. Migrate Organization from an existing Cell

This is different to split, as we intend to perform logical and selective replication of data belonging to a single Organization.
Today this type of selective replication is only implemented by Gitaly where we can migrate Git repository from a single Gitaly node to another with minimal downtime.

In this model we would require identifying all resources belonging to a given Organization: database rows, object storage files, Git repositories, etc. and selectively copy them over to another (likely) existing Cell importing data into it.
Ideally ensuring that we can perform logical replication live of all changed data, but change similarly to split which Cell is authoritative for this Organization.

1. It is hard to identify all resources belonging to an Organization.
1. It requires either downtime for the Organization or a robust system to identify live changes made.
1. It likely will require a full database structure analysis (more robust than Project import/export) to perform selective PostgreSQL logical replication.

#### More challenges of this proposal

1. Logical replication is still not performant enough to keep up with our
   scale. Even if we could use logical replication we still don't have an
   efficient way to filter data related to a single Organization without
   joining all the way to the `organizations` table which will slow down
   logical replication dramatically.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
