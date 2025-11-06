---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD inputs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) in GitLab 15.11 as a beta feature.
- [Made generally available](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) in GitLab 17.0.

{{< /history >}}

Use CI/CD inputs to increase the flexibility of CI/CD configuration. Inputs and [CI/CD variables](../variables/_index.md)
can be used in similar ways, but have different benefits:

- Inputs provide typed parameters for reusable templates with built-in validation at pipeline creation time.
  To define specific values when the pipeline runs, use inputs instead of CI/CD variables.
- CI/CD variables offer flexible values that can be defined at multiple levels, but can be modified
  throughout pipeline execution. Use variables for values that need to be accessible in the job's runtime environment.
  You can also use [predefined variables](../variables/predefined_variables.md) with `rules`
  for dynamic pipeline configuration.

## CI/CD Inputs and variables comparison

Inputs:

- **Purpose**: Defined in CI configurations (templates, components or `.gitlab-ci.yml`) and assigned values
  when a pipeline is triggered, allowing consumers to customize reusable CI configurations.
- **Modification**: Once passed at pipeline initialization, input values are interpolated in the CI/CD
  configuration and remain fixed for the entire pipeline run.
- **Scope**: Available only in the file they are defined, whether in the `.gitlab-ci.yml` or a file
  being `include`d. You can pass them explicitly to other files - using `include:inputs` - or pipeline
  using `trigger:inputs`.
- **Validation**: Provide robust validation capabilities including type checking, regex patterns,
  predefined option lists, and helpful descriptions for users.

CI/CD Variables:

- **Purpose**: Values that can be set as environment variables during job execution and in various parts
  of the pipeline for passing data between jobs.
- **Modification**: Can be dynamically generated or modified during pipeline execution through dotenv artifacts,
  conditional rules, or directly in job scripts.
- **Scope**: Can be defined globally (affecting all jobs), at the job level (affecting only specific jobs),
  or for the entire project or group through the GitLab UI.
- **Validation**: Simple key-value pairs with minimal built-in validation, though you can add some controls through
  the GitLab UI for project variables.

## Define input parameters with `spec:inputs`

Use `spec:inputs` in the CI/CD configuration [header](../yaml/_index.md#header-keywords) to define input parameters that
can be passed to the configuration file.

Use the `$[[ inputs.input-id ]]` interpolation format outside the header section to declare where to use
the inputs.

For example:

```yaml
spec:
  inputs:
    job-stage:
      default: test
    environment:
      default: production
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

In this example, the inputs are `job-stage` and `environment`.

With `spec:inputs`:

- Inputs are mandatory if `default` is not specified.
- Inputs are evaluated and populated when the configuration is fetched during pipeline creation.
- A string containing an input must be less than 1 MB.
- A string inside an input must be less than 1 KB.
- Inputs can use CI/CD variables, but have the same [variable limitations as the `include` keyword](../yaml/includes.md#use-variables-with-include).
- If the file that defines `spec:inputs` also contains job definitions, add a YAML document
  separator (`---`) after the header.

Then you set the values for the inputs when you:

- [Trigger a new pipeline](#for-a-pipeline) using this configuration file.
  You should always set default values when using inputs to configure new pipelines
  with any method other than `include`. Otherwise the pipeline could fail to start
  if a new pipeline triggers automatically, including in:
  - Merge request pipelines
  - Branch pipelines
  - Tag pipelines
- [Include the configuration](#for-configuration-added-with-include) in your pipeline.
  Any inputs that are mandatory must be added to the `include:inputs` section, and are used
  every time the configuration is included.

### Input configuration

To configure inputs, use:

- [`spec:inputs:default`](../yaml/_index.md#specinputsdefault) to define default values for inputs
  when not specified. When you specify a default, the inputs are no longer mandatory.
- [`spec:inputs:description`](../yaml/_index.md#specinputsdescription) to give a description to
  a specific input. The description does not affect the input, but can help people
  understand the input details or expected values.
- [`spec:inputs:options`](../yaml/_index.md#specinputsoptions) to specify a list of allowed values
  for an input.
- [`spec:inputs:regex`](../yaml/_index.md#specinputsregex) to specify a regular expression
  that the input must match.
- [`spec:inputs:type`](../yaml/_index.md#specinputstype) to force a specific input type, which
  can be `string` (default when not specified), `array`, `number`, or `boolean`.

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407176) in GitLab 16.11.

{{< /history >}}

The content of the items in an array type can be any valid YAML map, sequence, or scalar. More complex YAML features
like [`!reference`](../yaml/yaml_optimization.md#reference-tags) cannot be used. When using the value of an array
input in a string (for example `echo "My rules: $[[ inputs.rules-config ]]"` in your `script:` section), you might
see unexpected results. The array input is converted to its string representation, which might not match your
expectations for complex YAML structures such as maps.

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

Array inputs must be formatted as JSON, for example `["array-input-1", "array-input-2"]`,
when manually passing inputs for:

- [Manually triggered pipelines](../pipelines/_index.md#run-a-pipeline-manually).
- The [pipeline triggers API](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token).
- The [pipelines API](../../api/pipelines.md#create-a-new-pipeline).
- Git [push options](../../topics/git/commit.md#push-options-for-gitlab-cicd)
- [Pipeline schedules](../pipelines/schedules.md#create-a-pipeline-schedule)

#### Multi-line input string values

Inputs support different value types. You can pass multi-string values using the following format:

```yaml
spec:
  inputs:
    closed_message:
      description: Message to announce when an issue is closed.
      default: 'Hi {{author}} :wave:,

        Based on the policy for inactive issues, this is now being closed.

        If this issue requires further attention, reopen this issue.'
---
```

## Set input values

### For configuration added with `include`

{{< history >}}

- `include:with` [renamed to `include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780) in GitLab 16.0.

