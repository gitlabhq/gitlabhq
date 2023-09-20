---
stage: enablement
group: Tenant Scale
description: 'Cells: Secrets'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Secrets

Where possible, each Cell should have its own distinct set of secrets.
However, there will be some secrets that will be required to be the same for all Cells in the cluster.

## 1. Definition

GitLab has a lot of [secrets](https://docs.gitlab.com/charts/installation/secrets.html) that need to be configured.
Some secrets are for inter-component communication, for example, `GitLab Shell secret`, and used only within a Cell.
Some secrets are used for features, for example, `ci_jwt_signing_key`.

## 2. Data flow

## 3. Proposal

1. Secrets used for features will need to be consistent across all Cells, so that the UX is consistent.
    1. This is especially true for the `db_key_base` secret which is used for
       encrypting data at rest in the database - so that Projects that are
       transferred to another Cell will continue to work. We do not want to have
       to re-encrypt such rows when we move Projects/Groups between Cells.
1. Secrets which are used for intra-Cell communication only should be uniquely generated
   per Cell.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
