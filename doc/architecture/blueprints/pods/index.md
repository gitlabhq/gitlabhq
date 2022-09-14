---
stage: enablement
group: pods
comments: false
description: 'Pods'
---

# Pods

DISCLAIMER:
This page may contain information related to upcoming products, features and functionality. It is important to note that the information presented is for informational purposes only, so please do not rely on the information for purchasing or planning purposes. Just like with all projects, the items mentioned on the page are subject to change or delay, and the development, release, and timing of any products, features, or functionality remain at the sole discretion of GitLab Inc.

This document is a work-in-progress and represents a very early state of the Pods design. Significant aspects are not documented, though we expect to add them in the future.

## Summary

Pods is a new architecture for our Software as a Service platform that is horizontally-scalable, resilient, and provides a more consistent user experience. It may also provide additional features in the future, such as data residency control (regions) and federated features.

## Terminology

We use the following terms to describe components and properties of the Pods architecture.

### Pod

A Pod is a set of infrastructure components that contains multiple workspaces that belong to different organizations. The components include both datastores (PostgreSQL, Redis etc.) and stateless services (web etc.). The infrastructure components provided within a Pod are shared among workspaces but not shared with other Pods. This isolation of infrastructure components means that Pods are independent from each other.

#### Pod properties

- Each pod is independent from the others
- Infrastructure components are shared by workspaces within a Pod
- More Pods can be provisioned to provide horizontal scalability
- A failing Pod does not lead to failure of other Pods
- Noisy neighbor effects are limited to within a Pod
- Pods are not visible to organizations; it is an implementation detail
- Pods may be located in different geographical regions (for example, EU, US, JP, UK)

Discouraged synonyms: GitLab instance, cluster, shard

### Workspace

A [workspace](../../../user/workspace/index.md) is the name for the top-level namespace that is used by organizations to manage everything GitLab. It will provide similar administrative capabilities to a self-managed instance.

See more in the [workspace group overview](https://about.gitlab.com/direction/manage/workspace/#overview).

#### Workspace properties

- Workspaces are isolated from each other by default
- A workspace is located on a single Pod
- Workspaces share the resources provided by a Pod

### Top-Level namespace

A top-level namespace is the logical object container in the code that represents all groups, subgroups and projects that belong to an organization.

A top-level namespace is the root of nested collection namespaces and projects. The namespace and its related entities form a tree-like hierarchy: Namespaces are the nodes of the tree, projects are the leaves. An organization usually contains a single top-level namespace, called a workspace.

Example: 

`https://gitlab.com/gitlab-org/gitlab/`:

- `gitlab-org` is a `top-level namespace`; the root for all groups and projects of an organization
- `gitlab` is a `project`; a project of the organization.

Discouraged synonyms: Root-level namespace

#### Top-level namespace properties

Same as workspaces.

### Users

Users are available globally and not restricted to a single Pod. Users can create multiple workspaces and they may be members of several workspaces and contribute to them. Because users' activity is not limited to an individual Pod, their activity needs to be aggregated across Pods to reflect all their contributions (for example TODOs). This means, the Pods architecture may need to provide a central dashboard.

#### User properties

- Users are shared globally across all Pods
- Users can create multiple workspaces
- Users can be a member of multiple workspaces

## Goals

### Scalability

The main goal of this new shared-infrastructure architecture is to provide additional scalability for our SaaS Platform. GitLab.com is largely monolithic and we have estimated (internal) that the current architecture has scalability limitations, even when database partitioning and decomposition are taken into account.

Pods provide a horizontally scalable solution because additional Pods can be created based on demand. Pods can be provisioned and tuned as needed for optimal scalability.

### Increased availability

A major challenge for shared-infrastructure architectures is a lack of isolation between workspaces. This can lead to noisy neighbor effects. A organization's behavior inside a workspace can impact all other workspaces. This is highly undesirable. Pods provide isolation at the pod level. A group of organizations is fully isolated from other organizations located on a different Pod. This minimizes noisy neighbor effects while still benefiting from the cost-efficiency of shared infrastructure.

Additionally, Pods provide a way to implement disaster recovery capabilities. Entire Pods may be replicated to read-only standbys with automatic failover capabilities.

### A consistent experience

Organizations should have the same user experience on our SaaS platform as they do on a self-managed GitLab instance.

### Regions

GitLab.com is only hosted within the United States of America. Organizations located in other regions have voiced demand for local SaaS offerings. Pods provide a path towards [GitLab Regions](https://gitlab.com/groups/gitlab-org/-/epics/6037) because Pods may be deployed within different geographies. Depending on which of the organization's data is located outside a Pod, this may solve data residency and compliance problems.

## Market segment

Pods would provide a solution for organizations in the small to medium business (up to 100 users) and the mid-market segment (up to 2000 users).
(See [segmentation definitions](https://about.gitlab.com/handbook/sales/field-operations/gtm-resources/#segmentation).)
Larger organizations may benefit substantially from [GitLab Dedicated](../../../subscriptions/gitlab_dedicated/index.md).

## High-level architecture problems to solve

A number of technical issues need to be resolved to implement Pods (in no particular order). This section will be expanded.

1. How are users of an organization routed to the correct Pod containing their workspace?
1. How do users authenticate?
1. How are Pods rebalanced?
1. How are Pods provisioned?
1. How can Pods implement disaster recovery capabilities?

## Iteration 1

Ultimately, a Pods architecture should offer the same user experience as self-managed and GitLab dedicated. However, at this moment GitLab.com has many more "social-network"-like capabilities that will be difficult to implement with a Pods architecture. We should evaluate if the SMB and mid market segment is interested in these features, or if not having them is acceptable in most cases. 

The first iteration of Pods will still contain some limitations that would break cross-workspace workflows. This means it may only be acceptable for new customers, or for existing customers that are briefed.

Limitations are:

- An organization can create only a single workspace.
- Workspaces are isolated from each other. This means cross-workspace workflows are broken.

## Iteration 2

Based on user research, we may want to change certain features to work across namespaces to allow organizations to interact with each other in specific circumstances. We may also allow organizations to have more than one workspace. This is particularly relevant for organizations with sub-divisions, or multi-national organizations that want to have workspaces in different regions.

Additional features:

- Specific features allow for cross-workspace interactions, for example forking, search.
- An organization can own multiple workspaces on different Pods.

### Links

- [Internal Pods presentation](https://docs.google.com/presentation/d/1x1uIiN8FR9fhL7pzFh9juHOVcSxEY7d2_q4uiKKGD44/edit#slide=id.ge7acbdc97a_0_155)
- [Pods Epic](https://gitlab.com/groups/gitlab-org/-/epics/7582)
- [Database Group investigation](https://about.gitlab.com/handbook/engineering/development/enablement/data_stores/database/doc/root-namespace-sharding.html)
- [Shopify Pods architecture](https://shopify.engineering/a-pods-architecture-to-allow-shopify-to-scale)
- [Opstrace architecture](https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/docs/architecture/overview.md)

### Who

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Fabian Zimmer           |
| Architecture Evolution Coach | Kamil Trzciński         |
| Engineering Leader           | TBD                     |
| Product Manager              | Fabian Zimmer           |
| Domain Expert / Database     | TBD                     |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   | TBD                    |
| Product                      | Fabian Zimmer          |
| Engineering                  | Thong Kuah |
