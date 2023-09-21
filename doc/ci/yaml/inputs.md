---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Define inputs for configuration added with `include` **(FREE ALL BETA)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) in GitLab 15.11 as a Beta feature.

FLAG:
`spec` and `inputs` are experimental [Open Beta features](../../policy/experiment-beta-support.md#beta)
and subject to change without notice.

## Define input parameters with `spec:inputs`

> `description` keyword [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415637) in GitLab 16.5.

Use `spec:inputs` to define input parameters for CI/CD configuration intended to be added
to a pipeline with `include`. Use [`include:inputs`](#set-input-parameter-values-with-includeinputs)
to define the values to use when the pipeline runs.

The specs must be declared at the top of the configuration file, in a header section.
Separate the header from the rest of the configuration with `---`.

Use the interpolation format `$[[ input.input-id ]]` to reference the values outside of the header section.
The inputs are evaluated and interpolated once, when the configuration is fetched
during pipeline creation, but before the configuration is merged with the contents of the `.gitlab-ci.yml`.

```yaml
spec:
  inputs:
    environment:
    job-stage:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

When using `spec:inputs`:

- Defined inputs are mandatory by default.
- Inputs can be made optional by specifying a `default`. Use `default: null` to have no default value.
- You can optionally use `description` to give a description to a specific input.
- A string containing an interpolation block must not exceed 1 MB.
- The string inside an interpolation block must not exceed 1 KB.

For example, a `custom_configuration.yml`:

```yaml
spec:
  inputs:
    website:
    user:
      default: 'test-user'
    flags:
      default: null
      description: 'Sample description of the `flags` input detail.'
---

# The pipeline configuration would follow...
```

In this example:

- `website` is mandatory and must be defined.
- `user` is optional. If not defined, the value is `test-user`.
- `flags` is optional. If not defined, it has no value. The optional description should give details about the input.

## Set input parameter values with `include:inputs`

> `include:with` [renamed to `include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780) in GitLab 16.0.

Use `include:inputs` to set the values for the parameters when the included configuration
is added to the pipeline.

For example, to include a `custom_configuration.yml` that has the same specs
as the [example above](#define-input-parameters-with-specinputs):

```yaml
include:
  - local: 'custom_configuration.yml'
    inputs:
      website: "My website"
```

In this example:

- `website` has a value of `My website` for the included configuration.

### Use `include:inputs` with multiple files

`inputs` must be specified separately for each included file. For example:

```yaml
include:
  - component: gitlab.com/org/my-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

You can also include the same file multiple times, with different inputs.
For example:

```yaml
include:
  - local: path/to/my-super-linter.yml
    inputs:
      type: docs
      job-name: lint-docs
      lint-path: "doc/"
  - local: path/to/my-super-linter.yml
    inputs:
      type: yaml
      job-name: lint-yaml
      lint-path: "data/yaml/"
```

## Specify functions to manipulate input values

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) in GitLab 16.3.

You can specify predefined functions in the interpolation block to manipulate the input value.
The format supported is the following:

```yaml
$[[ input.input-id | <function1> | <function2> | ... <functionN> ]]
```

Details:

- Only [predefined interpolation functions](#predefined-interpolation-functions) are permitted.
- A maximum of 3 functions may be specified in a single interpolation block.
- The functions are executed in the sequence they are specified.

```yaml
spec:
  inputs:
    test:
      default: '0123456789'
---

test-job:
  script: echo $[[ inputs.test | truncate(1,3) ]]
```

In this example:

- The function [`truncate`](#truncate) applies to the value of `inputs.test`.
- Assuming the value of `inputs.test` is `0123456789`, then the output of `script` would be `echo 123`.

### Predefined interpolation functions

#### `truncate`

Use `truncate` to shorten the interpolated value. For example:

- `truncate(<offset>,<length>)`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `offset` | Integer | Number of characters to offset by. |
| `length` | Integer | Number of characters to return after the offset. |

Example:

```yaml
$[[ inputs.test | truncate(3,5) ]]
```

Assuming the value of `inputs.test` is `0123456789`, then the output would be `34567`.
