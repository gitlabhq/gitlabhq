---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Detect
description: Vulnerability detection and result evaluation.
---

Detect vulnerabilities in your project's repository and application's behavior throughout the
software development lifecycle.

To help you manage the risk of vulnerabilities during development:

- Security scanners run when you push code changes to a branch.
- You can view details of vulnerabilities detected in the branch. Developers can remediate
  vulnerabilities at this point, fixing them before they reach production.
- Optionally, you can enforce additional approval on merge requests containing vulnerabilities. For
  details, see [merge request approval policies](../policies/merge_request_approval_policies.md).

To help manage vulnerabilities outside development:

- Security scanning can be scheduled or run manually.
- Vulnerabilities detected in the default branch appear in a vulnerability report. Use this report
  to triage, analyze, and remediate vulnerabilities.

## Security scanning

To get the most from security scanning, it's important to understand:

- How to trigger security scanning.
- What aspects of your application or repository are scanned.
- What determines which scanners run.
- How security scanning occurs.

### Triggers

Security scanning in a CI/CD pipeline is triggered by default when changes are pushed to a project's
repository.

You can also run security scanning by:

- Running a CI/CD pipeline manually.
- Scheduling security scanning by using a scan execution policy.
- For DAST only, running an on-demand DAST scan manually or on a schedule.
- For SAST only, running a scan by using the GitLab Workflow extension for VS Code.

### Detection coverage

Scan your project's repository and test your application's behavior for vulnerabilities:

- Repository scanning can detect vulnerabilities in your project's repository. Coverage includes
  your application's source code, also the libraries and container images it's dependent on.
- Behavioral testing of your application and its API can detect vulnerabilities that occur only at
  runtime.

#### Repository scanning

Your project's repository may contain source code, dependency declarations, and infrastructure
definitions. Repository scanning can detect vulnerabilities in each of these.

Repository scanning tools include:

- Static application security testing (SAST): Analyze source code for vulnerabilities.
- Infrastructure as Code (IaC) scanning: Detect vulnerabilities in your application's infrastructure
  definitions.
- Secret detection: Detect and block secrets from being committed to the repository.
- Dependency scanning: Detect vulnerabilities in your application's dependencies and container
  images.

#### Behavioral testing

Behavioral testing requires a deployable application to test for known vulnerabilities and
unexpected behavior.

Behavioral testing tools include:

- Dynamic Application Security Testing (DAST): Test your application for known attack vectors.
- API security testing: Test your application's API for known attacks and vulnerabilities to input.
- Coverage-guided fuzz testing: Test your application for unexpected behavior.

### Scanner selection

Security scanners are enabled for a project by either:

- Adding the scanner's CI/CD template to the `.gitlab-ci.yml` file, either directly or by using
  AutoDevOps.
- Enforcing the scanner by using a scan execution policy, pipeline execution policy, or
  compliance framework. This enforcement can be applied directly to the project or inherited from
  the project's parent group.

For more details, see [Security configuration](security_configuration.md).

### Security scanning process

The security scanning process is:

1. According to the CI/CD job criteria, those scanners that are enabled and intended to run in a
   pipeline run as separate jobs.

   Each successful job outputs one or more security reports as job artifacts. These reports contain
   details of all vulnerabilities detected in the branch, regardless of whether they were previously
   found, dismissed, or new.
1. Each security report is processed, including [validation](security_report_validation.md) and
   [deduplication](vulnerability_deduplication.md).
1. When all jobs finish, including manual jobs, you can download or view the results.

For more details on the output of security scanning, see
[Security scanning results](security_scanning_results.md).

#### CI/CD security job criteria

Security scanning jobs in a CI/CD pipeline are determined by the following criteria:

1. Inclusion of security scanning templates

   The selection of security scanning jobs is first determined by which templates are included or
   enforced by a policy or compliance framework.

   Security scanning runs by default in branch pipelines. To run security scanning in merge request
   pipelines you must specifically [enable it](security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

1. Evaluation of rules

   Each template has defined [rules](../../../ci/yaml/_index.md#rules) which determine if the
   analyzer is run.

   For example, some analyzers run only if files of a specific type are detected in the
   repository.

1. Analyzer logic

   If the template's rules dictate that the job is to be run, a job is created in the pipeline stage
   specified in the template. However, each analyzer has its own logic which determines if the
   analyzer itself is to be run.

   For example, if dependency scanning doesn't detect supported files at the default depth, the
   analyzer is not run and no artifacts are output.

Jobs pass if they complete a scan, even if they don't find vulnerabilities. The only exception is
coverage fuzzing, which fails if it identifies findings. All jobs are permitted to fail so that
they don't fail the entire pipeline. Don't change the job
[`allow_failure` setting](../../../ci/yaml/_index.md#allow_failure) because that fails the entire
pipeline.

## Data privacy

GitLab processes the source code and performs analysis locally on the GitLab Runner. No data is
transmitted outside GitLab infrastructure (server and runners).

Security analyzers access the internet only to download the latest sets of signatures, rules, and
patches. If you prefer the scanners do not access the internet, consider using an
[offline environment](../offline_deployments/_index.md).
