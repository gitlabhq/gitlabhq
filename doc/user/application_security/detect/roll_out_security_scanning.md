---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Roll out security scanning
---

You can roll out security scanning to individual projects, subgroups, and groups. You should start
with individual projects, then increase the scope in increments. An incremental roll out allows you
to evaluate the results at each point and adjust as needed.

To enable security scanning of individual projects:

- Enable individual security scanners.
- Enable all security scanners by using AutoDevOps.

To enable security scanning of multiple projects, subgroups, or groups:

- Use a scan execution policy to enforce all or a subset of security scanners.

## Enable individual security scanners

To enable individual security scanning tools with the option of customizing settings, add the
GitLab CI/CD [templates](#template-editions) to your `.gitlab-ci.yml` file.

For instructions on how to enable individual security scanners, see their documentation.

## Enable security scanning by using Auto DevOps

To enable the following security scanning tools, with default settings, enable
[Auto DevOps](../../../topics/autodevops/_index.md):

- [Auto SAST](../../../topics/autodevops/stages.md#auto-sast)
- [Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection)
- [Auto DAST](../../../topics/autodevops/stages.md#auto-dast)
- [Auto Dependency Scanning](../../../topics/autodevops/stages.md#auto-dependency-scanning)
- [Auto Container Scanning](../../../topics/autodevops/stages.md#auto-container-scanning)

While you cannot directly customize Auto DevOps, you can [include the Auto DevOps template in your project's `.gitlab-ci.yml` file](../../../topics/autodevops/customize.md#customize-gitlab-ciyml).

## Customizing security scanners

The behavior of each security scanner can be customized by using the
[predefined CD/CD variables](../../../ci/variables/predefined_variables.md) and each scanner's own
CI/CD variables. See each scanner's documentation for details of the CI/CD variables available.

WARNING:
All customization of security scanning tools should be tested in a merge request before merging
these changes to the default branch. Failure to do so can give unexpected results, including a large
number of false positives.

### Template editions

Most of the GitLab application security tools have two template editions:

- **Stable:** The stable template is the default. It offers a reliable and consistent application
  security experience. You should use the stable template for most users and projects that require
  stability and predictable behavior in their CI/CD pipelines.
- **Latest:** The latest template is for those who want to access and test cutting-edge features. It
  is identified by the word `latest` in the template's name. It is not considered stable and may
  include breaking changes that are planned for the next major release. This template allows you to
  try new features and updates before they become part of the stable release.

NOTE:
Mixing different security template editions can cause both merge request and branch pipelines to
run. You should use **either** the stable or latest edition templates in a project.

### Override the default registry base address

By default, GitLab security scanners use `registry.gitlab.com/security-products` as the
base address for Docker images. You can override this for most scanners by setting the CI/CD variable
`SECURE_ANALYZERS_PREFIX` to another location. This affects all scanners at once.

The [Container Scanning](../container_scanning/_index.md) analyzer is an exception, and it
does not use the `SECURE_ANALYZERS_PREFIX` variable. To override its Docker image, see
the instructions for
[Running container scanning in an offline environment](../container_scanning/_index.md#running-container-scanning-in-an-offline-environment).

### Use security scanning tools with merge request pipelines

By default, the application security jobs are configured to run for branch pipelines only.
To use them with [merge request pipelines](../../../ci/pipelines/merge_request_pipelines.md),
you must reference their [`latest` edition template](#template-editions).

For example, to run both SAST and Dependency Scanning, the following template is used:

```yaml
include:
  - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  - template: Jobs/SAST.latest.gitlab-ci.yml
```

### Use a custom scanning stage

When security scanning is enabled by [enabling individual security scanners](#enable-individual-security-scanners),
the scanning jobs use the predefined `test` stage by default. If you specify a custom stage in your
`.gitlab-ci.yml` file without including a `test` stage, an error occurs.

For example, the following attempts to use a `unit-tests` stage:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
  - template: Jobs/SAST.gitlab-ci.yml
  - template: Jobs/Secret-Detection.gitlab-ci.yml

stages:
  - unit-tests

custom job:
  stage: unit-tests
  script:
    - echo "custom job"
```

The above `.gitlab-ci.yml` causes a linting error:

```plaintext
Unable to create pipeline
- dependency_scanning job: chosen stage test does not exist; available stages are .pre
- unit-tests
- .post
```

This error appears because the `test` stage used by the security scanning jobs isn't declared in the `.gitlab-ci.yml` file.
To fix this issue, you can either:

- Add a `test` stage in your `.gitlab-ci.yml`:

  ```yaml
  include:
    - template: Jobs/Dependency-Scanning.gitlab-ci.yml
    - template: Jobs/SAST.gitlab-ci.yml
    - template: Jobs/Secret-Detection.gitlab-ci.yml

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
    - template: Jobs/Dependency-Scanning.gitlab-ci.yml
    - template: Jobs/SAST.gitlab-ci.yml
    - template: Jobs/Secret-Detection.gitlab-ci.yml

  stages:
    - unit-tests

  dependency_scanning:
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

For more information about overriding security jobs, see:

- [Overriding SAST jobs](../sast/_index.md#overriding-sast-jobs).
- [Overriding Dependency Scanning jobs](../dependency_scanning/_index.md#overriding-dependency-scanning-jobs).
- [Overriding Container Scanning jobs](../container_scanning/_index.md#overriding-the-container-scanning-template).
- [Overriding Secret Detection jobs](../secret_detection/pipeline/_index.md#configuration).
- [Overriding DAST jobs](../dast/browser/_index.md).

All the security scanning tools define their stage, so this error can occur with all of them.
