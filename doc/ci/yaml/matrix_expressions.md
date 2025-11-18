---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Matrix expressions in GitLab CI/CD
---

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423553) in GitLab 18.6. This feature is in [beta](../../policy/development_stages_support.md#beta).

{{< /history >}}

Matrix expressions enable dynamic job dependencies based on [`parallel:matrix`](_index.md#parallelmatrix)
identifiers, to create 1:1 mappings between `parallel:matrix` jobs.

Matrix expressions have some limitations compared to [inputs expressions](expressions.md#inputs-context):

- Compile-time only: Identifiers are resolved when the pipeline is created, not during job execution.
- String replacement only: No complex logic or transformations.
- Matrix identifiers only: Cannot reference CI/CD variables or inputs.

## Syntax

Matrix expressions use the `$[[ matrix.IDENTIFIER ]]` syntax to reference a
`parallel:matrix` identifier in job dependencies. For example:

```yaml
needs:
  - job: build
    parallel:
      matrix:
        - OS: ['$[[ matrix.OS ]]']
          ARCH: ['$[[ matrix.ARCH ]]']
```

### Matrix expressions in `needs:parallel:matrix`

You can use matrix expressions to dynamically reference matrix identifiers in job dependencies,
enabling 1:1 mappings between matrix jobs without manually specifying all combinations.

For example:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]

linux:test:
  stage: test
  script: echo "Testing linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: ['$[[ matrix.PROVIDER ]]']
            STACK: ['$[[ matrix.STACK ]]']
```

This example creates a 1:1 dependency mapping between all `linux:build` and `linux:test` jobs:

- `linux:test: [aws, monitoring]` depends on `linux:build: [aws, monitoring]`
- `linux:test: [aws, app1]` depends on `linux:build: [aws, app1]`
- The same applies for all 6 `parallel:matrix` value combinations.

With `matrix.` expressions you do not need to manually specify each matrix combination.

Matrix expressions reference identifiers from the current job's matrix configuration only.

### Use YAML anchors to reuse `parallel:matrix` configuration

You can use [YAML anchors](yaml_optimization.md#anchors) to reuse the `parallel:matrix`
configuration across multiple jobs with complex `parallel:matrix` configuration and dependencies.

For example:

```yaml
stages:
  - compile
  - test
  - deploy

.build_matrix: &build_matrix
  parallel:
    matrix:
      - OS: ["ubuntu", "alpine"]
        ARCH: ["amd64", "arm64"]
        VARIANT: ["slim", "full"]

compile_binary:
  stage: compile
  script:
    - echo "Compiling for $OS-$ARCH-$VARIANT"
  <<: *build_matrix

integration_test:
  stage: test
  script:
    - echo "Testing $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: compile_binary
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']

deploy_artifact:
  stage: deploy
  script:
    - echo "Deploying $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: integration_test
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']
```

This configuration creates 24 jobs: 8 jobs in each stage (2 `OS` × 2 `ARCH` × 2 `VARIANT` combinations),
with 1:1 dependencies between stages.

### Use a subset of values

You can combine matrix expressions with specific values to create selective subset of dependencies:

```yaml
stages:
  - prepare
  - build
  - test

.full_matrix: &full_matrix
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]
        VERSION: ["16", "18", "20"]

.platform_only: &platform_only
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]

prepare_env:
  stage: prepare
  script:
    - echo "Preparing $PLATFORM with Node.js $VERSION"
  <<: *full_matrix

build_project:
  stage: build
  script:
    - echo "Building on $PLATFORM"
  needs:
    - job: prepare_env
      parallel:
        matrix:
          - PLATFORM: ['$[[ matrix.PLATFORM ]]']
            VERSION: ["18"]  # Only depend on Node.js 18 preparations
  <<: *platform_only
```

In this example:

- `prepare_env` uses `parallel:matrix` to create 9 jobs: 3 `PLATFORM` × 3 `VERSIONS`.
- `build_project` use `parallel:matrix` to create 3 jobs: 3 `PLATFORM` values only.
- Each `build_project` job depends only on Node.js `18` (`VERSION`) for all platforms (`PLATFORM`).

Alternatively, you can [configure all the dependencies manually](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs).

## Related topics

- [Parallel jobs with matrix](../jobs/job_control.md#parallelize-large-jobs)
- [Job dependencies with `needs`](needs.md)
- [CI expressions overview](expressions.md)
- [YAML optimization](yaml_optimization.md)
