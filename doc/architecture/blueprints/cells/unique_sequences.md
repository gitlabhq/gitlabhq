---
stage: core platform
group: database
description: 'Cells: Unique sequences'
status: accepted
---

<!-- vale gitlab.FutureTense = NO -->

# Cells: Unique Sequences

GitLab today ensures that every database row create has a unique ID, allowing to access a merge request, CI Job or Project by a known global ID.
Cells will use many distinct and not connected databases, each of them having a separate ID for most entities.

At a minimum, any ID referenced between a Cell and the shared schema will need to be unique across the cluster to avoid ambiguous references.
Further to required global IDs, it might also be desirable to retain globally unique IDs for all database rows to allow moving organizations between Cells.

## 1. Goal

Is to have non-overlapping sequences across the cluster, so that there will not be a problem while moving organizations between cells.

## 2. Decision

Secondary cells will have bigint IDs while provisioning and each cell will reach out to the Topology Service to get
the sequence range, TS will ensure that the sequence ranges are not colliding with other cells.

The range got from the SequenceService will be used to set `maxval` and `minval` for all existing ID sequences and any
newly created IDs.

Logic to compute to the sequence range and the interactions between cells and the topology service can be found [here](topology_service.md#workflow).
