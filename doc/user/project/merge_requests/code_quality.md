---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Code Quality

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1984) in [GitLab Starter](https://about.gitlab.com/pricing/) 9.3.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/212499) in 13.2.

Ensuring your project's code stays simple, readable and easy to contribute to can be problematic. With the help of [GitLab CI/CD](../../../ci/README.md), you can analyze your
source code quality using GitLab Code Quality.

Code Quality:

- Uses [Code Climate Engines](https://codeclimate.com), which are
  free and open source. Code Quality does not require a Code Climate
  subscription.
- Runs in [pipelines](../../../ci/pipelines/index.md) using a Docker image built in the
  [GitLab Code
  Quality](https://gitlab.com/gitlab-org/ci-cd/codequality) project using [default Code Climate configurations](https://gitlab.com/gitlab-org/ci-cd/codequality/-/tree/master/codeclimate_defaults).
- Can make use of a [template](#example-configuration).
- Is available with [Auto
  DevOps](../../../topics/autodevops/stages.md#auto-code-quality).
- Can be extended through [Analysis Plugins](https://docs.codeclimate.com/docs/list-of-engines) or a [custom tool](#implementing-a-custom-tool).

## Code Quality Widget

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1984) in [GitLab Starter](https://about.gitlab.com/pricing/) 9.3.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/212499) in 13.2.

Going a step further, GitLab can show the Code Quality report right
in the merge request widget area if a report from the target branch is available to compare to:

![Code Quality Widget](img/code_quality.png)

Watch a quick walkthrough of Code Quality in action:

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=B32LxtJKo9M">Code Quality: Speed Run</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/B32LxtJKo9M" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

NOTE: **Note:**
For one customer, the auditor found that having Code Quality, SAST, and Container Scanning all automated in GitLab CI/CD was almost better than a manual review! [Read more](https://about.gitlab.com/customers/bi_worldwide/).

See also the Code Climate list of [Supported Languages for Maintainability](https://docs.codeclimate.com/docs/supported-languages-for-maintainability).

## Use cases

For instance, consider the following workflow:

1. Your backend team member starts a new implementation for making a certain
   feature in your app faster.
1. With Code Quality reports, they analyze how their implementation is impacting
   the code quality.
1. The metrics show that their code degrades the quality by 10 points.
1. You ask a co-worker to help them with this modification.
1. They both work on the changes until Code Quality report displays no
   degradations, only improvements.
1. You approve the merge request and authorize its deployment to staging.
1. Once verified, their changes are deployed to production.

## Example configuration

This example shows how to run Code Quality on your code by using GitLab CI/CD and Docker.
It requires GitLab 11.11 or later, and GitLab Runner 11.5 or later. If you are using
GitLab 11.4 or earlier, you can view the deprecated job definitions in the
[documentation archive](https://docs.gitlab.com/12.10/ee/user/project/merge_requests/code_quality.html#previous-job-definitions).

First, you need GitLab Runner configured:

- For the [Docker-in-Docker workflow](../../../ci/docker/using_docker_build.md#use-docker-in-docker-workflow-with-docker-executor).
- With enough disk space to handle generated Code Quality files. For example on the [GitLab project](https://gitlab.com/gitlab-org/gitlab) the files are approximately 7 GB.

Once you set up GitLab Runner, include the Code Quality template in your CI configuration:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml
```

The above example creates a `code_quality` job in your CI/CD pipeline which
scans your source code for code quality issues. The report is saved as a
[Code Quality report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportscodequality)
that you can later download and analyze.

It's also possible to override the URL to the Code Quality image by
setting the `CODE_QUALITY_IMAGE` variable. This is particularly useful if you want
to lock in a specific version of Code Quality, or use a fork of it:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODE_QUALITY_IMAGE: "registry.example.com/codequality-fork:latest"
```

In [GitLab 13.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/11100), you can override the [Code Quality environment variables](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables):

```yaml
variables:
  TIMEOUT_SECONDS: 1

include:
  - template: Code-Quality.gitlab-ci.yml
```

By default, report artifacts are not downloadable. If you need them downloadable on the
job details page, you can add `gl-code-quality-report.json` to the artifact paths like so:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  artifacts:
    paths: [gl-code-quality-report.json]
```

The included `code_quality` job is running in the `test` stage, so it needs to be included in your CI configuration, like so:

```yaml
stages:
  - test
```

TIP: **Tip:**
This information is automatically extracted and shown right in the merge request widget.

CAUTION: **Caution:**
On self-managed instances, if a malicious actor compromises the Code Quality job
definition they could execute privileged Docker commands on the runner
host. Having proper access control policies mitigates this attack vector by
allowing access only to trusted actors.

### Disabling the code quality job

The `code_quality` job doesn't run if the `$CODE_QUALITY_DISABLED` environment
variable is present. Please refer to the environment variables [documentation](../../../ci/variables/README.md)
to learn more about how to define one.

To disable the `code_quality` job, add `CODE_QUALITY_DISABLED` as a custom environment
variable. This can be done:

- For the whole project, [in the project settings](../../../ci/variables/README.md#create-a-custom-variable-in-the-ui)
  or [CI/CD configuration](../../../ci/variables/README.md#create-a-custom-variable-in-the-ui).
- For a single pipeline run:

  1. Go to **CI/CD > Pipelines**
  1. Click **Run Pipeline**
  1. Add `CODE_QUALITY_DISABLED` as the variable key, with any value.

### Using with merge request pipelines

The configuration provided by the Code Quality template does not let the `code_quality` job
run on [pipelines for merge requests](../../../ci/merge_request_pipelines/index.md).

If pipelines for merge requests is enabled, the `code_quality:rules` must be redefined.

The template has these [`rules`](../../../ci/yaml/README.md#rules) for the `code quality` job:

```yaml
code_quality:
  rules:
    - if: '$CODE_QUALITY_DISABLED'
      when: never
    - if: '$CI_COMMIT_TAG || $CI_COMMIT_BRANCH'
```

If you are using merge request pipelines, your `rules` (or [`workflow: rules`](../../../ci/yaml/README.md#workflowrules))
might look like this example:

```yaml
job1:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"' # Run job1 in merge request pipelines
    - if: '$CI_COMMIT_BRANCH == "master"'                # Run job1 in pipelines on the master branch (but not in other branch pipelines)
    - if: '$CI_COMMIT_TAG'                               # Run job1 in pipelines for tags
```

To make these work together, you need to overwrite the code quality `rules`
so that they match your current `rules`. From the example above, it could look like:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  rules:
    - if: '$CODE_QUALITY_DISABLED'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"' # Run code quality job in merge request pipelines
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'      # Run code quality job in pipelines on the master branch (but not in other branch pipelines)
    - if: '$CI_COMMIT_TAG'                               # Run code quality job in pipelines for tags
```

## Configuring jobs using variables

The Code Quality job supports environment variables that users can set to
configure job execution at runtime.

For a list of available environment variables, see
[Environment variables](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables).

## Implementing a custom tool

It's possible to have a custom tool provide Code Quality reports in GitLab. To
do this:

1. Define a job in your `.gitlab-ci.yml` file that generates the
   [Code Quality report
   artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportscodequality).
1. Configure your tool to generate the Code Quality report artifact as a JSON
   file that implements a subset of the [Code Climate
   spec](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types).

The Code Quality report artifact JSON file must contain an array of objects
with the following properties:

| Name                   | Description                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------- |
| `description`          | A description of the code quality violation.                                           |
| `fingerprint`          | A unique fingerprint to identify the code quality violation. For example, an MD5 hash. |
| `severity`             | A severity string (can be `info`, `minor`, `major`, `critical`, or `blocker`).                          |
| `location.path`        | The relative path to the file containing the code quality violation.                   |
| `location.lines.begin` | The line on which the code quality violation occurred.                                 |

Example:

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
    "severity": "minor",
    "location": {
      "path": "lib/index.js",
      "lines": {
        "begin": 42
      }
    }
  }
]
```

NOTE: **Note:**
Although the Code Climate spec supports more properties, those are ignored by
GitLab.

## Code Quality reports

After the Code Quality job completes:

- Potential changes to code quality are shown directly in the merge request.
  The Code Quality widget in the merge request compares the reports from the base and head of the branch,
  then lists any violations that are resolved or created when the branch is merged.
- The full JSON report is available as a
  [downloadable artifact](../../../ci/pipelines/job_artifacts.md#downloading-artifacts)
  for the `code_quality` job.
- The full list of code quality violations generated by a pipeline is shown in the
  Code Quality tab of the Pipeline Details page. **(STARTER)**

### Generating an HTML report

In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/ci-cd/codequality/-/issues/10),
it is possible to generate an HTML report file by setting the `REPORT_FORMAT`
variable to `html`. This is useful if you just want to view the report in a more
human-readable format or to publish this artifact on GitLab Pages for even
easier reviewing.

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

It's also possible to generate both JSON and HTML report files by defining
another job and using `extends: code_quality`:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality_html:
  extends: code_quality
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

## Extending functionality

### Using Analysis Plugins

Should there be a need to extend the default functionality provided by Code Quality, as stated in [Code Quality](#code-quality), [Analysis Plugins](https://docs.codeclimate.com/docs/list-of-engines) are available.

For example, to use the [SonarJava analyzer](https://docs.codeclimate.com/docs/sonar-java),
add a file named `.codeclimate.yml` containing the [enablement code](https://docs.codeclimate.com/docs/sonar-java#enable-the-plugin)
for the plugin to the root of your repository:

```yaml
version: "2"
plugins:
  sonar-java:
    enabled: true
```

This adds SonarJava to the `plugins:` section of the [default `.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml)
included in your project.

Changes to the `plugins:` section do not affect the `exclude_patterns` section of the
default `.codeclimate.yml`. See the Code Climate documentation for
[excluding files and folders](https://docs.codeclimate.com/docs/excluding-files-and-folders)
for more details.

Here's [an example project](https://gitlab.com/jheimbuck_gl/jh_java_example_project) that uses Code Quality with a `.codeclimate.yml` file.

## Troubleshooting

### Changing the default configuration has no effect

A common issue is that the terms `Code Quality` (GitLab specific) and `Code Climate`
(Engine used by GitLab) are very similar. You must add a **`.codeclimate.yml`** file
to change the default configuration, **not** a `.codequality.yml` file. If you use
the wrong filename, the [default `.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml)
is still used.

### No Code Quality report is displayed in a Merge Request

This can be due to multiple reasons:

- You just added the Code Quality job in your `.gitlab-ci.yml`. The report does not
  have anything to compare to yet, so no information can be displayed. It only displays
  after future merge requests have something to compare to.
- Your pipeline is not set to run the code quality job on your default branch. If there is no report generated from the default branch, your MR branch reports will not have anything to compare to.
- If no [degradation or error is detected](https://docs.codeclimate.com/docs/maintainability#section-checks),
  nothing is displayed.
- The [`artifacts:expire_in`](../../../ci/yaml/README.md#artifactsexpire_in) CI/CD
  setting can cause the Code Quality artifact(s) to expire faster than desired.
- If you use the [`REPORT_STDOUT` environment variable](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables), no report file is generated and nothing displays in the merge request.
- Large `codeclimate.json` files (esp. >10 MB) are [known to prevent the report from being displayed](https://gitlab.com/gitlab-org/gitlab/-/issues/2737).
  As a work-around, try removing [properties](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)
  that are [ignored by GitLab](#implementing-a-custom-tool). You can:
  - Configure the Code Quality tool to not output those types.
  - Use `sed`, `awk` or similar commands in the `.gitlab-ci.yml` script to
    edit the `codeclimate.json` before the job completes.

### Only a single Code Quality report is displayed, but more are defined

GitLab only uses the Code Quality artifact from the latest created job (with the largest job ID).
If multiple jobs in a pipeline generate a code quality artifact, those of earlier jobs are ignored.
To avoid confusion, configure only one job to generate a `codeclimate.json`.
