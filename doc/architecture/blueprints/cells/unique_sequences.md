---
stage: core platform
group: database
description: 'Cells: Unique sequences'
status: ongoing
---

<!-- vale gitlab.FutureTense = NO -->

# Cells: Unique Sequences

GitLab today ensures that every database row create has a unique ID, allowing to access a merge request, CI Job or Project by a known global ID.
Cells will use many distinct and not connected databases, each of them having a separate ID for most entities.

At a minimum, any ID referenced between a Cell and the shared schema will need to be unique across the cluster to avoid ambiguous references.
Further to required global IDs, it might also be desirable to retain globally unique IDs for all database rows to allow moving organizations between Cells.

## 1. Decision

Secondary cells will have bigint IDs while provisioning and the primary cell's sequences will be altered to make sure it
doesn't overlap with the other cell's sequences.

More details on the decision taken and other solutions evaluated can be found [here](decisions/008_database_sequences.md).

## 1. Goal

Each cell will use Topology service's [Sequence Service](topology_service.md#sequence-service) to get the range of
sequences to use. Topology service will make sure the given sequence range is unique across the cluster.

## 3. Workflow

This section will get updated with the functional diagrams on the completion of [core-platform-section/data-stores/-/issues/106](https://gitlab.com/gitlab-org/core-platform-section/data-stores/-/issues/106).
