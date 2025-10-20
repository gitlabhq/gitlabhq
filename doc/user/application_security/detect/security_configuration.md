---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security configuration
description: Configuration, testing, compliance, scanning, and enablement.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can configure security scanners for projects individually or create a scanner configuration
shared by multiple projects. Configuring each project manually gives you maximum flexibility but
becomes difficult to maintain at scale. For multiple projects or groups, shared scanner
configuration provides easier management while still allowing some customization where needed.

For example, if you have 10 projects with the same security scanning configuration applied manually,
a single change must be made 10 times. If instead you create a shared CI/CD configuration, the
single change only needs to be made once.

## Configure an individual project

To configure security scanning in an individual project, either:

- Edit the CI/CD configuration file.
- Edit the CI/CD configuration in the UI.

### With a CI/CD file

To manually enable security scanning of individual projects, either:

- Enable individual security scanners.
- Enable all security scanners by using AutoDevOps.

AutoDevOps provides a least-effort path to enabling most of the security scanners. However,
customization options are limited, compared with enabling individual security scanners.

#### Enable individual security scanners

To enable individual security scanning tools with the option of customizing settings, include the
security scanner's templates to your `.gitlab-ci.yml` file.

For instructions on how to enable individual security scanners, see their documentation.

#### Enable security scanning by using Auto DevOps

To enable the following security scanning tools, with default settings, enable
[Auto DevOps](../../../topics/autodevops/_index.md):

