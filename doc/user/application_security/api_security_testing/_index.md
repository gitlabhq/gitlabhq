---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: API security testing analyzer
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/457449) in GitLab 17.0 from "DAST API analyzer" to "API security testing analyzer".

{{< /history >}}

Test web APIs to help discover bugs and potential security issues that other QA processes may miss.
Use API security testing in addition to other security scanners and your own test processes. You can
run API security testing tests either as part your CI/CD workflow,
[on-demand](../dast/on-demand_scan.md), or both.

{{< alert type="warning" >}}

Do not run API security testing against a production server. Not only can it perform any function that
the API can, it may also trigger bugs in the API. This includes actions like modifying and deleting
data. Only run API security testing against a test server.

{{< /alert >}}

## Getting started

Get started with API security testing by editing your CI/CD configuration.

Prerequisites:

- You have a web API using one of the supported API types:
  - REST API
  - SOAP
  - GraphQL
  - Form bodies, JSON, or XML
- You have an API specification in one of the following formats:
  - [OpenAPI v2 or v3 Specification](configuration/enabling_the_analyzer.md#openapi-specification)
  - [GraphQL Schema](configuration/enabling_the_analyzer.md#graphql-schema)
  - [HTTP Archive (HAR)](configuration/enabling_the_analyzer.md#http-archive-har)
  - [Postman Collection v2.0 or v2.1](configuration/enabling_the_analyzer.md#postman-collection)

  Each scan supports exactly one specification. To scan more than one specification, use multiple scans.
- You have a [GitLab Runner](../../../ci/runners/_index.md) available, with the
  [`docker` executor](https://docs.gitlab.com/runner/executors/docker.html) on Linux/amd64.
- You have a deployed target application. For more details, see the [deployment options](#application-deployment-options).
- The `dast` stage is added to your CI/CD pipeline definition, after the `deploy` stage. For example:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - dast
  ```

To enable API security testing, you must alter your GitLab CI/CD configuration YAML based on the unique needs of your environment. You can specify the API you want to scan using:

- [OpenAPI v2 or v3 Specification](configuration/enabling_the_analyzer.md#openapi-specification)
- [GraphQL Schema](configuration/enabling_the_analyzer.md#graphql-schema)
- [HTTP Archive (HAR)](configuration/enabling_the_analyzer.md#http-archive-har)
- [Postman Collection v2.0 or v2.1](configuration/enabling_the_analyzer.md#postman-collection)

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
     [Learn more about severity levels](../vulnerabilities/severities.md).
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

To get the most out of API security testing, follow these recommendations:

- Configure runners to use the [always pull policy](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy) to run the latest versions of the analyzers.
- By default, API security testing downloads all artifacts defined by previous jobs in the pipeline.
  If your DAST job does not rely on `environment_url.txt` to define the URL under test or any other
  files created in previous jobs, you should not download artifacts. To avoid downloading artifacts,
  extend the analyzer CI/CD job to specify no dependencies. For example, for the API security
  testing analyzer, add the following to your `.gitlab-ci.yml` file:

  ```yaml
  api_security:
    dependencies: []
  ```

To configure API security testing for your particular application or environment, see the full list of [configuration options](configuration/_index.md).

## Roll out

When run in your CI/CD pipeline, API security testing scanning runs in the `dast` stage by default. To ensure
API security testing scanning examines the latest code, ensure your CI/CD pipeline deploys changes to a test
environment in a stage before the `dast` stage.

If your pipeline is configured to deploy to the same web server on each run, running a pipeline
while another is still running could cause a race condition in which one pipeline overwrites the
code from another. The API to be scanned should be excluded from changes for the duration of a
API security testing scan. The only changes to the API should be from the API security testing scanner. Changes made to the
API (for example, by users, scheduled tasks, database changes, code changes, other pipelines, or
other scanners) during a scan could cause inaccurate results.

### Example API security testing scanning configurations

The following projects demonstrate API security testing scanning:

- [Example OpenAPI v3 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-v3-example)
- [Example OpenAPI v2 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example)
- [Example HTTP Archive (HAR) project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/har-example)
- [Example Postman Collection project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/postman-example)
- [Example GraphQL project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/graphql-example)
- [Example SOAP project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/soap-example)
- [Authentication Token using Selenium](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-token-selenium)

### Application deployment options

API security testing requires a deployed application to be available to scan.

Depending on the complexity of the target application, there are a few options as to how to deploy and configure
the API security testing template.

#### Review apps

Review apps are the most involved method of deploying your DAST target application. To assist in the process,
GitLab created a review app deployment using Google Kubernetes Engine (GKE). This example can be found in the
[Review Apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) project, plus detailed
instructions to configure review apps for DAST in the [README.md](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md).

#### Docker Services

If your application uses Docker containers you have another option for deploying and scanning with DAST.
After your Docker build job completes and your image is added to your container registry, you can use the image as a
[service](../../../ci/services/_index.md).

By using service definitions in your `.gitlab-ci.yml`, you can scan services with the DAST analyzer.

When adding a `services` section to the job, the `alias` is used to define the hostname that can be used to access the service. In the following example, the `alias: yourapp` portion of the `dast` job definition means that the URL to the deployed application uses `yourapp` as the hostname (`https://yourapp/`).

```yaml
stages:
  - build
  - dast

include:
  - template: API-Security.gitlab-ci.yml

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

api_security:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  APISEC_TARGET_URL: https://yourapp
```

Most applications depend on multiple services such as databases or caching services. By default, services defined in the services fields cannot communicate
with each another. To allow communication between services, enable the `FF_NETWORK_PER_BUILD` [feature flag](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags).

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## Get support or request an improvement

To get support for your particular problem, use the [getting help channels](https://about.gitlab.com/get-help/).

The [GitLab issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) is the right place for bugs and feature proposals about API security testing.
Use `~"Category:API Security"` label when opening a new issue regarding API security testing to ensure it is quickly reviewed by the right people.

[Search the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues) for similar entries before submitting your own, there's a good chance somebody else had the same issue or feature proposal. Show your support with an emoji reaction or join the discussion.

When experiencing a behavior not working as expected, consider providing contextual information:

- GitLab version if using a GitLab Self-Managed instance.
- `.gitlab-ci.yml` job definition.
- Full job console output.
- Scanner log file available as a job artifact named `gl-api-security-scanner.log`.

{{< alert type="warning" >}}

**Sanitize data attached to a support issue**. Remove sensitive information, including: credentials, passwords, tokens, keys, and secrets.

{{< /alert >}}

## Glossary

- Assert: Assertions are detection modules used by checks to trigger a vulnerability. Many assertions have
  configurations. A check can use multiple Assertions. For example, Log Analysis, Response Analysis,
  and Status Code are common Assertions used together by checks. Checks with multiple Assertions
  allow them to be turned on and off.
- Check: Performs a specific type of test, or performed a check for a type of vulnerability. For
  example, the SQL Injection Check performs DAST testing for SQL Injection vulnerabilities. The API security testing scanner is comprised of several checks. Checks can be turned on and off in a profile.
- Profile: A configuration file has one or more testing profiles, or sub-configurations. You may
  have a profile for feature branches and another with extra testing for a main branch.
