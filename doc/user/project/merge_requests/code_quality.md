---
type: reference, howto
---

# Code Quality **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1984) in [GitLab Starter](https://about.gitlab.com/pricing/) 9.3.

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
  DevOps](../../../topics/autodevops/stages.md#auto-code-quality-starter).
- Can be extended through [Analysis Plugins](https://docs.codeclimate.com/docs/list-of-engines) or a [custom tool](#implementing-a-custom-tool).

Going a step further, GitLab can show the Code Quality report right
in the merge request widget area:

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

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.11 and later versions. It
also requires the GitLab Runner 11.5 or later. For earlier versions, use the
[previous job definitions](#previous-job-definitions).

This example shows how to run Code Quality on your code by using GitLab CI/CD and Docker.

First, you need GitLab Runner configured:

- For the [Docker-in-Docker workflow](../../../ci/docker/using_docker_build.md#use-docker-in-docker-workflow-with-docker-executor).
- With enough disk space to handle generated Code Quality files. For example on the [GitLab project](https://gitlab.com/gitlab-org/gitlab) the files are approximately 7 GB.

Once you set up the Runner, include the Code Quality template in your CI configuration:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml
```

The above example will create a `code_quality` job in your CI/CD pipeline which
will scan your source code for code quality issues. The report will be saved as a
[Code Quality report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportscodequality-starter)
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
This information will be automatically extracted and shown right in the merge request widget.

CAUTION: **Caution:**
On self-managed instances, if a malicious actor compromises the Code Quality job
definition they will be able to execute privileged Docker commands on the Runner
host. Having proper access control policies mitigates this attack vector by
allowing access only to trusted actors.

### Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, Code Quality job and artifact had to be named specifically to
automatically extract report data and show it in the merge request widget. While these
old job definitions are still maintained they have been deprecated and are no longer supported on GitLab 12.0 or higher.
You're advised to update your `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.5 and later, the job should look like:

```yaml
code_quality:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env SOURCE_CODE="$PWD"
        --volume "$PWD":/code
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/ci-cd/codequality:$SP_VERSION" /code
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

In GitLab 12.6, Code Quality switched to the
[new versioning scheme](https://gitlab.com/gitlab-org/ci-cd/codequality#versioning-and-release-cycle).
It's highly recommended to include the Code Quality template as shown in the
[example configuration](#example-configuration), which uses the new versioning scheme.
If not using the template, the `SP_VERSION` variable can be hardcoded to use the
new image versions:

```yaml
code_quality:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
    SP_VERSION: 0.85.6
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - docker run
        --env SOURCE_CODE="$PWD"
        --volume "$PWD":/code
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/ci-cd/codequality:$SP_VERSION" /code
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

For GitLab 11.4 and earlier, the job should look like:

```yaml
code_quality:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env SOURCE_CODE="$PWD"
        --volume "$PWD":/code
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/ci-cd/codequality:$SP_VERSION" /code
  artifacts:
      paths: [gl-code-quality-report.json]
```

Alternatively the job name could be `codeclimate` or `codequality` and the artifact
name could be `codeclimate.json`. These names have been deprecated with GitLab 11.0
and may be removed in the next major release, GitLab 12.0.

For GitLab 10.3 and earlier, the job should look like:

```yaml
codequality:
  image: docker:latest
  variables:
    DOCKER_DRIVER: overlay
  services:
    - docker:dind
  script:
    - docker pull codeclimate/codeclimate:0.69.0
    - docker run --env CODECLIMATE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock --volume /tmp/cc:/tmp/cc codeclimate/codeclimate:0.69.0 init
    - docker run --env CODECLIMATE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock --volume /tmp/cc:/tmp/cc codeclimate/codeclimate:0.69.0 analyze -f json > codeclimate.json || true
  artifacts:
    paths: [codeclimate.json]
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
   artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportscodequality-starter).
1. Configure your tool to generate the Code Quality report artifact as a JSON
   file that implements a subset of the [Code Climate
   spec](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types).

The Code Quality report artifact JSON file must contain an array of objects
with the following properties:

| Name                   | Description                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------- |
| `description`          | A description of the code quality violation.                                           |
| `fingerprint`          | A unique fingerprint to identify the code quality violation. For example, an MD5 hash. |
| `location.path`        | The relative path to the file containing the code quality violation.                   |
| `location.lines.begin` | The line on which the code quality violation occurred.                                 |

Example:

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
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

Once the Code Quality job has completed:

- The full list of code quality violations generated by a pipeline is available in the
  Code Quality tab of the Pipeline Details page.
- Potential changes to code quality are shown directly in the merge request.
  The Code Quality widget in the merge request compares the reports from the base and head of the branch,
  then lists any violations that will be resolved or created when the branch is merged.
- The full JSON report is available as a
  [downloadable artifact](../../../ci/pipelines/job_artifacts.md#downloading-artifacts)
  for the `code_quality` job.

## Troubleshooting

### No Code Quality report is displayed in a Merge Request

This can be due to multiple reasons:

- You just added the Code Quality job in your `.gitlab-ci.yml`. The report does not
  have anything to compare to yet, so no information can be displayed. Future merge
  requests will have something to compare to.
- If no [degradation or error is detected](https://docs.codeclimate.com/docs/maintainability#section-checks),
  nothing will be displayed.
- The [`artifacts:expire_in`](../../../ci/yaml/README.md#artifactsexpire_in) CI/CD
  setting can cause the Code Quality artifact(s) to expire faster than desired.
- Large `codeclimate.json` files (esp. >10 MB) are [known to prevent the report from being displayed](https://gitlab.com/gitlab-org/gitlab/-/issues/2737).
  As a work-around, try removing [properties](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)
  that are [ignored by GitLab](#implementing-a-custom-tool). You can:
  - Configure the Code Quality tool to not output those types.
  - Use `sed`, `awk` or similar commands in the `.gitlab-ci.yml` script to
    edit the `codeclimate.json` before the job completes.

### Only a single Code Quality report is displayed, but more are defined

GitLab only uses the Code Quality artifact from the latest created job (with the largest job ID).
If multiple jobs in a pipeline generate a code quality artifact, those of earlier jobs are ignored.
To avoid confusion, configure only one job to generate a `codeclimate.json`.
