---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting SAST **(FREE ALL)**

## Debug-level logging

Debug-level logging can help when troubleshooting. For details, see
[debug-level logging](../index.md#debug-level-logging).

## Pipeline errors related to changes in the GitLab-managed CI/CD template

The [GitLab-managed SAST CI/CD template](index.md#configure-sast-in-your-cicd-yaml) controls which [analyzer](analyzers.md) jobs run and how they're configured. While using the template, you might experience a job failure or other pipeline error. For example, you might:

- See an error message like `'<your job>' needs 'spotbugs-sast' job, but 'spotbugs-sast' is not in any previous stage` when you view an affected pipeline.
- Experience another type of unexpected issue with your CI/CD pipeline configuration.

If you're experiencing a job failure or seeing a SAST-related `yaml invalid` pipeline status, you can temporarily revert to an older version of the template so your pipelines keep working while you investigate the issue. To use an older version of the template, change the existing `include` statement in your CI/CD YAML file to refer to a specific template version, such as `v15.3.3-ee`:

```yaml
include:
  remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/v15.3.3-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml'
```

If your GitLab instance has limited network connectivity, you can also download the file and host it elsewhere.

We recommend that you only use this solution temporarily and that you return to [the standard template](index.md#configure-sast-in-your-cicd-yaml) as soon as possible.

## Errors in a specific analyzer job

GitLab SAST [analyzers](analyzers.md) are released as container images.
If you're seeing a new error that doesn't appear to be related to [the GitLab-managed SAST CI/CD template](index.md#configure-sast-in-your-cicd-yaml) or changes in your own project, you can try [pinning the affected analyzer to a specific older version](index.md#pinning-to-minor-image-version).

Each [analyzer project](analyzers.md#sast-analyzers) has a `CHANGELOG.md` file listing the changes made in each available version.

## `exec /bin/sh: exec format error` message in job log

GitLab SAST analyzers [only support](index.md#requirements) running on the `amd64` CPU architecture.
This message indicates that the job is being run on a different architecture, such as `arm`.

## `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the SAST job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

## Getting warning message `gl-sast-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

## Error: `sast is used for configuration only, and its script should not be executed`

For information on this, see the [GitLab Secure troubleshooting section](../index.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

## SAST jobs are running unexpectedly

The [SAST CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
uses the `rules:exists` parameter. For performance reasons, a maximum number of 10000 matches are
made against the given glob pattern. If the number of matches exceeds the maximum, the `rules:exists`
parameter returns `true`. Depending on the number of files in your repository, a SAST job might be
triggered even if the scanner doesn't support your project. For more details about this limitation,
see the [`rules:exists` documentation](../../../ci/yaml/index.md#rulesexists).

## SpotBugs UTF-8 unmappable character errors

These errors occur when UTF-8 encoding isn't enabled on a SpotBugs build and there are UTF-8
characters in the source code. To fix this error, enable UTF-8 for your project's build tool.

For Gradle builds, add the following to your `build.gradle` file:

```gradle
compileJava.options.encoding = 'UTF-8'
tasks.withType(JavaCompile) {
    options.encoding = 'UTF-8'
}
```

For Maven builds, add the following to your `pom.xml` file:

```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

## SpotBugs Error: `Project couldn't be built`

If your job is failing at the build step with the message "Project couldn't be built", it's most likely because your job is asking SpotBugs to build with a tool that isn't part of its default tools. For a list of the SpotBugs default tools, see [SpotBugs' asdf dependencies](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/raw/master/config/.tool-versions).

The solution is to use [pre-compilation](index.md#pre-compilation). Pre-compilation ensures the images required by SpotBugs are available in the job's container.

## Flawfinder encoding error

This occurs when Flawfinder encounters an invalid UTF-8 character. To fix this, convert all source code in your project to UTF-8 character encoding. This can be done with [`cvt2utf`](https://github.com/x1angli/cvt2utf) or [`iconv`](https://www.gnu.org/software/libiconv/documentation/libiconv-1.13/iconv.1.html) either over the entire project or per job using the [`before_script`](../../../ci/yaml/index.md#before_script) feature.

## Semgrep slowness, unexpected results, or other errors

If Semgrep is slow, reports too many false positives or false negatives, crashes, fails, or is otherwise broken, see the Semgrep docs for [troubleshooting GitLab SAST](https://semgrep.dev/docs/troubleshooting/semgrep-ci/#troubleshooting-gitlab-sast).
