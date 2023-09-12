---
stage: enablement
group: Tenant Scale
description: 'Cells: CI/CD Catalog'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the Cells design.
Significant aspects are not documented, though we expect to add them in the future.
This is one possible architecture for Cells, and we intend to contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that we can document the reasons for not choosing this approach.

# Cells: CI/CD Catalog

The [CI/CD pipeline components catalog](../../ci_pipeline_components/index.md) is a currently experimental feature that aims at helping users reuse pipeline configurations.
Potentially, there are several aspects of the CI/CD catalog that might be affected by Cells:

1. Namespace catalog, exists today as an experimental feature. With the introduction of Cells we would likely remove the namespace catalog and create a single Organization catalog, where all users would see all available published components in a single place (based on their permissions). This would replace today's offering, where users can have multiple catalogs which are bound to a namespace and completely isolated from each other.
1. The community catalog is supposed to allow users to search across different Organizations.

## 1. Definition

The [CI/CD pipeline components catalog](../../ci_pipeline_components/index.md) makes reusing pipeline configurations easier and more efficient.
It provides a way to discover and reuse pipeline constructs, allowing for a more streamlined experience.

There are several flavors of the CI/CD catalog:

1. [Namespace catalog (experimental)](../../../../ci/components/index.md): Bound to the top-level namespace (group or personal namespace). The namespace catalog aggregates all published components from Projects it contains. The number of top-level namespaces available in an Organization could potentially be the number of available catalogs.
1. Instance-wide component catalog (planned): Surfacing all the components that are scattered across an instance. All published components in a public or internal Project will be available in the instance-wide catalog. Only a single instance-wide catalog is planned per instance.
1. Community catalog (planned): Allow users to search all published components in different repositories across multiple namespaces. The original plan was to introduce a community catalog within self-managed customer that would act as an aggregator of all published components hosted in that instance.

## 2. Data flow

## 3. Proposal

Moving to Organizations is a great opportunity to improve the user experience and to reach parity for both self-managed and GitLab.com users.

- We introduce an Organization catalog which aggregates and surfaces all the published components that are hosted in a single Organization. The Organization catalog would make the namespace catalog obsolete.
- Once Organizations exist, GitLab.com users would need a community catalog to surface components across multiple Organizations. We need additional research to understand if such a solution is needed for self-managed customers as well.

## 4. Evaluation

Moving to a single Organization will improve the experience for users of the CI/CD component catalog.
Today we can have multiple catalogs based on the number of namespaces, making it difficult for users to surface information across an Organization.

### 4.1. Pros

- An Organization catalog will be one unified catalog serving as the single source of truth for an Organization.
- An Organization catalog would serve both self-managed and GitLab.com users, whereas the current plan was to introduce two types of catalogs: an instance-wide component catalog for self-managed and a community catalog for GitLab.com.

### 4.2. Cons

- A separate catalog that surfaces components across Organizations would need to be implemented to serve the wider community (community catalog). This catalog will be required for GitLab.com only, later on we can evaluate if a similar catalog is needed for self-managed customers.
