---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
title: Requirements
---

- A web API using one of the supported API types:
  - REST API
  - SOAP
  - GraphQL
  - Form bodies, JSON, or XML
- An API specification in one of the following formats:
  - [OpenAPI v2 or v3 Specification](enabling_the_analyzer.md#openapi-specification)
  - [GraphQL Schema](enabling_the_analyzer.md#graphql-schema)
  - [HTTP Archive (HAR)](enabling_the_analyzer.md#http-archive-har)
  - [Postman Collection v2.0 or v2.1](enabling_the_analyzer.md#postman-collection)
- [GitLab Runner](../../../../ci/runners/_index.md) available, with the
  [`docker` executor](https://docs.gitlab.com/runner/executors/docker.html) on Linux/amd64.
- Target application deployed. For more details, read [Deployment options](#application-deployment-options).
- `fuzz` stage added to the CI/CD pipeline definition. This should be added after the deploy step, for example:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - fuzz
  ```

## Recommendations

- Configure runners to use the [always pull policy](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy) to run the latest versions of the analyzers.
- By default, API Fuzzing downloads all artifacts defined by previous jobs in the pipeline. If your
  API Fuzzing job does not rely on `environment_url.txt` to define the URL under test or any other
  files created in previous jobs, you should not download artifacts. To avoid downloading artifacts,
  extend the analyzer CI/CD job to specify no dependencies. For example, for the API fuzzing
  analyzer, add the following to your `.gitlab-ci.yml` file:

  ```yaml
  apifuzzer_fuzz:
    dependencies: []
  ```

## Application deployment options

API Fuzzing requires a deployed application to be available to scan.

Depending on the complexity of the target application, there are a few options as to how to deploy and configure
the API Fuzzing template.

### Review apps

Review apps are the most involved method of deploying your API Fuzzing target application. To assist in the process,
we created a Review App deployment using Google Kubernetes Engine (GKE). This example can be found in our
[Review apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) project, along with detailed
instructions in the [README.md](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md)
on how to configure review apps for DAST.

### Docker Services

If your application uses Docker containers you have another option for deploying and scanning with API Fuzzing.
After your Docker build job completes and your image is added to your container registry, you can use the image as a
[service](../../../../ci/services/_index.md).

By using service definitions in your `.gitlab-ci.yml`, you can scan services with the DAST analyzer.

When adding a `services` section to the job, the `alias` is used to define the hostname that can be used to access the service. In the following example, the `alias: yourapp` portion of the `dast` job definition means that the URL to the deployed application uses `yourapp` as the hostname (`https://yourapp/`).

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
