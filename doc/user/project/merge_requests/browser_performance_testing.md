---
type: reference, howto
---

# Browser Performance Testing **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3507) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.3.

If your application offers a web interface and you are using
[GitLab CI/CD](../../../ci/README.md), you can quickly determine the performance
impact of pending code changes.

## Overview

GitLab uses [Sitespeed.io](https://www.sitespeed.io), a free and open source
tool for measuring the performance of web sites, and has built a simple
[Sitespeed plugin](https://gitlab.com/gitlab-org/gl-performance)
which outputs the results in a file called `performance.json`. This plugin
outputs the performance score for each page that is analyzed.

The [Sitespeed.io performance score](https://examples.sitespeed.io/6.0/2017-11-23-23-43-35/help.html)
is a composite value based on best practices, and we will be expanding support
for [additional metrics](https://gitlab.com/gitlab-org/gitlab-ee/issues/4370)
in a future release.

Going a step further, GitLab can show the Performance report right
in the merge request widget area (see below).

## Use cases

For instance, consider the following workflow:

1. A member of the marketing team is attempting to track engagement by adding a new tool.
1. With browser performance metrics, they see how their changes are impacting the usability
   of the page for end users.
1. The metrics show that after their changes the performance score of the page has gone down.
1. When looking at the detailed report, they see that the new JavaScript library was
   included in `<head>` which affects loading page speed.
1. They ask a front end developer to help them, who sets the library to load asynchronously.
1. The frontend developer approves the merge request and authorizes its deployment to production.

## How it works

First of all, you need to define a job in your `.gitlab-ci.yml` file that generates the
[Performance report artifact](../../../ci/yaml/README.md#artifactsreportsperformance-premium).
For more information on how the Performance job should look like, check the
example on [Testing Browser Performance](../../../ci/examples/browser_performance.md).

GitLab then checks this report, compares key performance metrics for each page
between the source and target branches, and shows the information right on the merge request.

NOTE: **Note:**
If the Performance report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
Performance job in your `.gitlab-ci.yml` for the very first time.
Consecutive merge requests will have something to compare to, and the Performance
report will be shown properly.

![Performance Widget](img/browser_performance_testing.png)

## Configuring Browser Performance Testing

NOTE: **Note:**
The job definition shown below is supported in GitLab 11.5 and later versions.
It also requires GitLab Runner 11.5 or later. For earlier versions, use the
[previous job definitions](#previous-job-definitions).

This example shows how to run the [sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/)
on your code by using GitLab CI/CD and [sitespeed.io](https://www.sitespeed.io)
using Docker-in-Docker.

First, you need GitLab Runner with
[docker-in-docker build](../../../ci/docker/using_docker_build.md#use-docker-in-docker-workflow-with-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` that generates the
expected report:

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
      - sitespeed-results/
    reports:
      performance: performance.json
```

The above example will create a `performance` job in your CI/CD pipeline and will run
sitespeed.io against the webpage you defined in `URL` to gather key metrics.
The [GitLab plugin for sitespeed.io](https://gitlab.com/gitlab-org/gl-performance)
is downloaded in order to save the report as a [Performance report artifact](../../../ci/yaml/README.md#artifactsreportsperformance-premium)
that you can later download and analyze. Due to implementation limitations we always
take the latest Performance artifact available.

The full HTML sitespeed.io report will also be saved as an artifact, and if you have
[GitLab Pages](../pages/index.md) enabled, it can be viewed directly in your browser.

For further customization options for sitespeed.io, including the ability to provide a
list of URLs to test, please see the [Sitespeed.io Configuration](https://www.sitespeed.io/documentation/sitespeed.io/configuration/)
documentation.

TIP: **Tip:**
Key metrics are automatically extracted and shown in the merge request widget.

### Performance testing on Review Apps

The above CI YML is great for testing against static environments, and it can
be extended for dynamic environments. There are a few extra steps to take to
set this up:

1. The `performance` job should run after the dynamic environment has started.
1. In the `review` job, persist the hostname and upload it as an artifact so
   it's available to the `performance` job (the same can be done for static
   environments like staging and production to unify the code path). Saving it
   as an artifact is as simple as `echo $CI_ENVIRONMENT_URL > environment_url.txt`
   in your job's `script`.
1. In the `performance` job, read the previous artifact into an environment
   variable, like `$CI_ENVIRONMENT_URL`, and use it to parameterize the test
   URLs.
1. You can now run the sitespeed.io container against the desired hostname and
   paths.

Your `.gitlab-ci.yml` file would look like:

```yaml
stages:
  - deploy
  - performance

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
  stage: performance
  image: docker:git
  services:
    - docker:stable-dind
  dependencies:
    - review
  script:
    - export CI_ENVIRONMENT_URL=$(cat environment_url.txt)
    - mkdir gitlab-exporter
    - wget -O ./gitlab-exporter/index.js https://gitlab.com/gitlab-org/gl-performance/raw/master/index.js
    - mkdir sitespeed-results
    - docker run --shm-size=1g --rm -v "$(pwd)":/sitespeed.io sitespeedio/sitespeed.io:6.3.1 --plugins.add ./gitlab-exporter --outputFolder sitespeed-results "$CI_ENVIRONMENT_URL"
    - mv sitespeed-results/data/performance.json performance.json
  artifacts:
    paths:
      - sitespeed-results/
    reports:
      performance: performance.json
```

A complete example can be found in our [Auto DevOps CI YML](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml).

### Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, Performance job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

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
