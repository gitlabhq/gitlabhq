---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD expressions
---

CI/CD expressions enable dynamic configuration in your CI/CD pipelines by referencing variables and inputs in specialized contexts.
GitLab evaluates expressions in the pipeline configuration before the pipeline is created.

## Configuration expressions

Configuration expressions use the `$[[ ]]` syntax and are evaluated at pipeline creation time (compile-time).
They enable dynamic configuration based on different contexts.

All configuration expressions share these characteristics:

- **Compile-time evaluation**: Values are resolved when the pipeline configuration is created,
  not during job execution. A large number of expressions can increase pipeline creation time,
  but does not affect job execution time.
- **Static resolution**: Cannot perform dynamic logic or access runtime job state.

Configuration expressions support different contexts for accessing values:

| Context                           | Syntax                     | Availability | Purpose |
|-----------------------------------|----------------------------|--------------|---------|
| [Inputs context](#inputs-context) | `$[[ inputs.INPUT_NAME ]]` | GitLab 17.0  | Reference CI/CD inputs in reusable configurations. |
| [Matrix context](#matrix-context) | `$[[ matrix.IDENTIFIER ]]` | GitLab 18.6 (Beta)  | Reference `parallel:matrix` identifiers in job dependencies. |

### Inputs context

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) in GitLab 15.11 as a beta feature.
- [Made generally available](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) in GitLab 17.0.

{{< /history >}}

Use the `inputs.` context to reference [CI/CD inputs](../inputs/_index.md) in reusable configurations
using `$[[ inputs.INPUT_NAME ]]` syntax.

For example:

```yaml
spec:
  inputs:
    environment:
      default: production
    job-stage:
      default: test
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

`input.` expressions have the following characteristics:

- Type validation: Supports `string`, `number`, `boolean`, and `array` types with validation.
  Input validation prevents pipeline creation with invalid values.
- Function support: Predefined functions like `expand_vars` and `truncate` can manipulate values.
- Scope: Available in the file where defined, or passed explicitly with `include:inputs`.

### Matrix context

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423553) in GitLab 18.6. This feature is in [beta](../../policy/development_stages_support.md#beta).

{{< /history >}}

Use the [`matrix.` context](matrix_expressions.md) to reference [`parallel:matrix`](_index.md#parallelmatrix)
values by using a `$[[ matrix.IDENTIFIER ]]` syntax. Use it in job dependencies to enable
dynamic 1:1 mappings between `parallel:matrix` jobs.

For example:

```yaml
.os-arch-matrix:
  parallel:
    matrix:
      - OS: [ubuntu, alpine]
        ARCH: [amd64, arm64]

build:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]

test:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]
  needs:
    - job: build
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
```

`matrix.` expressions have the following characteristics:

- Scoped to job-level `parallel:matrix`: Only values from the current job can be referenced.
- Automatic mapping: Creates 1:1 dependencies between matrix jobs across stages

## Related topics

- [CI/CD inputs](../inputs/_index.md)
- [Matrix expressions](matrix_expressions.md)
- [YAML optimization](yaml_optimization.md)
