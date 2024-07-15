---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Advanced SAST analyzer

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Beta

> - Introduced in GitLab 17.1 as an [experiment](../../../policy/experiment-beta-support.md) for Python.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461859) to beta in GitLab 17.2.

NOTE:
This analyzer is in [beta](../../../policy/experiment-beta-support.md)
and is subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

GitLab Advanced SAST is a Static Application Security Testing (SAST) analyzer
designed to discover vulnerabilities by performing cross-function and cross-file taint analysis.

During the Beta phase, we advise running it side-by-side with your existing SAST analyzer, if any.

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
1. If there is already an include of `Jobs/SAST.latest.gitlab-ci.yml`,
GitLab Advanced SAST is already configured.
There is no additional step needed.
1. If there is already an `include:` line, add `- template: Jobs/SAST.gitlab-ci.yml`
   below that line then paste only the `gitlab-advanced-sast:` block to the bottom of the file,
   otherwise paste the whole block to the bottom of the file.

   ```yaml
   include:
     - template: Jobs/SAST.gitlab-ci.yml

   gitlab-advanced-sast:
     extends: .sast-analyzer
     image:
       name: "$SAST_ANALYZER_IMAGE"
     variables:
       SEARCH_MAX_DEPTH: 20
       SAST_ANALYZER_IMAGE_TAG: 0
       SAST_ANALYZER_IMAGE: "$SECURE_ANALYZERS_PREFIX/gitlab-advanced-sast:$SAST_ANALYZER_IMAGE_TAG$SAST_IMAGE_SUFFIX"
     rules:
       - if: $SAST_DISABLED == 'true' || $SAST_DISABLED == '1'
         when: never
       - if: $SAST_EXCLUDED_ANALYZERS =~ /gitlab-advanced-sast/
         when: never
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"  # Add the job to merge request pipelines if there's an open merge request.
         exists:
           - '**/*.py'
           - '**/*.go'
           - '**/*.java'
       - if: $CI_OPEN_MERGE_REQUESTS  # Don't add it to a *branch* pipeline if it's already in a merge request pipeline.
         when: never
       - if: $CI_COMMIT_BRANCH        # If there's no open merge request, add it to a *branch* pipeline instead.
         exists:
           - '**/*.py'
           - '**/*.go'
           - '**/*.java'
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
