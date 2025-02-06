---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Performance tuning and testing speed
---

Security tools that perform dynamic analysis testing, such as API security testing, perform testing by sending requests to an instance of your running application. The requests are engineered to test for specific vulnerabilities that might exist in your application. The speed of a dynamic analysis test depends on the following:

- How many requests per second can be sent to your application by our tooling
- How fast your application responds to requests
- How many requests must be sent to test the application
  - How many operations your API is comprised of
  - How many fields are in each operation (think JSON bodies, headers, query string, cookies, etc.)

If the API security testing job still takes longer than expected reach after following the advice in this performance guide, reach out to support for further assistance.

## Diagnosing performance issues

The first step to resolving performance issues is to understand what is contributing to the slower-than-expected testing time. Some common issues we see are:

- API security testing is running on a low-vCPU runner
- The application deployed to a slow/single-CPU instance and is not able to keep up with the testing load
- The application contains a slow operation that impacts the overall test speed (> 1/2 second)
- The application contains an operation that returns a large amount of data (> 500K+)
- The application contains a large number of operations (> 40)

### The application contains a slow operation that impacts the overall test speed (> 1/2 second)

The API security testing job output contains helpful information about how fast we are testing, how fast each operation being tested responds, and summary information. Let's take a look at some sample output to see how it can be used in tracking down performance issues:

```shell
API SECURITY: Loaded 10 operations from: assets/har-large-response/large_responses.har
API SECURITY:
API SECURITY: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API SECURITY:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API SECURITY:  - Request body size: 0 Bytes (0 bytes)
API SECURITY:
API SECURITY: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API SECURITY:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API SECURITY:  - Performed 767 requests
API SECURITY:  - Average response body size: 130 MB
API SECURITY:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API SECURITY:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

This job console output snippet starts by telling us how many operations were found (10), followed by notifications that testing has started on a specific operation and a summary of the operation has been completed. The summary is the most interesting part of this log output. In the summary, we can see that it took API security testing 767 requests to fully test this operation and its related fields. We can also see that the average response time was 2 seconds and the time to complete was 14 minutes for this one operation.

An average response time of 2 seconds is a good initial indicator that this specific operation takes a long time to test. Further, we can see that the response body size is quite large. The large body size is the culprit here, transferring that much data on each request is what takes the majority of that 2 seconds.

For this issue, the team might decide to:

- Use a runner with more vCPUs, as this allows API security testing to parallelize the work being performed. This helps lower the test time, but getting the test down under 10 minutes might still be problematic without moving to a high CPU machine due to how long the operation takes to test. While larger runners are more costly, you also pay for less minutes if the job executions are quicker.
- [Exclude this operation](#excluding-slow-operations) from API security testing. While this is the simplest, it has the downside of a gap in security test coverage.
- [Exclude the operation from feature branch API security testing, but include it in the default branch test](#excluding-operations-in-feature-branches-but-not-default-branch).
- [Split up API security testing into multiple jobs](#splitting-a-test-into-multiple-jobs).

The likely solution is to use a combination of these solutions to reach an acceptable test time, assuming your team's requirements are in the 5-7 minute range.

## Addressing performance issues

The following sections document various options for addressing performance issues for API security testing:

- [Using a larger runner](#using-a-larger-runner)
- [Excluding slow operations](#excluding-slow-operations)
- [Splitting a test into multiple jobs](#splitting-a-test-into-multiple-jobs)
- [Excluding operations in feature branches, but not default branch](#excluding-operations-in-feature-branches-but-not-default-branch)

### Using a larger runner

One of the easiest performance boosts can be achieved using a [larger runner](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64) with API security testing. This table shows statistics collected during benchmarking of a Java Spring Boot REST API. In this benchmark, the target and API security testing share a single runner instance.

| Hosted runner on Linux tag           | Requests per Second |
|------------------------------------|-----------|
| `saas-linux-small-amd64` (default) | 255 |
| `saas-linux-medium-amd64`          | 400 |

As we can see from this table, increasing the size of the runner and vCPU count can have a large impact on testing speed/performance.

Here is an example job definition for API security testing that adds a `tags` section to use the medium SaaS runner on Linux. The job extends the job definition included through the API security testing template.

```yaml
api_security:
  tags:
  - saas-linux-medium-amd64
