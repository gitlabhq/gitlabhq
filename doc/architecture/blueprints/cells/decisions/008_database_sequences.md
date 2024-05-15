---
stage: core platform
group: Database
description: 'Cells ADR 008: Cluster wide unique database sequences'
---

# Cells ADR 008: Cluster wide unique database sequences

## Context

Having non-overlapping unique sequences across the cluster is necessary for moving organizations between cells,
this was highlighted in [core-platform-section/-/epics/3](https://gitlab.com/groups/gitlab-org/core-platform-section/-/epics/3)
and different solutions were discussed in <https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/102>.

## Decision

All secondary cells will have bigint IDs on creation. While provisioning, each of them will get a
large range of sequences to use from the [Topology Service](../topology_service.md).
On decommissioning the cell, these ranges will be
returned back to the topology service. If the returned range is large enough for another cell, it could be handed out to
them so that the short-lived cells won't exhaust large parts of the key range.

We will update the primary cell's sequence to have a `maxval`, it will be a minimum possible range to make sure it
won't collide with any secondary cells.

## Consequences

The above decision will support till [Cells 1.5](../iterations/cells-1.5.md) but not [Cells 2.0](../iterations/cells-2.0.md).

To support Cells 2.0 (i.e: allow moving organizations from
secondary cells to the primary), we need all integer IDs in the primary to be converted to `bigint`. Which is an
ongoing effort as part of [core-platform-section/data-stores/-/issues/111](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/111)
and it is estimated to take around 12 months.

## Alternatives

In addition to the [earliest proposal](../rejected/impacted_features/database_sequences.md), we evaluated
below solutions before making the final decision.

- [Solution 1: Global Service to claim sequences](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/102#note_1853252715)
- [Solution 2: Converting all int IDs to bigint to generate uniq IDs](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/102#note_1853260434)
- [Solution 3: Using composite primary key [(existing PKs), original cell ID]](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/102#note_1853265147)
- [Solution 4: Use bigint IDs only for Secondary cell](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/102#note_1853328985)
- [Solution 5: Using Logical replication](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/102#note_1857486154)
