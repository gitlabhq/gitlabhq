---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web API fuzz testing
description: Testing, security, vulnerabilities, automation, and errors.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Web API fuzz testing passes unexpected values to API operation parameters to cause unexpected behavior
and errors in the backend. Use fuzz testing to discover bugs and potential vulnerabilities that other
QA processes might miss.

You should use fuzz testing in addition to the other security scanners in [GitLab Secure](../_index.md)
and your own test processes. If you're using [GitLab CI/CD](../../../ci/_index.md),
you can run fuzz tests as part your CI/CD workflow.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [WebAPI Fuzzing - Advanced Security Testing](https://www.youtube.com/watch?v=oUHsfvLGhDk).

## Getting started

Get started with API fuzzing by editing your CI/CD configuration.

Prerequisites:

- A web API using one of the supported API types:
  - REST API
  - SOAP
  - GraphQL
  - Form bodies, JSON, or XML
- An API specification in one of the following formats:
  - OpenAPI v2 or v3 Specification
  - GraphQL Schema
  - HTTP Archive (HAR)
  - Postman Collection v2.0 or v2.1
- An available GitLab Runner with the `docker` executor on Linux/amd64.
- A deployed target application.
- The `fuzz` stage is added to your CI/CD pipeline definition, after the `deploy` stage:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - fuzz
  ```

To enable API fuzzing:

- Use the [Web API fuzzing configuration form](configuration/enabling_the_analyzer.md#web-api-fuzzing-configuration-form).

  The form lets you choose values for the most common API fuzzing options, and builds
  a YAML snippet that you can paste in your GitLab CI/CD configuration.

## Understanding the results

To view the output of a security scan:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the left sidebar, select **Build** > **Pipelines**.
1. Select the pipeline.
1. Select the **Security** tab.
1. Select a vulnerability to view its details, including:
   - Status: Indicates whether the vulnerability has been triaged or resolved.
   - Description: Explains the cause of the vulnerability, its potential impact, and recommended remediation steps.
   - Severity: Categorized into six levels based on impact.
     For more information, see [severity levels](../vulnerabilities/severities.md).
   - Scanner: Identifies which analyzer detected the vulnerability.
   - Method: Establishes the vulnerable server interaction type.
   - URL: Shows the location of the vulnerability.
   - Evidence: Describes test case to prove the presence of a given vulnerability
   - Identifiers: A list of references used to classify the vulnerability, such as CWE identifiers.

You can also download the security scan results:

- In the pipeline's **Security** tab, select **Download results**.

For more details, see the [pipeline security report](../detect/security_scanning_results.md).

{{< alert type="note" >}}

Findings are generated on feature branches. When they are merged into the default branch, they become vulnerabilities. This distinction is important when evaluating your security posture.

{{< /alert >}}

## Optimization

To get the most out of API fuzzing, follow these recommendations:

- To run the latest versions of the analyzers, configure runners to use `pull_policy: always`.
- By default, API fuzzing downloads all artifacts defined by previous jobs in the pipeline. If your
  API fuzzing job does not rely on `environment_url.txt` to define the URL under test or any other
  files created in previous jobs, you should not download artifacts.

  To avoid downloading artifacts, extend the analyzer CI/CD job to specify no dependencies.
  For example, for the API fuzzing analyzer, add the following to your `.gitlab-ci.yml` file:

  ```yaml
  apifuzzer_fuzz:
    dependencies: []
  ```

### Application deployment options

API fuzzing requires a deployed application to be available to scan.

Depending on the complexity of the target application, there are a few options as to how to deploy and configure
the API fuzzing template.

#### Review apps

Review apps are the most involved method of deploying your API Fuzzing target application. To assist in the process,
GitLab created a review app deployment using Google Kubernetes Engine (GKE). This example can be found in the
[Review apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) project, plus detailed
instructions to configure review apps in DAST.

#### Docker services

If your application uses Docker containers, you have another option for deploying and scanning with API fuzzing.
After your Docker build job completes and your image is added to your container registry, you can use the image as a service.

By using service definitions in your `.gitlab-ci.yml`, you can scan services with the DAST analyzer.

When adding a `services` section to the job, the `alias` is used to define the hostname that can be used to access the service. In the following example, the `alias: yourapp` portion of the `dast` job definition means that the URL to the deployed application uses `yourapp` as the hostname: `https://yourapp/`.

```yaml
stages:
  - build
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

# Deploys the container to the GitLab container registry
deploy:
  services:
  - name: docker:dind
    alias: dind
  image: docker:20.10.16
  stage: build
  script:
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest

apifuzzer_fuzz:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  FUZZAPI_TARGET_URL: https://yourapp
```

Most applications depend on multiple services such as databases or caching services. By default, services defined in the services fields cannot communicate
with each another. To allow communication between services, enable the `FF_NETWORK_PER_BUILD` feature flag.

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## Roll out

Web API fuzzing runs in the `fuzz` stage of the CI/CD pipeline. To ensure API fuzzing scans the
latest code, your CI/CD pipeline should deploy changes to a test environment in one of the stages
preceding the `fuzz` stage.

If your pipeline is configured to deploy to the same web server on each run, running a
pipeline while another is still running could cause a race condition in which one pipeline
overwrites the code from another. The API to scan should be excluded from changes for the duration
of a fuzzing scan. The only changes to the API should be from the fuzzing scanner. Any changes made
to the API (for example, by users, scheduled tasks, database changes, code changes, other pipelines,
or other scanners) during a scan could cause inaccurate results.

You can run a web API fuzzing scan using the following methods:

- OpenAPI specification (versions 2 and 3)
- GraphQL schema
- HTTP archive (HAR)
- Postman collection (versions 2.0 and 2.1)

### Example API fuzzing projects

- [Example OpenAPI v2 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [Example HTTP Archive (HAR) project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Example Postman Collection project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)
- [Example GraphQL project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/graphql-api-fuzzing-example)
- [Example SOAP project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/soap-api-fuzzing-example)
- [Authentication Token using Selenium](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/auth-token-selenium)

## Get support or request an improvement

To get support for your particular problem use the [getting help channels](https://about.gitlab.com/get-help/).

The [GitLab issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) is the right place for bugs and feature proposals about API security and API fuzzing.
Use `~"Category:API Security"` label when opening a new issue regarding API fuzzing to ensure it is quickly reviewed by the right people.

Search the issue tracker for similar entries before submitting your own, there's a good chance somebody else had the same issue or feature proposal. Show your support with an emoji reaction or join the discussion.

When experiencing a behavior not working as expected, consider providing contextual information:

- GitLab version if using a GitLab Self-Managed instance.
- `.gitlab-ci.yml` job definition.
- Full job console output.
- Scanner log file available as a job artifact named `gl-api-security-scanner.log`.

{{< alert type="warning" >}}

Do not include sensitive information when you submit an issue. Remove credentials like passwords, tokens, and keys.

{{< /alert >}}

## Glossary

- Assert: Assertions are detection modules used by checks to trigger a fault. Many assertions have
  configurations. A check can use multiple Assertions. For example, Log Analysis, Response Analysis,
  and Status Code are common Assertions used together by checks. Checks with multiple Assertions
  allow them to be turned on and off.
- Check: Performs a specific type of test, or performed a check for a type of vulnerability. For
  example, the JSON Fuzzing Check performs fuzz testing of JSON payloads. The API fuzzer is
  comprised of several checks. Checks can be turned on and off in a profile.
- Fault: During fuzzing, a failure identified by an Assert is called a fault. Faults are
  investigated to determine if they are a security vulnerability, a non-security issue, or a false
  positive. Faults don't have a known vulnerability type until they are investigated. Example
  vulnerability types are SQL Injection and Denial of Service.
- Profile: A configuration file has one or more testing profiles, or sub-configurations. You may
  have a profile for feature branches and another with extra testing for a main branch.
