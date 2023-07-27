---
stage: enablement
group: Tenant Scale
description: 'Cells: Explore'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells:Explore

The existing Group and Project Explore will initially be scoped to an Organization. However, there is a need for a global Explore that spans across Organizations to support the discoverability of public Groups and Projects.

## 1. Definition

The Explore functionality helps users in discovering Groups and Projects. Unauthenticated Users are only able to explore public Groups and Projects, authenticated Users can see all the Groups and Projects that they have access to, including private and internal Groups and Projects.

## 2. Data flow

## 3. Proposal

The Explore feature problem falls under the broader umbrella of solving inter-Cell communication. [This topic warrants deeper research](index.md#can-different-cells-communicate-with-each-other).

Below are possible directions for further investigation.

### 3.1. Read only table mirror

- Create a `shared_projects` table in the shared cluster-wide database.
- The model for this table is read-only. No inserts/updates/deletes are allowed.
- The table is filled with data (or a subset of data) from the Projects Cell-local table.
  - The write model Project (which is Cell-local) writes to the local database. We will primarily use this model for anything Cell-local.
  - This data is synchronized with `shared_projects` via a background job any time something changes.
  - The data in `shared_projects` is stored normalized, so that all the information necessary to display the Project Explore is there.
- The Project Explore (as of today) is part of an instance-wide functionality, since it's not namespaced to any organizations/groups.
  - This section will read data using the read model for `shared_projects`.
- Once the user clicks on a Project, they are redirected to the Cell containing the Organization.

Downsides:

- Need to have an explicit pattern to access instance-wide data. This however may be useful for admin functionalities too.
- The Project Explore may not be as rich in features as it is today (various filtering options, role you have on that Project, etc.).
- Extra complexity in managing CQRS.

### 3.2 Explore scoped to an Organization

The Project Explore and Group Explore will be scoped to an organization

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
