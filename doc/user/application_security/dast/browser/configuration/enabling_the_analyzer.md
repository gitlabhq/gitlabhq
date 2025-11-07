---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Enabling the analyzer
---

To run a DAST scan:

- Read the [requirements](../_index.md) conditions for running a DAST scan.
- Create a [DAST job](#create-a-dast-cicd-job) in your CI/CD pipeline.
- [Authenticate](authentication.md) as a user if your application requires it.

The DAST job runs in a Docker container defined by the `image` keyword in the DAST CI/CD template file.
When you run the job, DAST connects to the target application specified by the `DAST_TARGET_URL` variable
and crawls the site using an embedded browser.

## Create a DAST CI/CD job

{{< history >}}

- This template was [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87183) to DAST_VERSION: 3 in GitLab 15.0.
- This template was updated to DAST_VERSION: 4 in GitLab 16.0.
- This template was [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151910) to DAST_VERSION: 5 in GitLab 17.0.
- This template was [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188703) to DAST_VERSION: 6 in GitLab 18.0.

{{< /history >}}

To add DAST scanning to your application, use the DAST job defined
in the GitLab DAST CI/CD template file. Updates to the template are provided with GitLab
upgrades, allowing you to benefit from any improvements and additions.

To create the CI/CD job:

1. Include the appropriate CI/CD template:

   - [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml):
     Stable version of the DAST CI/CD template.
   - [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml):
     Latest version of the DAST template.

   {{< alert type="warning" >}}

   The latest version of the template may include breaking changes. Use the
   stable template unless you need a feature provided only in the latest template.

   {{< /alert >}}

1. Add a `dast` stage to your GitLab CI/CD stages configuration.

1. Define the URL to be scanned by DAST by using one of these methods:

   - Set the `DAST_TARGET_URL` [CI/CD variable](../../../../../ci/yaml/_index.md#variables).
     If set, this value takes precedence.

   - Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
     dynamic environments. To run DAST against an application dynamically created during a GitLab CI/CD
     pipeline, write the application URL to an `environment_url.txt` file. DAST automatically reads the
     URL to find the scan target.

     You can see an [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

For example:

```yaml
stages:
  - dast

include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_USERNAME: "test_user"
    DAST_AUTH_USERNAME_FIELD: "name:user[login]"
    DAST_AUTH_PASSWORD_FIELD: "name:user[password]"
```

You must define `DAST_TARGET_URL` or create an `environment_url.txt` file for the DAST job to run successfully.

### Network connectivity

Your runner must be able to connect to the target application URL. If your application uses a non-standard port, include it in the URL.

## After you enable the analyzer

When your pipeline runs, the DAST job:

1. Connects to your application.
1. Launches a Chromium browser to crawl the site.
1. Performs security checks on discovered pages.

### Configure authentication

If your application requires users to log in, configure DAST to authenticate before scanning. Without authentication, DAST can only scan publicly accessible pages.

To configure authentication, see [authentication](authentication.md).

### Verify crawl coverage

After your first scan completes, verify that DAST is discovering your application pages correctly.

To visualize the crawl results:

- Enable the crawl graph using the `DAST_CRAWL_GRAPH` [variable](variables.md).
- Review the graph to identify any missing pages or navigation paths.
- If pages are missing, adjust your [scan scope](customize_settings.md#managing-scope).

### Troubleshooting

If you encounter issues:

- For setup problems, see [setting up DAST](../troubleshooting.md#setting-up-dast).
- For detailed diagnostic information, see [diagnostic logs](../troubleshooting.md#diagnostic-logs).
- For connection troubleshooting, see [runner cannot connect to target application](../troubleshooting.md#runner-cannot-connect-to-target-application).
