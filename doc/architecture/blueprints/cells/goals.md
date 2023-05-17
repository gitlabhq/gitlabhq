---
stage: enablement
group: Tenant Scale
description: 'Cells: Goals'
---

# Cells: Goals

## Scalability

The main goal of this new shared-infrastructure architecture is to provide additional scalability for our SaaS Platform. GitLab.com is largely monolithic and we have estimated (internal) that the current architecture has scalability limitations, even when database partitioning and decomposition are taken into account.

Cells provide a horizontally scalable solution because additional Cells can be created based on demand. Cells can be provisioned and tuned as needed for optimal scalability.

## Increased availability

A major challenge for shared-infrastructure architectures is a lack of isolation between top-level groups. This can lead to noisy neighbor effects. A organization's behavior inside a top-level group can impact all other organizations. This is highly undesirable. Cells provide isolation at the cell level. A group of organizations is fully isolated from other organizations located on a different Cell. This minimizes noisy neighbor effects while still benefiting from the cost-efficiency of shared infrastructure.

Additionally, Cells provide a way to implement disaster recovery capabilities. Entire Cells may be replicated to read-only standbys with automatic failover capabilities.

## A consistent experience

Organizations should have the same user experience on our SaaS platform as they do on a self-managed GitLab instance.

## Regions

GitLab.com is only hosted within the United States of America. Organizations located in other regions have voiced demand for local SaaS offerings. Cells provide a path towards [GitLab Regions](https://gitlab.com/groups/gitlab-org/-/epics/6037) because Cells may be deployed within different geographies. Depending on which of the organization's data is located outside a Cell, this may solve data residency and compliance problems.

## Market segment

Cells would provide a solution for organizations in the small to medium business (up to 100 users) and the mid-market segment (up to 2000 users).
(See [segmentation definitions](https://about.gitlab.com/handbook/sales/field-operations/gtm-resources/#segmentation).)
Larger organizations may benefit substantially from [GitLab Dedicated](../../../subscriptions/gitlab_dedicated/index.md).

At this moment, GitLab.com has "social-network"-like capabilities that may not fit well into a more isolated organization model. Removing those features, however, possesses some challenges:

1. How will existing `gitlab-org` contributors contribute to the namespace??
1. How do we move existing top-level groups into the new model (effectively breaking their social features)?

We should evaluate if the SMB and mid market segment is interested in these features, or if not having them is acceptable in most cases.

## Self-managed

For reasons of consistency, it is expected that self-managed instances will
adopt the cells architecture as well. To expand, self-managed instances can
continue with just a single Cell while supporting the option of adding additional
Cells. Organizations, and possible User decomposition will also be adopted for
self-managed instances.

## High-level architecture problems to solve

A number of technical issues need to be resolved to implement Cells (in no particular order). This section will be expanded.

1. How are Cells provisioned? - [Design discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/396641)
1. What is a Cells topology? - [Design discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/396641)
1. How are users of an organization routed to the correct Cell? -
1. How do users authenticate with Cells and Organizations? - [Design discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/395736)
1. How are Cells rebalanced?
1. How can Cells implement disaster recovery capabilities?
