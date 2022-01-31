---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Secure your application **(ULTIMATE)**

GitLab can check your application for security vulnerabilities including:

- Unauthorized access.
- Data leaks.
- Denial of service attacks.

Statistics and details on vulnerabilities are included in the merge request. Providing
actionable information _before_ changes are merged enables you to be proactive.

GitLab also provides high-level statistics of vulnerabilities across projects and groups:

- The [Security Dashboard](security_dashboard/index.md) provides a
  high-level view of vulnerabilities detected in your projects, pipeline, and groups.
- The [Threat Monitoring](threat_monitoring/index.md) page provides runtime security metrics
  for application environments. With the information provided,
  you can immediately begin risk analysis and remediation.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of GitLab application security, see [Shifting Security Left](https://www.youtube.com/watch?v=XnYstHObqlA&t).

## Security scanning tools

GitLab uses the following tools to scan and report known vulnerabilities found in your project.

| Secure scanning tool                                           | Description                                                         |
| :------------------------------------------------------------- | :------------------------------------------------------------------ |
| [Container Scanning](container_scanning/index.md)              | Scan Docker containers for known vulnerabilities.                   |
| [Dependency List](dependency_list/index.md)                    | View your project's dependencies and their known vulnerabilities.   |
| [Dependency Scanning](dependency_scanning/index.md)            | Analyze your dependencies for known vulnerabilities.                |
| [Dynamic Application Security Testing (DAST)](dast/index.md)   | Analyze running web applications for known vulnerabilities.         |
| [DAST API](dast_api/index.md)                                  | Analyze running web APIs for known vulnerabilities.                 |
| [API fuzzing](api_fuzzing/index.md)                            | Find unknown bugs and vulnerabilities in web APIs with fuzzing.     |
| [Secret Detection](secret_detection/index.md)                  | Analyze Git history for leaked secrets.                             |
| [Security Dashboard](security_dashboard/index.md)              | View vulnerabilities in all your projects and groups.               |
| [Static Application Security Testing (SAST)](sast/index.md)    | Analyze source code for known vulnerabilities.                      |
| [Infrastructure as Code (IaC) Scanning](iac_scanning/index.md) | Analyze your IaC configuration files for known vulnerabilities.      |
| [Coverage fuzzing](coverage_fuzzing/index.md)                  | Find unknown bugs and vulnerabilities with coverage-guided fuzzing. |
| [Cluster Image Scanning](cluster_image_scanning/index.md)      | Scan Kubernetes clusters for known vulnerabilities.                 |

## Security scanning with Auto DevOps

To enable all GitLab Security scanning tools, with default settings, enable
[Auto DevOps](../../topics/autodevops/):

- [Auto SAST](../../topics/autodevops/stages.md#auto-sast)
- [Auto Secret Detection](../../topics/autodevops/stages.md#auto-secret-detection)
- [Auto DAST](../../topics/autodevops/stages.md#auto-dast)
- [Auto Dependency Scanning](../../topics/autodevops/stages.md#auto-dependency-scanning)
- [Auto License Compliance](../../topics/autodevops/stages.md#auto-license-compliance)
- [Auto Container Scanning](../../topics/autodevops/stages.md#auto-container-scanning)

While you cannot directly customize Auto DevOps, you can [include the Auto DevOps template in your project's `.gitlab-ci.yml` file](../../topics/autodevops/customize.md#customizing-gitlab-ciyml).

## Security scanning without Auto DevOps

To enable all GitLab security scanning tools, with the option of customizing settings, add the
GitLab CI/CD templates to your `.gitlab-ci.yml` file.

To enable Static Application Security Testing, Dependency Scanning, License Scanning, and Secret
Detection, add:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
```

To enable Dynamic Application Security Testing (DAST) scanning, add the following to your
`.gitlab-ci.yml`. Replace `https://staging.example.com` with a staging server's web address:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml

variables:
  DAST_WEBSITE: https://staging.example.com
```

For more details about each of the security scanning tools, see their respective
[documentation sections](#security-scanning-tools).

### Override the default registry base address

By default, GitLab security scanners use `registry.gitlab.com/gitlab-org/security-products/analyzers` as the
base address for Docker images. You can override this globally by setting the CI/CD variable
`SECURE_ANALYZERS_PREFIX` to another location. Note that this affects all scanners at once, except
the container-scanning analyzer which uses
`registry.gitlab.com/security-products/container-scanning` as its registry.

### Use security scanning tools with merge request pipelines

By default, the application security jobs are configured to run for branch pipelines only.
To use them with [merge request pipelines](../../ci/pipelines/merge_request_pipelines.md),
you may need to override the default `rules:` configuration to add:

```yaml
rules:
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

## Default behavior of GitLab security scanning tools

### Secure jobs in your pipeline

If you add the security scanning jobs as described in [Security scanning with Auto DevOps](#security-scanning-with-auto-devops) or [Security scanning without Auto DevOps](#security-scanning-without-auto-devops) to your `.gitlab-ci.yml` each added [security scanning tool](#security-scanning-tools) behave as described below.

For each compatible analyzer, a job is created in the `test`, `dast` or `fuzz` stage of your pipeline and runs on the next new branch pipeline.
Features such as the [Security Dashboard](security_dashboard/index.md), [Vulnerability Report](vulnerability_report/index.md), and [Dependency List](dependency_list/index.md)
that rely on this scan data only show results from pipelines on the default branch, only if all jobs are finished, including manual ones. One tool might use many analyzers.

Our language and package manager specific jobs attempt to assess which analyzer(s) they should run for your project so that you can do less configuration.

If you want to override this to increase the pipeline speed you may choose which analyzers to exclude if you know they are not applicable (languages or package managers not contained in your project) by following variable customization directions for that specific tool.

### Secure job status

Jobs pass if they are able to complete a scan. A _pass_ result does NOT indicate if they did, or did not, identify findings. The only exception is coverage fuzzing, which fails if it identifies findings.

Jobs fail if they are unable to complete a scan. You can view the pipeline logs for more information.

All jobs are permitted to fail by default. This means that if they fail it do not fail the pipeline.

If you want to prevent vulnerabilities from being merged, you should do this by adding [Security Approvals in Merge Requests](#security-approvals-in-merge-requests) which prevents unknown, high or critical findings from being merged without an approval from a specific group of people that you choose.

We do not recommend changing the job [`allow_failure` setting](../../ci/yaml/index.md#allow_failure) as that fails the entire pipeline.

### JSON Artifact

The artifact generated by the secure analyzer contains all findings it discovers on the target branch, regardless of whether they were previously found, dismissed, or completely new (it puts in everything that it finds).

## View security scan information in merge requests **(FREE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4393) in GitLab Free 13.5.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/273205) in 13.6.
> - Report download dropdown [added](https://gitlab.com/gitlab-org/gitlab/-/issues/273418) in 13.7.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/249550) in GitLab 13.9.

### All tiers

Merge requests which have run security scans let you know that the generated
reports are available to download. To download a report, click on the
**Download results** dropdown, and select the desired report.

![Security widget](img/security_widget_v13_7.png)

### Ultimate

A merge request contains a security widget which displays a summary of the NEW results. New results are determined by comparing the current findings against existing findings in the target (default) branch (if there are prior findings).

We recommended you run a scan of the `default` branch before enabling feature branch scans for your developers. Otherwise, there is no base for comparison and all feature branches display the full scan results in the merge request security widget.

The merge request security widget displays only a subset of the vulnerabilities in the generated JSON artifact because it contains both NEW and EXISTING findings.

From the merge request security widget, select **Expand** to unfold the widget, displaying any new and no longer detected (removed) findings by scan type. Select **View full report** to go directly to the **Security** tab in the latest branch pipeline.

![Security scanning results in a merge request](img/mr_security_scanning_results_v14_3.png)

## View security scan information in the pipeline Security tab

A pipeline's security tab lists all findings in the current branch. It includes new findings introduced by this branch and existing vulnerabilities that were already present when the branch was created. These results likely do not match the findings displayed in the Merge Request security widget as those do not include the existing vulnerabilities (with the exception of showing any existing vulnerabilities that are no longer detected in the feature branch).

For more details, see [security tab](security_dashboard/index.md#view-vulnerabilities-in-a-pipeline).

## View security scan information in the Security Dashboard

The Security Dashboard show vulnerabilities present in a project's default branch. Data is updated every 24 hours. Vulnerability count updates resulting from any feature branches introducing new vulnerabilities that are merged to default are included after the daily data refresh.

For more details, see [Security Dashboard](security_dashboard/index.md).

## View security scan information in the Vulnerability Report

The vulnerability report shows the results of the last completed pipeline on the default branch. It is updated on every pipeline completion. All detected vulnerabilities are shown as well as any previous ones that are no longer detected in the latest scan. Vulnerabilities that are no longer detected may have been remediated or otherwise removed and can be marked as `Resolved` after proper verification. Vulnerabilities that are no longer detected are denoted with an icon for filtering and review.

By default, the vulnerability report does not show vulnerabilities of `dismissed` or `resolved` status so you can focus on open vulnerabilities. You can change the Status filter to see these.

[Read more about the Vulnerability report](vulnerability_report/index.md).

## Security approvals in merge requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9928) in GitLab 12.2.

You can enforce an additional approval for merge requests that would introduce one of the following
security issues:

- A security vulnerability. For more details, read
  [Vulnerability-Check rule](#vulnerability-check-rule).
- A software license compliance violation. For more details, read
  [Enabling license approvals within a project](../compliance/license_compliance/index.md#enabling-license-approvals-within-a-project).

### Vulnerability-Check rule

To prevent a merge request introducing a security vulnerability in a project, enable the
Vulnerability-Check rule. While this rule is enabled, additional merge request approval by
[eligible approvers](../project/merge_requests/approvals/rules.md#eligible-approvers)
is required when the latest security report in a merge request:

- Contains vulnerabilities with states (for example, `previously detected`, `dismissed`) matching the rule's vulnerability states. Only `newly detected` will be considered if the target branch differs from the project default branch.
- Contains vulnerabilities with severity levels (for example, `high`, `critical`, or `unknown`)
  matching the rule's severity levels.
- Contains a vulnerability count higher than the rule allows.
- Is not yet generated (until pipeline completion).

An approval is optional when the security report:

- Contains only vulnerabilities with states (for example, `newly detected`, `resolved`) **NOT** matching the rule's vulnerability states.
- Contains only vulnerabilities with severity levels (for example, `low`, `medium`) **NOT** matching
  the rule's severity levels.
- Contains a vulnerability count equal to or less than what the rule allows.

Project members with at least the Maintainer role can enable or edit
the Vulnerability-Check rule.

#### Enable the Vulnerability-Check rule

To enable or edit the Vulnerability-Check rule:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Merge request approvals**.
1. Select **Activate** or **Edit** of the Vulnerability-Check.
1. Complete the fields. **Approvals required** must be at least 1.
1. Select **Add approval rule**.

The approval rule is enabled for all merge requests. Any code changes reset the approvals required.

## Using private Maven repositories

If you have a private Apache Maven repository that requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable
to pass a username and password. You can set it under your project's settings
so that your credentials aren't exposed in `.gitlab-ci.yml`.

If the username is `myuser` and the password is `verysecret` then you would
[set the following variable](../../ci/variables/index.md#custom-cicd-variables)
under your project's settings:

| Type     | Key              | Value |
| -------- | ---------------- | ----- |
| Variable | `MAVEN_CLI_OPTS` | `--settings mysettings.xml -Drepository.password=verysecret -Drepository.user=myuser` |

```xml
<!-- mysettings.xml -->
<settings>
    ...
    <servers>
        <server>
            <id>private_server</id>
            <username>${private.username}</username>
            <password>${private.password}</password>
        </server>
    </servers>
</settings>
```

## Using a custom scanning stage

When security scanning is enabled by including CI/CD templates as described in the
[Security scanning without Auto DevOps](#security-scanning-without-auto-devops) section, the scanning jobs
use the predefined `test` stage by default. If you specify a custom stage in your `.gitlab-ci.yml` file without
including a `test` stage, an error occurs.

For example, the following attempts to use a `unit-tests` stage:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml

stages:
  - unit-tests

custom job:
  stage: unit-tests
  script:
    - echo "custom job"
```

The above `.gitlab-ci.yml` causes a linting error:

```plaintext
Found errors in your .gitlab-ci.yml:
- dependency_scanning job: chosen stage does not exist; available stages are .pre
- unit-tests
- .post
```

This error appears because the `test` stage used by the security scanning jobs isn't declared in the `.gitlab-ci.yml` file.
To fix this issue, you can either:

- Add a `test` stage in your `.gitlab-ci.yml`:

  ```yaml
  include:
    - template: Security/Dependency-Scanning.gitlab-ci.yml
    - template: Security/License-Scanning.gitlab-ci.yml
    - template: Security/SAST.gitlab-ci.yml
    - template: Security/Secret-Detection.gitlab-ci.yml

  stages:
    - test
    - unit-tests

  custom job:
    stage: unit-tests
    script:
      - echo "custom job"
  ```

- Override the default stage of each security job. For example, to use a pre-defined stage named `unit-tests`:

  ```yaml
  include:
    - template: Security/Dependency-Scanning.gitlab-ci.yml
    - template: Security/License-Scanning.gitlab-ci.yml
    - template: Security/SAST.gitlab-ci.yml
    - template: Security/Secret-Detection.gitlab-ci.yml

  stages:
    - unit-tests

  dependency_scanning:
    stage: unit-tests

  license_scanning:
    stage: unit-tests

  sast:
    stage: unit-tests

  .secret-analyzer:
    stage: unit-tests

  custom job:
    stage: unit-tests
    script:
      - echo "custom job"
  ```

Learn more on overriding security jobs:

- [Overriding SAST jobs](sast/index.md#overriding-sast-jobs).
- [Overriding Dependency Scanning jobs](dependency_scanning/index.md#overriding-dependency-scanning-jobs).
- [Overriding Container Scanning jobs](container_scanning/index.md#overriding-the-container-scanning-template).
- [Overriding Secret Detection jobs](secret_detection/index.md#customizing-settings).
- [Overriding DAST jobs](dast/index.md#customize-dast-settings).
- [Overriding License Compliance jobs](../compliance/license_compliance/index.md#overriding-the-template).

All the security scanning tools define their stage, so this error can occur with all of them.

## Security report validation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/321918) in GitLab 13.11.
> - Schema validation message [added](https://gitlab.com/gitlab-org/gitlab/-/issues/321730) in GitLab 14.0.

You can enforce validation of the security report artifacts before ingesting the vulnerabilities.
This prevents ingestion of broken vulnerability data into the database. GitLab validates the
artifacts based on the [report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/tree/master/dist).

In GitLab 14.0 and later, when artifact validation is enabled, the pipeline's **Security** tab lists
any report artifacts that failed validation.

### Enable security report validation

To enable report artifacts validation, set the `VALIDATE_SCHEMA` environment variable to `"true"`
for the desired jobs in the `.gitlab-ci.yml` file.

For example, to enable validation for only the `sast` job:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
stages:
  - security-scan
dependency_scanning:
  stage: security-scan
license_scanning:
  stage: security-scan
sast:
  stage: security-scan
  variables:
    VALIDATE_SCHEMA: "true"
.secret-analyzer:
  stage: security-scan
```

## Interact with findings and vulnerabilities

You can interact with the results of the security scanning tools in several locations:

- [Scan information in merge requests](#view-security-scan-information-in-merge-requests)
- [Project Security Dashboard](security_dashboard/index.md)
- [Security pipeline tab](security_dashboard/index.md)
- [Group Security Dashboard](security_dashboard/index.md)
- [Security Center](security_dashboard/#security-center)
- [Vulnerability Report](vulnerability_report/index.md)
- [Vulnerability Pages](vulnerabilities/index.md)
- [Dependency List](dependency_list/index.md)

For more details about which findings or vulnerabilities you can view in each of those locations,
select the respective link. Each page details the ways in which you can interact with the findings
and vulnerabilities. As an example, in most cases findings start out as _detected_ status.

You have the option to:

- Change the status.
- Create an issue.
- Link it to an existing issue.
- [Resolve the vulnerability](vulnerabilities/index.md#resolve-a-vulnerability), if a solution is known.

## Security scanning configuration tips

Each GitLab security scanning tool has a default
[CI/CD configuration file](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security),
also known as a _template_.

When customizing the configuration:

- [Include](../../ci/yaml/index.md#include) the scanning tool's CI/CD template. Don't _copy_ the content
  of the template.
- Use the [stable](../../development/cicd/templates.md#stable-version) version of each template
  for production workflows. The stable version changes less often, and breaking changes are only
  made between major GitLab versions. The [latest](../../development/cicd/templates.md#latest-version)
  version contains the most recent changes, but may have significant changes between minor GitLab versions.
- Only override values in the template as needed. All other values are inherited from the template.

### Enforce scan execution

Security and compliance teams must ensure that security scans:

- Run on a regular basis for all projects.
- Can't be disabled by developers.

GitLab provides two methods of accomplishing this, each with advantages and disadvantages.

- [Compliance framework pipelines](../project/settings/#compliance-pipeline-configuration)
  are recommended when:

  - Scan execution enforcement is required for SAST IaC, Container Scanning, Dependency Scanning,
    License Compliance, API Fuzzing, or Coverage-guided Fuzzing.
  - Scan execution enforcement of SAST or Secret Detection when customization of the default scan
    variables is required.
  - Scan execution enforcement is required for scanners external to GitLab.
  - Enforced execution is required for custom jobs other than security scans.

- [Scan execution policies](policies/#scan-execution-policies)
  are recommended when:

  - Scan execution enforcement is required for DAST.
  - Scan execution enforcement is required for SAST or Secret Detection with the default scan
    variables.
  - Scans are required to run on a regular, scheduled cadence.

Additional details about the differences between the two solutions are outlined below:

| | Compliance Framework Pipelines | Scan Execution Policies |
| ------ | ------ | ------ |
| **Flexibility** | Supports anything that can be done in a CI file. | Limited to only the items for which GitLab has explicitly added support. DAST, SAST, and Secret Detection scans are supported. |
| **Usability** | Requires knowledge of CI YAML. | Follows a `rules` and `actions`-based YAML structure. |
| **Inclusion in CI pipeline** | The compliance pipeline is executed instead of the project's `gitlab-ci.yml` file. To include the project's `gitlab-ci.yml` file, use an `include` statement. Defined variables aren't allowed to be overwritten by the included project's YAML file. | Forced inclusion of a new job into the CI pipeline. DAST jobs that must be customized on a per-project basis can have project-level Site Profiles and Scan Profiles defined. To ensure separation of duties, these profiles are immutable when referenced in a scan execution policy. |
| **Schedulable** | Can be scheduled through a scheduled pipeline on the group. | Can be scheduled natively through the policy configuration itself. |
| **Separation of Duties** | Only group owners can create compliance framework labels. Only project owners can apply compliance framework labels to projects. The ability to make or approve changes to the compliance pipeline definition is limited to individuals who are explicitly given access to the project that contains the compliance pipeline. | Only project owners can define a linked security policy project. The ability to make or approve changes to security policies is limited to individuals who are explicitly given access to the security policy project. |
| **Ability to apply one standard to multiple projects** | The same compliance framework label can be applied to multiple projects inside a group. | The same security policy project can be used for multiple projects across GitLab with no requirement of being located in the same group. |

Feedback is welcome on our vision for [unifying the user experience for these two features](https://gitlab.com/groups/gitlab-org/-/epics/7312)

## Troubleshooting

### Secure job failing with exit code 1

If a Secure job is failing and it's unclear why, add `SECURE_LOG_LEVEL: "debug"` as a global CI/CD variable for
more verbose output that is helpful for troubleshooting.

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

### Outdated security reports

When a security report generated for a merge request becomes outdated, the merge request shows a
warning message in the security widget and prompts you to take an appropriate action.

This can happen in two scenarios:

- Your [source branch is behind the target branch](#source-branch-is-behind-the-target-branch).
- The [target branch security report is out of date](#target-branch-security-report-is-out-of-date).

#### Source branch is behind the target branch

A security report can be out of date when the most recent common ancestor commit between the
target branch and the source branch is not the most recent commit on the target branch.

To fix this issue, rebase or merge to incorporate the changes from the target branch.

![Incorporate target branch changes](img/outdated_report_branch_v12_9.png)

#### Target branch security report is out of date

This can happen for many reasons, including failed jobs or new advisories. When the merge request
shows that a security report is out of date, you must run a new pipeline on the target branch.
Select **new pipeline** to run a new pipeline.

![Run a new pipeline](img/outdated_report_pipeline_v12_9.png)

### Getting warning messages `… report.json: no matching files`

This message is often followed by the [error `No files to upload`](../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload),
and preceded by other errors or warnings that indicate why the JSON report wasn't generated. Check
the entire job log for such messages. If you don't find these messages, retry the failed job after
setting `SECURE_LOG_LEVEL: "debug"` as a [custom CI/CD variable](../../ci/variables/index.md#custom-cicd-variables).
This provides extra information to investigate further.

### Getting error message `sast job: config key may not be used with 'rules': only/except`

When [including](../../ci/yaml/index.md#includetemplate) a `.gitlab-ci.yml` template
like [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml),
the following error may occur, depending on your GitLab CI/CD configuration:

```plaintext
Found errors in your .gitlab-ci.yml:

    jobs:sast config key may not be used with `rules`: only/except
```

This error appears when the included job's `rules` configuration has been [overridden](sast/index.md#overriding-sast-jobs)
with [the deprecated `only` or `except` syntax.](../../ci/yaml/index.md#only--except)
To fix this issue, you must either:

- [Transition your `only/except` syntax to `rules`](#transitioning-your-onlyexcept-syntax-to-rules).
- (Temporarily) [Pin your templates to the deprecated versions](#pin-your-templates-to-the-deprecated-versions)

[Learn more on overriding SAST jobs](sast/index.md#overriding-sast-jobs).

#### Transitioning your `only/except` syntax to `rules`

When overriding the template to control job execution, previous instances of
[`only` or `except`](../../ci/yaml/index.md#only--except) are no longer compatible
and must be transitioned to [the `rules` syntax](../../ci/yaml/index.md#rules).

If your override is aimed at limiting jobs to only run on `master`, the previous syntax
would look similar to:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on master or merge requests
spotbugs-sast:
  only:
    refs:
      - master
      - merge_requests
```

To transition the above configuration to the new `rules` syntax, the override
would be written as follows:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on master or merge requests
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_BRANCH == "master"
    - if: $CI_MERGE_REQUEST_ID
```

If your override is aimed at limiting jobs to only run on branches, not tags,
it would look similar to:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  except:
    - tags
```

To transition to the new `rules` syntax, the override would be rewritten as:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_TAG == null
```

[Learn more on the usage of `rules`](../../ci/yaml/index.md#rules).

#### Pin your templates to the deprecated versions

To ensure the latest support, we **strongly** recommend that you migrate to [`rules`](../../ci/yaml/index.md#rules).

If you're unable to immediately update your CI configuration, there are several workarounds that
involve pinning to the previous template versions, for example:

  ```yaml
  include:
    remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/12-10-stable-ee/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'
  ```

Additionally, we provide a dedicated project containing the versioned legacy templates.
This can be used for offline setups or anyone wishing to use [Auto DevOps](../../topics/autodevops/index.md).

Instructions are available in the [legacy template project](https://gitlab.com/gitlab-org/auto-devops-v12-10).

#### Vulnerabilities are found, but the job succeeds. How can I have a pipeline fail instead?

In these circumstances, that the job succeeds is the default behavior. The job's status indicates
success or failure of the analyzer itself. Analyzer results are displayed in the
[job logs](../../ci/jobs/index.md#expand-and-collapse-job-log-sections),
[Merge Request widget](#view-security-scan-information-in-merge-requests) or
[Security Dashboard](security_dashboard/index.md).

### Error: job `is used for configuration only, and its script should not be executed`

[Changes made in GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41260)
to the `Security/Dependency-Scanning.gitlab-ci.yml` and `Security/SAST.gitlab-ci.yml`
templates mean that if you enable the `sast` or `dependency_scanning` jobs by setting the `rules` attribute,
they fail with the error `(job) is used for configuration only, and its script should not be executed`.

The `sast` or `dependency_scanning` stanzas can be used to make changes to all SAST or Dependency Scanning,
such as changing `variables` or the `stage`, but they cannot be used to define shared `rules`.

There [is an issue open to improve extendability](https://gitlab.com/gitlab-org/gitlab/-/issues/218444).
Please upvote the issue to help with prioritization, and
[contributions are welcomed](https://about.gitlab.com/community/contribute/).

### Empty Vulnerability Report, Dependency List, License list pages

If the pipeline has manual steps with a job that has the `allow_failure: false` option, and this job is not finished,
GitLab can't populate listed pages with the data from security reports.
In this case, [the Vulnerability Report](vulnerability_report/index.md), [the Dependency List](dependency_list/index.md),
and [the License list](../compliance/license_compliance/index.md#license-list) pages will be empty.
These security pages can be populated by running the jobs from the manual step of the pipeline.

There is [an issue open to handle this scenario](https://gitlab.com/gitlab-org/gitlab/-/issues/346843).
Please upvote the issue to help with prioritization, and
[contributions are welcomed](https://about.gitlab.com/community/contribute/).
