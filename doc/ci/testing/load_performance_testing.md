---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Load Performance Testing
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

With Load Performance Testing, you can test the impact of any pending code changes
to your application's backend in [GitLab CI/CD](../_index.md).

GitLab uses [k6](https://k6.io/), a free and open source
tool, for measuring the system performance of applications under
load.

Unlike [Browser Performance Testing](browser_performance_testing.md), which is
used to measure how web sites perform in client browsers, Load Performance Testing
can be used to perform various types of [load tests](https://k6.io/docs/#use-cases)
against application endpoints such as APIs, Web Controllers, and so on.
This can be used to test how the backend or the server performs at scale.

For example, you can use Load Performance Testing to perform many concurrent
GET calls to a popular API endpoint in your application to see how it performs.

## How Load Performance Testing works

First, define a job in your `.gitlab-ci.yml` file that generates the
[Load Performance report artifact](../yaml/artifacts_reports.md#artifactsreportsload_performance).
GitLab checks this report, compares key load performance metrics
between the source and target branches, and then shows the information in a merge request widget:

![Load Performance Widget](img/load_performance_testing_v13_2.png)

Next, you need to configure the test environment and write the k6 test.

The key performance metrics that the merge request widget shows after the test completes are:

- Checks: The percentage pass rate of the [checks](https://k6.io/docs/using-k6/checks) configured in the k6 test.
- TTFB P90: The 90th percentile of how long it took to start receiving responses, aka the [Time to First Byte](https://en.wikipedia.org/wiki/Time_to_first_byte) (TTFB).
- TTFB P95: The 95th percentile for TTFB.
- RPS: The average requests per second (RPS) rate the test was able to achieve.

NOTE:
If the Load Performance report has no data to compare, such as when you add the
Load Performance job in your `.gitlab-ci.yml` for the very first time,
the Load Performance report widget doesn't display. It must have run at least
once on the target branch (`main`, for example), before it displays in a
merge request targeting that branch.

## Configure the Load Performance Testing job

Configuring your Load Performance Testing job can be broken down into several distinct parts:

- Determine the test parameters such as throughput, and so on.
- Set up the target test environment for load performance testing.
- Design and write the k6 test.

### Determine the test parameters

The first thing you need to do is determine the [type of load test](https://grafana.com/load-testing/types-of-load-testing/)
you want to run, and how you want it to run (for example, the number of users, throughput, and so on).

Refer to the [k6 docs](https://k6.io/docs/), especially the [k6 testing guides](https://k6.io/docs/testing-guides),
for guidance on the above and more.

### Test Environment setup

A large part of the effort around load performance testing is to prepare the target test environment
for high loads. You should ensure it's able to handle the
[throughput](https://k6.io/blog/monthly-visits-concurrent-users) it is tested with.

It's also typically required to have representative test data in the target environment
for the load performance test to use.

We strongly recommend [not running these tests against a production environment](https://k6.io/our-beliefs#load-test-in-a-pre-production-environment).

### Write the load performance test

After the environment is prepared, you can write the k6 test itself. k6 is a flexible
tool and can be used to run [many kinds of performance tests](https://grafana.com/load-testing/types-of-load-testing/).
Refer to the [k6 documentation](https://k6.io/docs/) for detailed information on how to write tests.

### Configure the test in GitLab CI/CD

When your k6 test is ready, the next step is to configure the load performance
testing job in GitLab CI/CD. The easiest way to do this is to use the
[`Verify/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Load-Performance-Testing.gitlab-ci.yml)
template that is included with GitLab.

NOTE:
For large scale k6 tests you need to ensure the GitLab Runner instance performing the actual
test is able to handle running the test. Refer to [k6's guidance](https://k6.io/docs/testing-guides/running-large-tests#hardware-considerations)
for spec details. The [default shared GitLab.com runners](../runners/hosted_runners/linux.md)
likely have insufficient specs to handle most large k6 tests.

This template runs the
[k6 Docker container](https://hub.docker.com/r/loadimpact/k6/) in the job and provides several ways to customize the
job.

An example configuration workflow:

1. Set up GitLab Runner to run Docker containers, like the
   [Docker-in-Docker workflow](../docker/using_docker_build.md#use-docker-in-docker).
1. Configure the default Load Performance Testing CI/CD job in your `.gitlab-ci.yml` file.
   You need to include the template and configure it with CI/CD variables:

   ```yaml
   include:
     template: Verify/Load-Performance-Testing.gitlab-ci.yml

   load_performance:
     variables:
       K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
   ```

The above example creates a `load_performance` job in your CI/CD pipeline that runs
the k6 test.

NOTE:
For Kubernetes setups a different template should be used: [`Jobs/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Load-Performance-Testing.gitlab-ci.yml).

k6 has [various options](https://k6.io/docs/using-k6/k6-options/reference/) to configure how it runs the tests, such as what throughput (RPS) to run with,
how long the test should run, and so on. Almost all options can be configured in the test itself, but as
you can also pass command line options via the `K6_OPTIONS` variable.

For example, you can override the duration of the test with a CLI option:

```yaml
  include:
    template: Verify/Load-Performance-Testing.gitlab-ci.yml

  load_performance:
    variables:
      K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
      K6_OPTIONS: '--duration 30s'
```

GitLab only displays the key performance metrics in the MR widget if k6's results are saved
via [summary export](https://k6.io/docs/results-output/real-time/json/#summary-export)
as a [Load Performance report artifact](../yaml/artifacts_reports.md#artifactsreportsload_performance).
The latest Load Performance artifact available is always used, using the
summary values from the test.

If [GitLab Pages](../../user/project/pages/_index.md) is enabled, you can view the report directly in your browser.

### Load Performance testing in review apps

The CI/CD YAML configuration example above works for testing against static environments,
but it can be extended to work with [review apps](../review_apps/_index.md) or
[dynamic environments](../environments/_index.md) with a few extra steps.

The best approach is to capture the dynamic URL in a [`.env` file](https://docs.docker.com/compose/environment-variables/env-file/)
as a job artifact to be shared, then use a custom CI/CD variable we've provided named `K6_DOCKER_OPTIONS`
to configure the k6 Docker container to use the file. With this, k6 can then use any
environment variables from the `.env` file in scripts using standard JavaScript,
such as: ``http.get(`${__ENV.ENVIRONMENT_URL}`)``.

For example:

1. In the `review` job:
   1. Capture the dynamic URL and save it into a `.env` file, for example, `echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env`.
   1. Set the `.env` file to be a [job artifact](../jobs/job_artifacts.md).
1. In the `load_performance` job:
   1. Set it to depend on the review job, so it inherits the environment file.
   1. Set the `K6_DOCKER_OPTIONS` variable with the [Docker CLI option for environment files](https://docs.docker.com/reference/cli/docker/container/run/#env), for example `--env-file review.env`.
1. Configure the k6 test script to use the environment variable in it's steps.

Your `.gitlab-ci.yml` file might be similar to:

```yaml
stages:
  - deploy
  - performance

include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: http://$CI_ENVIRONMENT_SLUG.example.com
  script:
    - run_deploy_script
    - echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env
  artifacts:
    paths:
      - review.env
  rules:
    - if: $CI_COMMIT_BRANCH  # Modify to match your pipeline rules, or use `only/except` if needed.

load_performance:
  dependencies:
    - review
  variables:
    K6_DOCKER_OPTIONS: '--env-file review.env'
  rules:
    - if: $CI_COMMIT_BRANCH  # Modify to match your pipeline rules, or use `only/except` if needed.
```
