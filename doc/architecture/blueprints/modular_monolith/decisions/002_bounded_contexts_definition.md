---
creation-date: "2024-05-07"
authors: [ "@fabiopitino" ]
---

# Modular Monolith ADR 002: Define bounded contexts

## Context

With the focus primarily on the application domain we needed to define how to
modularize it.

## Decision

The application domain is divided into bounded contexts which define the top-level
modules of GitLab application. The term bounded context is widely used in
Domain-Driven Design.

Defining bounded contexts means to organize the code around product structure rather than
organizational structure.

From the research in [Proposal: split GitLab monolith into components](https://gitlab.com/gitlab-org/gitlab/-/issues/365293)
it seems that following [product categories](https://handbook.gitlab.com/handbook/product/categories/#hierarchy), as a guideline,
would be much better than translating organization structure into folder structure (for example, `app/modules/verify/pipeline-execution/...`).

However, this guideline alone is not sufficient and we need a more specific strategy:

- Bounded contexts (top level modules) should be [sufficiently deep](../../../../development/software_design.md#use-namespaces-to-define-bounded-contexts)
  to encapsulate implementation details and provide a smaller interface.
- Some product categories, such as Browser Performance Testing, are just too small to represent
  a bounded context on their own.
  We should have a strategy for grouping product categories together when makes sense.
- Product categories don't necessarily translate into clean boundaries.
  `Category:Pipeline Composition` and `Category:Continuous Integration` are some examples
  where Pipeline Authoring team and Pipeline Execution team share a lot of code.
- Some parts of the code might not have a clear product category associated to it.

Despite the above, product categories provide a rough view of the bounded contexts at play in the application.
For that we use product categories to sketch the initial set of bounded contexts.
Then, group related or strongly coupled categories under the same bounded context and create new bounded contexts if missing.

## Consequences

In May 2024 we completed the [Bounded Contexts working group](https://handbook.gitlab.com/handbook/company/working-groups/bounded-contexts/)
which completed the first phase of modularization, described in this page.

We defined a list of [bounded contexts in code](../../../../development/software_design.md#use-namespaces-to-define-bounded-contexts)
and started enforcing them with RuboCop, in order to move towards a fully namespaced monolith.
Team members can edit this list by creating and deleting bounded contexts explicitly and the decision is reviewed
by Staff+ engineers.

## Alternatives

We evaluated whether to align the code to the organizational structure but we decided it wasn't viable:

- Product categories can change ownership and we have seen some pretty frequent changes, even back and forth.
  Moving code every time a product category changes ownership adds too much maintenance overhead.
- Teams and organization changes should just mean relabelling the ownership of specific modules.
- Coupling and complexity are directly correlated to business logic and product structure.
  A code organization that aligns to organizational structure could generate unnecessary complexity and
  much more coupling.
