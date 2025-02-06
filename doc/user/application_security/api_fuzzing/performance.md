---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Performance tuning and testing speed
---

Security tools that perform API fuzz testing, such as API Fuzzing, perform testing by sending requests to an instance of your running application. The requests are mutated by our fuzzing engine to trigger unexpected behavior that might exist in your application. The speed of an API fuzzing test depends on the following:

- How many requests per second can be sent to your application by our tooling
- How fast your application responds to requests
- How many requests must be sent to test the application
  - How many operations your API is comprised of
  - How many fields are in each operation (think JSON bodies, headers, query string, cookies, etc.)

If API Fuzzing testing job still takes longer than expected after following the advice in this performance guide, reach out to support for further assistance.

## Diagnosing performance issues

The first step to resolving performance issues is to understand what is contributing to the slower-than-expected testing time. Some common issues we see are:

- API Fuzzing is running on a low-vCPU runner
- The application deployed to a slow/single-CPU instance and is not able to keep up with the testing load
- The application contains a slow operation that impacts the overall test speed (> 1/2 second)
- The application contains an operation that returns a large amount of data (> 500K+)
- The application contains a large number of operations (> 40)

### The application contains a slow operation that impacts the overall test speed (> 1/2 second)

The API Fuzzing job output contains helpful information about how fast we are testing, how fast each operation being tested responds, and summary information. Let's take a look at some sample output to see how it can be used in tracking down performance issues:

```shell
API Fuzzing: Loaded 10 operations from: assets/har-large-response/large_responses.har
API Fuzzing:
API Fuzzing: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API Fuzzing:  - Request body size: 0 Bytes (0 bytes)
API Fuzzing:
API Fuzzing: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API Fuzzing:  - Performed 767 requests
API Fuzzing:  - Average response body size: 130 MB
API Fuzzing:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API Fuzzing:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

This job console output snippet starts by telling us how many operations were found (10), followed by notifications that testing has started on a specific operation and a summary of the operation has been completed. The summary is the most interesting part of this log output. In the summary, we can see that it took API Fuzzing 767 requests to fully test this operation and its related fields. We can also see that the average response time was 2 seconds and the time to complete was 14 minutes for this one operation.

An average response time of 2 seconds is a good initial indicator that this specific operation takes a long time to test. Further, we can see that the response body size is quite large. The large body size is the culprit here, transferring that much data on each request is what takes the majority of that 2 seconds.

For this issue, the team might decide to:

- Use a runner with more vCPUs, because this allows API Fuzzing to parallelize the work being performed. This helps lower the test time, but getting the test down under 10 minutes might still be problematic without moving to a high CPU machine due to how long the operation takes to test. While larger runners are more costly, you also pay for less minutes if the job executions are quicker.
- [Exclude this operation](#excluding-slow-operations) from the API Fuzzing test. While this is the simplest, it has the downside of a gap in security test coverage.
- [Exclude the operation from feature branch API Fuzzing tests, but include it in the default branch test](#excluding-operations-in-feature-branches-but-not-default-branch).
- [Split up the API Fuzzing testing into multiple jobs](#splitting-a-test-into-multiple-jobs).

The likely solution is to use a combination of these solutions to reach an acceptable test time, assuming your team's requirements are in the 5-7 minute range.

## Addressing performance issues

The following sections document various options for addressing performance issues for API Fuzzing:

- [Using a larger runner](#using-a-larger-runner)
- [Excluding slow operations](#excluding-slow-operations)
- [Splitting a test into multiple jobs](#splitting-a-test-into-multiple-jobs)
- [Excluding operations in feature branches, but not default branch](#excluding-operations-in-feature-branches-but-not-default-branch)

### Using a larger runner

One of the easiest performance boosts can be achieved using a [larger runner](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)
with API Fuzzing. This table shows statistics collected during benchmarking of a Java Spring Boot REST API. In this benchmark, the target and API Fuzzing share a single runner instance.

| Hosted runner on Linux tag           | Requests per Second |
|------------------------------------|-----------|
| `saas-linux-small-amd64` (default) | 255 |
| `saas-linux-medium-amd64`          | 400 |

As we can see from this table, increasing the size of the runner and vCPU count can have a large impact on testing speed/performance.

Here is an example job definition for API Fuzzing that adds a `tags` section to use the medium SaaS runner on Linux. The job extends the job definition included through the API Fuzzing template.

```yaml
apifuzzer_fuzz:
  tags:
  - saas-linux-medium-amd64
