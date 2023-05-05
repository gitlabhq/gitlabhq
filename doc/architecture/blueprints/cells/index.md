---
status: accepted
creation-date: "2022-09-07"
authors: [ "@ayufan", "@fzimmer", "@DylanGriffith" ]
coach: "@ayufan"
approvers: [ "@fzimmer" ]
owning-stage: "~devops::enablement"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# Cells

This document is a work-in-progress and represents a very early state of the Cells design. Significant aspects are not documented, though we expect to add them in the future.

Cells is a new architecture for our Software as a Service platform. This architecture is horizontally-scalable, resilient, and provides a more consistent user experience. It may also provide additional features in the future, such as data residency control (regions) and federated features.

For more information about Cells, see also:

- [Glossary](glossary.md)
- [Goals](goals.md)
- [Cross-section impact](impact.md)

## Work streams

We can't ship the entire Cells architecture in one go - it is too large.
Instead, we are defining key work streams required by the project.

Not all objectives need to be fulfilled to reach production readiness.
It is expected that some objectives will not be completed for General Availability (GA),
but will be enough to run Cells in production.

### 1. Data access layer

Before Cells can be run in production we need to prepare the codebase to accept the Cells architecture.
This preparation involves:

- Allowing data sharing between Cells.
- Updating the tooling for discovering cross-Cell data traversal.
- Defining code practices for cross-Cell data traversal.
- Analyzing the data model to define the data affinity.

Under this objective the following steps are expected:

1. **Allow to share cluster-wide data with database-level data access layer.**

    Cells can connect to a database containing shared data. For example:
    application settings, users, or routing information.

1. **Evaluate the efficiency of database-level access vs. API-oriented access layer.**

    Reconsider the consequences of database-level data access for data migration, resiliency of updates and of interconnected systems when we share only a subset of data.

1. **Cluster-unique identifiers**

    Every object has a unique identifier that can be used to access data across the cluster. The IDs for allocated projects, issues and any other objects are cluster-unique.

1. **Cluster-wide deletions**

    If entities deleted in Cell 2 are cross-referenced, they are properly deleted or nullified across clusters. We will likely re-use existing [loose foreign keys](../../../development/database/loose_foreign_keys.md) to extend it with cross-Cells data removal.

1. **Data access layer**

    Ensure that a stable data-access (versioned) layer that allows to share cluster-wide data is implemented.

1. **Database migration**

    Ensure that migrations can be run independently between Cells, and we safely handle migrations of shared data in a way that does not impact other Cells.

### 2. Essential workflows

To make Cells viable we require to define and support
essential workflows before we can consider the Cells
to be of Beta quality. Essential workflows are meant
to cover the majority of application functionality
that makes the product mostly useable, but with some caveats.

The current approach is to define workflows from top to bottom.
The order defines the presumed priority of the items.
This list is not exhaustive as we would be expecting
other teams to help and fix their workflows after
the initial phase, in which we fix the fundamental ones.

To consider a project ready for the Beta phase, it is expected
that all features defined below are supported by Cells.
In the cases listed below, the workflows define a set of tables
to be properly attributed to the feature. In some cases,
a table with an ambiguous usage has to be broken down.
For example: `uploads` are used to store user avatars,
as well as uploaded attachments for comments. It would be expected
that `uploads` is split into `uploads` (describing group/project-level attachments)
and `global_uploads` (describing, for example, user avatars).

Except for initial 2-3 quarters this work is highly parallel.
It would be expected that **group::tenant scale** would help other
teams to fix their feature set to work with Cells. The first 2-3 quarters
would be required to define a general split of data and build required tooling.

1. **Instance-wide settings are shared across cluster.**

    The Admin Area section for most part is shared across a cluster.

1. **User accounts are shared across cluster.**

    The purpose is to make `users` cluster-wide.

1. **User can create group.**

    The purpose is to perform a targeted decomposition of `users` and `namespaces`, because the `namespaces` will be stored locally in the Cell.

1. **User can create project.**

    The purpose is to perform a targeted decomposition of `users` and `projects`, because the `projects` will be stored locally in the Cell.

1. **User can change profile avatar that is shared in cluster.**

    The purpose is to fix global uploads that are shared in cluster.

1. **User can push to Git repository.**

    The purpose is to ensure that essential joins from the projects table are properly attributed to be 
    Cell-local, and as a result the essential Git workflow is supported.

1. **User can run CI pipeline.**

    The purpose is that `ci_pipelines` (like `ci_stages`, `ci_builds`, `ci_job_artifacts`) and adjacent tables are properly attributed to be Cell-local.

1. **User can create issue, merge request, and merge it after it is green.**

    The purpose is to ensure that `issues` and `merge requests` are properly attributed to be `Cell-local`.

