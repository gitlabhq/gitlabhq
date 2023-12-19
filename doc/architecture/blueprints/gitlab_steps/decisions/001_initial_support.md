---
owning-stage: "~devops::verify"
description: 'GitLab Steps ADR 001: Bootstrap Step Runner'
---

# GitLab Steps ADR 001: Bootstrap Step Runner

## Context

[GitLab Steps](../index.md) is a new feature that does not have any prior usage at GitLab.
We decided that there are two important objectives at this stage of the project:

- Integrate the project into existing CI pipelines for the purpose of user evaluation as part of an [Experiment](../../../../policy/experiment-beta-support.md#experiment) phase.
- Provide a contribution framework for other developers in the form of a project with contribution guidelines.

## Decision

The [GitLab Steps: Iteration 1: Bootstrap Step Runner (MVC)](https://gitlab.com/groups/gitlab-org/-/epics/11736)
was created to achieve the following objectives:

- We defined the initial plan to bootstrap the project.
- The project will be stored in [`gitlab-org/step-runner`](https://gitlab.com/gitlab-org/step-runner).
- We will implement the [Step Definition](../step-definition.md) as a [Protocol Buffer](https://protobuf.dev/). The initial implementation is described in the [Baseline Step Proto](../implementation.md).
- Usage of [Protocol Buffers](https://protobuf.dev/) will provide strong guards for the minimal required definition to be used by the project.
- We will provide documentation on how to use GitLab Steps in existing CI pipelines.

## Alternatives

No alternatives were considered at this phase, since there's no pre-existing work at GitLab
for that type of feature.
