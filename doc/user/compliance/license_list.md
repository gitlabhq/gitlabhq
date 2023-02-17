---
type: reference, howto
stage: Govern
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# License list **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13582) in GitLab 12.7.

The License list allows you to see your project's licenses and key
details about them.

For the licenses to appear under the license list, the following
requirements must be met:

1. You must be generating an SBOM file with components from one of our [one of our supported languages](license_scanning_of_cyclonedx_files/index.md#supported-languages-and-package-managers).
1. If using our [`Dependency-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/License-Scanning.gitlab-ci.yml) to generate the SBOM file, then your project must use at least one of the [supported languages and package managers](license_compliance/index.md#supported-languages-and-package-managers).

Alternatively, licenses will also appear under the license list when using our deprecated [`License-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/License-Scanning.gitlab-ci.yml) as long as the following requirements are met:

1. The License Compliance CI/CD job must be [enabled](license_compliance/index.md#enable-license-compliance) for your project.
1. Your project must use at least one of the
   [supported languages and package managers](license_compliance/index.md#supported-languages-and-package-managers).

When everything is configured, on the left sidebar, select **Security & Compliance > License Compliance**.

The licenses are displayed, where:

- **Name:** The name of the license.
- **Component:** The components which have this license.
- **Policy Violation:** The license has a [license policy](license_approval_policies.md) marked as **Deny**.

![License List](img/license_list_v13_0.png)
