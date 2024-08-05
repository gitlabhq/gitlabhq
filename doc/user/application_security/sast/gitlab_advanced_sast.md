---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Advanced SAST analyzer

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Introduced in GitLab 17.1 as an [experiment](../../../policy/experiment-beta-support.md) for Python.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461859) to beta in GitLab 17.2.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/474094) to GA in GitLab 17.3.

GitLab Advanced SAST is a Static Application Security Testing (SAST) analyzer
designed to discover vulnerabilities by performing cross-function and cross-file taint analysis.

GitLab Advanced SAST is an opt-in feature.
When it is enabled, the GitLab Advanced SAST analyzer scans all the files of the supported languages,
using the GitLab Advanced SAST predefined ruleset.
The Semgrep analyzer will not scan these files.

All vulnerabilities identified by the GitLab Advanced SAST analyzer will be reported,
including vulnerabilities previously reported by the Semgrep analyzer.
An automated transition process is proposed for the future,
in which the Vulnerability Management system will automatically de-duplicate findings
that were identified by both the GitLab Advanced SAST analyzer and the Semgrep analyzer.
It's proposed that the capability will be based on the advanced tracking algorithm
and will keep the original record of the vulnerability
(if it was first identified by Semgrep, then the Semgrep finding).

NOTE:
In case a duplicated vulnerability was already introduced (in the interim time until the deduplication is available),the deduplication capability will not deduplicate it. The capability will be relevant only for validating new vulnerabilities that are not already duplicated.

By following the paths user inputs take, the analyzer identifies potential points
where untrusted data can influence the execution of your application in unsafe ways,
ensuring that injection vulnerabilities, such as SQL injection and cross-site scripting (XSS),
are detected even when they span multiple functions and files.

GitLab Advanced SAST includes the following features:

- Source detection: Usually user input that can be tweaked by a malicious entity.
- Sink detection: Sensitive function calls, whose arguments should not be controlled by the user.
- Cross-function analysis: Tracks data flow through different functions to detect vulnerabilities that span multiple functions.
- Cross-file analysis: Tracks data flow across different files, discovering vulnerabilities at a deeper level.
- Sanitizer detection: Avoid false positive results in case the user input is properly sanitized.

## Supported languages

GitLab Advanced SAST supports the following languages with cross-function and cross-file taint analysis:

- Python
- Go
- Java
- JavaScript
- C#

## Configuration

Enable the Advanced SAST analyzer to discover vulnerabilities in your application by performing
cross-function and cross-file taint analysis. You can then adjust its behavior by using CI/CD
variables.

### Enabling the analyzer

Prerequisites:

- GitLab version 17.1 or later, if you are running a self-managed instance. (GitLab.com is ready to use.)
- The `.gitlab-ci.yml` file must include:
  - The `test` stage.

To enable the Advanced SAST analyzer:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. If no `.gitlab-ci.yml` file exists, select **Configure pipeline**, then delete the example
   content.
1. Include a SAST template (if not already done), either `Jobs/SAST.gitlab-ci.yml` or `Jobs/SAST.latest.gitlab-ci.yml`.
   **Note:** The `latest` templates can receive breaking changes in any release.
1. Set the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `true`.

Here is a minimal YAML file for enabling GitLab Advanced SAST:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
```

1. Select the **Validate** tab, then select **Validate pipeline**.

   The message **Simulation completed successfully** confirms the file is valid.
1. Select the **Edit** tab.
1. Complete the fields. Do not use the default branch for the **Branch** field.
1. Select the **Start a new merge request with these changes** checkbox, then select **Commit
   changes**.
1. Complete the fields according to your standard workflow, then select **Create
   merge request**.
1. Review and edit the merge request according to your standard workflow, then select **Merge**.

Pipelines now include an advanced SAST job.

## Troubleshooting

If you encounter issues while using GitLab Advanced SAST, refer to the [troubleshooting guide](troubleshooting.md).

## Feedback

Feel free to add your feedback in the dedicated [issue 466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322).
