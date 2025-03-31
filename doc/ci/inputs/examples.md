---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD input examples
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[CI/CD inputs](_index.md) increase the flexibility of your CI/CD configuration.
Use these examples as guidelines for configuring your pipeline to use inputs.

## Include the same file multiple times

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

## Reuse configuration in `inputs`

To reuse configuration with `inputs`, you can use [YAML anchors](../yaml/yaml_optimization.md#anchors).

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

You cannot use [`!reference` tags](../yaml/yaml_optimization.md#reference-tags) in inputs,
but [issue 424481](https://gitlab.com/gitlab-org/gitlab/-/issues/424481) proposes adding
this functionality.

## Use `inputs` with `needs`

You can use array type inputs with [`needs`](../yaml/_index.md#needs) for complex job dependencies.

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

In this example, the inputs are `first_needs` and `second_needs`, both [array type inputs](_index.md#array-type).
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

You can have [`needs`](../yaml/_index.md#needs) in an included job, but also add additional jobs
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
      test_job_needs: [my-other-job]

my-other-job:
  script:
    - echo "I want build-job` in the component to need this job too"
```

### Add `needs` to an included job that doesn't have `needs`

You can add [`needs`](../yaml/_index.md#needs) to an included job that does not have `needs`
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
