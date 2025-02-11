---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Browser Performance Testing
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If your application offers a web interface and you're using
[GitLab CI/CD](../_index.md), you can quickly determine the rendering performance
impact of pending code changes in the browser.

NOTE:
You can automate this feature in your applications by using [Auto DevOps](../../topics/autodevops/_index.md).

## Overview

GitLab uses [Sitespeed.io](https://www.sitespeed.io), a free and open source
tool, for measuring the rendering performance of web sites. The
[Sitespeed plugin](https://gitlab.com/gitlab-org/gl-performance) that GitLab built outputs
the performance score for each page analyzed in a file called `browser-performance.json`
this data can be shown on merge requests.

## Use cases

Consider the following workflow:

1. A member of the marketing team is attempting to track engagement by adding a new tool.
1. With browser performance metrics, they see how their changes are impacting the usability
   of the page for end users.
1. The metrics show that after their changes, the performance score of the page has gone down.
1. When looking at the detailed report, they see the new JavaScript library was
   included in `<head>`, which affects loading page speed.
1. They ask for help from a front end developer, who sets the library to load asynchronously.
1. The frontend developer approves the merge request, and authorizes its deployment to production.

## How browser performance testing works

First, define a job in your `.gitlab-ci.yml` file that generates the
[Browser Performance report artifact](../yaml/artifacts_reports.md#artifactsreportsbrowser_performance).
GitLab then checks this report, compares key performance metrics for each page
between the source and target branches, and shows the information in the merge request.

For an example Browser Performance job, see
[Configuring Browser Performance Testing](#configuring-browser-performance-testing).

NOTE:
If the Browser Performance report has no data to compare, such as when you add the
Browser Performance job in your `.gitlab-ci.yml` for the very first time,
the Browser Performance report widget doesn't display. It must have run at least
once on the target branch (`main`, for example), before it displays in a
merge request targeting that branch. Additionally, the widget only displays if the
job ran in the latest pipeline for the Merge request.

![Browser Performance Widget](img/browser_performance_testing_v13_4.png)

## Configuring Browser Performance Testing

> - Support for the `SITESPEED_DOCKER_OPTIONS` variable [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134024) in GitLab 16.6.

This example shows how to run the [sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/)
on your code by using GitLab CI/CD and [sitespeed.io](https://www.sitespeed.io)
using Docker-in-Docker.

1. First, set up GitLab Runner with a
   [Docker-in-Docker build](../docker/using_docker_build.md#use-docker-in-docker).
1. Configure the default Browser Performance Testing CI/CD job as follows in your `.gitlab-ci.yml` file:

   ```yaml
   include:
     template: Verify/Browser-Performance.gitlab-ci.yml

   browser_performance:
     variables:
       URL: https://example.com
   ```

The above example:

- Creates a `browser_performance` job in your CI/CD pipeline and runs sitespeed.io against the webpage you
  defined in `URL` to gather key metrics.
- Uses a template that doesn't work with Kubernetes clusters. If you are using a Kubernetes cluster,
  use [`template: Jobs/Browser-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Browser-Performance-Testing.gitlab-ci.yml)
  instead.

The template uses the [GitLab plugin for sitespeed.io](https://gitlab.com/gitlab-org/gl-performance),
and it saves the full HTML sitespeed.io report as a [Browser Performance report artifact](../yaml/artifacts_reports.md#artifactsreportsbrowser_performance)
that you can later download and analyze. This implementation always takes the latest
Browser Performance artifact available. If [GitLab Pages](../../user/project/pages/_index.md) is enabled,
you can view the report directly in your browser.

You can also customize the jobs with CI/CD variables:

- `SITESPEED_IMAGE`: Configure the Docker image to use for the job (default `sitespeedio/sitespeed.io`), but not the image version.
- `SITESPEED_VERSION`: Configure the version of the Docker image to use for the job (default `14.1.0`).
- `SITESPEED_OPTIONS`: Configure any additional sitespeed.io options as required (default `nil`). Refer to the [sitespeed.io documentation](https://www.sitespeed.io/documentation/sitespeed.io/configuration/) for more details.
- `SITESPEED_DOCKER_OPTIONS`: Configure any additional Docker options (default `nil`). Refer to the [Docker options documentation](https://docs.docker.com/reference/cli/docker/container/run/#options) for more details.

For example, you can override the number of runs sitespeed.io
makes on the given URL, and change the version:

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

browser_performance:
  variables:
    URL: https://www.sitespeed.io/
    SITESPEED_VERSION: 13.2.0
    SITESPEED_OPTIONS: -n 5
```

### Configuring degradation threshold

You can configure the sensitivity of degradation alerts to avoid getting alerts for minor drops in metrics.
This is done by setting the `DEGRADATION_THRESHOLD` CI/CD variable. In the example below, the alert only shows up
if the `Total Score` metric degrades by 5 points or more:

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

browser_performance:
  variables:
    URL: https://example.com
    DEGRADATION_THRESHOLD: 5
```

The `Total Score` metric is based on sitespeed.io's [coach performance score](https://www.sitespeed.io/documentation/sitespeed.io/metrics/#performance-score). There is more information in [the coach documentation](https://www.sitespeed.io/documentation/coach/how-to/#what-do-the-coach-do).

### Performance testing on review apps

The above CI YAML configuration is great for testing against static environments, and it can
be extended for dynamic environments, but a few extra steps are required:

1. The `browser_performance` job should run after the dynamic environment has started.
1. In the `review` job:
   1. Generate a URL list file with the dynamic URL.
   1. Save the file as an artifact, for example with `echo $CI_ENVIRONMENT_URL > environment_url.txt`
      in your job's `script`.
   1. Pass the list as the URL environment variable (which can be a URL or a file containing URLs)
      to the `browser_performance` job.
1. You can now run the sitespeed.io container against the desired hostname and
   paths.

Your `.gitlab-ci.yml` file would look like:

```yaml
stages:
  - deploy
  - performance

include:
  template: Verify/Browser-Performance.gitlab-ci.yml

review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: http://$CI_COMMIT_REF_SLUG.$APPS_DOMAIN
  script:
    - run_deploy_script
    - echo $CI_ENVIRONMENT_URL > environment_url.txt
  artifacts:
    paths:
      - environment_url.txt
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_COMMIT_BRANCH

browser_performance:
  dependencies:
    - review
  variables:
    URL: environment_url.txt
```
