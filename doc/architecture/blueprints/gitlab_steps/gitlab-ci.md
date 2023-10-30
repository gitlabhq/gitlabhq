---
owning-stage: "~devops::verify"
description: Usage of the [GitLab Steps](index.md) with [`.gitlab-ci.yml`](../../../ci/yaml/index.md).
---

# Usage of the [GitLab Steps](index.md) with [`.gitlab-ci.yml`](../../../ci/yaml/index.md)

This document describes how [GitLab Steps](index.md) are integrated into the `.gitlab-ci.yml`.

GitLab Steps will be integrated using a three-stage execution cycle
and replace `before_script:`, `script:` and `after_script:`.

- `setup:`: Execution stage responsible for provisioning the environment,
  including cloning the repository, restoring artifacts, or installing all dependencies.
  This stage will replace implicitly cloning, restoring artifacts, and cache download.
- `run:`: Execution stage responsible for running a test, build,
  or any other main command required by that job.
- `teardown:`: Execution stage responsible for cleaning the environment,
  uploading artifacts, or storing cache. This stage will replace implicit
  artifacts and cache uploads.

Before we can achieve three-stage execution we will ship minimal initial support
that does not require any prior GitLab integration.

## Phase 1: Initial support

Initially the Step Runner will be used externally, without any prior dependencies
to GitLab:

