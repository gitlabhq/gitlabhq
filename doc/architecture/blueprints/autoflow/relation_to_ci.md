---
stage: Deploy
group: Environments
info: Relation of GitLab AutoFlow to GitLab CI
---

# Relation of GitLab AutoFlow to GitLab CI

GitLab CI and GitLab AutoFlow are different tools for solving different sets of problems. Here are the differences based
on the
[PoC](https://gitlab.com/groups/gitlab-org/-/epics/12571#note_1759648935) / [demo implementation](https://gitlab.com/gitlab-org/ci-cd/section-showcases/-/issues/54)
of the idea that is based on [Temporal](https://temporal.io/). Technical details and decisions on what technology to use
will be part of separate documents. But, since the question of relation to GitLab CI came up a few times, the following
is documented here to pre-emptively answer the question.

## Conceptual differentiation

- GitLab CI solves the problem of Continuous Integration. Use it to build and test your software.
- GitLab AutoFlow solves the problem of automation in the DevSecOps domain, but not CI.
  Use it to automate business processes.

## Task-based differentiation

Use GitLab CI if:

- Need to execute a program/binary/tool, including a (shell) script.
- Need to execute a container.
- Need to perform heavy computations.
- Need lots of RAM to perform an operation.

Use GitLab AutoFlow:

- Orchestrating complex, cross-project CI pipelines as part of the DevSecOps domain.
- Manipulating DevOps domain object(s) when something happens (or on a schedule) by calling APIs.
- Need to wait for an unspecified amount of time (possibly days or even weeks) for async events to take place
  before proceeding.

## Implementation differences

Temporal-based GitLab AutoFlow implementation:

- Designed for durable execution. I.e. can safely resume workflow execution after failure.
- Designed to run for an arbitrary long time (literary years). I.e. can wait for events and/or timers to "wake up" a
  workflow, only occupying disk space in the DB for state storage. No CPU/RAM resources are reserved/used for a
  non-executing workflow.
- Not designed to run heavy execution tasks. This is not a limitation of Temporal (as it does not run any code), it's
  just this PoC doesn't give user a way to run something computationally expensive. Well, you could do computations in
  Starlark, but you cannot run an external program.
- Not designed to run containers.
- Activities (executable unit of a workflow) have near-zero execution overhead. Think "function invocation" in an
  already
  running program. No startup cost at all. Activities are literally functions in kas that kas calls when it's told to.
- Not designed (at least not in this PoC) to run untrusted code BUT Starlark interpreter is not doing code generation
  and is built in Go, not C, so most of typical "interpreter VM" vulnerabilities are simply impossible. This means it's
  quite safe to execute untrusted Starlark code. Such code can only interact with the host program/machine via objects
  explicitly injected into the script, which we control, it cannot do anything else.

GitLab CI:

- Is not designed for durable execution. If a job fails, it can be manually restarted. It will run from the start,
  not from a particular point where it failed. It may not be safe to restart a failed job because it depends on what the
  user is doing there. It's by far not a 1:1 comparison, but unlike CI jobs, Temporal activities are/must be idempotent
  so are safe to retry automatically.
- Designed as a perfect solution for Continuous Integration.
- Designed to run arbitrary containers and untrusted code.
