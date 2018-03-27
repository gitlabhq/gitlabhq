# Browser Performance Testing with the Sitespeed.io container

This example shows how to run the [Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/) on your code by using
GitLab CI/CD and [Sitespeed.io](https://www.sitespeed.io) using Docker-in-Docker.

First, you need a GitLab Runner with the [docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml`, called `performance`:

```yaml
  stage: performance
  image: docker:git
  services:
    - docker:dind
  script:
    - mkdir gitlab-exporter
    - wget -O ./gitlab-exporter/index.js https://gitlab.com/gitlab-org/gl-performance/raw/10-5/index.js
    - mkdir sitespeed-results
    - docker run --shm-size=1g --rm -v "$(pwd)":/sitespeed.io sitespeedio/sitespeed.io:6.3.1 --plugins.add ./gitlab-exporter --outputFolder sitespeed-results https://my.website.com
    - mv sitespeed-results/data/performance.json performance.json
  artifacts:
    paths:
    - performance.json
    - sitespeed-results/
```

This will create a `performance` job in your CI/CD pipeline and will run Sitespeed.io against the webpage you define. The GitLab plugin for Sitespeed.io is downloaded in order to export key metrics to JSON. The full HTML Sitespeed.io report will also be saved as an artifact, and if you have Pages enabled it can be viewed directly in your browser. For further customization options of Sitespeed.io, including the ability to provide a list of URLs to test, please consult their [documentation](https://www.sitespeed.io/documentation/sitespeed.io/configuration/).

For [GitLab Premium](https://about.gitlab.com/products/) users, key metrics are automatically
extracted and shown right in the merge request widget. Learn more about [Browser Performance Testing](https://docs.gitlab.com/ee/user/project/merge_requests/browser_performance_testing.html).

## Performance testing on Review Apps

The above CI YML is great for testing against static environments, and it can be extended for dynamic environments. There are a few extra steps to take to set this up:
1. The `performance` job should run after the environment has started.
1. In the `deploy` job, persist the hostname so it is available to the `performance` job. The same can be done for static environments like staging and production to unify the code path. Saving it as an artifact is as simple as `echo $CI_ENVIRONMENT_URL > environment_url.txt`.
1. In the `performance` job read the artifact into an environment variable, like `$CI_ENVIRONMENT_URL`, and use it to parameterize the test URL's.
1. Now you can run the Sitespeed.io container against the desired hostname and paths.

A simple `performance` job would look like:

```yaml
  stage: performance
  image: docker:git
  services:
    - docker:dind
  script:
    - export CI_ENVIRONMENT_URL=$(cat environment_url.txt)
    - mkdir gitlab-exporter
    - wget -O ./gitlab-exporter/index.js https://gitlab.com/gitlab-org/gl-performance/raw/10-5/index.js
    - mkdir sitespeed-results
    - docker run --shm-size=1g --rm -v "$(pwd)":/sitespeed.io sitespeedio/sitespeed.io:6.3.1 --plugins.add ./gitlab-exporter --outputFolder sitespeed-results "$CI_ENVIRONMENT_URL"
    - mv sitespeed-results/data/performance.json performance.json
  artifacts:
    paths:
    - performance.json
    - sitespeed-results/
```

A complete example can be found in our [Auto DevOps CI YML](https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml).