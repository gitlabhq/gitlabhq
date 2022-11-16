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
1. The `routes` is updated on for all organizations to be split to indicate an authorative
   Pod holding the most recent data, like `gitlab-org` on `pod-100`.
1. The data for `gitlab-org` on Pod 0, and on other non-authoritative N-Pods are dormant
   and will be removed in the future.
1. All accesses to `gitlab-org` on a given Pod are validated about `pod_id` of `routes`
   to ensure that given Pod is authoritative to handle the data.

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

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