- [Auto SAST](../../../topics/autodevops/stages.md#auto-sast)
- [Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection)
- [Auto DAST](../../../topics/autodevops/stages.md#auto-dast)
- [Auto Dependency Scanning](../../../topics/autodevops/stages.md#auto-dependency-scanning)
- [Auto container scanning](../../../topics/autodevops/stages.md#auto-container-scanning)

While you cannot directly customize Auto DevOps, you can
[include the Auto DevOps template in your project's `.gitlab-ci.yml` file](../../../topics/autodevops/customize.md#customize-gitlab-ciyml)
and override its settings as required.

### With the UI

Use the **Security configuration** page to view and configure the security testing and vulnerability
management settings of a project.

The **Security testing** tab reflects the status of each of the security tools by checking the
CI/CD pipeline in the most recent commit on the default branch.

Enabled
: The security testing tool's artifact was found in the pipeline's output.

Not enabled
: Either no CI/CD pipeline exists or the security testing tool's artifact was not found in the
  pipeline's output.

#### View security configuration page

To view a project's security configuration:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure** > **Security configuration**.

To see a historic view of changes to the CI/CD configuration file, select **Configuration history**.

#### Edit a project's security configuration

To edit a project's security configuration:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure** > **Security configuration**.
1. Select the security scanner you want to enable or configure and follow the instructions.

For more details on how to enable and configure individual security scanners, see their
documentation.

## Create a shared configuration

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To apply the same security scanning configuration to multiple projects, use one of the following
methods:

- [Scan execution policy](../policies/scan_execution_policies.md)
- [Pipeline execution policy](../policies/pipeline_execution_policies.md)

Each of these methods allow a CI/CD configuration, including security scanning, to be defined once
and applied to multiple projects and groups. These methods have several advantages over configuring
each project individually, including:

- Configuration changes only have to be made once instead of for each project.
- Permission to make configuration changes is restricted, providing separation of duties.

## Customize security scanning

You can customize security scanning to suit your requirements and environment. For details of how
to customize individual security scanners, refer to their documentation.

### Best practices

When customizing the security scanning configuration:

- Test all customization of security scanning tools by using a merge request before merging changes
  to the default branch. Failure to do so can give unexpected results, including a large number of
  false positives.
- [Include](../../../ci/yaml/_index.md#include) the scanning tool's CI/CD template. Don't copy the
  content of the template.
- Override values in the template only as needed. All other values are inherited from the template.
- Use the stable edition of each template for production workflows. The stable edition changes less
  often, and breaking changes are only made between major GitLab versions. The latest version
  contains the most recent changes, but may have significant changes between minor GitLab versions.

### Template editions

GitLab application security tools have up to two template editions:

- **Stable**: The stable template is the default. It offers a reliable and consistent application
  security experience. You should use the stable template for most users and projects that require
  stability and predictable behavior in their CI/CD pipelines.
- **Latest**: The latest template is for those who want to access and test cutting-edge features. It
  is identified by the word `latest` in the template's name. It is not considered stable and may
  include breaking changes that are planned for the next major release. This template allows you to
  try new features and updates before they become part of the stable release.

{{< alert type="note" >}}

Don't mix security templates in the same project. Mixing different security template editions can
cause both merge request and branch pipelines to run.

{{< /alert >}}

### Override the default registry base address

By default, GitLab security scanners use `registry.gitlab.com/security-products` as the
base address for Docker images. You can override this for most scanners by setting the CI/CD variable
`SECURE_ANALYZERS_PREFIX` to another location. This affects all scanners at once.

The [container scanning](../container_scanning/_index.md) analyzer is an exception, and it
does not use the `SECURE_ANALYZERS_PREFIX` variable. To override its Docker image, see
the instructions for
[Running container scanning in an offline environment](../container_scanning/_index.md#running-container-scanning-in-an-offline-environment).

### Use security scanning tools with merge request pipelines

By default, the application security jobs are configured to run for branch pipelines only.
To use them with [merge request pipelines](../../../ci/pipelines/merge_request_pipelines.md),
either:

- Set the CI/CD variable `AST_ENABLE_MR_PIPELINES` to `"true"` ([introduced in 18.0](https://gitlab.com/gitlab-org/gitlab/-/issues/410880)) (Recommended)
- Use the [`latest` edition template](#template-editions) which enables merge request pipelines by default.

For example, to run both SAST and Dependency Scanning with merge request pipelines enabled, the following configuration is used:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  AST_ENABLE_MR_PIPELINES: "true"
```

### Use a custom scanning stage

Security scanner templates use the predefined `test` stage by default. To have them instead run in
a different stage, add the custom stage's name to the `stages:` section of the `.gitlab-ci.yml`
file.

For more information about overriding security jobs, see:

- [Overriding SAST jobs](../sast/_index.md#overriding-sast-jobs).
- [Overriding Dependency Scanning jobs](../dependency_scanning/_index.md#overriding-dependency-scanning-jobs).
- [Overriding container scanning jobs](../container_scanning/_index.md#overriding-the-container-scanning-template).
- [Overriding Secret Detection jobs](../secret_detection/pipeline/configure.md).
- [Overriding DAST jobs](../dast/browser/_index.md).

## Troubleshooting

When configuring security scanning you might encounter the following issues.

### Error: `chosen stage test does not exist`

When running a pipeline you might get an error that states `chosen stage test does not exist`.

This issue occurs when the stage used by the security scanning jobs isn't declared in the `.gitlab-ci.yml` file.

To resolve this, either:

- Add a `test` stage in your `.gitlab-ci.yml`:

  ```yaml
  stages:
    - test
    - unit-tests

  include:
    - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    - template: Jobs/SAST.gitlab-ci.yml
    - template: Jobs/Secret-Detection.gitlab-ci.yml

  custom job:
    stage: unit-tests
    script:
      - echo "custom job"
  ```

- Override the default stage of each security job. For example, to use a pre-defined stage named `unit-tests`:

  ```yaml
  stages:
    - unit-tests

  include:
    - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
      inputs:
        stage: unit-tests
    - template: Jobs/SAST.gitlab-ci.yml
    - template: Jobs/Secret-Detection.gitlab-ci.yml

  sast:
    stage: unit-tests

  .secret-analyzer:
    stage: unit-tests

  custom job:
    stage: unit-tests
    script:
      - echo "custom job"
  ```
