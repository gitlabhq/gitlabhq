---
status: proposed
creation-date: "2023-06-21"
authors: [ "@fabiopitino" ]
coach: [ ]
approvers: [ ]
owning-stage: ""
---

# References

## Related design docs

- [Composable codebase design doc](../composable_codebase_using_rails_engines/index.md)

## Related Issues

- [Split GitLab monolith into components](https://gitlab.com/gitlab-org/gitlab/-/issues/365293)
- [Make it simple to build and use "Decoupled Services"](https://gitlab.com/gitlab-org/gitlab/-/issues/31121)
- [Use nested structure to organize CI classes](https://gitlab.com/gitlab-org/gitlab/-/issues/209745)
- [Create new models / classes within a module / namespace](https://gitlab.com/gitlab-org/gitlab/-/issues/212156)
- [Make teams to be maintainers of their code](https://gitlab.com/gitlab-org/gitlab/-/issues/25872)
- [Add backend guide for Dependency Injection](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73644)

## Internal Slack Channels

- [`#modular_monolith`](https://gitlab.slack.com/archives/C03NTK6HZBM)
- [`#architecture`](https://gitlab.slack.com/archives/CJ4DB7517)

## Reference Implementations / Guides

Gusto / RubyAtScale:

- [RubyAtScale toolchain for modularization](https://github.com/rubyatscale)
- [Gusto's engineering blog](https://engineering.gusto.com/laying-the-cultural-and-technical-foundation-for-big-rails/)
- [Gradual modularization](https://gradualmodularization.com/) (successor to CBRA)
- [Component-Based Rails Applications](https://cbra.info) ("deprecated")

Shopify:

- [Packwerk](https://github.com/Shopify/packwerk)
- [Shopify's jurney to modularization](https://shopify.engineering/shopify-monolith)
- [Internal GitLab doc transcript of an AMA with a Shopify engineer](https://docs.google.com/document/d/1uZbcaK8Aqs-D_n7_uQ5XE295r5UWDJEBwA6g5bTjcwc/edit#heading=h.d1tml5rlzrpa)

Domain-Driven Rails / Rails Event Store:

Rails Event Store is relevant because it is a mechanism to achieve many
of the goals discussed here, and is based upon patterns used by Arkency
to build production applications.

This doesn't mean we need to use this specific framework or approach.

However, the general concepts of DDD/ES/CQRS are important and in some
cases maybe necessary to achieve the goals of this blueprint, so it's
useful to have concrete production-proven implementations of those
concepts to look at as an example.

- [Arkency's domain-driven Rails](https://products.arkency.com/domain-driven-rails/)
- [Arkency's Rails Event Store](https://railseventstore.org)

App Continuum:

An illustration of how an application can evolve from a small, unstructured app, through various
stages including a modular well-structured monolith, all the way to a microservices architecture.

Includes discussion of why you might want to stop at various stages, and specifically the
challenges/concerns with making the jump to microservices, and why sticking with a
well-structured monolith may be preferable in many cases.

- [App Continuum](https://www.appcontinuum.io)
