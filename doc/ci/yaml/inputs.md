---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Define inputs for configuration added with `include`

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) in GitLab 15.11 as a Beta feature.

Use inputs to increase the flexibility of CI/CD configuration files that are designed
to be reused.

Inputs can use CI/CD variables, but have the same [variable limitations as the `include` keyword](includes.md#use-variables-with-include).

## Define input parameters with `spec:inputs`

Use `spec:inputs` to define input parameters for CI/CD configuration intended to be added
to a pipeline with `include`. Use [`include:inputs`](#set-input-values-when-using-include)
to pass input values when building the configuration for a pipeline.

The specs must be declared at the top of the configuration file, in a header section.
Separate the header from the rest of the configuration with `---`.

Use the interpolation format `$[[ inputs.input-id ]]` outside the header section to replace the values.
The inputs are evaluated and interpolated when the configuration is fetched during pipeline creation, but before the
configuration is merged with the contents of the `.gitlab-ci.yml` file.

For example, in a file named `custom_website_scan.yml`:

```yaml
spec:
  inputs:
    job-stage:
    environment:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

When using `spec:inputs`:

- Inputs are mandatory by default.
- Validation errors are returned if:
  - A string containing an interpolation block exceeds 1 MB.
  - The string inside an interpolation block exceeds 1 KB.

Additionally, use:

- [`spec:inputs:default`](index.md#specinputsdefault) to define default values for inputs
  when not specified. When you specify a default, the inputs are no longer mandatory.
- [`spec:inputs:description`](index.md#specinputsdescription) to give a description to
  a specific input. The description does not affect the input, but can help people
  understand the input details or expected values.
- [`spec:inputs:options`](index.md#specinputsoptions) to specify a list of allowed values
  for an input.
- [`spec:inputs:regex`](index.md#specinputsoptions) to specify a regular expression
  that the input must match.
- [`spec:inputs:type`](index.md#specinputstype) to force a specific input type, which
  can be `string` (default when not specified), `array`, `number`, or `boolean`.

### Define inputs with multiple parameters

You can define multiple inputs per CI/CD configuration file, and each input can have
multiple configuration parameters.

For example, in a file named `scan-website-job.yml`:

```yaml
spec:
  inputs:
    job-prefix:     # Mandatory string input
      description: "Define a prefix for the job name"
    job-stage:      # Optional string input with a default value when not provided
      default: test
    environment:    # Mandatory input that must match one of the options
      options: ['test', 'staging', 'production']
    concurrency:
      type: number  # Optional numeric input with a default value when not provided
      default: 1
    version:        # Mandatory string input that must match the regular expression
      type: string
      regex: /^v\d\.\d+(\.\d+)$/
    export_results: # Optional boolean input with a default value when not provided
      type: boolean
      default: true
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - echo "scanning website -e $[[ inputs.environment ]] -c $[[ inputs.concurrency ]] -v $[[ inputs.version ]]"
    - if [ $[[ inputs.export_results ]] ]; then echo "export results"; fi
```

In this example:

- `job-prefix` is a mandatory string input and must be defined.
- `job-stage` is optional. If not defined, the value is `test`.
- `environment` is a mandatory string input that must match one of the defined options.
- `concurrency` is an optional numeric input. When not specified, it defaults to `1`.
- `version` is a mandatory string input that must match the specified regular expression.
- `export_results` is an optional boolean input. When not specified, it defaults to `true`.

### Input types

You can specify that an input must use a specific type with the optional `spec:inputs:type` keyword.

The input types are:

- [`array`](#array-type)
- `boolean`
- `number`
- `string` (default when not specified)

When an input replaces an entire YAML value in the CI/CD configuration, it is interpolated
into the configuration as its specified type. For example:

```yaml
spec:
  inputs:
    array_input:
      type: array
    boolean_input:
      type: boolean
    number_input:
      type: number
    string_input:
      type: string
---

test_job:
  allow_failure: $[[ inputs.boolean_input ]]
  needs: $[[ inputs.array_input ]]
  parallel: $[[ inputs.number_input ]]
  script: $[[ inputs.string_input ]]
```

When an input is inserted into a YAML value as part of a larger string, the input
is always interpolated as a string. For example:

```yaml
spec:
  inputs:
    port:
      type: number
---

test_job:
  script: curl "https://gitlab.com:$[[ inputs.port ]]"
```

#### Array type

The content of the items in an array type can be any valid YAML map, sequence, or scalar. More complex YAML features
like [`!reference`](yaml_optimization.md#reference-tags) cannot be used.

```yaml
spec:
  inputs:
    rules-config:
      type: array
      default:
        - if: $CI_PIPELINE_SOURCE == "merge_request_event"
          when: manual
        - if: $CI_PIPELINE_SOURCE == "schedule"
---

test_job:
  rules: $[[ inputs.rules-config ]]
  script: ls
```

#### Multi-line input string values

[Inputs](../yaml/inputs.md) support different value types. You can pass multi-string values using the following format:

```yaml
spec:
  inputs:
    closed_message:
      description: Message to announce when an issue is closed.
      default: 'Hi {{author}} :wave:,

        Based on the policy for inactive issues, this is now being closed.

        If this issue requires further attention, please reopen this issue.'
---
```

## Set input values when using `include`

> - `include:with` [renamed to `include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780) in GitLab 16.0.

Use [`include:inputs`](index.md#includeinputs) to set the values for the parameters
when the included configuration is added to the pipeline.

For example, to include the `scan-website-job.yml` in the [example above](#define-inputs-with-multiple-parameters):

```yaml
include:
  - local: 'scan-website-job.yml'
    inputs:
      job-prefix: 'some-service-'
      environment: 'staging'
      concurrency: 2
      version: 'v1.3.2'
      export_results: false
```

In this example, the inputs for the included configuration are:

| Input            | Value           | Details |
|------------------|-----------------|---------|
| `job-prefix`     | `some-service-` | Must be explicitly defined. |
| `job-stage`      | `test`          | Not defined in `include:inputs`, so the value comes from `spec:inputs:default` in the included configuration. |
| `environment`    | `staging`       | Must be explicitly defined, and must match one of the values in `spec:inputs:options` in the included configuration. |
| `concurrency`    | `2`             | Must be a numeric value to match the `spec:inputs:type` set to `number` in the included configuration. Overrides the default value. |
| `version`        | `v1.3.2`        | Must be explicitly defined, and must match the regular expression in the `spec:inputs:regex` in the included configuration. |
| `export_results` | `false`         | Must be either `true` or `false` to match the `spec:inputs:type` set to `boolean` in the included configuration. Overrides the default value. |

### Use `include:inputs` with multiple files

[`inputs`](index.md#includeinputs) must be specified separately for each included file.
For example:

```yaml
include:
  - component: gitlab.com/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### Include the same file multiple times

You can include the same file multiple times, with different inputs. However, if multiple jobs
with the same name are added to one pipeline, each additional job overwrites the previous job
with the same name. You must ensure the configuration prevents duplicate job names.

For example, including the same configuration multiple times with different inputs:

```yaml
include:
  - local: path/to/my-super-linter.yml
    inputs:
      linter: docs
      lint-path: "doc/"
  - local: path/to/my-super-linter.yml
    inputs:
      linter: yaml
      lint-path: "data/yaml/"
```

The configuration in `path/to/my-super-linter.yml` ensures the job has a unique name
each time it is included:

```yaml
spec:
  inputs:
    linter:
    lint-path:
---
"run-$[[ inputs.linter ]]-lint":
  script: ./lint --$[[ inputs.linter ]] --path=$[[ inputs.lint-path ]]
```

## Specify functions to manipulate input values

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) in GitLab 16.3.

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
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars | truncate(5,8) ]]
```

In this example, assuming the input uses the default value and `$MY_VAR` is an unmasked project variable with value `my value`:

1. First, the function [`expand_vars`](#expand_vars) expands the value to `test my value`.
1. Then [`truncate`](#truncate) applies to `test my value` with a character offset of `5` and length `8`.
1. The output of `script` would be `echo my value`.

### Predefined interpolation functions

#### `expand_vars`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387632) in GitLab 16.5.

Use `expand_vars` to expand [CI/CD variables](../variables/index.md) in the input value.

Only variables you can [use with the `include` keyword](includes.md#use-variables-with-include) and which are
**not** [masked](../variables/index.md#mask-a-cicd-variable) can be expanded.
[Nested variable expansion](../variables/where_variables_can_be_used.md#nested-variable-expansion) is not supported.

Example:

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars ]]
```

In this example, if `$MY_VAR` is unmasked (exposed in job logs) with a value of `my value`, then the input
would expand to `test my value`.

#### `truncate`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) in GitLab 16.3.

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

## Troubleshooting

### YAML syntax errors when using `inputs`

[CI/CD variable expressions](../jobs/job_control.md#cicd-variable-expressions)
in `rules:if` expect a comparison of a CI/CD variable with a string, otherwise
[a variety of syntax errors could be returned](../jobs/job_troubleshooting.md#this-gitlab-ci-configuration-is-invalid-for-variable-expressions).

You must ensure that expressions remain properly formatted after input values are
inserted into the configuration, which might require the use of additional quote characters.

For example:

```yaml
spec:
  inputs:
    branch:
      default: $CI_DEFAULT_BRANCH
---

job-name:
  rules:
    - if: $CI_COMMIT_REF_NAME == $[[ inputs.branch ]]
```

In this example:

- Using `include: inputs: branch: $CI_DEFAULT_BRANCH` is valid. The `if:` clause evaluates to
  `if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH`, which is a valid variable expression.
- Using `include: inputs: branch: main` is **invalid**. The `if:` clause evaluates to
  `if: $CI_COMMIT_REF_NAME == main`, which is invalid because `main` is a string but is not quoted.

Alternatively, add quotes to resolve some variable expression issues. For example:

```yaml
spec:
  inputs:
    environment:
      default: "$ENVIRONMENT"
---

$[[ inputs.environment | expand_vars ]] job:
  script: echo
  rules:
    - if: '"$[[ inputs.environment1 | expand_vars ]]" == "production"'
```

In this example, quoting the input block and also the entire variable expression
ensures valid `if:` syntax after the input is evaluated. The internal and external quotes
in the expression must not be the same character. You can use `"` for the internal quotes
and `'` for the external quotes, or the inverse. On the other hand, the job name does
not require any quoting.
