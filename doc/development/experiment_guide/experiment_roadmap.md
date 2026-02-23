---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Experimentation Framework Roadmap
---

We're actively investing in improving the experimentation platform based on feedback from teams running experiments at
scale. The full roadmap is tracked in
[Improve Growth experiment process and velocity](https://gitlab.com/groups/gitlab-org/-/epics/19812).

## Planned Improvements

### Sticky candidate assignments across exclusion boundaries

Currently, control assignments are cached and remain sticky, but candidate assignments can be overridden by exclusion
rules in subsequent experiment blocks. We're working on allowing cached candidate assignments to take precedence over
exclusion logic, simplifying multi-step experiment flows - especially in registration and onboarding scenarios where
context is built up progressively.

Related: <!-- markdownlint-disable-line MD044 -->[gitlab-experiment#91](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment/-/issues/91)

### Forced variant assignment for testing and validation

Engineers need a way to force themselves into specific experiment variants during UAT and staging validation - including
for anonymous entry points and backend-only experiments where there's no clear UI parameter to pass. We're exploring
approaches through segmentation rules and operational tooling.

Related: <!-- markdownlint-disable-line MD044 -->[gitlab#579133](https://gitlab.com/gitlab-org/gitlab/-/issues/579133)

### Improved event validation and observability

Verifying that experiment tracking events are structured correctly and arriving in analytics pipelines is currently a
late-stage, manual process. We're working on shifting event validation left in the development cycle and providing
near-realtime observability for staging and production environments.

Related: <!-- markdownlint-disable-line MD044 -->[gitlab#579150](https://gitlab.com/gitlab-org/gitlab/-/issues/579150), [gitlab#579137](https://gitlab.com/gitlab-org/gitlab/-/issues/579137)

### Graceful experiment transitions

When experiments conclude and are either promoted or reverted, users can experience a jarring shift in their experience.
We're improving the cleanup process to account for these user experience transitions and provide guidance on handling
them smoothly.

Related: <!-- markdownlint-disable-line MD044 -->[gitlab#579148](https://gitlab.com/gitlab-org/gitlab/-/issues/579148)

## Goals

- Reduce time from experiment design to implementation
- Fewer tracking-related issues during rollout
- Improved developer experience across the experiment lifecycle