```

In the `gl-api-security-scanner.log` file you can search for the string `Starting work item processor` to inspect the reported max DOP (degree of parallelism). The max DOP should be greater than or equal to the number of vCPUs assigned to the runner. If unable to identify the problem, open a ticket with support to assist.

Example log entry:

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### Excluding slow operations

In the case of one or two slow operations, the team might decide to skip testing the operations. Excluding the operation is done using the `FUZZAPI_EXCLUDE_PATHS` configuration [variable as explained in this section.](configuration/customizing_analyzer_settings.md#exclude-paths)

In this example, we have an operation that returns a large amount of data. The operation is `GET http://target:7777/api/large_response_json`. To exclude it we provide the `FUZZAPI_EXCLUDE_PATHS` configuration variable with the path portion of our operation URL `/api/large_response_json`.

To verify the operation is excluded, run the API Fuzzing job and review the job console output. It includes a list of included and excluded operations at the end of the test.

```yaml
apifuzzer_fuzz:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
```

WARNING:
Excluding operations from testing could allow some vulnerabilities to go undetected.

### Splitting a test into multiple jobs

Splitting a test into multiple jobs is supported by API Fuzzing through the use of [`FUZZAPI_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths) and [`FUZZAPI_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls). When splitting a test up, a good pattern is to disable the `apifuzzer_fuzz` job and replace it with two jobs with identifying names. In this example we have two jobs, each job is testing a version of the API, so our names reflect that. However, this technique can be applied to any situation, not just with versions of an API.

The rules we are using in the `apifuzzer_v1` and `apifuzzer_v2` jobs are copied from the [API Fuzzing template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml).

```yaml
# Disable the main apifuzzer_fuzz job
apifuzzer_fuzz:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

apifuzzer_v1:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v1/**
  rules:
    rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH

apifuzzer_v2:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v2/**
  rules:
    rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH
```

### Excluding operations in feature branches, but not default branch

In the case of one or two slow operations, the team might decide to skip testing the operations, or exclude them from feature branch tests, but include them for default branch tests. Excluding the operation is done using the `FUZZAPI_EXCLUDE_PATHS` configuration [variable as explained in this section.](configuration/customizing_analyzer_settings.md#exclude-paths)

In this example, we have an operation that returns a large amount of data. The
operation is `GET http://target:7777/api/large_response_json`. To exclude it we
provide the `FUZZAPI_EXCLUDE_PATHS` configuration variable with the path portion
of our operation URL `/api/large_response_json`. Our configuration disables the
main `apifuzzer_fuzz` job and creates two new jobs `apifuzzer_main` and
`apifuzzer_branch`. The `apifuzzer_branch` is set up to exclude the long
operation and only run on non-default branches (for example, feature branches).
The `apifuzzer_main` branch is set up to only execute on the default branch
(`main` in this example). The `apifuzzer_branch` jobs run faster, allowing for
quick development cycles, while the `apifuzzer_main` job which only runs on
default branch builds, takes longer to run.

To verify the operation is excluded, run the API Fuzzing job and review the job console output. It includes a list of included and excluded operations at the end of the test.

```yaml
# Disable the main job so we can create two jobs with
# different names
apifuzzer_fuzz:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

# API Fuzzing for feature branch work, excludes /api/large_response_json
apifuzzer_branch:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
  rules:
    rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_COMMIT_BRANCH

# API Fuzzing for default branch (main in our case)
# Includes the long running operations
apifuzzer_main:
  extends: apifuzzer_fuzz
    rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
