---
stage: enablement
group: pods
comments: false
description: 'Pods: Data migration'
---

DISCLAIMER:
This page may contain information related to upcoming products, features and
functionality. It is important to note that the information presented is for
informational purposes only, so please do not rely on the information for
purchasing or planning purposes. Just like with all projects, the items
mentioned on the page are subject to change or delay, and the development,
release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

This document is a work-in-progress and represents a very early state of the
Pods design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Pods, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Pods: Data migration

It is essential for Pods architecture to provide a way to migrate data out of big Pods
into smaller ones. This describes various approaches to provide this type of split.

We also need to handle for cases where data is already violating the expected
isolation constraints of Pods (ie. references cannot span multiple
organizations). We know that existing features like linked issues allowed users
to link issues across any projects regardless of their hierarchy. There are many
similar features. All of this data will need to be migrated in some way before
it can be split across different pods. This may mean some data needs to be
deleted, or the feature changed and modelled slightly differently before we can
properly split or migrate the organizations between pods.

Having schema deviations across different Pods, which is a necessary
consequence of different databases, will also impact our ability to migrate
data between pods. Different schemas impact our ability to reliably replicate
data across pods and especially impact our ability to validate that the data is
correctly replicated. It might force us to only be able to move data between
pods when the schemas are all in sync (slowing down deployments and the
rebalancing process) or possibly only migrate from newer to older schemas which
would be complex.

## 1. Definition

## 2. Data flow

## 3. Proposal

### 3.1. Split large Pods

A single Pod can only be divided into many Pods. This is based on principle
that it is easier to create exact clone of an existing Pod in many replicas
out of which some will be made authoritative once migrated. Keeping those
replicas up-to date with Pod 0 is also much easier due to pre-existing
replication solutions that can replicate the whole systems: Geo, PostgreSQL
physical replication, etc.

1. All data of an organization needs to not be divided across many Pods.
1. Split should be doable online.
1. New Pods cannot contain pre-existing data.
1. N Pods contain exact replica of Pod 0.
1. The data of Pod 0 is live replicated to as many Pods it needs to be split.
1. Once consensus is achieved between Pod 0 and N-Pods the organizations to be migrated away
   are marked as read-only cluster-wide.
1. The `routes` is updated on for all organizations to be split to indicate an authoritative
   Pod holding the most recent data, like `gitlab-org` on `pod-100`.
1. The data for `gitlab-org` on Pod 0, and on other non-authoritative N-Pods are dormant
   and will be removed in the future.
1. All accesses to `gitlab-org` on a given Pod are validated about `pod_id` of `routes`
   to ensure that given Pod is authoritative to handle the data.

#### More challenges of this proposal

1. There is no streaming replication capability for Elasticsearch, but you could
   snapshot the whole Elasticsearch index and recreate, but this takes hours.
   It could be handled by pausing Elasticsearch indexing on the initial pod during
   the migration as indexing downtime is not a big issue, but this still needs
   to be coordinated with the migration process
1. Syncing Redis, Gitaly, CI Postgres, Main Postgres, registry Postgres, other
   new data stores snapshots in an online system would likely lead to gaps
   without a long downtime. You need to choose a sync point and at the sync
   point you need to stop writes to perform the migration. The more data stores
   there are to migrate at the same time the longer the write downtime for the
   failover. We would also need to find a reliable place in the application to
   actually block updates to all these systems with a high degree of
   confidence. In the past we've only been confident by shutting down all rails
   services because any rails process could write directly to any of these at
   any time due to async workloads or other surprising code paths.
1. How to efficiently delete all the orphaned data. Locating all `ci_builds`
   associated with half the organizations would be very expensive if we have to
   do joins. We haven't yet determined if we'd want to store an `organization_id`
   column on every table, but this is the kind of thing it would be helpful for.

### 3.2. Migrate organization from an existing Pod

This is different to split, as we intend to perform logical and selective replication
of data belonging to a single organization.

Today this type of selective replication is only implemented by Gitaly where we can migrate
Git repository from a single Gitaly node to another with minimal downtime.

In this model we would require identifying all resources belonging to a given organization:
database rows, object storage files, Git repositories, etc. and selectively copy them over
to another (likely) existing Pod importing data into it. Ideally ensuring that we can
perform logical replication live of all changed data, but change similarly to split
which Pod is authoritative for this organization.

1. It is hard to identify all resources belonging to organization.
1. It requires either downtime for organization or a robust system to identify
   live changes made.
1. It likely will require a full database structure analysis (more robust than project import/export)
   to perform selective PostgreSQL logical replication.

#### More challenges of this proposal

1. Logical replication is still not performant enough to keep up with our
   scale. Even if we could use logical replication we still don't have an
   efficient way to filter data related to a single organization without
   joining all the way to the `organizations` table which will slow down
   logical replication dramatically.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