1. **User can manage group and project members.**

    The `members` table is properly attributed to be either `Cell-local` or `cluster-wide`.

1. **User can manage instance-wide runners.**

    The purpose is to scope all CI Runners to be Cell-local. Instance-wide runners in fact become Cell-local runners. The expectation is to provide a user interface view and manage all runners per Cell, instead of per cluster.

1. **User is part of organization and can only see information from the organization.**

    The purpose is to have many organizations per Cell, but never have a single organization spanning across many Cells. This is required to ensure that information shown within an organization is isolated, and does not require fetching information from other Cells.

### 3. Additional workflows

Some of these additional workflows might need to be supported, depending on the group decision.
This list is not exhaustive of work needed to be done.

1. **User can use all group-level features.**
1. **User can use all project-level features.**
1. **User can share groups with other groups in an organization.**
1. **User can create system webhook.**
1. **User can upload and manage packages.**
1. **User can manage security detection features.**
1. **User can manage Kubernetes integration.**
1. TBD

### 4. Routing layer

The routing layer is meant to offer a consistent user experience where all Cells are presented
under a single domain (for example, `gitlab.com`), instead of 
having to navigate to separate domains.

The user will able to use `https://gitlab.com` to access Cell-enabled GitLab. Depending
on the URL access, it will be transparently proxied to the correct Cell that can serve this particular
information. For example:

- All requests going to `https://gitlab.com/users/sign_in` are randomly distributed to all Cells.
- All requests going to `https://gitlab.com/gitlab-org/gitlab/-/tree/master` are always directed to Cell 5, for example.
- All requests going to `https://gitlab.com/my-username/my-project` are always directed to Cell 1.

1. **Technology.**

    We decide what technology the routing service is written in.
    The choice is dependent on the best performing language, and the expected way
    and place of deployment of the routing layer. If it is required to make
    the service multi-cloud it might be required to deploy it to the CDN provider.
    Then the service needs to be written using a technology compatible with the CDN provider.

1. **Cell discovery.**

    The routing service needs to be able to discover and monitor the health of all Cells.

1. **Router endpoints classification.**

    The stateless routing service will fetch and cache information about endpoints
    from one of the Cells. We need to implement a protocol that will allow us to
    accurately describe the incoming request (its fingerprint), so it can be classified
    by one of the Cells, and the results of that can be cached. We also need to implement
    a mechanism for negative cache and cache eviction.

