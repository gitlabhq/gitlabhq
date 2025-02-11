---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Evaluate GitLab SAST
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You might choose to evaluate GitLab SAST before using it in your organization.
Consider the following guidance as you plan and conduct your evaluation.

## Important concepts

GitLab SAST is designed to help teams collaboratively improve the security of the code they write.
The steps you take to scan your code and view the results are centered around the source code repository being scanned.

### Scanning process

GitLab SAST automatically selects the right scanning technology to use depending on which programming languages are found in your project.
For all languages except Groovy, GitLab SAST scans your source code directly without requiring a compilation or build step.
This makes it easier to enable scanning across a variety of projects.
For details, see [Supported languages and frameworks](_index.md#supported-languages-and-frameworks).

### When vulnerabilities are reported

GitLab SAST [analyzers](analyzers.md) and their [rules](rules.md) are designed to minimize noise for development and security teams.

For details on when the GitLab Advanced SAST analyzer reports vulnerabilities, see [When vulnerabilities are reported](gitlab_advanced_sast.md#when-vulnerabilities-are-reported).

### Other platform features

SAST is integrated with other security and compliance features in GitLab Ultimate.
If you're comparing GitLab SAST to another product, you may find that some of its features are included in a related GitLab feature area instead of SAST:

- [IaC scanning](../iac_scanning/_index.md) scans your Infrastructure as Code (IaC) definitions for security problems.
- [Secret detection](../secret_detection/_index.md) finds leaked secrets in your code.
- [Security policies](../policies/_index.md) allow you to force scans to run or require that vulnerabilities are fixed.
- [Vulnerability management and reporting](../vulnerability_report/_index.md) manages the vulnerabilities that exist in the codebase and integrates with issue trackers.
- GitLab Duo [vulnerability explanation](../vulnerabilities/_index.md#explaining-a-vulnerability) and [vulnerability resolution](../vulnerabilities/_index.md#resolve-a-vulnerability) help you remediate vulnerabilities quickly by using AI.

## Choose a test codebase

When choosing a codebase to test SAST, you should:

- Test in a repository where you can safely modify the CI/CD configuration without getting in the way of normal development activities.
  SAST scans run in your CI/CD pipeline, so you'll need to make a small edit to the CI/CD configuration to [enable SAST](_index.md#configuration).
  - You can make a fork or copy of an existing repository for testing. This way, you can set up your testing environment without any chance of interrupting normal development.
- Use a codebase that matches your organization's typical technology stack.
- Use a language that [GitLab Advanced SAST supports](gitlab_advanced_sast.md#supported-languages).
  GitLab Advanced SAST produces more accurate results than other [analyzers](analyzers.md).

Your test project must have GitLab Ultimate. Only Ultimate includes [features](_index.md#features) like:

- Proprietary cross-file, cross-function scanning with GitLab Advanced SAST.
- The merge request widget, pipeline security report, and default-branch vulnerability report that makes scan results visible and actionable.

### Benchmarks and example projects

If you choose to use a benchmark or an intentionally vulnerable application for testing, remember that these applications:

- Focus on specific vulnerability types.
  The benchmark's focus may be different from the vulnerability types your organization prioritizes for discovery and remediation.
- Use specific technologies in specific ways that may differ from how your organization builds software.
- Report results in ways that may implicitly emphasize certain criteria over others.
  For example, you may prioritize precision (fewer false-positive results) while the benchmark only scores based on recall (fewer false-negative results).

[Epic 15296](https://gitlab.com/groups/gitlab-org/-/epics/15296) tracks work to recommend specific projects for testing.

### AI-generated test code

You should not use AI tools to create vulnerable code for testing SAST.
AI models often return code that is not truly exploitable.

For example:

- AI tools often write small functions that take a parameter and use it in a sensitive context (called a "sink"), without actually receiving any user input.
  This can be a safe design if the function is only called with program-controlled values, like constants.
  The code is not vulnerable unless user input is allowed to flow to these sinks without first being sanitized or validated.
- AI tools may comment out part of the vulnerability to prevent you from accidentally running the code.

Reporting vulnerabilities in these unrealistic examples would cause false-positive results in real-world code.
GitLab SAST is not designed to report vulnerabilities in these cases.

## Conduct the test

After you choose a codebase to test with, you're ready to conduct the test. You can follow these steps:

1. [Enable SAST](_index.md#configuration) by creating a merge request (MR) that adds SAST to the CI/CD configuration.
   - Be sure to set the CI/CD variable to [enable GitLab Advanced SAST](gitlab_advanced_sast.md#enable-gitlab-advanced-sast-scanning) for more accurate results.
1. Merge the MR to the repository's default branch.
1. Open the [Vulnerability Report](../vulnerability_report/_index.md) to see the vulnerabilities found on the default branch.
   - If you're using GitLab Advanced SAST, you can use the [Tool filter](../vulnerability_report/_index.md#tool-filter) to show results only from that scanner.
1. Review vulnerability results.
   - Check the [code flow view](../vulnerabilities/_index.md#vulnerability-code-flow) for GitLab Advanced SAST vulnerabilities that involve tainted user input, like SQL injection or path traversal.
   - If you have GitLab Duo Enterprise, [explain](../vulnerabilities/_index.md#explaining-a-vulnerability) or [resolve](../vulnerabilities/_index.md#resolve-a-vulnerability) a vulnerability.
1. To see how scanning works as new code is developed, create a new merge request that changes application code and adds a new vulnerability or weakness.
