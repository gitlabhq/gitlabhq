---
stage: enablement
group: Tenant Scale
description: 'Cells: Schema changes'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Schema changes

When we introduce multiple Cells that own their own databases this will complicate the process of making schema changes to Postgres and Elasticsearch.
Today we already need to be careful to make changes comply with our zero downtime deployments.
For example, [when removing a column we need to make changes over 3 separate deployments](../../../../development/database/avoiding_downtime_in_migrations.md#dropping-columns).
We have tooling like `post_migrate` that helps with these kinds of changes to reduce the number of merge requests needed, but these will be complicated when we are dealing with deploying multiple Rails applications that will be at different versions at any one time.
This problem will be particularly tricky to solve for shared databases like our plan to share the `users` related tables among all Cells.

A key benefit of Cells may be that it allows us to run different customers on different versions of GitLab.
We may choose to update our own Cell before all our customers giving us even more flexibility than our current canary architecture.
But doing this means that schema changes need to have even more versions of backward compatibility support which could slow down development as we need extra steps to make schema changes.

## 1. Definition

## 2. Data flow

## 3. Proposal

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
