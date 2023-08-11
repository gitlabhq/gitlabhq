---
stage: enablement
group: Tenant Scale
description: 'Cells: Admin Area'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Admin Area

In our Cells architecture proposal we plan to share all admin related tables in GitLab.
This allows for simpler management of all Cells in one interface and reduces the risk of settings diverging in different Cells.
This introduces challenges with Admin Area pages that allow you to manage data that will be spread across all Cells.

## 1. Definition

There are consequences for Admin Area pages that contain data that span "the whole instance" as the Admin Area pages may be served by any Cell or possibly just one Cell.
There are already many parts of the Admin Area that will have data that span many Cells.
For example lists of all Groups, Projects, Topics, Jobs, Analytics, Applications and more.
There are also administrative monitoring capabilities in the Admin Area that will span many Cells such as the "Background Jobs" and "Background Migrations" pages.

## 2. Data flow

## 3. Proposal

We will need to decide how to handle these exceptions with a few possible
options:

1. Move all these pages out into a dedicated per-Cell admin section. Probably
   the URL will need to be routable to a single Cell like `/cells/<cell_id>/admin`,
   then we can display these data per Cell. These pages will be distinct from
   other Admin Area pages which control settings that are shared across all Cells. We
   will also need to consider how this impacts self-managed customers and
   whether, or not, this should be visible for single-Cell instances of GitLab.
1. Build some aggregation interfaces for this data so that it can be fetched
   from all Cells and presented in a single UI. This may be beneficial to an
   administrator that needs to see and filter all data at a glance, especially
   when they don't know which Cell the data is on. The downside, however, is
   that building this kind of aggregation is very tricky when all Cells are
   designed to be totally independent, and it does also enforce stricter
   requirements on compatibility between Cells.

The following overview describes at what level each feature contained in the current Admin Area will be managed:

| Feature | Cluster | Cell | Organization |
| --- | --- | --- | --- |
| Abuse reports | | | |
| Analytics | | | |
| Applications | | | |
| Deploy keys | | | |
| Labels | | | |
| Messages | ✓ | | |
| Monitoring | | ✓ | |
| Subscription | | | |
| System hooks | | | |
| Overview | | | |
| Settings - General | ✓ | | |
| Settings - Integrations | ✓ | | |
| Settings - Repository | ✓ | | |
| Settings - CI/CD (1) | ✓ | ✓ | |
| Settings - Reporting | ✓ | | |
| Settings - Metrics | ✓ | | |
| Settings - Service usage data | | ✓ | |
| Settings - Network | ✓ | | |
| Settings - Appearance | ✓ | | |
| Settings - Preferences | ✓ | | |

(1) Depending on the specific setting, some will be managed at the cluster-level, and some at the Cell-level.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
