---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Advanced SAST
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Introduced in GitLab 17.1 as an [experiment](../../../policy/development_stages_support.md) for Python.
> - Support for Go and Java added in 17.2.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461859) from experiment to beta in GitLab 17.2.
> - Support for JavaScript, TypeScript, and C# added in 17.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/474094) in GitLab 17.3.
> - Support for Java Server Pages (JSP) added in GitLab 17.4.

GitLab Advanced SAST is a Static Application Security Testing (SAST) analyzer
designed to discover vulnerabilities by performing cross-function and cross-file taint analysis.

GitLab Advanced SAST is an opt-in feature.
When it is enabled, the GitLab Advanced SAST analyzer scans all the files of the supported languages,
using the GitLab Advanced SAST predefined ruleset.
The Semgrep analyzer will not scan these files.

All vulnerabilities identified by the GitLab Advanced SAST analyzer will be reported,
including vulnerabilities previously reported by the Semgrep-based analyzer.
An automated transition automatically de-duplicates findings
when GitLab Advanced SAST locates the same type of vulnerability in the same location as the Semgrep-based analyzer.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of GitLab Advanced SAST and how it works, see [GitLab Advanced SAST: Accelerating Vulnerability Resolution](https://youtu.be/xDa1MHOcyn8).

For a product tour, see the [GitLab Advanced SAST product tour](https://gitlab.navattic.com/advanced-sast).

## When vulnerabilities are reported

GitLab Advanced SAST uses cross-file, cross-function scanning with taint analysis to trace the flow of user input into the program.
By following the paths user inputs take, the analyzer identifies potential points
where untrusted data can influence the execution of your application in unsafe ways,
ensuring that injection vulnerabilities, such as SQL injection and cross-site scripting (XSS),
are detected even when they span multiple functions and files.

To minimize noise, GitLab Advanced SAST only reports taint-based vulnerabilities when there is a verifiable flow that brings untrusted user input source to a sensitive sink.
Other products may report vulnerabilities with less validation.

GitLab Advanced SAST is tuned to emphasize input that crosses trust boundaries, like values that are sourced from HTTP requests.
The set of untrusted input sources does not include command-line arguments, environment variables, or other inputs that are typically provided by the user operating the program.

For details of which types of vulnerabilities GitLab Advanced SAST detects, see [GitLab Advanced SAST CWE coverage](advanced_sast_coverage.md).

## Supported languages

GitLab Advanced SAST supports the following languages with cross-function and cross-file taint analysis:

- C#
- Go
- Java, including Java Server Pages (JSP)
- JavaScript, TypeScript
- Python
- Ruby

## Configuration

Enable the GitLab Advanced SAST analyzer to discover vulnerabilities in your application by performing
cross-function and cross-file taint analysis. You can then adjust its behavior by using CI/CD
variables.

### Requirements

Like other GitLab SAST analyzers, the GitLab Advanced SAST analyzer requires a runner and a CI/CD pipeline; see [SAST requirements](_index.md#requirements) for details.

On GitLab Self-Managed, you must also use a GitLab version that supports GitLab Advanced SAST:

- You should use GitLab 17.4 or later if possible. GitLab 17.4 includes a new code-flow view, vulnerability deduplication, and further updates to the SAST CI/CD template.
- The [SAST CI/CD templates](_index.md#stable-vs-latest-sast-templates) were updated to include GitLab Advanced SAST in the following releases:
  - The stable template includes GitLab Advanced SAST in GitLab 17.3 or later.
  - The latest template includes GitLab Advanced SAST in GitLab 17.2 or later. Note that you [should not mix latest and stable templates](../detect/roll_out_security_scanning.md#template-editions) in a single project.
- At a minimum, GitLab Advanced SAST requires version 17.1 or later.

### Enable GitLab Advanced SAST scanning

GitLab Advanced SAST is included in the standard GitLab SAST CI/CD template, but isn't yet enabled by default.
To enable it, set the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `true`.
You can set this variable in different ways depending on how you manage your CI/CD configuration.

#### Edit the CI/CD pipeline definition manually

If you've already enabled GitLab SAST scanning in your project, add a new CI/CD variable to enable GitLab SAST.

This minimal YAML file includes the [stable SAST template](_index.md#stable-vs-latest-sast-templates) and enables GitLab Advanced SAST:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
```

#### Enforce it in a Scan Execution Policy

To enable GitLab Advanced SAST in a [Scan Execution Policy](../policies/scan_execution_policies.md), update your policy's scan action to set the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `true`.
You can set this variable by:

- Selecting it from the menu in the [policy editor](../policies/scan_execution_policies.md#scan-execution-policy-editor).
- Adding it to the [`variables` object](../policies/scan_execution_policies.md#scan-action-type) in the scan action.

#### By using the pipeline editor

To enable GitLab Advanced SAST by using the pipeline editor:

1. In your project, select **Build > Pipeline editor**.
1. If no `.gitlab-ci.yml` file exists, select **Configure pipeline**, then delete the example
   content.
1. Update the CI/CD configuration to:
   - Include one of the GitLab-managed [SAST CI/CD templates](_index.md#stable-vs-latest-sast-templates) if it is not [already included](_index.md#configure-sast-in-your-cicd-yaml).
       - In GitLab 17.3 or later, you should use the stable template, `Jobs/SAST.gitlab-ci.yml`.
       - In GitLab 17.2, GitLab Advanced SAST is only available in the latest template, `Jobs/SAST.latest.gitlab-ci.yml`. Note that you [should not mix latest and stable templates](../detect/roll_out_security_scanning.md#template-editions) in a single project.
       - In GitLab 17.1, you must manually copy the contents of the GitLab Advanced SAST job into your CI/CD pipeline definition.
   - Set the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `true`.

   See the [minimal YAML example above](#edit-the-cicd-pipeline-definition-manually).
1. Select the **Validate** tab, then select **Validate pipeline**.

   The message **Simulation completed successfully** confirms the file is valid.
1. Select the **Edit** tab.
1. Complete the fields. Do not use the default branch for the **Branch** field.
1. Select the **Start a new merge request with these changes** checkbox, then select **Commit
   changes**.
1. Complete the fields according to your standard workflow, then select **Create
   merge request**.
1. Review and edit the merge request according to your standard workflow, then select **Merge**.

Pipelines now include a GitLab Advanced SAST job.

### Disable GitLab Advanced SAST scanning

Advanced SAST scanning is not enabled by default, but it may be enabled at the group level or in another way that affects multiple projects.

To explicitly disable Advanced SAST scanning in a project, set the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `false`.
You can set this variable anywhere you can configure CI/CD variables, including the same ways you can [enable Advanced SAST scanning](#enable-gitlab-advanced-sast-scanning).

## Vulnerability code flow

> - Introduced in GitLab 17.3 [with several flags](../../../administration/feature_flags.md). Enabled by default.
> - Enabled on GitLab Self-Managed and GitLab Dedicated in GitLab 17.7.
> - Generally available in GitLab 17.7. All feature flags removed.

For specific types of vulnerabilities, GitLab Advanced SAST provides code flow information.
A vulnerability's code flow is the path the data takes from the user input (source) to the vulnerable line of code (sink), through all assignments, manipulation, and sanitization.
This information helps you understand and evaluate the vulnerability's context, impact, and risk.
Code flow information is available for vulnerabilities that are detected by tracing input from a source to a sink, including:

- SQL injection
- Command injection
- Cross-site scripting (XSS)
- Path traversal

The code flow information is shown the **Code flow** tab and includes:

- The steps from source to sink.
- The relevant files, including code snippets.

![A code flow of a Python application across two files](../vulnerabilities/img/code_flow_view_v17_7.png)

## Troubleshooting

If you encounter issues while using GitLab Advanced SAST, refer to the [troubleshooting guide](troubleshooting.md).

### Locate the GitLab Advanced SAST analyzer version

To locate the GitLab Advanced SAST analyzer version:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Jobs**.
1. Locate the `gitlab-advanced-sast` job.
1. In the output of the job, search for the string `GitLab GitLab Advanced SAST analyzer`.

You should find the version at the end of line with that string. For example:

```plaintext
[INFO] [GitLab Advanced SAST] [2025-01-24T15:51:03Z] ▶ GitLab GitLab Advanced SAST analyzer v1.1.1
```

In this example, the version is `1.1.1`.

## Customize GitLab Advanced SAST

You can disable GitLab Advanced SAST rules or edit their metadata, just as you can other analyzers.
For details, see [Customize rulesets](customize_rulesets.md#disable-predefined-gitlab-advanced-sast-rules).

## Request source code of LGPL-licensed components in GitLab Advanced SAST

To request information about the source code of LGPL-licensed components in GitLab Advanced SAST, please
[contact GitLab Support](https://about.gitlab.com/support/).

To ensure a quick response, include the GitLab Advanced SAST analyzer version in your request.

Because this feature is only available at the Ultimate tier, you must be associated with an organization with that level of support entitlement.

## Feedback

Feel free to add your feedback in the dedicated [issue 466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322).
