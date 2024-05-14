---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
---

# Enabling the analyzer

To run a DAST scan:

- Read the [requirements](requirements.md) conditions for running a DAST scan.
- Create a [DAST job](#create-a-dast-cicd-job) in your CI/CD pipeline.
- [Authenticate](authentication.md) as a user if your application requires it.

## Create a DAST CI/CD job

> - This template was [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87183) to DAST_VERSION: 3 in GitLab 15.0.
> - This template was updated to DAST_VERSION: 4 in GitLab 16.0.

To add DAST scanning to your application, use the DAST job defined
in the GitLab DAST CI/CD template file. Updates to the template are provided with GitLab
upgrades, allowing you to benefit from any improvements and additions.

To create the CI/CD job:

1. Include the appropriate CI/CD template:

    - [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml):
      Stable version of the DAST CI/CD template.
    - [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml):
      Latest version of the DAST template.

   WARNING:
   The latest version of the template may include breaking changes. Use the
   stable template unless you need a feature provided only in the latest template.

   For more information about template versioning, see the
   [CI/CD documentation](../../../../../development/cicd/templates.md#latest-version).

1. Add a `dast` stage to your GitLab CI/CD stages configuration.

1. Define the URL to be scanned by DAST by using one of these methods:

    - Set the `DAST_TARGET_URL` [CI/CD variable](../../../../../ci/yaml/index.md#variables).
      If set, this value takes precedence.

    - Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
      dynamic environments. To run DAST against an application dynamically created during a GitLab CI/CD
      pipeline, write the application URL to an `environment_url.txt` file. DAST automatically reads the
      URL to find the scan target.

      You can see an [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

1. Set the `DAST_BROWSER_SCAN` [CI/CD variable](../../../../../ci/yaml/index.md#variables) to `"true"`.

For example:

```yaml
stages:
  - build
  - test
  - deploy
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_BROWSER_SCAN: "true"
```