1. **GraphQL and other ambigious endpoints.**

    Most endpoints have a unique sharding key: the organization, which directly
    or indirectly (via a group or project) can be used to classify endpoints.
    Some endpoints are ambiguous in their usage (they don't encode the sharding key),
    or the sharding key is stored deep in the payload. In these cases, we need to decide how to handle endpoints like `/api/graphql`.

### 5. Cell deployment

We will run many Cells. To manage them easier, we need to have consistent
deployment procedures for Cells, including a way to deploy, manage, migrate,
and monitor.

We are very likely to use tooling made for [GitLab Dedicated](https://about.gitlab.com/dedicated/)
with its control planes.

1. **Extend GitLab Dedicated to support GCP.**
1. TBD

### 6. Migration

When we reach production and are able to store new organizations on new Cells, we need
to be able to divide big Cells into many smaller ones.

1. **Use GitLab Geo to clone Cells.**

    The purpose is to use GitLab Geo to clone Cells.

1. **Split Cells by cloning them.**

    Once Cell is cloned we change routing information for organizations.
    Organization will encode `cell_id`. When we update `cell_id` it will automatically
    make the given Cell to be authoritative to handle the traffic for the given organization.

1. **Delete redundant data from previous Cells.**

    Since the organization is now stored on many Cells, once we change `cell_id`
    we will have to remove data from all other Cells based on `organization_id`.

## Availability of the feature

We are following the [Support for Experiment, Beta, and Generally Available features](../../../policy/alpha-beta-support.md).

### 1. Experiment

Expectations:

- We can deploy a Cell on staging or another testing environment by using a separate domain (ex. `cell2.staging.gitlab.com`)
  using [Cell deployment](#5-cell-deployment) tooling.
- User can create organization, group and project, and run some of the [essential workflows](#2-essential-workflows).
- It is not expected to be able to run a router to serve all requests under a single domain.
- We expect data-loss of data stored on additional Cells.
- We expect to tear down and create many new Cells to validate tooling.

### 2. Beta

Expectations:

- We can run many Cells under a single domain (ex. `staging.gitlab.com`).
- All features defined in [essential workflows](#2-essential-workflows) are supported.
- Not all aspects of [Routing layer](#4-routing-layer) are finalized.
- We expect additional Cells to be stable with minimal data loss.

### 3. GA

Expectations:

- We can run many Cells under a single domain (for example, `staging.gitlab.com`).
- All features defined in [essential workflows](#2-essential-workflows) are supported.
- All features of [routing layer](#4-routing-layer) are supported.
- Most of [additional workflows](#3-additional-workflows) are supported.
- We don't expect to support any of [migration](#6-migration) aspects.

### 4. Post GA

Expectations:

- We support all [additional workflows](#3-additional-workflows).
- We can [migrate](#6-migration) existing organizations onto new Cells.

## Iteration plan

The delivered iterations will focus on solving particular steps of a given
key work stream.

It is expected that initial iterations will rather
be slow, because they require substantially more
changes to prepare the codebase for data split.

One iteration describes one quarter's worth of work.

1. Iteration 1 - FY24Q1

    - Data access layer: Initial Admin Area settings are shared across cluster.
    - Essential workflows: Allow to share cluster-wide data with database-level data access layer

1. Iteration 2 - FY24Q2

    - Essential workflows: User accounts are shared across cluster.
    - Essential workflows: User can create group.

1. Iteration 3 - FY24Q3

    - Essential workflows: User can create project.
    - Essential workflows: User can push to Git repository.
    - Cell deployment: Extend GitLab Dedicated to support GCP
    - Routing: Technology.

1. Iteration 4 - FY24Q4

    - Essential workflows: User can run CI pipeline.
    - Essential workflows: User can create issue, merge request, and merge it after it is green.
    - Data access layer: Evaluate the efficiency of database-level access vs. API-oriented access layer
    - Data access layer: Cluster-unique identifiers.
    - Routing: Cell discovery.
    - Routing: Router endpoints classification.

1. Iteration 5 - FY25Q1

    - TBD

## Technical Proposals

The Cells architecture do have long lasting implications to data processing, location, scalability and the GitLab architecture.
This section links all different technical proposals that are being evaluated.

- [Stateless Router That Uses a Cache to Pick Cell and Is Redirected When Wrong Cell Is Reached](proposal-stateless-router-with-buffering-requests.md)

- [Stateless Router That Uses a Cache to Pick Cell and pre-flight `/api/v4/cells/learn`](proposal-stateless-router-with-routes-learning.md)

## Impacted features

The Cells architecture will impact many features requiring some of them to be rewritten, or changed significantly.
This is the list of known affected features with the proposed solutions.

- [Cells: Git Access](cells-feature-git-access.md)
- [Cells: Data Migration](cells-feature-data-migration.md)
- [Cells: Database Sequences](cells-feature-database-sequences.md)
- [Cells: GraphQL](cells-feature-graphql.md)
- [Cells: Organizations](cells-feature-organizations.md)
- [Cells: Router Endpoints Classification](cells-feature-router-endpoints-classification.md)
- [Cells: Schema changes (Postgres and Elasticsearch migrations)](cells-feature-schema-changes.md)
- [Cells: Backups](cells-feature-backups.md)
- [Cells: Global Search](cells-feature-global-search.md)
- [Cells: CI Runners](cells-feature-ci-runners.md)
- [Cells: Admin Area](cells-feature-admin-area.md)
- [Cells: Secrets](cells-feature-secrets.md)
- [Cells: Container Registry](cells-feature-container-registry.md)
- [Cells: Contributions: Forks](cells-feature-contributions-forks.md)
- [Cells: Personal Namespaces](cells-feature-personal-namespaces.md)
- [Cells: Dashboard: Projects, Todos, Issues, Merge Requests, Activity, ...](cells-feature-dashboard.md)
- [Cells: Snippets](cells-feature-snippets.md)
- [Cells: Uploads](cells-feature-uploads.md)
- [Cells: GitLab Pages](cells-feature-gitlab-pages.md)
- [Cells: Agent for Kubernetes](cells-feature-agent-for-kubernetes.md)

## Decision log

- 2022-03-15: Google Cloud as the cloud service. For details, see [issue 396641](https://gitlab.com/gitlab-org/gitlab/-/issues/396641#note_1314932272).

## Links

- [Internal Pods presentation](https://docs.google.com/presentation/d/1x1uIiN8FR9fhL7pzFh9juHOVcSxEY7d2_q4uiKKGD44/edit#slide=id.ge7acbdc97a_0_155)
- [Internal link to all diagrams](https://drive.google.com/file/d/13NHzbTrmhUM-z_Bf0RjatUEGw5jWHSLt/view?usp=sharing)
- [Cells Epic](https://gitlab.com/groups/gitlab-org/-/epics/7582)
- [Database Group investigation](https://about.gitlab.com/handbook/engineering/development/enablement/data_stores/database/doc/root-namespace-sharding.html)
- [Shopify Pods architecture](https://shopify.engineering/a-pods-architecture-to-allow-shopify-to-scale)
- [Opstrace architecture](https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/docs/architecture/overview.md)
