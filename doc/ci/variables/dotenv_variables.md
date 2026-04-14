---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pass dotenv variables to specific jobs
description: Use dotenv reports to pass environment variables between jobs in pipelines.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To pass environment variables to other jobs, use a dotenv file.
A dotenv file is a file with the `.env` extension
that stores a list of environment variable keys and values.
For example, in a `sample.env` file:

```plaintext
REVIEW_URL=review.example.com/123456
BUILD_VERSION=v1.0.0
```

Save the dotenv file as a [dotenv report artifact](../yaml/artifacts_reports.md#artifactsreportsdotenv),
which can be passed to other jobs in the same pipeline, downstream pipelines, or to set dynamic environment URLs.

You can use dotenv variables in the following ways:

- Generate values in one job and use them in subsequent jobs.
- Pass computed values between pipeline stages.
- Set dynamic environment URLs based on deployment outputs.
- Share variables across multi-project pipelines.

Dotenv variables can only be used in job scripts, not to configure pipelines.
They take [precedence](_index.md#cicd-variable-precedence) over job variables
and default variables defined in `.gitlab-ci.yml`,
but not over project, group, instance, or pipeline variables.

If the same variable name appears multiple times in a `dotenv` report, the last value is used.

## Pass variables to later jobs

By default, dotenv variables are available to all jobs in later stages.
To pass variables between jobs:

1. In a job, create a file (for example, `build.env`) with variables in the format `VARIABLE_NAME=value`,
   one variable per line.
1. Output the file as a `dotenv` report artifact.
1. In later jobs, use the variables in your scripts.

For example, `build-job` creates `build.env` with `BUILD_VERSION=v1.0.0`,
and `test-job` automatically receives it as an environment variable:

```yaml
build-job:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

test-job:
  stage: test
  script:
    - echo "Testing version $BUILD_VERSION"  # Output: 'Testing version v1.0.0'
```

> [!warning]
> Don't include sensitive data like credentials, API keys, or tokens in dotenv files.
> Pipeline users can access dotenv file contents. To restrict access, use
> [`artifacts:access`](../yaml/_index.md#artifactsaccess).

## Control which jobs receive dotenv variables

To control which jobs receive dotenv variables, use the
[`dependencies`](../yaml/_index.md#dependencies) or [`needs`](../yaml/_index.md#needs) keywords.

### Inherit from specific jobs

Use `dependencies` to limit inheritance to specific jobs only:

```yaml
build-job1:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

build-job2:
  stage: build
  script:
    - echo "This job has no dotenv artifacts"

test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: 'v1.0.0'
  dependencies:
    - build-job1
    # build-job2 is not listed, so its artifacts are not inherited
```

### Exclude dotenv variables

To prevent a job from receiving dotenv variables from a named job, use `needs` with `artifacts: false`.
This blocks all artifact downloads from that job, not just dotenv variables:

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  needs:
    - job: build-job1
      artifacts: false
```

The [`needs`](../yaml/_index.md#needs) in this example also makes the job start as soon as `build-job1` completes.

Or use an empty [`dependencies`](../yaml/_index.md) array to block artifact downloads from all upstream jobs:

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  dependencies: []
```

## Pass variables to downstream pipelines

You can pass dotenv variables to a downstream pipeline with dotenv variable inheritance.
In a [multi-project pipeline](../pipelines/downstream_pipelines.md#multi-project-pipelines),
create the dotenv artifact in an upstream job and use `needs` in the downstream job to
inherit it:

1. Save the variables in a `.env` file.
1. Save the `.env` file as a `dotenv` report artifact.
1. Trigger the downstream pipeline.

```yaml
build_vars:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  trigger: my/downstream_project
```

In the downstream pipeline, set the job to inherit the artifacts from the upstream job
with `needs`. The job receives the dotenv variables and can then access `BUILD_VERSION` in the script:

```yaml
test:
  stage: test
  script:
    - echo $BUILD_VERSION
  needs:
    - project: my/upstream_project
      job: build_vars
      ref: master
      artifacts: true
```

## Set a dynamic environment URL

You can use dotenv variables to set a dynamic environment URL after a deployment job finishes.
This is useful when an external hosting platform generates a URL dynamically for each deployment.

For more information, see [set a dynamic environment URL](../environments/_index.md#set-a-dynamic-environment-url).

## Store complex values

Dotenv files have specific format limitations, such as restrictions on multiline values
and special characters that require escaping. If your value contains JSON, spans multiple
lines, or includes characters that need escaping, avoid dotenv variables. Use a separate file artifact instead.
For the full list of value constraints, see [format requirements](#format-requirements).

Instead of:

```yaml
# Not supported
- echo 'CONFIG={"key": "value"}' >> build.env
```

Use a separate artifact:

```yaml
build-job:
  stage: build
  script:
    - echo '{"key": "value"}' > config.json
  artifacts:
    paths:
      - config.json
```

## Dotenv file requirements

Dotenv files must meet the following format, size, and variable requirements.

GitLab uses the [dotenv gem](https://github.com/bkeepers/dotenv) to handle dotenv files,
but applies additional restrictions beyond the
[original dotenv rules](https://github.com/motdotla/dotenv?tab=readme-ov-file#what-rules-does-the-parsing-engine-follow)
and the gem's implementation.

### Format requirements

- Only [UTF-8 encoding](../jobs/job_artifacts_troubleshooting.md#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner) is supported.
- The file cannot contain empty lines or comments (lines starting with `#`).
- Variable names can contain only ASCII letters (`A-Za-z`), digits (`0-9`), and underscores (`_`).
- The dotenv file does not support quoting. Single or double quotes are preserved as-is and cannot be used for escaping.
- Values cannot contain newlines or other special characters that require escaping.
- Multiline values are not supported. GitLab rejects the file on upload.
- Leading and trailing spaces or newline characters (`\n`) are stripped.

### Size and variable limits

| Limit                                                      | Value |
| ---------------------------------------------------------- | ----- |
| Maximum file size                                          | 5 KB  |
| Default maximum inherited variables on GitLab Self-Managed | 20    |

For GitLab.com tier limits, see [GitLab.com CI/CD settings](../../user/gitlab_com/_index.md#cicd).

To change these limits on GitLab Self-Managed, see [CI/CD limits](../../administration/instance_limits.md#cicd-limits).
