# Browser Performance Testing with the Sitespeed.io container

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

This example shows how to run the
[Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/) on
your code by using GitLab CI/CD and [Sitespeed.io](https://www.sitespeed.io)
using Docker-in-Docker.

First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` that
generates the expected report:

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
Sitespeed.io against the webpage you defined in `URL` to gather key metrics.
The [GitLab plugin](https://gitlab.com/gitlab-org/gl-performance) for
Sitespeed.io is downloaded in order to save the report as a
[Performance report artifact](../yaml/README.md#artifactsreportsperformance-premium)
that you can later download and analyze.
Due to implementation limitations we always take the latest Performance artifact available.

The full HTML Sitespeed.io report will also be saved as an artifact, and if you have
[GitLab Pages](../../user/project/pages/index.md) enabled, it can be viewed
directly in your browser.

For further customization options of Sitespeed.io, including the ability to
provide a list of URLs to test, please consult
[their documentation](https://www.sitespeed.io/documentation/sitespeed.io/configuration/).

TIP: **Tip:**
For [GitLab Premium](https://about.gitlab.com/pricing/) users, key metrics are automatically
extracted and shown right in the merge request widget.
[Learn more on Browser Performance Testing in merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/browser_performance_testing.html).

## Performance testing on Review Apps

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
1. You can now run the Sitespeed.io container against the desired hostname and
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

## Previous job definitions

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