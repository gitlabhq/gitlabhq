---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security configuration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The **Security configuration** page lists the following for the security testing and compliance tools:

- Name, description, and a documentation link.
- Whether or not it is available.
- A configuration button or a link to its configuration guide.

To determine the status of each security control, GitLab checks for a [CI/CD pipeline](../../../ci/pipelines/_index.md)
in the most recent commit on the default branch.

If GitLab finds a CI/CD pipeline, then it inspects each job in the `.gitlab-ci.yml` file.

- If a job defines an [`artifacts:reports` keyword](../../../ci/yaml/artifacts_reports.md)
  for a security scanner, then GitLab considers the security scanner enabled and shows the **Enabled** status.
- If no jobs define an `artifacts:reports` keyword for a security scanner, then GitLab considers
  the security scanner disabled and shows the **Not enabled** status.

If GitLab does not find a CI/CD pipeline, then it considers all security scanners disabled and shows the **Not enabled** status.

Failed pipelines and jobs are included in this process. If a scanner is configured but the job fails,
that scanner is still considered enabled. This process also determines the scanners and statuses
returned through the [API](../../../api/graphql/reference/_index.md#securityscanners).

If the latest pipeline uses [Auto DevOps](../../../topics/autodevops/_index.md),
all security features are configured by default.

To view a project's security configuration:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.

Select **Configuration history** to see the `.gitlab-ci.yml` file's history.

## Security testing

You can configure the following security controls:

- [Static Application Security Testing](../sast/_index.md) (SAST)
  - Select **Enable SAST** to configure SAST for the current project.
    For more details, read [Configure SAST in the UI](../sast/_index.md#configure-sast-by-using-the-ui).
- [Dynamic Application Security Testing](../dast/_index.md) (DAST)
  - Select **Enable DAST** to configure DAST for the current project.
  - Select **Manage scans** to manage the saved DAST scans, site profiles, and scanner profiles.
    For more details, read [DAST on-demand scans](../dast/on-demand_scan.md).
- [Dependency Scanning](../dependency_scanning/_index.md)
  - Select **Configure with a merge request** to create a merge request with the changes required to
    enable Dependency Scanning. For more information, see [Use a preconfigured merge request](../dependency_scanning/_index.md#use-a-preconfigured-merge-request).
- [Container Scanning](../container_scanning/_index.md)
  - Select **Configure with a merge request** to create a merge request with the changes required to
    enable Container Scanning. For more details, see
    [Enable Container Scanning through an automatic merge request](../container_scanning/_index.md#use-a-preconfigured-merge-request).
- [Container Scanning For Registry](../container_scanning/_index.md#container-scanning-for-registry)
  - Enable toggle to configure **Container Scanning For Registry** for the current project.
- [Operational Container Scanning](../../clusters/agent/vulnerabilities.md)
  - Can be configured by adding a configuration block to your agent configuration. For more details, read [Operational Container Scanning](../../clusters/agent/vulnerabilities.md#enable-operational-container-scanning).
- [Secret Detection](../secret_detection/pipeline/_index.md)
  - Select **Configure with a merge request** to create a merge request with the changes required to
    enable Secret Detection. For more details, read [Use an automatically configured merge request](../secret_detection/pipeline/_index.md#use-an-automatically-configured-merge-request).
- [API Fuzzing](../api_fuzzing/_index.md)
  - Select **Enable API Fuzzing** to use API Fuzzing for the current project. For more details, read [API Fuzzing](../api_fuzzing/configuration/enabling_the_analyzer.md).
- [Coverage Fuzzing](../coverage_fuzzing/_index.md)
  - Can be configured with `.gitlab-ci.yml`. For more details, read [Coverage Fuzzing](../coverage_fuzzing/_index.md#enable-coverage-guided-fuzz-testing).

## Compliance

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can configure the following security controls:

- [Security Training](../vulnerabilities/_index.md#enable-security-training-for-vulnerabilities)
  - Enable **Security training** for the current project. For more details, read [security training](../vulnerabilities/_index.md#enable-security-training-for-vulnerabilities).
