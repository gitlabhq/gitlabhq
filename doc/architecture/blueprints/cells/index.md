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

## Iteration plan

We can't ship the entire Cells architecture in one go - it is too large. Instead, we are adopting an iteration plan that provides value along the way.

1. Introduce organizations
1. Migrate existing top-level namespaces to organizations
1. Create new organizations on `cell`
1. Migrate existing organizations from `cell` to `cell`
1. Add additional Cell capabilities (DR, Regions)

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
- [Cells Epic](https://gitlab.com/groups/gitlab-org/-/epics/7582)
- [Database Group investigation](https://about.gitlab.com/handbook/engineering/development/enablement/data_stores/database/doc/root-namespace-sharding.html)
- [Shopify Pods architecture](https://shopify.engineering/a-pods-architecture-to-allow-shopify-to-scale)
- [Opstrace architecture](https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/docs/architecture/overview.md)
