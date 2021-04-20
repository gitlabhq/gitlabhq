---
stage: secure
group: secure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Application security **(ULTIMATE)**

GitLab can check your application for security vulnerabilities that may lead to unauthorized access,
data leaks, denial of services, and more. GitLab reports vulnerabilities in the merge request so you
can fix them before you merge.

- The [Security Dashboard](security_dashboard/index.md) provides a
  high-level view of vulnerabilities detected in your projects, pipeline, and groups.
- The [Threat Monitoring](threat_monitoring/index.md) page provides runtime security metrics
  for application environments. With the information provided,
  you can immediately begin risk analysis and remediation.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of GitLab application security, see
[Security Deep Dive](https://www.youtube.com/watch?v=k4vEJnGYy84).

## Quick start

Get started quickly with Dependency Scanning, License Scanning, Static Application Security
Testing (SAST), and Secret Detection by adding the following to your [`.gitlab-ci.yml`](../../ci/yaml/README.md):

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
```

To add Dynamic Application Security Testing (DAST) scanning, add the following to your
`.gitlab-ci.yml` and replace `https://staging.example.com` with a staging server's web address:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml

variables:
  DAST_WEBSITE: https://staging.example.com
```

To ensure the DAST scanner runs *after* deploying the application to the staging server, review the [DAST full documentation](dast/index.md).

To add Container Scanning, follow the steps listed in the [Container Scanning documentation](container_scanning/index.md#requirements).

To further configure any of the other scanners, refer to each scanner's documentation.

### SAST configuration

You can set up and configure Static Application Security Testing
(SAST) for your project, without opening a text editor. For more details,
see [configure SAST in the UI](sast/index.md#configure-sast-in-the-ui).

### Override the default registry base address

By default, GitLab security scanners use `registry.gitlab.com/gitlab-org/security-products/analyzers` as the
base address for Docker images. You can override this globally by setting the CI/CD variable
`SECURE_ANALYZERS_PREFIX` to another location. Note that this affects all scanners at once.

## Security scanning tools

GitLab uses the following tools to scan and report known vulnerabilities found in your project.

| Secure scanning tool                                                         | Description                                                            |
|:-----------------------------------------------------------------------------|:-----------------------------------------------------------------------|
| [Container Scanning](container_scanning/index.md) **(ULTIMATE)**             | Scan Docker containers for known vulnerabilities.                      |
| [Dependency List](dependency_list/index.md) **(ULTIMATE)**                   | View your project's dependencies and their known vulnerabilities.      |
| [Dependency Scanning](dependency_scanning/index.md) **(ULTIMATE)**           | Analyze your dependencies for known vulnerabilities.                   |
| [Dynamic Application Security Testing (DAST)](dast/index.md) **(ULTIMATE)**  | Analyze running web applications for known vulnerabilities.            |
| [API fuzzing](api_fuzzing/index.md) **(ULTIMATE)**                           | Find unknown bugs and vulnerabilities in web APIs with fuzzing.        |
| [Secret Detection](secret_detection/index.md)                                | Analyze Git history for leaked secrets.                                |
| [Security Dashboard](security_dashboard/index.md) **(ULTIMATE)**             | View vulnerabilities in all your projects and groups.                  |
| [Static Application Security Testing (SAST)](sast/index.md)                  | Analyze source code for known vulnerabilities.                         |
| [Coverage fuzzing](coverage_fuzzing/index.md) **(ULTIMATE)**                 | Find unknown bugs and vulnerabilities with coverage-guided fuzzing.    |

### Use security scanning tools with Pipelines for Merge Requests

The security scanning tools can all be added to pipelines with [templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security).
See each tool for details on how to use include each template in your CI/CD configuration.

By default, the application security jobs are configured to run for branch pipelines only.
To use them with [pipelines for merge requests](../../ci/merge_request_pipelines/index.md),
you may need to override the default `rules:` configuration to add:

```yaml
rules:
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

## Security Scanning with Auto DevOps

When [Auto DevOps](../../topics/autodevops/) is enabled, all GitLab Security scanning tools are configured using default settings.

- [Auto SAST](../../topics/autodevops/stages.md#auto-sast)
- [Auto Secret Detection](../../topics/autodevops/stages.md#auto-secret-detection)
- [Auto DAST](../../topics/autodevops/stages.md#auto-dast)
- [Auto Dependency Scanning](../../topics/autodevops/stages.md#auto-dependency-scanning)
- [Auto License Compliance](../../topics/autodevops/stages.md#auto-license-compliance)
- [Auto Container Scanning](../../topics/autodevops/stages.md#auto-container-scanning)

While you cannot directly customize Auto DevOps, you can [include the Auto DevOps template in your project's `.gitlab-ci.yml` file](../../topics/autodevops/customize.md#customizing-gitlab-ciyml).

## Maintenance and update of the vulnerabilities database

The scanning tools and vulnerabilities database are updated regularly.

| Secure scanning tool                                         | Vulnerabilities database updates          |
|:-------------------------------------------------------------|-------------------------------------------|
| [Container Scanning](container_scanning/index.md)            | Uses `clair`. The latest `clair-db` version is used for each job by running the [`latest` Docker image tag](https://gitlab.com/gitlab-org/gitlab/blob/438a0a56dc0882f22bdd82e700554525f552d91b/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml#L37). The `clair-db` database [is updated daily according to the author](https://github.com/arminc/clair-local-scan#clair-server-or-local). |
| [Dependency Scanning](dependency_scanning/index.md)          | Relies on `bundler-audit` (for Ruby gems), `retire.js` (for npm packages), and `gemnasium` (the GitLab tool for all libraries). Both `bundler-audit` and `retire.js` fetch their vulnerabilities data from GitHub repositories, so vulnerabilities added to `ruby-advisory-db` and `retire.js` are immediately available. The tools themselves are updated once per month if there's a new version. The [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db) is updated at least once a week. See our [current measurement of time from CVE being issued to our product being updated](https://about.gitlab.com/handbook/engineering/development/performance-indicators/#cve-issue-to-update). |
| [Dynamic Application Security Testing (DAST)](dast/index.md) | The scanning engine is updated on a periodic basis. See the [version of the underlying tool `zaproxy`](https://gitlab.com/gitlab-org/security-products/dast/blob/master/Dockerfile#L1). The scanning rules are downloaded at scan runtime. |
| [Static Application Security Testing (SAST)](sast/index.md)  | Relies exclusively on [the tools GitLab wraps](sast/index.md#supported-languages-and-frameworks). The underlying analyzers are updated at least once per month if a relevant update is available. The vulnerabilities database is updated by the upstream tools. |

Currently, you do not have to update GitLab to benefit from the latest vulnerabilities definitions.
The security tools are released as Docker images. The vendored job definitions that enable them use
major release tags according to [Semantic Versioning](https://semver.org/). Each new release of the
tools overrides these tags.
The Docker images are updated to match the previous GitLab releases, so users automatically get the
latest versions of the scanning tools without having to do anything. There are some known issues
with this approach, however, and there is a
[plan to resolve them](https://gitlab.com/gitlab-org/gitlab/-/issues/9725).

## View security scan information in merge requests **(FREE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4393) in GitLab Free 13.5.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/273205) in 13.6.
> - Report download dropdown [added](https://gitlab.com/gitlab-org/gitlab/-/issues/273418) in 13.7.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/249550) in GitLab 13.9.

Merge requests which have run security scans let you know that the generated
reports are available to download. To download a report, click on the
**Download results** dropdown, and select the desired report.

![Security widget](img/security_widget_v13_7.png)

## View details of a DAST vulnerability

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36332) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.1.

Vulnerabilities detected by DAST occur in the live web application. Rectification of these types of
vulnerabilities requires specific information. DAST provides the information required to
investigate and rectify the underlying cause.

To view details of DAST vulnerabilities:

1. To see all vulnerabilities detected:
   - In a project, go to the project's **{shield}** **Security & Compliance** page.
   - Only in a merge request, go the merge request's **Security** tab.

1. Select the vulnerability's description. The following details are provided:

| Field            | Description                                                        |
|:-----------------|:------------------------------------------------------------------ |
| Description      | Description of the vulnerability.                                  |
| Project          | Namespace and project in which the vulnerability was detected.     |
| Method           | HTTP method used to detect the vulnerability.                      |
| URL              | URL at which the vulnerability was detected.                       |
| Request Headers  | Headers of the request.                                            |
| Response Status  | Response status received from the application.                     |
| Response Headers | Headers of the response received from the application.             |
| Evidence         | Evidence of the data found that verified the vulnerability. Often a snippet of the request or response, this can be used to help verify that the finding is a vulnerability. |
| Identifiers      | Identifiers of the vulnerability.                                  |
| Severity         | Severity of the vulnerability.                                     |
| Scanner Type     | Type of vulnerability report.                                      |
| Links            | Links to further details of the detected vulnerability.            |
| Solution         | Details of a recommended solution to the vulnerability (optional). |

### Hide sensitive information in headers

HTTP request and response headers may contain sensitive information, including cookies and
authorization credentials. By default, content of specific headers are masked in DAST vulnerability
reports. You can specify the list of all headers to be masked. For details, see
[Hide sensitive information](dast/index.md#hide-sensitive-information).

## Addressing vulnerabilities

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.8.

For each security vulnerability in a merge request or [Vulnerability Report](vulnerability_report/index.md),
you can:

- [Dismiss the vulnerability](#dismiss-a-vulnerability).
- Create a [confidential](../project/issues/confidential_issues.md)
  [issue](vulnerabilities/index.md#create-a-gitlab-issue-for-a-vulnerability).
- Apply an [automatically remediation](#apply-an-automatic-remediation-for-a-vulnerability).

### Dismiss a vulnerability

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.0, a dismissal reason.

You can dismiss a vulnerability for the entire project.

1. Select the vulnerability in the Security Dashboard.
1. In the top-right, from the **Status** selector menu, select **Dismissed**.
1. Optional. Add a reason for the dismissal and select **Save comment**.

To undo this action, select a different status from the same menu.

#### Dismiss multiple vulnerabilities

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35816) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.9.

You can dismiss multiple vulnerabilities at once.

1. In the list of vulnerabilities, select the checkbox for each vulnerability you want to dismiss.
   To select all, select the checkbox in the table header.
1. Above the table, select a dismissal reason.
1. Select **Dismiss Selected**.

### Create an issue for a vulnerability

You can create a GitLab or Jira issue for a vulnerability. For details, see [Vulnerability Pages](vulnerabilities/index.md).

#### Link to an existing issue

If you already have an open issue, you can link to it from the vulnerability.

- The vulnerability page shows related issues, but the issue page doesn't show the vulnerability it's related to.
- An issue can only be related to one vulnerability at a time.
- Issues can be linked across groups and projects.

To link to an existing issue:

1. Open the vulnerability.
1. [Add a linked issue](../project/issues/related_issues.md).

### Apply an automatic remediation for a vulnerability

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5656) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.7.

Some vulnerabilities can be fixed by applying the solution that GitLab automatically generates.
The following scanners are supported:

- [Dependency Scanning](dependency_scanning/index.md).
  Automatic Patch creation is only available for Node.js projects managed with
  `yarn`.
- [Container Scanning](container_scanning/index.md).

#### Manually apply the suggested patch

To manually apply the patch that GitLab generated for a vulnerability:

1. Select the **Resolve with merge request** dropdown, then select **Download patch to resolve**:

   ![Resolve with Merge Request button dropdown](img/vulnerability_page_merge_request_button_dropdown_v13_1.png)

1. Ensure your local project has the same commit checked out that was used to generate the patch.
1. Run `git apply remediation.patch`.
1. Verify and commit the changes to your branch.

#### Create a merge request with the suggested patch

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9224) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.9.

In some cases, you can create a merge request that automatically remediates the
vulnerability. Any vulnerability that has a
[solution](#apply-an-automatic-remediation-for-a-vulnerability) can have a merge
request created to automatically solve the issue.

If this action is available:

1. Select the **Resolve with merge request** dropdown, then select **Resolve with merge request**.

   ![Create merge request from vulnerability](img/create_mr_from_vulnerability_v13_4.png)

A merge request is created. It that applies the solution to the source branch.

## Security approvals in merge requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9928) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.2.

Merge Request Approvals can be configured to require approval from a member of your
security team when a merge request would introduce one of the following security issues:

- A security vulnerability
- A software license compliance violation

The security vulnerability threshold is defined as `high`, `critical`, or `unknown` severity. The
`Vulnerability-Check` approver group must approve merge requests that contain vulnerabilities.

When GitLab can assess vulnerability severity, the rating can be one of the following:

- `unknown`
- `low`
- `medium`
- `high`
- `critical`

The rating `unknown` indicates that the underlying scanner doesn't contain or provide a severity
rating.

### Enabling Security Approvals within a project

To enable the `Vulnerability-Check` or `License-Check` Security Approvals, a [project approval rule](../project/merge_requests/merge_request_approvals.md#adding--editing-a-default-approval-rule)
must be created. A [security scanner job](#security-scanning-tools) must be enabled for
`Vulnerability-Check`, and a [license scanning](../compliance/license_compliance/index.md#configuration)
job must be enabled for `License-Check`. When the proper jobs aren't configured, the following
appears:

![Un-configured Approval Rules](img/unconfigured_security_approval_rules_and_jobs_v13_4.png)

If at least one security scanner is enabled, you can enable the `Vulnerability-Check` approval rule. If a license scanning job is enabled, you can enable the `License-Check` rule.

![Un-configured Approval Rules with valid pipeline jobs](img/unconfigured_security_approval_rules_and_enabled_jobs_v13_4.png)

For this approval group, you must set the number of approvals required to greater than zero. You
must have Maintainer or Owner [permissions](../permissions.md#project-members-permissions)
to manage approval rules.

Follow these steps to enable `Vulnerability-Check`:

1. Navigate to your project's **Settings > General** and expand **Merge request approvals**.
1. Click **Enable**, or **Edit**.
1. Add or change the **Rule name** to `Vulnerability-Check` (case sensitive).

![Vulnerability Check Approver Rule](img/vulnerability-check_v13_4.png)

Once this group is added to your project, the approval rule is enabled for all merge requests.

Any code changes cause the approvals required to reset.

An approval is required when the latest security report in a merge request:

- Contains a vulnerability of `high`, `critical`, or `unknown` severity that is not present in the
  target branch. Note that approval is still required for dismissed vulnerabilities.
- Is not generated during pipeline execution.

An approval is optional when the security report:

- Contains no new vulnerabilities when compared to the target branch.
- Contains only new vulnerabilities of `low` or `medium` severity.

### Enabling License Approvals within a project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13067) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.3.

`License-Check` is a [security approval rule](#enabling-security-approvals-within-a-project)
you can enable to allow an individual or group to approve a merge request that contains a `denied`
license. For instructions on enabling this rule, see
[Enabling license approvals within a project](../compliance/license_compliance/index.md#enabling-license-approvals-within-a-project).

## Working in an offline environment

It is possible to run most of the GitLab security scanners when not
connected to the internet, in what is sometimes known as an offline,
limited connectivity, Local Area Network (LAN), Intranet, or "air-gap"
environment.

Read how to [operate the Secure scanners in an offline environment](offline_deployments/index.md).

## Using private Maven repositories

If you have a private Apache Maven repository that requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable
to pass a username and password. You can set it under your project's settings
so that your credentials aren't exposed in `.gitlab-ci.yml`.

If the username is `myuser` and the password is `verysecret` then you would
[set the following variable](../../ci/variables/README.md#custom-cicd-variables)
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

## Outdated security reports

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4913) in GitLab 12.7.

When a security report generated for a merge request becomes outdated, the merge request shows a warning
message in the security widget and prompts you to take an appropriate action.

This can happen in two scenarios:

1. Your [source branch is behind the target branch](#source-branch-is-behind-the-target-branch).
1. The [target branch security report is out of date](#target-branch-security-report-is-out-of-date).

### Source branch is behind the target branch

This means the most recent common ancestor commit between the target branch and the source branch is
not the most recent commit on the target branch. This is by far the most common situation.

In this case you must rebase or merge to incorporate the changes from the target branch.

![Incorporate target branch changes](img/outdated_report_branch_v12_9.png)

### Target branch security report is out of date

This can happen for many reasons, including failed jobs or new advisories. When the merge request shows that a
security report is out of date, you must run a new pipeline on the target branch.
You can do it quickly by following the hyperlink given to run a new pipeline.

![Run a new pipeline](img/outdated_report_pipeline_v12_9.png)

## Troubleshooting

### Getting error message `sast job: stage parameter should be [some stage name here]`

When [including](../../ci/yaml/README.md#includetemplate) a `.gitlab-ci.yml` template
like [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml),
the following error may occur, depending on your GitLab CI/CD configuration:

```plaintext
Found errors in your .gitlab-ci.yml:

* sast job: stage parameter should be unit-tests
```

This error appears when the included job's stage (named `test`) isn't declared in `.gitlab-ci.yml`.
To fix this issue, you can either:

- Add a `test` stage in your `.gitlab-ci.yml`.
- Override the default stage of each security job. For example, to use a pre-defined stage name `unit-tests`:

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
  ```

[Learn more on overriding SAST jobs](sast/index.md#overriding-sast-jobs).
All the security scanning tools define their stage, so this error can occur with all of them.

### Getting warning messages `… report.json: no matching files`

This is often followed by the [error `No files to upload`](../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload),
and preceded by other errors or warnings that indicate why the JSON report wasn't generated. Please
check the entire job log for such messages. If you don't find these messages, retry the failed job
after setting `SECURE_LOG_LEVEL: "debug"` as a
[custom CI/CD variable](../../ci/variables/README.md#custom-cicd-variables).
This provides useful information to investigate further.

### Getting error message `sast job: config key may not be used with 'rules': only/except`

When [including](../../ci/yaml/README.md#includetemplate) a `.gitlab-ci.yml` template
like [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml),
the following error may occur, depending on your GitLab CI/CD configuration:

```plaintext
Found errors in your .gitlab-ci.yml:

    jobs:sast config key may not be used with `rules`: only/except
```

This error appears when the included job's `rules` configuration has been [overridden](sast/index.md#overriding-sast-jobs)
with [the deprecated `only` or `except` syntax.](../../ci/yaml/README.md#onlyexcept-basic)
To fix this issue, you must either:

- [Transition your `only/except` syntax to `rules`](#transitioning-your-onlyexcept-syntax-to-rules).
- (Temporarily) [Pin your templates to the deprecated versions](#pin-your-templates-to-the-deprecated-versions)

[Learn more on overriding SAST jobs](sast/index.md#overriding-sast-jobs).

#### Transitioning your `only/except` syntax to `rules`

When overriding the template to control job execution, previous instances of
[`only` or `except`](../../ci/yaml/README.md#onlyexcept-basic) are no longer compatible
and must be transitioned to [the `rules` syntax](../../ci/yaml/README.md#rules).

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

[Learn more on the usage of `rules`](../../ci/yaml/README.md#rules).

#### Pin your templates to the deprecated versions

To ensure the latest support, we **strongly** recommend that you migrate to [`rules`](../../ci/yaml/README.md#rules).

If you're unable to immediately update your CI configuration, there are several workarounds that
involve pinning to the previous template versions, for example:

  ```yaml
  include:
    remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/12-10-stable-ee/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'
  ```

Additionally, we provide a dedicated project containing the versioned legacy templates.
This can be useful for offline setups or anyone wishing to use [Auto DevOps](../../topics/autodevops/index.md).

Instructions are available in the [legacy template project](https://gitlab.com/gitlab-org/auto-devops-v12-10).

#### Vulnerabilities are found, but the job succeeds. How can I have a pipeline fail instead?

This is the current default behavior, because the job's status indicates success or failure of the analyzer itself.
Analyzer results are displayed in the [job logs](../../ci/jobs/index.md#expand-and-collapse-job-log-sections),
[Merge Request widget](#view-security-scan-information-in-merge-requests)
or [Security Dashboard](security_dashboard/index.md).

### Error: job `is used for configuration only, and its script should not be executed`

[Changes made in GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41260)
to the `Security/Dependency-Scanning.gitlab-ci.yml` and `Security/SAST.gitlab-ci.yml`
templates mean that if you enable the `sast` or `dependency_scanning` jobs by setting the `rules` attribute,
they will fail with the error `(job) is used for configuration only, and its script should not be executed`.

The `sast` or `dependency_scanning` stanzas can be used to make changes to all SAST or Dependency Scanning,
such as changing `variables` or the `stage`, but they cannot be used to define shared `rules`.

There [is an issue open to improve extendability](https://gitlab.com/gitlab-org/gitlab/-/issues/218444).
Please upvote the issue to help with prioritization, and
[contributions are welcomed](https://about.gitlab.com/community/contribute/).
