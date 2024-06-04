---
status: proposed
creation-date: "2024-05-27"
authors: [ "@bsandlin" ]
coach: "@ntepluhina"
approvers: [ "@dhershkovitch", "@marknuzzo" ]
owning-stage: "~devops::verify"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Pipeline Mini Graph

This blueprint serves as living documentation for the Pipeline Mini Graph. The Pipeline Mini Graph is used in various places throughout the platform to communicate to users the status of the relevant pipeline. Users are able to re-run jobs directly from the component or drilldown into said jobs and linked pipelines for further investigation.

## Motivation

While the Pipeline Mini Graph primarily functions via REST, we are updating the component to support GraphQL and subsequently migrating all instances of this component to GraphQL. This documentation will serve as the SSOT for this refactor. Developers have expressed difficulty contributing to this component as the two APIs co-exist, so we need to make this code easier to update while also supporting both REST and GraphQL. This refactor lives behind a feature flag called `ci_graphql_pipeline_mini_graph`.

### Goals

- Improved maintainability
- Backwards compatibility
- Improved query performance
- Deprecation of REST support

### Non-Goals

- Redesign of the Pipeline Mini Graph UI

## Proposal

To break down implementation, we are taking the following steps:

1. Separate the REST version and the GraphQL version of the component into 2 directories called `pipeline_mini_graph` and `legacy_pipeline_mini_graph`. This way, developers can contribute with more ease and we can easily remove the REST version once all apps are using GraphQL.
1. Finish updating the newer component to fully support GraphQL by adding a query for the stage dropdown.
1. Optimize GraphQL query structure to be more performant.
1. Roll out `ci_graphql_pipeline_mini_graph` to globally enable GraphQL instances of the component.
