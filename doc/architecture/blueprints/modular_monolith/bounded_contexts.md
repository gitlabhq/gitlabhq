---
status: proposed
creation-date: "2023-06-21"
authors: [ "@fabiopitino" ]
coach: [ ]
approvers: [ ]
owning-stage: ""
---

# Defining bounded contexts

## Status quo

Today the GitLab codebase doesn't have a clear domain structure.
We have [forced the creation of some modules](https://gitlab.com/gitlab-org/gitlab/-/issues/212156)
as a first step but we don't have a well defined strategy for doing it consistently.

The majority of the code is not properly namespaced and organized:

- Ruby namespaces used don't always represent the SSoT. We have overlapping concepts spread across multiple
  namespaces. For example: `Abuse::` and `Spam::` or `Security::Orchestration::` and `Security::SecurityOrchestration`.
- Domain code related to the same bounded context is scattered across multiple directories.
- Domain code is present in `lib/` directory under namespaces that differ from the same domain under `app/`.
- Some namespaces are very shallow, containing a few classes while other namespaces are very deep and large.
- A lot of the old code is not namespaced, making it difficult to understand the context where it's used.

## Goal

1. Define a list of characteristics that bounded contexts should have. For example: must relate to at least 1 product category.
1. Have a list of top-level bounded contexts where all domain code is broken down into.
1. Engineers can clearly see the list of available bounded contexts and can make an easy decision where to add
   new classes and modules.
1. Define a process for adding a new bounded context to the application. This should occur quite infrequently
   and new bounded contexts need to adhere to the characteristics defined previously.
1. Enforce the list of bounded contexts so that no new top-level namespaces can be used aside from the authorized ones.

## Iterations

### 0. Extract libraries out of the codebase

In June 2023 we've started extracing gems out of the main codebase, into
[`gems/` directory inside the monorepo](https://gitlab.com/gitlab-org/gitlab/-/blob/4c6e120069abe751d3128c05ade45ea749a033df/doc/development/gems.md).

This is our first step towards modularization.

- We want to separate generic code from domain code (that powers the business logic).
- We want to cleanup `lib/` directory from generic code.
- We want to isolate code that could live in a separate project, to prevent it from depending on domain code.

These gems as still part of the monorepo but could be extracted into dedicated repositories if needed.

Extraction of gems is non blocking to modularization but the less generic code exists in `lib/` the
easier will be identifying and separating bounded context.

### 1. What makes a bounded context?

From the research in [Proposal: split GitLab monolith into components](https://gitlab.com/gitlab-org/gitlab/-/issues/365293)
it seems that following [product categories](https://handbook.gitlab.com/handbook/product/categories/#hierarchy), as a guideline,
would be much better than translating organization structure into folder structure (for example, `app/modules/verify/pipeline-execution/...`).

However, this guideline alone is not sufficient and we need a more specific strategy:

- Product categories can change ownership and we have seen some pretty frequent changes, even back and forth.
  Moving code every time a product category changes ownership adds too much maintenance overhead.
- Teams and organization changes should just mean relabelling the ownership of specific modules.
- Bounded contexts (top level modules) should be [sufficiently deep](../../../development/software_design.md#use-namespaces-to-define-bounded-contexts)
  to encapsulate implementation details and provide a smaller interface.
- Some product categories, such as Browser Performance Testing, are just too small to represent a bounded context on their own.
  We should have a strategy for grouping product categories together when makes sense.
- Product categories don't necessarily translate into clean boundaries.
  `Category:Pipeline Composition` and `Category:Continuous Integration` are some examples where Pipeline Authoring team
  and Pipeline Execution team share a lot of code.
- Some parts of the code might not have a clear product category associated to it.

Despite the above, product categories provide a rough view of the bounded contexts at play in the application.

One idea could be to use product categories to sketch the initial set of bounded contexts.
Then, group related or strongly coupled categories under the same bounded context and create new bounded contexts if missing.

### 2. Identify existing bounded contexts

Start with listing all the Ruby files in a spreadsheet and categorize them into components following the guidelines above.
Some of them are already pretty explicit like Ci::, Packages::, etc. Components should follow our
[existing naming guide](../../../development/software_design.md#use-namespaces-to-define-bounded-contexts).

This could be a short-lived Working Group with representative members of each DevOps stage (for example, Senior+ engineers).
The WG would help defining high-level components and will be the DRIs for driving the changes in their respective DevOps stage.

### 3. Publish the list of bounded contexts

The list of bounded contexts (top-level namespaces) extracted from the codebase should be defined statically so it can be
used programmatically.

```yaml
# file: config/bounded_contexts.yml
bounded_contexts:
  continuous_integration:
    dir: modules/ci
    namespace: 'Ci::'
  packages: ...
  merge_requests: ...
  git: ...
```

With this static list we could:

- Document the existing bounded contexts for engineers to see the big picture.
- Understand where to place new classes and modules.
- Enforce if any top-level namespaces are used that are not in the list of bounded contexts.
- Autoload non-standard Rails directories based on the given list.