```

In the `gl-api-security-scanner.log` file you can search for the string `Starting work item processor` to inspect the reported max DOP (degree of parallelism). The max DOP should be greater than or equal to the number of vCPUs assigned to the runner. If unable to identify the problem, open a ticket with support to assist.

Example log entry:

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### Excluding slow operations

In the case of one or two slow operations, the team might decide to skip testing the operations. Excluding the operation is done using the `APISEC_EXCLUDE_PATHS` configuration [variable as explained in this section.](configuration/customizing_analyzer_settings.md#exclude-paths)

In this example, we have an operation that returns a large amount of data. The operation is `GET http://target:7777/api/large_response_json`. To exclude it we provide the `APISEC_EXCLUDE_PATHS` configuration variable with the path portion of our operation URL `/api/large_response_json`.

To verify the operation is excluded, run the API security testing job and review the job console output. It includes a list of included and excluded operations at the end of the test.

```yaml
api_security:
  variables:
    APISEC_EXCLUDE_PATHS: /api/large_response_json
```

WARNING:
Excluding operations from testing could allow some vulnerabilities to go undetected.

### Splitting a test into multiple jobs

Splitting a test into multiple jobs is supported by API security testing through the use of [`APISEC_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths) and [`APISEC_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls). When splitting a test up, a good pattern is to disable the `dast_api` job and replace it with two jobs with identifying names. In this example we have two jobs, each job is testing a version of the API, so our names reflect that. However, this technique can be applied to any situation, not just with versions of an API.

The rules we are using in the `APISEC_v1` and `APISEC_v2` jobs are copied from the [API security testing template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml).

```yaml
# Disable the main dast_api job
api_security:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

APISEC_v1:
  extends: dast_api
  variables:
    APISEC_EXCLUDE_PATHS: /api/v1/**
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH

APISEC_v2:
  variables:
    APISEC_EXCLUDE_PATHS: /api/v2/**
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH
```

### Excluding operations in feature branches, but not default branch

In the case of one or two slow operations, the team might decide to skip testing the operations, or exclude them from feature branch tests, but include them for default branch tests. Excluding the operation is done using the `APISEC_EXCLUDE_PATHS` configuration [variable as explained in this section.](configuration/customizing_analyzer_settings.md#exclude-paths)

In this example, we have an operation that returns a large amount of data. The operation is `GET http://target:7777/api/large_response_json`. To exclude it we provide the `APISEC_EXCLUDE_PATHS` configuration variable with the path portion of our operation URL `/api/large_response_json`. Our configuration disables the main `dast_api` job and creates two new jobs `APISEC_main` and `APISEC_branch`. The `APISEC_branch` is set up to exclude the long operation and only run on non-default branches (for example, feature branches). The `APISEC_main` branch is set up to only execute on the default branch (`main` in this example). The `APISEC_branch` jobs run faster, allowing for quick development cycles, while the `APISEC_main` job which only runs on default branch builds, takes longer to run.

To verify the operation is excluded, run the API security testing job and review the job console output. It includes a list of included and excluded operations at the end of the test.

```yaml
# Disable the main job so we can create two jobs with
# different names
api_security:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

# API security testing for feature branch work, excludes /api/large_response_json
APISEC_branch:
  extends: dast_api
  variables:
    APISEC_EXCLUDE_PATHS: /api/large_response_json
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    when: never
  - if: $CI_COMMIT_BRANCH

# API security testing for default branch (main in our case)
# Includes the long running operations
APISEC_main:
  extends: dast_api
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
