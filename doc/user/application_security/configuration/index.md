---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Security Configuration **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20711) in GitLab 12.6.
> - SAST configuration was [enabled](https://gitlab.com/groups/gitlab-org/-/epics/3659) in 13.3 and [improved](https://gitlab.com/gitlab-org/gitlab/-/issues/232862) in 13.4.
> - DAST Profiles feature was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40474) in 13.4.
> - A simplified version was made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/294076) in GitLab 13.10.
> - [Redesigned](https://gitlab.com/gitlab-org/gitlab/-/issues/326926) in 14.2.

The Security Configuration page lists the following for the security testing and compliance tools:

- Name, description, and a documentation link.
- Whether or not it is available.
- A configuration button or a link to its configuration guide.

The status of each security control is determined by the project's latest default branch
[CI pipeline](../../../ci/pipelines/index.md).
If a job with the expected security report artifact exists in the pipeline, the feature's status is
_enabled_.

If the latest pipeline used [Auto DevOps](../../../topics/autodevops/index.md),
all security features are configured by default.

To view a project's security configuration:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.

Select **Configuration history** to see the `.gitlab-ci.yml` file's history.

## Security testing

You can configure the following security controls:

- [Static Application Security Testing](../sast/index.md) (SAST)
  - Select **Enable SAST** to configure SAST for the current project.
    For more details, read [Configure SAST in the UI](../sast/index.md#configure-sast-in-the-ui).
- [Dynamic Application Security Testing](../dast/index.md) (DAST)
  - Select **Enable DAST** to configure DAST for the current project.
  - Select **Manage scans** to manage the saved DAST scans, site profiles, and scanner profiles.
    For more details, read [DAST on-demand scans](../dast/index.md#on-demand-scans).
- [Dependency Scanning](../dependency_scanning/index.md)
  - Select **Configure with a merge request** to create a merge request with the changes required to
    enable Dependency Scanning. For more details, see [Enable Dependency Scanning via an automatic merge request](../dependency_scanning/index.md#enable-dependency-scanning-via-an-automatic-merge-request).
- [Container Scanning](../container_scanning/index.md)
  - Can be configured with `.gitlab-ci.yml`. For more details, read [Container Scanning](../../../user/application_security/container_scanning/index.md#configuration).
- [Cluster Image Scanning](../cluster_image_scanning/index.md)
  - Can be configured with `.gitlab-ci.yml`. For more details, read [Cluster Image Scanning](../../../user/application_security/cluster_image_scanning/#configuration).
- [Secret Detection](../secret_detection/index.md)
  - Select **Configure with a merge request** to create a merge request with the changes required to
    enable Secret Detection. For more details, read [Enable Secret Detection via an automatic merge request](../secret_detection/index.md#enable-secret-detection-via-an-automatic-merge-request).
- [API Fuzzing](../api_fuzzing/index.md)
  - Select **Enable API Fuzzing** to use API Fuzzing for the current project. For more details, read [API Fuzzing](../../../user/application_security/api_fuzzing/index.md#enable-web-api-fuzzing).
- [Coverage Fuzzing](../coverage_fuzzing/index.md)
  - Can be configured with `.gitlab-ci.yml`. For more details, read [Coverage Fuzzing](../../../user/application_security/coverage_fuzzing/index.md#enable-coverage-guided-fuzz-testing).

## Compliance **(ULTIMATE)**

You can configure the following security controls:

- [License Compliance](../../../user/compliance/license_compliance/index.md)
  - Can be configured with `.gitlab-ci.yml`. For more details, read [License Compliance](../../../user/compliance/license_compliance/index.md#enable-license-compliance).
