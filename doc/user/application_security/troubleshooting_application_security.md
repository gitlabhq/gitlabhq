---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting application security
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When working with application security features, you might encounter the following issues.

## Logging level

The verbosity of logs output by GitLab analyzers is determined by the `SECURE_LOG_LEVEL` environment
variable. Messages of this logging level or higher are output.

From highest to lowest severity, the logging levels are:

- `fatal`
- `error`
- `warn`
- `info` (default)
- `debug`

### Debug-level logging

WARNING:
Debug logging can be a serious security risk. The output may contain the content of
environment variables and other secrets available to the job. The output is uploaded
to the GitLab server and is visible in job logs.

To enable debug-level logging, add the following to your `.gitlab-ci.yml` file:

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

This indicates to all GitLab analyzers that they are to output **all** messages. For more details,
see [logging level](#logging-level).

<!-- NOTE: The below subsection(`### Secure job failing with exit code 1`) documentation URL is referred in the [/gitlab-org/security-products/analyzers/command](https://gitlab.com/gitlab-org/security-products/analyzers/command/-/blob/main/command.go#L19) repository. If this section/subsection changes, ensure to update the corresponding URL in the mentioned repository.
-->

## Secure job failing with exit code 1

If a Secure job is failing and it's unclear why:

1. Enable [debug-level logging](#debug-level-logging).
1. Run the job.
1. Examine the job's output.
1. Remove the `debug` log level to return to the default `info` value.

## Outdated security reports

When a security report generated for a merge request becomes outdated, the merge request shows a
warning message in the security widget and prompts you to take an appropriate action.

This can happen in two scenarios:

- Your [source branch is behind the target branch](#source-branch-is-behind-the-target-branch).
- The [target branch security report is out of date](#target-branch-security-report-is-out-of-date).

### Source branch is behind the target branch

A security report can be out of date when the most recent common ancestor commit between the
target branch and the source branch is not the most recent commit on the target branch.

To fix this issue, rebase or merge to incorporate the changes from the target branch.

![Incorporate target branch changes](img/outdated_report_branch_v12_9.png)

### Target branch security report is out of date

This can happen for many reasons, including failed jobs or new advisories. When the merge request
shows that a security report is out of date, you must run a new pipeline on the target branch.
Select **new pipeline** to run a new pipeline.

![Run a new pipeline](img/outdated_report_pipeline_v12_9.png)

## Getting warning messages `… report.json: no matching files`

WARNING:
Debug logging can be a serious security risk. The output may contain the content of
environment variables and other secrets available to the job. The output is uploaded
to the GitLab server and visible in job logs.

This message is often followed by the [error `No files to upload`](../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload),
and preceded by other errors or warnings that indicate why the JSON report wasn't generated. Check
the entire job log for such messages. If you don't find these messages, retry the failed job after
setting `SECURE_LOG_LEVEL: "debug"` as a [custom CI/CD variable](../../ci/variables/_index.md#for-a-project).
This provides extra information to investigate further.

## Getting error message `sast job: config key may not be used with 'rules': only/except`

When [including](../../ci/yaml/_index.md#includetemplate) a `.gitlab-ci.yml` template
like [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml),
the following error may occur, depending on your GitLab CI/CD configuration:

```plaintext
Unable to create pipeline

    jobs:sast config key may not be used with `rules`: only/except
```

This error appears when the included job's `rules` configuration has been [overridden](sast/_index.md#overriding-sast-jobs)
with [the deprecated `only` or `except` syntax.](../../ci/yaml/_index.md#only--except)
To fix this issue, you must either:

- [Transition your `only/except` syntax to `rules`](#transitioning-your-onlyexcept-syntax-to-rules).
- (Temporarily) [Pin your templates to the deprecated versions](#pin-your-templates-to-the-deprecated-versions)

For more information, see [Overriding SAST jobs](sast/_index.md#overriding-sast-jobs).

### Transitioning your `only/except` syntax to `rules`

When overriding the template to control job execution, previous instances of
[`only` or `except`](../../ci/yaml/_index.md#only--except) are no longer compatible
and must be transitioned to [the `rules` syntax](../../ci/yaml/_index.md#rules).

If your override is aimed at limiting jobs to only run on `main`, the previous syntax
would look similar to:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  only:
    refs:
      - main
      - merge_requests
```

To transition the above configuration to the new `rules` syntax, the override
would be written as follows:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_MERGE_REQUEST_ID
```

If your override is aimed at limiting jobs to only run on branches, not tags,
it would look similar to:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  except:
    - tags
```

To transition to the new `rules` syntax, the override would be rewritten as:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_TAG == null
```

For more information, see [`rules`](../../ci/yaml/_index.md#rules).

### Pin your templates to the deprecated versions

To ensure the latest support, we **strongly** recommend that you migrate to [`rules`](../../ci/yaml/_index.md#rules).

If you're unable to immediately update your CI configuration, there are several workarounds that
involve pinning to the previous template versions, for example:

  ```yaml
  include:
    remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/12-10-stable-ee/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'
  ```

Additionally, we provide a dedicated project containing the versioned legacy templates.
This can be used for offline setups or for anyone wishing to use [Auto DevOps](../../topics/autodevops/_index.md).

Instructions are available in the [legacy template project](https://gitlab.com/gitlab-org/auto-devops-v12-10).

### Vulnerabilities are found, but the job succeeds. How can you have a pipeline fail instead?

In these circumstances, that the job succeeds is the default behavior. The job's status indicates
success or failure of the analyzer itself. Analyzer results are displayed in the
[job logs](../../ci/jobs/job_logs.md#expand-and-collapse-job-log-sections),
[merge request widget](detect/security_scan_results.md#merge-request), or
[security dashboard](security_dashboard/_index.md).

## Error: job `is used for configuration only, and its script should not be executed`

[Changes made in GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41260)
to the `Security/Dependency-Scanning.gitlab-ci.yml` and `Security/SAST.gitlab-ci.yml`
templates mean that if you enable the `sast` or `dependency_scanning` jobs by setting the `rules` attribute,
they fail with the error `(job) is used for configuration only, and its script should not be executed`.

The `sast` or `dependency_scanning` stanzas can be used to make changes to all SAST or Dependency Scanning,
such as changing `variables` or the `stage`, but they cannot be used to define shared `rules`.

There [is an issue open to improve extendability](https://gitlab.com/gitlab-org/gitlab/-/issues/218444).
You can upvote the issue to help with prioritization, and
[contributions are welcomed](https://about.gitlab.com/community/contribute/).

## Empty Vulnerability Report, Dependency List pages

If the pipeline has manual steps with a job that has the `allow_failure: false` option, and this job is not finished,
GitLab can't populate listed pages with the data from security reports.
In this case, [the Vulnerability Report](vulnerability_report/_index.md) and [the Dependency List](dependency_list/_index.md)
pages are empty.
These security pages can be populated by running the jobs from the manual step of the pipeline.

There is [an issue open to handle this scenario](https://gitlab.com/gitlab-org/gitlab/-/issues/346843).
You can upvote the issue to help with prioritization, and
[contributions are welcomed](https://about.gitlab.com/community/contribute/).