- The `step-runner` will be provided as part of a container image.
- The `step-runner` will be explicitly run in the `script:` section.
- The `$STEPS` environment variable will be executed as [`type: steps`](step-definition.md#the-steps-step-type).

```yaml
hello-world:
  image: registry.gitlab.com/gitlab-org/step-runner
  variables:
    STEPS: |
      - step: gitlab.com/josephburnett/component-hello-steppy@master
        inputs:
          greeting: "hello world"
  script:
    - /step-runner ci
```

## Phase 2: The addition of `run:` to `.gitlab-ci.yml`

In Phase 2 we will add `run:` as a first class way to use GitLab Steps:

- `run:` will use a [`type: steps`](step-definition.md#the-steps-step-type) syntax.
- `run:` will replace usage of `before_script`, `script` and `after_script`.
- All existing functions to support Git cloning, artifacts, and cache would continue to be supported.
- It is yet to be defined how we would support `after_script`, which is executed unconditionally
  or when the job is canceled.
- `run:` will not be allowed to be combined with `before_script:`, `script:` or `after_script:`.
- GitLab Rails would not parse `run:`, instead it would only perform static validation
  with a JSON schema provided by the Step Runner.

```yaml
hello-world:
  image: registry.gitlab.com/gitlab-org/step-runner
  run:
    - step: gitlab.com/josephburnett/component-hello-steppy@master
      inputs:
        greeting: "hello world"
```

The following example would **fail** syntax validation:

```yaml
hello-world:
  image: registry.gitlab.com/gitlab-org/step-runner
  run:
    - step: gitlab.com/josephburnett/component-hello-steppy@master
      inputs:
        greeting: "hello world"
  script: echo "This is ambiguous and invalid example"
```

### Transitioning from `before_script:`, `script:` and `after_script:`

GitLab Rails would automatically convert the `*script:` syntax into relevant `run:` specification:

- Today `before_script:` and `script:` are joined together as a single script for execution.
- The `after_script:` section is always executed in a separate context, representing a separate step to be executed.
- It is yet to be defined how we would retain the existing behavior of `after_script`, which is always executed
  regardless of the job status or timeout, and uses a separate timeout.
- We would retain all implicit behavior which defines all environment variables when translating `script:`
  into step-based execution.

For example, this CI/CD configuration:

```yaml
hello-world:
  before_script:
    - echo "Run before_script"
  script:
    - echo "Run script"
  after_script:
    - echo "Run after_script"
```

Could be translated into this equivalent specification:

```yaml
hello-world:
  run:
    - step: gitlab.com/gitlab-org/components/steps/legacy/script@v1.0
      inputs:
        script:
          - echo "Run before_script"
          - echo "Run script"
    - step: gitlab.com/gitlab-org/components/steps/legacy/script@v1.0
      inputs:
        script:
          - echo "Run after_script"
      when: always
```

## Phase 3: The addition of `setup:` and `teardown:` to `.gitlab-ci.yml`

The addition of `setup:` and `teardown:` will replace the implicit functions
provided by GitLab Runner: Git clone, artifacts and cache handling:

- The usage of `setup:` would stop GitLab Runner from implicitly cloning the repository.
- `artifacts:` and `cache:`, when specified, would be translated and appended to `setup:` and `teardown:`
  to provide backward compatibility for the old syntax.
- `release:`, when specified, would be translated and appended to `teardown:`
  to provide backward compatibility for the old syntax.
- `setup:` and `teardown:` could be used in `default:` to simplify support
  of common workflows like where the repository is cloned, or how the artifacts are handled.
- The split into 3-stage execution additionally improves composability of steps with `extends:`.
- The `hooks:pre_get_sources_script` would be implemented similar to [`script:`](#transitioning-from-before_script-script-and-after_script)
  and be prepended to `setup:`.

For example, this CI/CD configuration:

```yaml
rspec:
  script:
    - echo "This job uses a cache."
  artifacts:
    paths: [binaries/, .config]
  cache:
    key: binaries-cache
    paths: [binaries/*.apk, .config]
```

Could be translated into this equivalent specification executed by a step runner:

```yaml
rspec:
  setup:
    - step: gitlab.com/gitlab-org/components/git/clone@v1.0
    - step: gitlab.com/gitlab-org/components/artifacts/download@v1.0
    - step: gitlab.com/gitlab-org/components/cache/restore@v1.0
      inputs:
        key: binaries-cache
  run:
    - step: gitlab.com/gitlab-org/components/steps/legacy/script@v1.0
      inputs:
        script:
          - echo "This job uses a cache."
  teardown:
    - step: gitlab.com/gitlab-org/components/artifacts/upload@v1.0
      inputs:
        paths: [binaries/, .config]
    - step: gitlab.com/gitlab-org/components/cache/restore@v1.0
      inputs:
        key: binaries-cache
        paths: [binaries/*.apk, .config]
```

### Inheriting common operations with `default:`

`setup:` and `teardown:` are likely to become very verbose over time. One way to simplify them
is to allow inheriting the common `setup:` and `teardown:` operations
with `default:`.

The previous example could be simplified to:

```yaml
default:
  setup:
    - step: gitlab.com/gitlab-org/components/git/clone@v1.0
    - step: gitlab.com/gitlab-org/components/artifacts/download@v1.0
    - step: gitlab.com/gitlab-org/components/cache/restore@v1.0
      inputs:
        key: binaries-cache
  teardown:
    - step: gitlab.com/gitlab-org/components/artifacts/upload@v1.0
      inputs:
        paths: [binaries/, .config]
    - step: gitlab.com/gitlab-org/components/cache/restore@v1.0
      inputs:
        key: binaries-cache
        paths: [binaries/*.apk, .config]

rspec:
  run:
    - step: gitlab.com/gitlab-org/components/steps/legacy/script@v1.0
      inputs:
        script:
          - echo "This job uses a cache."

linter:
  run:
    - step: gitlab.com/gitlab-org/components/steps/legacy/script@v1.0
      inputs:
        script:
          - echo "Run linting"
```

### Parallel jobs and `setup:`

With the introduction of `setup:` at some point in the future we will introduce
an efficient way to parallelize the jobs:

- `setup:` would define all steps required to provision the environment.
- The result of `setup:` would be snapshot and distributed as the base
  for all parallel jobs, if `parallel: N` is used.
- The `run:` and `teardown:` would be run on top of cloned job, and all its services.
- The runner would control and intelligently distribute all parallel
  jobs, significantly cutting the resource requirements for fixed
  parts of the job (Git clone, artifacts, installing dependencies.)

```yaml
rspec-parallel:
  image: ruby:3.2
  services: [postgres, redis]
  parallel: 10
  setup:
    - step: gitlab.com/gitlab-org/components/git/clone@v1.0
    - step: gitlab.com/gitlab-org/components/artifacts/download@v1.0
      inputs:
        jobs: [setup-all]
    - script: bundle install --without production
  run:
    - script: bundle exec knapsack
```

Potential GitLab Runner flow:

1. Runner receives the `rspec-parallel` job with `setup:` and `parallel:` configured.
1. Runner executes a job on top of Kubernetes cluster using block volumes up to the `setup`.
1. Runner then runs 10 parallel jobs in Kubernetes, overlaying the block volume from 2
   and continue execution of `run:` and `teardown:`.
