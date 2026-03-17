---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Job inputs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17833) in GitLab 18.10.
- Requires GitLab Runner 18.9 or later.

{{< /history >}}

Use job inputs to define typed, validated parameters for individual CI/CD jobs that can be overridden
when manually running or retrying jobs. Unlike [CI/CD variables](../variables/_index.md), job inputs provide:

- Type safety: Inputs can be `string`, `number`, `boolean`, or `array` with automatic validation.
- Explicit contract: Jobs only accept the inputs you define. Unexpected inputs are rejected.
- Override capability: Input values can be set when [running](#run-a-manual-job-with-input-values)
  a job, and changed when [retrying](#retry-a-job-with-different-input-values) the job.

Use job inputs for parameters that control job behavior and might need to be adjusted
when re-running a job. For example: deployment targets, test configurations, or feature flags.

Job inputs are scoped to the job where they are defined and cannot be accessed in included files
or other jobs. If you need to share configuration across jobs or files, use [CI/CD configuration inputs](../inputs/_index.md) instead.

## Job input comparison

### Compared to CI/CD pipeline configuration inputs

Job inputs and [CI/CD pipeline configuration inputs](../inputs/_index.md) serve different purposes:

| Feature        | Job inputs                                                              | CI/CD configuration inputs |
|----------------|-------------------------------------------------------------------------|---------------------|
| Purpose        | Configure individual job behavior                                       | Configure reusable templates and components |
| Syntax         | `inputs:` in job definition                                             | `spec:inputs:` in configuration header |
| Interpolation  | `${{ job.inputs.INPUT_NAME }}`                                          | `$[[ inputs.INPUT_NAME ]]` |
| Evaluation     | Values set when job is created, can be overridden when running/retrying | Values set at pipeline creation, fixed for entire pipeline |
| Default values | Required                                                                | Optional |
| Scope          | Single job only                                                         | Entire configuration file or passed to included files |

### Compared to environment variables

Job inputs are interpolated into the job configuration when the job is created. They are not
environment variables and cannot be accessed with `$INPUT_NAME` syntax. You can use job inputs
directly in scripts and other supported keywords with the `${{ job.inputs.INPUT_NAME }}` syntax.

## Define and use job inputs

Use the `inputs` keyword in a job to define input parameters. Each input must have a default value.
Reference input values with the `${{ job.inputs.INPUT_NAME }}` [Moa expression](../functions/moa.md) syntax.

For example:

```yaml
deploy_job:
  inputs:
    target_env:
      default: staging
      options: [staging, production]
    replicas:
      type: number
      default: 3
    debug_mode:
      type: boolean
      default: false
  script:
    - 'echo "Deploying to ${{ job.inputs.target_env }}"'
    - 'echo "Replicas - ${{ job.inputs.replicas }}"'
    - 'if [ "${{ job.inputs.debug_mode }}" == "true" ]; then set -x; fi'
    - ./deploy.sh
```

### Input configuration

Configure inputs with these keywords:

- `default`: The default value used when the job runs. All job inputs must have defaults.
- `type`: Optional. The input type. Can be `string` (default), `number`, `boolean`, or `array`.
- `description`: Optional. A human-readable description of the input's purpose.
- `options`: Optional. A list of allowed values. The input must match one of these values.
- `regex`: Optional. A regular expression pattern the input must match.

For example:

```yaml
test_job:
  inputs:
    test_framework:
      default: rspec
      description: Testing framework to use
      options: [rspec, minitest, cucumber]
    parallel_count:
      type: number
      default: 5
      description: Number of parallel test jobs
    run_integration_tests:
      type: boolean
      default: false
      description: Whether to run integration tests
    test_tags:
      type: array
      default: [smoke, regression]
      description: Test tags to run
  script:
    - bundle exec ${{ job.inputs.test_framework }}
    - 'echo "Running ${{ job.inputs.parallel_count }} parallel jobs"'
```

Job inputs are validated when the job is created and when input values are overridden.
If validation fails, the job fails to start with a clear error message.

### Input types

Job inputs support these types:

- `string` (default): Text values, for example `"staging"` or `"v1.2.3"`.
- `number`: Numeric values, for example `5`, `3.14`, or `-10`.
- `boolean`: Boolean values, either `true` or `false`.
- `array`: List of values, for example `[1, 2, 3]` or `["a", "b"]`.

When passing input values through the API or UI, arrays must be JSON-formatted, for example:
`["value1", "value2"]`.

### Where you can use job inputs

You can use simple interpolation or more complex expressions with operators and functions.
See [Moa expression language](../functions/moa.md) for the complete syntax.

Job inputs can be used in these job keywords and their subkeys:

- `script`, `before_script`, and `after_script`
- `artifacts`
- `cache`
- `image`
- `services`

### Limitations

Job inputs use `${{ job.inputs.INPUT_NAME }}` syntax which is evaluated when the job runs, not when
the pipeline configuration is created. You cannot use job inputs in parts of the configuration
that must be evaluated at pipeline creation time, such as:

- Job names
- `stage` keyword
- `rules` keyword
- `include` keyword
- Other job-level keywords not listed above

To configure these parts of your pipeline dynamically, use [CI/CD pipeline configuration inputs](../inputs/_index.md)
with `$[[ inputs.* ]]` syntax instead.

## Provide input values

You can provide job input values when:

- Running a manual job.
- Retrying a job after it completes.

### Run a manual job with input values

When you run a manual job that has inputs defined, you can specify the input values.

To run a manual job with specific inputs:

1. Go to the pipeline, job, or [environment](../environments/deployments.md#configure-manual-deployments) view.
1. Select the name of the manual job, not **Run** ({{< icon name="play" >}}).
1. In the form, specify the input values.
1. Select **Run job**.

### Retry a job with different input values

When you retry a job that has inputs defined, you can update the input values.

To retry a job with different inputs:

1. Go to the job details page.
1. Select **Retry job with modified values** ({{< icon name="chevron-down" >}}).
1. In the form, the inputs are prefilled with the values from the previous run.
   Modify the input values as needed.
1. Select **Run job again**.

To retry with the same input values, select **Retry** ({{< icon name="retry" >}}) instead.

## Job input examples

### Basic deployment job with inputs

```yaml
deploy:
  when: manual
  inputs:
    target_env:
      default: staging
      description: Target deployment environment
      options: [staging, production]
    version:
      default: latest
      description: Application version to deploy
  script:
    - 'echo "Deploying version ${{ job.inputs.version }} to ${{ job.inputs.target_env }}"'
    - ./deploy.sh --env ${{ job.inputs.target_env }} --version ${{ job.inputs.version }}
```

### Test job with validation

```yaml
integration_tests:
  inputs:
    test_suite:
      default: smoke
      description: Which test suite to run
      options: [smoke, regression, full]
    parallel_jobs:
      type: number
      default: 5
      description: Number of parallel test runners
    enable_debug:
      type: boolean
      default: false
      description: Enable debug logging
    tags:
      type: array
      default: ["critical"]
      description: Test tags to run
  script:
    - 'if [ "${{ job.inputs.enable_debug }}" == "true" ]; then export DEBUG=1; fi'
    - ./run_tests.sh
        --suite ${{ job.inputs.test_suite }}
        --parallel ${{ job.inputs.parallel_jobs }}
        --tags '${{ job.inputs.tags }}'
```

### Database migration with safety checks

```yaml
migrate_database:
  when: manual
  inputs:
    target_db:
      default: development
      description: Database environment
      options: [development, staging, production]
    migration_name:
      default: ""
      description: Specific migration to run (leave empty for all)
      regex: ^[a-zA-Z0-9_]*$
    dry_run:
      type: boolean
      default: true
      description: Run in dry-run mode without applying changes
  script:
    - 'echo "Running migrations on ${{ job.inputs.target_db }}"'
    - |
      if [ "${{ job.inputs.dry_run }}" == "true" ]; then
        echo "DRY RUN MODE - no changes will be applied"
        MIGRATION_FLAGS="--dry-run"
      fi
    - |
      if [ -n "${{ job.inputs.migration_name }}" ]; then
        ./migrate.sh $MIGRATION_FLAGS --migration ${{ job.inputs.migration_name }}
      else
        ./migrate.sh $MIGRATION_FLAGS --all
      fi
```

## Use job inputs with the API

You can specify job input values when using the API to run or retry jobs.

### Run a manual job with inputs

Use the [`POST /projects/:id/jobs/:job_id/play` endpoint](../../api/jobs.md#run-a-job)
with the `job_inputs` parameter:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "staging",
      "version": "v2.1.0"
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/456/play"
```

### Retry a job with inputs

Use the [`POST /projects/:id/jobs/:job_id/retry` endpoint](../../api/jobs.md#retry-a-job)
with the `job_inputs` parameter:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "production",
      "replicas": 10
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/123/retry"
```

### Use GraphQL

You can use the [`jobPlay` mutation](../../api/graphql/reference/_index.md#mutationjobplay)
or [`jobRetry` mutation](../../api/graphql/reference/_index.md#mutationjobretry)
with an `inputs` argument:

```graphql
mutation {
  jobPlay(input: {
    id: "gid://gitlab/Ci::Build/123",
    inputs: [
      { name: "environment", value: "production" },
      { name: "replicas", value: 10 }
    ]
  }) {
    job {
      id
      status
    }
    errors
  }
}
```

## Troubleshooting

### Job fails with `input must have a default value`

Job inputs must always have default values to ensure jobs can run in pipelines
where inputs cannot be manually specified.

To fix this error, add a `default` to every input:

```yaml
my_job:
  inputs:
    target_env:
      default: staging  # Default specified
  script:
    - echo ${{ job.inputs.target_env }}
```

### Input validation fails with `unexpected value`

When input validation fails, check:

- If using `options`, ensure the value matches one of the allowed options exactly (case-sensitive).
- If using `regex`, test your regular expression matches the input value.
- If using `type: number`, ensure the value is numeric, not a string.
- If using `type: array`, ensure the value is formatted as a JSON array when passing through the API.
