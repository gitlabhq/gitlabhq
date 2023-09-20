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

# Cells: Explore

Explore may not play a critical role in GitLab as it functions today, but GitLab today is not isolated. It is the isolation that makes Explore or some viable replacement necessary.

The existing Group and Project Explore will initially be scoped to an Organization. However, there is a need for a global Explore that spans across Organizations to support the discoverability of public Groups and Projects, in particular in the context of discovering open source Projects. See user feedback [here](https://gitlab.com/gitlab-org/gitlab/-/issues/21582#note_1458298192) and [here](https://gitlab.com/gitlab-org/gitlab/-/issues/418228#note_1470045468).

## 1. Definition

The Explore functionality helps users in discovering Groups and Projects. Unauthenticated Users are only able to explore public Groups and Projects, authenticated Users can see all the Groups and Projects that they have access to, including private and internal Groups and Projects.

## 2. Data flow

## 3. Proposal

The Explore feature problem falls under the broader umbrella of solving inter-Cell communication. [This topic warrants deeper research](../index.md#can-different-cells-communicate-with-each-other).

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

The Project Explore and Group Explore are scoped to an Organization.

Downsides:

- No global discoverability of Groups and Projects.

## 4. Evaluation

The existing Group and Project Explore will initially be scoped to an Organization. Considering the [current usage of the Explore feature](https://gitlab.com/gitlab-data/product-analytics/-/issues/1302#note_1491215521), we deem this acceptable. Since all existing Users, Groups and Projects will initially be part of the default Organization, Groups and Projects will remain explorable and accessible as they are today. Only once existing Groups and Projects are moved out of the default Organization into different Organizations will this become a noticeable problem. Solutions to mitigate this are discussed in [issue #418228](https://gitlab.com/gitlab-org/gitlab/-/issues/418228). Ultimately, Explore could be replaced with a better search experience altogether.

## 4.1. Pros

- Initially the lack of discoverability will not be a problem.
- Only around [1.5% of all exisiting Users are using the Explore functionality on a monthly basis](https://gitlab.com/gitlab-data/product-analytics/-/issues/1302#note_1491215521).

## 4.2. Cons

- The GitLab owned top-level Groups would be some of the first to be moved into their own Organization and thus be detached from the explorability of the default Organization.
