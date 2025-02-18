---
stage: DevSecOps
group: Technical writing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Get started securing your application
---

Identify and remediate vulnerabilities in your application's source code.
Integrate security testing into the software development lifecycle
by automatically scanning your code for potential security issues.

You can scan various programming languages and frameworks,
and detect vulnerabilities like SQL injection, cross-site scripting (XSS),
and insecure dependencies. The results of the security scans are displayed in the GitLab UI,
where you can review and address them.

These features can also be integrated with other GitLab features like merge requests
and pipelines to ensure that security is a priority throughout the development process.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Adopting GitLab application security](https://www.youtube.com/watch?v=5QlxkiKR04k)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[View an interactive reading and how-to demo playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)

This process is part of a larger workflow:

![Workflow](img/get_started_app_sec_v16_11.png)

## Step 1: Learn about scanning

Secret Detection scans your repository to help prevent your secrets from being exposed.
It works with all programming languages.

Dependency Scanning analyzes your application's dependencies for known vulnerabilities.
It works with certain languages and package managers.

For more information, see:

- [Secret Detection](secret_detection/_index.md)
- [Dependency Scanning](dependency_scanning/_index.md)

## Step 2: Choose a project to test

If it's your first time setting up GitLab security scanning, you should start with a single project.
The project should:

- Use your organization's typical programming languages and technologies,
  because some scanning features work differently for different languages.
- Allow you to try new settings, like required approvals, without interrupting your team's daily work.
  You can create a copy of a high-traffic project, or select a project that's not as busy.

## Step 3: Enable scanning

To identify leaked secrets and vulnerable packages in the project,
create a merge request that enables Secret Detection and Dependency Scanning.

This merge request updates your `.gitlab-ci.yml` file, so that the scans
run as part of your project's CI/CD pipeline.

As part of this MR, you can change settings to accommodate your project's layout or configuration.
For example, you might exclude a directory of third-party code.

After you merge this MR to your default branch, the system creates a baseline scan.
This scan identifies which vulnerabilities already exist on the default branch.
Then, merge requests will highlight any newly introduced problems.

Without a baseline scan, merge requests display every vulnerability in the branch,
even if the vulnerability already exists on the default branch.

For more information, see:

- [Enable Secret Detection](secret_detection/pipeline/_index.md#enable-the-analyzer)
- [Secret Detection settings](secret_detection/pipeline/_index.md#configuration)
- [Enable Dependency Scanning](dependency_scanning/_index.md#configuration)
- [Dependency Scanning settings](dependency_scanning/_index.md#available-cicd-variables)

## Step 4: Review scan results

Let your team get comfortable with viewing security findings in merge requests
and the vulnerability report.

Establish a vulnerability triage workflow. Consider creating labels and issue boards
to help manage issues created from vulnerabilities. With issue boards, all stakeholders
have a common view of all issues and can track remediation progress.

Monitor the Security Dashboard trends to gauge success in remediating existing vulnerabilities
and preventing the introduction of new ones.

For more information, see:

- [View the vulnerability report](vulnerability_report/_index.md)
- [View security findings in merge requests](detect/security_scan_results.md#merge-request)
- [View the Security Dashboard](security_dashboard/_index.md)
- [Labels](../project/labels.md)
- [Issue boards](../project/issue_board.md)

## Step 5: Schedule future scanning jobs

Enforce scheduled security scanning jobs by using a scan execution policy.
These scheduled jobs run independently from any other security scans you
might have defined in a compliance framework pipeline or in the project's `.gitlab-ci.yml` file.

Scheduled scans are most useful for projects or important branches with
low development activity and where pipeline scans are infrequent.

For more information, see:

- [Scan execution policy](policies/scan_execution_policies.md)
- [Container scans](container_scanning/_index.md)
- [Operational container scanning](../clusters/agent/vulnerabilities.md)

## Step 6: Limit new vulnerabilities

To enforce required scan types and ensure separation of duties between security and engineering,
use Scan Execution Policies.

To limit new vulnerabilities from being merged into your default branch,
create a merge request approval policy.

After you've gotten familiar with how scanning works, you can then choose to:

- Follow the same steps to enable scanning in more projects.
- Enforce scanning across more of your projects at once.

For more information, see:

- [Scan Execution Policies](policies/scan_execution_policies.md)
- [Merge request approval policy](policies/_index.md)

## Step 7: Continue scanning for new vulnerabilities

Over time, you want to ensure new vulnerabilities are not introduced.

- To surface newly discovered vulnerabilities that already exist in your repository,
  run regular dependency and container scans.
- To scan container images in your production cluster for security vulnerabilities,
  enable operational container scanning.
- Enable other scan types, like SAST, DAST, or Fuzz testing.
- To allow for DAST and Web API fuzzing on ephemeral test environments,
  consider enabling review apps.

For more information, see:

- [SAST](sast/_index.md)
- [DAST](dast/_index.md)
- [Fuzz testing](coverage_fuzzing/_index.md)
- [Web API fuzzing](api_fuzzing/_index.md)
- [Review apps](../../development/testing_guide/review_apps.md)
