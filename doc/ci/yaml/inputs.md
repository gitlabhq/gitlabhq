---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Define inputs for configuration added with `include`
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) in GitLab 15.11 as a beta feature.
> - [Made generally available](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) in GitLab 17.0.

Use inputs to increase the flexibility of CI/CD configuration files that are designed
to be reused.

Inputs can use CI/CD variables, but have the same [variable limitations as the `include` keyword](includes.md#use-variables-with-include).

## Define input parameters with `spec:inputs`

Use `spec:inputs` to define parameters that can be populated in reusable CI/CD configuration
files when added to a pipeline. Then use [`include:inputs`](#set-input-values-when-using-include)
to add the configuration to a project's pipeline and set the values for the parameters.

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

In this example, the inputs are `job-stage` and `environment`. Then, in a `.gitlab-ci.yml` file,
you can add this configuration and set the input values:

```yaml
include:
  - local: 'custom_website_scan.yml'
    inputs:
      job-stage: 'my-test-stage'
      environment: 'my-environment'
```

Specs must be declared at the top of a configuration file, in a header section separated
from the rest of the configuration with `---`. Use the `$[[ inputs.input-id ]]` interpolation format
outside the header section to declare where to use the inputs.

With `spec:inputs`:

- Inputs are mandatory by default.
- Inputs are evaluated and populated when the configuration is fetched during pipeline creation,
  before the configuration is merged with the contents of the `.gitlab-ci.yml` file.
- A string containing an input must be less than 1 MB.
- A string inside an input must be less than 1 KB.

Additionally, use:

- [`spec:inputs:default`](_index.md#specinputsdefault) to define default values for inputs
  when not specified. When you specify a default, the inputs are no longer mandatory.
- [`spec:inputs:description`](_index.md#specinputsdescription) to give a description to
  a specific input. The description does not affect the input, but can help people
  understand the input details or expected values.
- [`spec:inputs:options`](_index.md#specinputsoptions) to specify a list of allowed values
  for an input.
- [`spec:inputs:regex`](_index.md#specinputsregex) to specify a regular expression
  that the input must match.
- [`spec:inputs:type`](_index.md#specinputstype) to force a specific input type, which
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
      regex: ^v\d\.\d+(\.\d+)$
    export_results: # Optional boolean input with a default value when not provided
      type: boolean
      default: true
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - echo "scanning website -e $[[ inputs.environment ]] -c $[[ inputs.concurrency ]] -v $[[ inputs.version ]]"
    - if $[[ inputs.export_results ]]; then echo "export results"; fi
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407176) in GitLab 16.11.

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

Use [`include:inputs`](_index.md#includeinputs) to set the values for the parameters
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

[`inputs`](_index.md#includeinputs) must be specified separately for each included file.
For example:

```yaml
include:
  - component: $CI_SERVER_FQDN/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### Use `inputs` with downstream pipelines

You can pass inputs to [downstream pipelines](../pipelines/downstream_pipelines.md),
if the downstream pipeline's configuration file uses [`spec:inputs`](#define-input-parameters-with-specinputs).
For example:

::Tabs

:::TabTitle Parent-child pipeline

```yaml
trigger-job:
  trigger:
    strategy: depend
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

:::TabTitle Multi-project pipeline

```yaml
trigger-job:
  trigger:
    strategy: depend
    include:
      - project: project-group/my-downstream-project
        file: ".gitlab-ci.yml"
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

::EndTabs

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

### Reuse configuration in `inputs`

To reuse configuration with `inputs`, you can use [YAML anchors](yaml_optimization.md#anchors).

For example, to reuse the same `rules` configuration with multiple components that support
`rules` arrays in the inputs:

```yaml
.my-job-rules: &my-job-rules
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

include:
  - component: $CI_SERVER_FQDN/project/path/component1@main
    inputs:
      job-rules: *my-job-rules
  - component: $CI_SERVER_FQDN/project/path/component2@main
    inputs:
      job-rules: *my-job-rules
```

You cannot use [`!reference` tags](yaml_optimization.md#reference-tags) in inputs,
but [issue 424481](https://gitlab.com/gitlab-org/gitlab/-/issues/424481) proposes adding
this functionality.

## `inputs` examples

### Use `inputs` with `needs`

You can use array type inputs with [`needs`](_index.md#needs) for complex job dependencies.

For example, in a file named `component.yml`:

```yaml
spec:
  inputs:
    first_needs:
      type: array
    second_needs:
      type: array
---

test_job:
  script: echo "this job has needs"
  needs:
    - $[[ inputs.first_needs ]]
    - $[[ inputs.second_needs ]]
```

In this example, the inputs are `first_needs` and `second_needs`, both [array type inputs](#array-type).
Then, in a `.gitlab-ci.yml` file, you can add this configuration and set the input values:

```yaml
include:
  - local: 'component.yml'
    inputs:
      first_needs:
        - build1
      second_needs:
        - build2
```

When the pipeline starts, the items in the `needs` array for `test_job` get concatenated into:

```yaml
test_job:
  script: echo "this job has needs"
  needs:
  - build1
  - build2
```

### Allow `needs` to be expanded when included

You can have [`needs`](_index.md#needs) in an included job, but also add additional jobs
to the `needs` array with `spec:inputs`.

For example:

```yaml
spec:
  inputs:
    test_job_needs:
      type: array
      default: []
---

build-job:
  script:
    - echo "My build job"

test-job:
  script:
    - echo "My test job"
  needs:
    - build-job
    - $[[ inputs.test_job_needs ]]
```

In this example:

- `test-job` job always needs `build-job`.
- By default the test job doesn't need any other jobs, as the `test_job_needs:` array input
  is empty by default.

To set `test-job` to need another job in your configuration, add it to the `test_needs` input
when you include the file. For example:

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job_needs: [ my-other-job ]

my-other-job:
  script:
    - echo "I want build-job` in the component to need this job too"
```

### Add `needs` to an included job that doesn't have `needs`

You can add [`needs`](_index.md#needs) to an included job that does not have `needs`
already defined. For example, in a CI/CD component's configuration:

```yaml
spec:
  inputs:
    test_job:
      default: test-job
---

build-job:
  script:
    - echo "My build job"

"$[[ inputs.test_job ]]":
  script:
    - echo "My test job"
```

In this example, the `spec:inputs` section allows the job name to be customized.

Then, after you include the component, you can extend the job with the additional
`needs` configuration. For example:

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job: my-test-job

my-test-job:
  needs: [my-other-job]

my-other-job:
  script:
    - echo "I want `my-test-job` to need this job"
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

Use `expand_vars` to expand [CI/CD variables](../variables/_index.md) in the input value.

Only variables you can [use with the `include` keyword](includes.md#use-variables-with-include) and which are
**not** [masked](../variables/_index.md#mask-a-cicd-variable) can be expanded.
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

[CI/CD variable expressions](../jobs/job_rules.md#cicd-variable-expressions)
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
    - if: '"$[[ inputs.environment | expand_vars ]]" == "production"'
```

In this example, quoting the input block and also the entire variable expression
ensures valid `if:` syntax after the input is evaluated. The internal and external quotes
in the expression must not be the same character. You can use `"` for the internal quotes
and `'` for the external quotes, or the inverse. On the other hand, the job name does
not require any quoting.
