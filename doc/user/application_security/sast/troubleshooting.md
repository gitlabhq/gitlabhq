---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting SAST
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The following troubleshooting scenarios have been collected from customer support cases. If you
experience a problem not addressed here, or the information here does not fix your problem, see the
[GitLab Support](https://about.gitlab.com/support/) page for ways to get help.

## Debug-level logging

Debug-level logging can help when troubleshooting. For details, see
[debug-level logging](../troubleshooting_application_security.md#debug-level-logging).

## Changes in the CI/CD template

The [GitLab-managed SAST CI/CD template](_index.md#configure-sast-in-your-cicd-yaml) controls which [analyzer](analyzers.md) jobs run and how they're configured. While using the template, you might experience a job failure or other pipeline error. For example, you might:

- See an error message like `'<your job>' needs 'spotbugs-sast' job, but 'spotbugs-sast' is not in any previous stage` when you view an affected pipeline.
- Experience another type of unexpected issue with your CI/CD pipeline configuration.

If you're experiencing a job failure or seeing a SAST-related `yaml invalid` pipeline status, you can temporarily revert to an older version of the template so your pipelines keep working while you investigate the issue. To use an older version of the template, change the existing `include` statement in your CI/CD YAML file to refer to a specific template version, such as `v15.3.3-ee`:

```yaml
include:
  remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/v15.3.3-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml'
```

If your GitLab instance has limited network connectivity, you can also download the file and host it elsewhere.

You should only use this solution temporarily, returning to [the standard template](_index.md#configure-sast-in-your-cicd-yaml) as soon as possible.

## Errors in a specific analyzer job

GitLab SAST [analyzers](analyzers.md) are released as container images.
If you're seeing a new error that doesn't appear to be related to [the GitLab-managed SAST CI/CD template](_index.md#configure-sast-in-your-cicd-yaml) or changes in your own project, you can try [pinning the affected analyzer to a specific older version](_index.md#pinning-to-minor-image-version).

Each [analyzer project](analyzers.md) has a `CHANGELOG.md` file listing the changes made in each available version.

## Job log messages

The SAST job's log may include error messages that help pinpoint the root cause. Below are some
of the error messages and recommended actions.

### Executable format

```plaintext
exec /bin/sh: exec format error` message in job log
```

GitLab SAST analyzers [only support](_index.md#requirements) running on the `amd64` CPU architecture.
This message indicates that the job is being run on a different architecture, such as `arm`.

### Docker error

```plaintext
Error response from daemon: error processing tar file: docker-tar: relocation error
```

This error occurs when the Docker version that runs the SAST job is `19.03.0`. Consider updating to
Docker `19.03.1` or greater. Older versions are not affected. For more details, see
[issue 13830](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992) -
"Current SAST container fails".

### No matching files

```plaintext
gl-sast-report.json: no matching files
```

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

### Configuration only

```plaintext
sast is used for configuration only, and its script should not be executed
```

For information on this, see the [GitLab Secure troubleshooting section](../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

## SAST jobs run unexpectedly

The [SAST CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
uses the `rules:exists` parameter. For performance reasons, a maximum number of 10000 matches are
made against the given glob pattern. If the number of matches exceeds the maximum, the `rules:exists`
parameter returns `true`. Depending on the number of files in your repository, a SAST job might be
triggered even if the scanner doesn't support your project. For more details about this limitation,
see the [`rules:exists` documentation](../../../ci/yaml/_index.md#rulesexists).

## SpotBugs errors

Below are details of the most common SpotBugs errors that occur, and recommended actions.

### UTF-8 unmappable character errors

These errors occur when UTF-8 encoding isn't enabled on a SpotBugs build and there are UTF-8
characters in the source code. To fix this error, enable UTF-8 for your project's build tool.

For Gradle builds, add the following to your `build.gradle` file:

```groovy
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

### Project couldn't be built

If your `spotbugs-sast` job is failing at the build step with the message "Project couldn't be built", it's most likely because:

- Your project is asking SpotBugs to build with a tool that isn't part of its default tools. For a list of the SpotBugs default tools, see [SpotBugs' asdf dependencies](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/config/.gl-tool-versions).
- Your build needs custom configurations or additional dependencies that the analyzer's automatic build process can't accommodate.

The SpotBugs-based analyzer is only used for scanning Groovy code, but it may trigger in other cases, such as [when all SAST jobs run unexpectedly](#sast-jobs-run-unexpectedly).

The solution depends on whether you need to scan Groovy code:

- If you don't have any Groovy code, or don't need to scan it, you should [disable the SpotBugs analyzer](analyzers.md#disable-specific-default-analyzers).
- If you do need to scan Groovy code, you should use [pre-compilation](_index.md#pre-compilation).
  Pre-compilation avoids these failures by scanning an artifact you've already built in your pipeline, rather than trying to compile it in the `spotbugs-sast` job.

### Java out of memory error

When a `spotbugs-sast` job is running you might get an error that states `java.lang.OutOfMemoryError`. This issue occurs when Java has run out of memory while scanning.

To try to resolve this issue you can:

- Choose a lower [level of effort](_index.md#security-scanner-configuration).
- Set the CI/CD variable `JAVA_OPTS` to replace the default `-XX:MaxRAMPercentage=80`, e.g. `-XX:MaxRAMPercentage=90`.
- [Tag a larger runner](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64) in your `spotbugs-sast` job.

#### Related topics

- [Overhauling memory tuning in OpenJDK containers updates](https://developers.redhat.com/articles/2023/03/07/overhauling-memory-tuning-openjdk-containers-updates)
- [OpenJDK Configuration & Tuning](https://wiki.openjdk.org/display/zgc/Main#Main-Configuration&Tuning)
- [Garbage First Garbage Collector Tuning](https://www.oracle.com/technical-resources/articles/java/g1gc.html)

### Exception analyzing

If your job log contains a message of the form "Exception analyzing ... using detector ..." followed by a Java stack trace, this is **not** a failure of the SAST pipeline. SpotBugs has determined that the exception is [recoverable](https://github.com/spotbugs/spotbugs/blob/5ebd4439f6f8f2c11246b79f58c44324718d39d8/spotbugs/src/main/java/edu/umd/cs/findbugs/FindBugs2.java#L1200), logged it, and resumed analysis.

The first "..." part of the message is the class being analyzed - if it's not part of your project, you can likely ignore the message and the stack trace that follows.

If, on the other hand, the class being analyzed is part of your project, consider creating an issue with the SpotBugs project on [GitHub](https://github.com/spotbugs/spotbugs/issues).

## Flawfinder encoding error

This occurs when Flawfinder encounters an invalid UTF-8 character. To fix this, apply [their documented advice](https://github.com/david-a-wheeler/flawfinder#character-encoding-errors) to your entire repository, or only per job using the [`before_script`](../../../ci/yaml/_index.md#before_script) feature.

You can configure the `before_script` section in each `.gitlab-ci.yml` file, or use a [pipeline execution policy](../policies/pipeline_execution_policies.md) to install the encoder and run the converter command. For example, you can add a `before_script` section to the `flawfinder-sast` job generated from the security scanner template to convert all files with a `.cpp` extension.

### Example pipeline execution policy YAML

```yaml
---
pipeline_execution_policy:
- name: SAST
  description: 'Run SAST on C++ application'
  enabled: true
  pipeline_config_strategy: inject_ci
  content:
    include:
    - project: my-group/compliance-project
      file: flawfinder.yml
      ref: main
```

`flawfinder.yml`:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

flawfinder-sast:
  before_script:
    - pip install cvt2utf
    - cvt2utf convert "$PWD" -i cpp
```

## Semgrep slowness, unexpected results, or other errors

If Semgrep is slow, reports too many false positives or false negatives, crashes, fails, or is otherwise broken, see the Semgrep docs for [troubleshooting GitLab SAST](https://semgrep.dev/docs/troubleshooting/semgrep-app#troubleshooting-gitlab-sast).

## Slow scans or timeouts with Advanced SAST

Because [Advanced SAST](gitlab_advanced_sast.md) scans your program in detail, scans can sometimes take a long time to complete, especially for large repositories. If you're experiencing performance issues, consider following the recommendations here.

### Reduce scan time by excluding files

Because each file is analyzed against all applicable rules, you can reduce the number of files scanned to decrease scan time. To do this, use the [SAST_EXCLUDED_PATHS](_index.md#vulnerability-filters) variable to exclude folders that do not need to be scanned.

### Optimize scans with multi-core scanning

Multi-core scanning is enabled by default in the Advanced SAST (analyzer version v1.1.10 and later). You can increase the runner size to make more resources available for scanning. For self-hosted runners, you may need to customize the `--multi-core` flag in the [security scanner configuration](_index.md#security-scanner-configuration).

### When to seek support

If you've followed these optimization steps and your Advanced SAST scan is still running longer than expected, reach out to GitLab Support for further assistance with the following information:

- Programming language used in your repository
- [Debug logs](../troubleshooting_application_security.md#debug-level-logging)
- [Performance debugging artifact](#generate-a-performance-debugging-artifact)

#### Generate a performance debugging artifact

To generate the `trace.ctf` artifact, add the following to your `.gitlab-ci.yml`.
Be sure to set `RUNNER_SCRIPT_TIMEOUT` to at least 10 minutes shorter than `timeout` to ensure the artifact has time to upload.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
  MEMTRACE: 'trace.ctf'
  DISABLE_MULTI_CORE: true # Disable multi core when collecting memtrace

gitlab-advanced-sast:
  artifacts:
    paths:
      - '**/trace.ctf'  # Collects all trace.ctf files generated by this job
    expire_in: 1 week   # Sets retention for artifacts
    when: always        # Ensures artifact export even if the job fails
  variables:
    RUNNER_SCRIPT_TIMEOUT: 50m
  timeout: 1h
```