{{< /history >}}

Use [`include:inputs`](../yaml/_index.md#includeinputs) to set the values for inputs
when the included configuration is added to the pipeline, including for:

- [CI/CD components](../components/_index.md)
- [Custom CI/CD templates](../examples/_index.md#adding-templates-to-your-gitlab-installation)
- Any other configuration added with `include`.

For example, to include and set the input values for `scan-website-job.yml` from the
[input configuration example](#input-configuration):

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

#### With multiple `include` entries

Inputs must be specified separately for each include entry. For example:

```yaml
include:
  - component: $CI_SERVER_FQDN/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### For a pipeline

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16321) in GitLab 17.11.

{{< /history >}}

Inputs provide advantages over variables including type checking, validation and a clear contract.
Unexpected inputs are rejected.
Inputs for pipelines must be defined in the [`spec:inputs` header](#define-input-parameters-with-specinputs)
of the main `.gitlab-ci.yml` file. You cannot use inputs defined in included files for pipeline-level configuration.

{{< alert type="note" >}}

In [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables)
and later, pipeline inputs are recommended over passing [pipeline variables](../variables/_index.md#use-pipeline-variables).
For enhanced security, you should [disable pipeline variables](../variables/_index.md#restrict-pipeline-variables) when using inputs.

{{< /alert >}}

You should always set default values when defining inputs for pipelines.
Otherwise the pipeline could fail to start if a new pipeline triggers automatically.
For example, merge request pipelines can trigger for changes to a merge request's source branch.
You cannot manually set inputs for merge request pipelines, so if any input is missing a default,
the pipeline fails to create. This can also happen for branch pipelines, tag pipelines,
and other automatically triggered pipelines.

You can set input values with:

- [Downstream pipelines](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)
- [Manually triggered pipelines](../pipelines/_index.md#run-a-pipeline-manually).
- The [pipeline triggers API](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)
- The [pipelines API](../../api/pipelines.md#create-a-new-pipeline)
- Git [push options](../../topics/git/commit.md#push-options-for-gitlab-cicd)
- [Pipeline schedules](../pipelines/schedules.md#create-a-pipeline-schedule)
- The [`trigger` keyword](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)

A pipeline can take up to 20 inputs.

Feedback is welcome on [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/533802).

You can pass inputs to [downstream pipelines](../pipelines/downstream_pipelines.md),
if the downstream pipeline's configuration file uses [`spec:inputs`](#define-input-parameters-with-specinputs).

For example, with [`trigger:inputs`](../yaml/_index.md#triggerinputs):

{{< tabs >}}

{{< tab title="Parent-child pipeline" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< tab title="Multi-project pipeline" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    project: project-group/my-downstream-project
    inputs:
      job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< /tabs >}}

## Specify functions to manipulate input values

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) in GitLab 16.3.

{{< /history >}}

You can specify predefined functions in the interpolation block to manipulate the input value.
The format supported is the following:

```yaml
$[[ input.input-id | <function1> | <function2> | ... <functionN> ]]
```

With functions:

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387632) in GitLab 16.5.

{{< /history >}}

Use `expand_vars` to expand [CI/CD variables](../variables/_index.md) in the input value.

Only variables you can [use with the `include` keyword](../yaml/includes.md#use-variables-with-include) and which are
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) in GitLab 16.3.

{{< /history >}}

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

#### `posix_quote`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/568289) in GitLab 18.6.

{{< /history >}}

Use `posix_quote` to escape any POSIX _Bourne shell_ control or meta characters that might be included in input values.
`posix_quote` escapes the characters by inserting ` \ ` before any problematic characters in the input.

Example:

```yaml
spec:
  inputs:
    test:
      default: |
        A string with single ' and double " quotes and   blanks
---

test-job:
  script: printf '%s\n' $[[ inputs.test | posix_quote ]]
```

In this example, `posix_quote` escapes all the characters that could be shell control or metadata characters:

```console
$ printf '%s\n' A\ string\ with\ single\ \'\ and\ double\ \"\ quotes\ and\ \ \ blanks
A string with single ' and double " quotes and   blanks
```

The escaped input preserves all special characters and spacing exactly as provided.

{{< alert type="warning" >}}

Not using `posix_quote` can be a security risk if the input contains untrusted input.

{{< /alert >}}

Input values that do not escape shell control or metadata characters have risks:

- Shell code included in the string might be executed.
- Single or double quotes might be used to escape any surrounding quoting.
- Variable references could be used to access protected variables.
- Input or output redirection might be used to read or write to local files.
- Unescaped spaces are used by shells to split a string into multiple arguments.

Escaping might be unnecessary if:

- The [`spec:input:type`](../yaml/_index.md#specinputstype) is `number` or `boolean`, which cannot contain problematic characters.
- The input value is validated with [`spec:input:regex`](../yaml/_index.md#specinputsregex) to prevent problematic input.
- The input value is from a trusted source.

If you combine `posix_quote` with `expand_vars`, you must set `expand_vars` first.
Otherwise `posix_quote` would escape the `$` in the variable, preventing expansion.
For example:

```yaml
test-job:
  script: echo $[[ inputs.test | expand_vars | posix_quote ]]
```

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
