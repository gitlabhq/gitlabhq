---
status: proposed
creation-date: "2023-08-23"
authors: [ "@ayufan" ]
coach: "@grzegorz"
approvers: [ "@dhershkovitch", "@gabrielengel_gl" ]
owning-stage: "~devops::verify"
participating-stages: [ ]
---

# Step Runner for executing GitLab Steps

## Summary

This document describes architecture of a new component called Step Runner, the GitLab Steps syntax it uses,
and how the GitHub Actions support will be achieved.

The competitive CI products [drone.io](https://drone.io),
[GitHub Actions](https://docs.github.com/en/actions/creating-actions)
have a composable CI jobs execution in form of steps, or actions.

Their usage and our prior evaluation of [GitLab Runner Plugins](https://gitlab.com/gitlab-org/gitlab/-/issues/15067)
shows a need for a better way to define CI job execution.

## Glossary

- GitLab Steps: a name of GitLab CI feature to define and use reusable components
  within a single job execution context.
- Step Runner: a RFC implementation for GitLab Steps that provides compatibility with the GitHub Actions.
- GitHub Actions: similar to GitLab Steps, a reusable execution component used on GitHub.
- CI Catalog: a public or private component catalog that could be used to discover and use shared components.
- GitLab Rails: a main application responsible for pipeline execution, running on GitLab.com or on-premise installation.

## Motivation

Even though the current [`.gitlab-ci.yml`](../../../ci/yaml/gitlab_ci_yaml.md) is reasonably flexible, it easily becomes very
complex when trying to support complex workflows. This complexity is represented
with repetetitve patterns, a purpose-specific syntax, or a complex sequence of commands
to execute.

This is particularly challenging, because the [`.gitlab-ci.yml`](../../../ci/yaml/gitlab_ci_yaml.md)
is inflexible on more complex workflows that require fine-tuning or special behavior
for the CI job execution. Its prescriptive approach how to handle Git cloning,
when artifacts are downloaded, or how the shell script is being executed quite often
results in the need to work around the system for pipelines that are not "standard"
or when new features are requested.

This proves especially challenging when trying to add a new syntax to the
[`.gitlab-ci.yml`](../../../ci/yaml/gitlab_ci_yaml.md)
to support a specific feature, like [`secure files`](../../../ci/secure_files/index.md)
or `release:` keyword. Adding these special features on a syntax level
results in a more complex config, which is harder to maintain, and more complex
to deal with technical debt when requirements change.

An example of the `drone.io` and the `GitHub Actions` shows that a lot of workflows do not
have to be part of CI syntax. Instead, they can be provided in the form of reusable components
that are configured in a generic way in the CI config, and later downloaded and executed according
to inputs and parameters.

The GitLab Steps is meant to fill that product-gap by following similar model to competitors
and to some extent staying compatible with them. The GitLab Steps is meant to replace all
purpose-specific syntax to handle specific features. By providing and using reusable components,
that are build outside of `.gitlab-ci.yml`, that are versioned, and requested when needed
this allows the customer much more flexibility, and allows us to iterate on a catalog much faster.

The reusable components that are part of a CI job execution could be used from a publicily hosted
repository on GitLab.com, from on-premise repository of steps, or be fetched from local project.

Each CI job would define a list of `steps:` to execute, that would reference GitLab Steps
or GitHub Actions. Those steps would be executed by the step runner directly in the context of
the target environment. GitLab Runner would be responsible to be connection between GitLab.com
(or on-premise installation) and Step Runner.

### Goals

GitLab Steps:

- GitLab Steps defines a syntax and structure for GitLab specific Steps implementation.
- GitLab Steps are published in CI Catalog.
- GitLab Steps can be used across instances (federation).
- GitLab Steps do define `inputs` and `outputs`.
- GitLab Steps needs to explicitly request sensitive informations with expected permissions.
  For example: secrets, variables, tokens.

GitLab Inc. managed repository of GitLab Steps:

- GitLab Inc. provides a repository of GitLab Steps that are a drop-in replacement
  for all current purpose-specific syntax: `artifacts:`, `cache:`, `release:`, etc.
- GitLab Inc. will provide a generic step to execute `shell` steps supporting various
  shells (`bash`, `powershell`).
- The usage of purpose-specific syntax might be eventually deprecated in favor of steps.

Step Runner:

- Step Runner is hosted in a separate project in `https://gitlab.com/gitlab-org`.
- Step Runner can be used to execute most of GitHub Actions.
- Step Runner is run as a process in a target environment.
- Step Runner can be used by user on their local machine to run steps of a specific CI job
  from locally stored `.gitlab-ci.yml`.
- Step Runner is external component to GitLab Runner, the GitLab Runner does provision
  environment, construct payload and pass execution to Step Runner.
- Step Runner is to replace all custom handling in GitLab Runner for `clone`, `artifacts`,
  `caches`, `script` and `after_script`, and custom handling for all different shells (`bash`, `powershell`).
- Step Runner is responsible for parsing and compiling GitLab Steps and GitHub Actions.
- Step Runner is responsible for downloading, and managing repositories required by GitLab Steps and GitHub Actions.
- Step Runner does control and monitor execution flow of individual steps of execution.
- Step Runner is required to be executable via command line interface (CLI). It means that it can be configured either via config file,
  or environment file, or be able to read `.gitlab-ci.yml`.
- Step Runner can expose gRPC or other programmable interface to run config or get trace from.

Steps Execution:

- Each Step is defined by a single published or locally defined GitLab Step, or GitHub Action.
- Each Step is executed depending on conditions that are defined by that step.
- Each Step is executed with least amount of information exposed. Exposed informations to step
  are requested explicitly by the step. For example: only environment variables explicitly
  requested by the step will be passed to the step.
- Each Step is considered untrusted. It means that even though some steps are trusted, the whole
  CI job should be considered untrusted, since system cannot guarantee trust.
- Each Step describes its execution in a form of preconditions, versions used, and output produced.
  This is meant to allow to sign steps execution for the purpose of creating reproducible builds.

Backward compatibility:

- All currently executable syntax (for example: `before_script:`, `script:`, `artifacts:`, `cache:`, etc.)
  should be convertible by GitLab (Rails)

## Non-Goals

TBD

## Proposal

TBD

## Design and implementation details

TBD

## References

- [GitLab Issue #215511](https://gitlab.com/gitlab-org/gitlab/-/issues/215511)
