---
status: proposed
creation-date: "2023-05-22"
authors: [ "@grzesiek", "@fabiopitino" ]
coach: [ ]
approvers: [ ]
owning-stage: ""
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# GitLab Modular Monolith

## Summary

The main [GitLab Rails](https://gitlab.com/gitlab-org/gitlab)
project has been implemented as a large monolithic application, using
[Ruby on Rails](https://rubyonrails.org/) framework. It has over 2.2 million
lines of Ruby code and hundreds of engineers contributing to it every day.

The application has been growing in complexity for more than a decade. The
monolithic architecture has served us well during this time, making it possible
to keep high development velocity and great engineering productivity.

Even though we strive for having [an approachable open-core architecture](https://about.gitlab.com/blog/2022/07/14/open-core-is-worse-than-plugins/)
we need to strengthen the boundaries between domains to retain velocity and
increase development predictability.

As we grow as an engineering organization, we want to explore a slightly
different, but related, architectural paradigm:
[a modular monolith design](https://en.wikipedia.org/wiki/Modular_programming),
while still using a [monolithic architecture](https://en.wikipedia.org/wiki/Monolithic_application)
with satellite services.

This should allow us to increase engineering efficiency, reduce the cognitive
load, and eventually decouple internal components to the extend that will allow
us to deploy and run them separately if needed.

## Motivation

Working with a large and tightly coupled monolithic application is challenging:

Engineering:

- Onboarding engineers takes time. It takes a while before engineers feel
  productive due to the size of the context and the amount of coupling.
- We need to use `CODEOWNERS` file feature for several domains but
  [these rules are complex](https://gitlab.com/gitlab-org/gitlab/-/blob/409228f064a950af8ff2cecdd138fc9da41c8e63/.gitlab/CODEOWNERS#L1396-1457).
- It is difficult for engineers to build a mental map of the application due to its size.
  Even apparently isolated changes can have [far-reaching repercussions](https://handbook.gitlab.com/handbook/engineering/core-development/#reducing-the-impact-of-far-reaching-work)
  on other parts of the monolith.
- Attrition/retention of engineering talent. It is fatiguing and demoralizing for
  engineers to constantly deal with the obstacles to productivity.

Architecture:

- There is little structure inside the monolith. We have attempted to enforce
  the creation [of some modules](https://gitlab.com/gitlab-org/gitlab/-/issues/212156)
  but have no company-wide strategy on what the functional parts of the
  monolith should be, and how code should be organized.
- There is no isolation between existing modules. Ruby does not provide
  out-of-the-box tools to effectively enforce boundaries. Everything lives
  under the same memory space.
- We rarely build abstractions that can boost our efficiency.
- Moving stable parts of the application into separate services is impossible
  due to high coupling.
- We are unable to deploy changes to specific domains separately and isolate
  failures that are happening inside them.

Productivity:

- High median-time-to-production for complex changes.
- It can be overwhelming for the wider-community members to contribute.
- Reducing testing times requires diligent and persistent efforts.

## Goals

- Increase the development velocity and predicability through separation of concerns.
- Improve code quality by reducing coupling and introducing useful abstractions.
- Build abstractions required to deploy and run GitLab components separately.

## How do we get there?

While we do recognize that modularization is a significant technical endeavor,
we believe that the main challenge is organizational, rather than technical. We
not only need to design separation in a way that modules are decoupled in a
pragmatic way which works well on GitLab.com but also on self-managed
instances, but we need to align modularization with the way in which we want to
work at GitLab.

There are many aspects and details required to make modularization of our
monolith successful. We will work on the aspects listed below, refine them, and
add more important details as we move forward towards the goal:

1. [Deliver modularization proof-of-concepts that will deliver key insights](proof_of_concepts.md).
1. Align modularization plans to the organizational structure by [defining bounded contexts](bounded_contexts.md).
1. [Separate domains into modules](packages_extraction.md) that will reflect organizational structure.
1. Start a training program for team members on how to work with decoupled domains (TODO)
1. Build tools that will make it easier to build decoupled domains through inversion of control (TODO)
1. [Introduce hexagonal architecture within the monolith](hexagonal_monolith/index.md)
1. Introduce clean architecture with one-way-dependencies and host application (TODO)
1. Build abstractions that will make it possible to run and deploy domains separately (TODO)

## Status

In progress.

## Glossary

- `modules` are Ruby modules and can be used to nest code hierarchically.
- `namespaces` are unique hierarchies of Ruby constants. For example, `Ci::` but also `Ci::JobArtifacts::` or `Ci::Pipeline::Chain::`.
- `packages` are Packwerk packages to group together related functionalities. These packages can be big or small depending on the design and architecture. Inside a package all constants (classes and modules) have the same namespace. For example:
  - In a package `ci`, all the classes would be nested under `Ci::` namespace. There can be also nested namespaces like `Ci::PipelineProcessing::`.
  - In a package `ci-pipeline_creation` all classes are nested under `Ci::PipelineCreation`, like `Ci::PipelineCreation::Chain::Command`.
  - In a package `ci` a class named `MergeRequests::UpdateHeadPipelineService` would not be allowed because it would not match the package's namespace.
  - This can be enforced easily with [Packwerk's based Rubocop Cops](https://github.com/rubyatscale/rubocop-packs/blob/main/lib/rubocop/cop/packs/root_namespace_is_pack_name.rb).
- `bounded context` is a top-level Packwerk package that represents a macro aspect of the domain. For example: `Ci::`, `MergeRequests::`, `Packages::`, etc.
  - A bounded context is represented by a single Ruby module/namespace. For example, `Ci::` and not `Ci::JobArtifacts::`.
  - A bounded context can be made of 1 or multiple Packwerk packages. Nested packages would be recommended if the domain is quite complex and we want to enforce privacy among all the implementation details. For example: `Ci::PipelineProcessing::` and `Ci::PipelineCreation::` could be separate packages of the same bounded context and expose their public API while keeping implementation details private.
  - A new bounded context like `RemoteDevelopment::` can be represented a single package while large and complex bounded contexts like `Ci::` would need to be organized into smaller/nested packages.

## References

[List of references](references.md)
