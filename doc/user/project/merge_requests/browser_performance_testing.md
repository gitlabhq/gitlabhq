---
type: reference, howto
---

# Browser Performance Testing **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/3507) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.3.

If your application offers a web interface and you're using
[GitLab CI/CD](../../../ci/README.md), you can quickly determine the performance
impact of pending code changes.

## Overview

GitLab uses [Sitespeed.io](https://www.sitespeed.io), a free and open source
tool, for measuring the performance of web sites. GitLab has built a simple
[Sitespeed plugin](https://gitlab.com/gitlab-org/gl-performance) which outputs
the performance score for each page analyzed in a file called `performance.json`.
The [Sitespeed.io performance score](https://examples.sitespeed.io/6.0/2017-11-23-23-43-35/help.html)
is a composite value based on best practices.

GitLab can [show the Performance report](#how-browser-performance-testing-works)
in the merge request widget area.

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
[Performance report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportsperformance-premium).
GitLab then checks this report, compares key performance metrics for each page
between the source and target branches, and shows the information in the merge request.

For an example Performance job, see
[Configuring Browser Performance Testing](#configuring-browser-performance-testing).

NOTE: **Note:**
If the Performance report has no data to compare, such as when you add the
Performance job in your `.gitlab-ci.yml` for the very first time, no information
displays in the merge request widget area. Consecutive merge requests will have data for
comparison, and the Performance report will be shown properly.

![Performance Widget](img/browser_performance_testing.png)

## Configuring Browser Performance Testing

This example shows how to run the [sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/)
on your code by using GitLab CI/CD and [sitespeed.io](https://www.sitespeed.io)
using Docker-in-Docker.

1. First, set up GitLab Runner with a
   [Docker-in-Docker build](../../../ci/docker/using_docker_build.md#use-docker-in-docker-workflow-with-docker-executor).
1. After configuring the Runner, add a new job to `.gitlab-ci.yml` that generates
   the expected report.
1. Define the `performance` job according to your version of GitLab:

   - For GitLab 12.4 and later - [include](../../../ci/yaml/README.md#includetemplate) the
     [`Browser-Performance.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Verify/Browser-Performance.gitlab-ci.yml) provided as a part of your GitLab installation.
   - For GitLab versions earlier than 12.4 - Copy and use the job as defined in the
     [`Browser-Performance.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Verify/Browser-Performance.gitlab-ci.yml).

   CAUTION: **Caution:**
   The job definition provided by the template does not support Kubernetes yet.
   For a complete example of a more complex setup that works in Kubernetes, see
   [`Browser-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Browser-Performance-Testing.gitlab-ci.yml).

1. Add the following to your `.gitlab-ci.yml` file:

   ```yaml
   include:
     template: Verify/Browser-Performance.gitlab-ci.yml

   performance:
     variables:
       URL: https://example.com
   ```

   CAUTION: **Caution:**
   The job definition provided by the template is supported in GitLab 11.5 and later versions.
   It also requires GitLab Runner 11.5 or later. For earlier versions, use the
   [previous job definitions](#previous-job-definitions).

The above example creates a `performance` job in your CI/CD pipeline and runs
sitespeed.io against the webpage you defined in `URL` to gather key metrics.
The [GitLab plugin for sitespeed.io](https://gitlab.com/gitlab-org/gl-performance)
is downloaded to save the report as a [Performance report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportsperformance-premium)
that you can later download and analyze. Due to implementation limitations, we always
take the latest Performance artifact available.

The full HTML sitespeed.io report is saved as an artifact, and if
[GitLab Pages](../pages/index.md) is enabled, it can be viewed directly in your browser.

You can also customize options by setting the `SITESPEED_OPTIONS` variable.
For example, you can override the number of runs sitespeed.io
makes on the given URL:

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

performance:
  variables:
    URL: https://example.com
    SITESPEED_OPTIONS: -n 5
```

For further customization options for sitespeed.io, including the ability to provide a
list of URLs to test, please see the
[Sitespeed.io Configuration](https://www.sitespeed.io/documentation/sitespeed.io/configuration/)
documentation.

TIP: **Tip:**
Key metrics are automatically extracted and shown in the merge request widget.

### Configuring degradation threshold

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27599) in GitLab 13.0.

You can configure the sensitivity of degradation alerts to avoid getting alerts for minor drops in metrics.
This is done by setting the `DEGRADATION_THRESHOLD` variable. In the example below, the alert will only show up
if the `Total Score` metric degrades by 5 points or more:

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

performance:
  variables:
    URL: https://example.com
    DEGRADATION_THRESHOLD: 5
```

The `Total Score` metric is based on sitespeed.io's [coach performance score](https://www.sitespeed.io/documentation/sitespeed.io/metrics/#performance-score). There is more information in [the coach documentation](https://www.sitespeed.io/documentation/coach/how-to/#what-do-the-coach-do).

### Performance testing on Review Apps

The above CI YAML configuration is great for testing against static environments, and it can
be extended for dynamic environments, but a few extra steps are required:

1. The `performance` job should run after the dynamic environment has started.
1. In the `review` job, persist the hostname and upload it as an artifact so
   it's available to the `performance` job. The same can be done for static
   environments like staging and production to unify the code path. You can save it
   as an artifact with `echo $CI_ENVIRONMENT_URL > environment_url.txt`
   in your job's `script`.
1. In the `performance` job, read the previous artifact into an environment
   variable. In this case, use `$URL` because the sitespeed.io command
   uses it for the URL parameter. Because Review App URLs are dynamic, define
   the `URL` variable through `before_script` instead of `variables`.
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
  only:
    - branches
  except:
    - master

performance:
  dependencies:
    - review
  before_script:
    - export URL=$(cat environment_url.txt)
```

### Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, the Performance job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained, they have been deprecated
and may be removed in next major release, GitLab 12.0.
GitLab recommends you update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
performance:
  stage: performance
  image: docker:git
  variables:
    URL: https://example.com
  services:
    - docker:stable-dind
  script:
    - mkdir gitlab-exporter
    - wget -O ./gitlab-exporter/index.js https://gitlab.com/gitlab-org/gl-performance/raw/master/index.js
    - mkdir sitespeed-results
    - docker run --shm-size=1g --rm -v "$(pwd)":/sitespeed.io sitespeedio/sitespeed.io:6.3.1 --plugins.add ./gitlab-exporter --outputFolder sitespeed-results $URL
    - mv sitespeed-results/data/performance.json performance.json
  artifacts:
    paths:
      - performance.json
      - sitespeed-results/
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
