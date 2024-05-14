---
status: proposed
creation-date: "2023-06-21"
authors: [ "@fabiopitino" ]
coach: [ ]
approvers: [ ]
owning-stage: ""
---

# Defining bounded contexts

## Historical context

Until May 2024 the GitLab codebase didn't have a clear domain structure.
We have [forced the creation of some modules](https://gitlab.com/gitlab-org/gitlab/-/issues/212156)
as a first step but we didn't have a well defined strategy for doing it consistently.

The majority of the code was not properly namespaced and organized:

- Ruby namespaces used didn't always represent the SSoT. We had overlapping concepts spread across multiple
  namespaces. For example: `Abuse::` and `Spam::` or `Security::Orchestration::` and `Security::SecurityOrchestration`.
- Domain code related to the same bounded context was scattered across multiple directories.
- Domain code was present in `lib/` directory under namespaces that differed from the same domain under `app/`.
- Some namespaces were very shallow, containing a few classes while other namespaces were very deep and large.
- A lot of the old code was not namespaced, making it difficult to understand the context where it was used.

In May 2024 we [defined and enforced bounded contexts](decisions/002_bounded_contexts_definition.md).

## Goal

1. Define a list of characteristics that bounded contexts should have. For example: must relate to at least 1 product category.
1. Have a list of top-level bounded contexts where all domain code is broken down into.
1. Engineers can clearly see the list of available bounded contexts and can make an easy decision where to add
   new classes and modules.
1. Define a process for adding a new bounded context to the application. This should occur quite infrequently
   and new bounded contexts need to adhere to the characteristics defined previously.
1. Enforce the list of bounded contexts so that no new top-level namespaces can be used aside from the authorized ones.

## Iterations

1. [Extract libraries out of the `lib/` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/4c6e120069abe751d3128c05ade45ea749a033df/doc/development/gems.md).
    - This step is non blocking to modularization but the less generic code exists in `lib/` the
      easier will be to identify and separate bounded context.
    - Isolate code that could live in a separate project, to prevent it from depending on domain code.

1. [ADR-001: Modularize application domain](decisions/001_modular_application_domain.md)? Start with modularizing
1. [ADR-002: Define bounded context around feature categories](decisions/002_bounded_contexts_definition.md) as a SSoT in the code.
1. [ADR-003: Assign stewards to all modules and libraries](decisions/003_stewardship.md).
1. [Publish the list of bounded contexts](../../../development/software_design.md#use-namespaces-to-define-bounded-contexts).
    - Define a SSoT list of bounded contexts.
    - Enforce enforce it using RuboCop static analyzer.
    - Autoload non-standard Rails directories based on the given list.
