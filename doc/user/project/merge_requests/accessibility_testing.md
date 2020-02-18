---
type: reference, howto
---

# Accessibility Testing

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25144) in GitLab 12.8.

If your application offers a web interface and you are using
[GitLab CI/CD](../../../ci/README.md), you can quickly determine the accessibility
impact of pending code changes.

## Overview

GitLab uses [pa11y](https://pa11y.org/), a free and open source tool for
measuring the accessibility of web sites, and has built a simple
[CI job template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml).
This job outputs accessibility violations, warnings, and notices for each page
analyzed to a file called `accessibility`.

## Configure Accessibility Testing

This example shows how to run [pa11y](https://pa11y.org/)
on your code with GitLab CI/CD using a node Docker image.

For GitLab 12.8 and later, to define the `a11y` job, you must
[include](../../../ci/yaml/README.md#includetemplate) the
[`Accessibility.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)
included with your GitLab installation, as shown below.
For GitLab versions earlier than 12.8, you can copy and use the job as
defined in that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  template: Verify/Accessibility.gitlab-ci.yml

a11y:
  variables:
    a11y_urls: https://example.com https://example.com/another-page
```

The example above will create an `a11y` job in your CI/CD pipeline and will run
Pa11y against the webpage you defined in `a11y_urls` to build a report.

The full HTML Pa11y report will be saved as an artifact that can be [viewed directly in your browser](../pipelines/job_artifacts.md#browsing-artifacts).

NOTE: **Note:**
The job definition provided by the template does not support Kubernetes yet.

It is not yet possible to pass configurations into Pa11y via CI configuration. To change anything,
copy the template to your CI file and make the desired edits.
