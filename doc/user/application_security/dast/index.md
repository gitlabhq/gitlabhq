---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
---

# Dynamic Application Security Testing (DAST) **(ULTIMATE)**

If you deploy your web application into a new environment, your application may
become exposed to new types of attacks. For example, misconfigurations of your
application server or incorrect assumptions about security controls may not be
visible from the source code.

Dynamic Application Security Testing (DAST) examines applications for
vulnerabilities like these in deployed environments.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Dynamic Application Security Testing (DAST)](https://www.youtube.com/watch?v=nbeDUoLZJTo).

NOTE:
To learn how four of the top six attacks were application-based and how
to protect your organization, download our
["A Seismic Shift in Application Security"](https://about.gitlab.com/resources/whitepaper-seismic-shift-application-security/)
whitepaper.

## GitLab DAST

GitLab provides the following DAST analyzers, one or more of which may be useful depending on the kind of application you're testing.

For scanning websites, use one of:

- The [DAST proxy-based analyzer](proxy-based.md) for scanning traditional applications serving simple HTML. The proxy-based analyzer can be run automatically or on-demand.
- The [DAST browser-based analyzer](browser_based.md) for scanning applications that make heavy use of JavaScript. This includes single page web applications.

For scanning APIs, use:

- The [DAST API analyzer](../dast_api/index.md) for scanning web APIs. Web API technologies such as GraphQL, REST, and SOAP are supported.

Analyzers follow the architectural patterns described in [Secure your application](../index.md).
Each analyzer can be configured in the pipeline using a CI template and runs the scan in a Docker container. Scans output a [DAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast)
which GitLab uses to determine discovered vulnerabilities based on differences between scan results on the source and target branches.

### Getting started

#### Prerequisites

- [GitLab Runner](../../../ci/runners/index.md) available, with the
  [`docker` executor](https://docs.gitlab.com/runner/executors/docker.html) on Linux/amd64.
- Target application deployed. For more details, read [Deployment options](#application-deployment-options).
- `dast` stage added to the CI/CD pipeline definition. This should be added after the deploy step, for example:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - dast
  ```

#### Recommendations

- Take care if your pipeline is configured to deploy to the same web server in each run. Running a DAST scan while a server is being updated leads to inaccurate and non-deterministic results.
- Configure runners to use the [always pull policy](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy) to run the latest versions of the analyzers.
- By default, DAST downloads all artifacts defined by previous jobs in the pipeline. If
  your DAST job does not rely on `environment_url.txt` to define the URL under test or any other files created
  in previous jobs, we recommend you don't download artifacts. To avoid downloading
  artifacts, extend the analyzer CI/CD job to specify no dependencies. For example, for the DAST proxy-based analyzer add the following to your `.gitlab-ci.yml` file:

  ```yaml
  dast:
    dependencies: []
  ```

#### Analyzer configuration

See [DAST proxy-based analyzer](proxy-based.md), [DAST browser-based analyzer](browser_based.md) or [DAST API analyzer](../dast_api/index.md) for
analyzer-specific configuration instructions.

### View scan results

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36332) in GitLab 13.1.

Detected vulnerabilities are shown in [Merge requests](../index.md#view-security-scan-information-in-merge-requests), the [Pipeline security tab](../index.md#view-security-scan-information-in-the-pipeline-security-tab),
and the [Vulnerability report](../index.md#view-security-scan-information-in-the-vulnerability-report).

1. To see all vulnerabilities detected, either:
    - From your project, select **Security & Compliance**, then **Vulnerability report**.
    - From your pipeline, select the **Security** tab.
    - From the merge request, go to the **Security scanning** widget and select **Full report** tab.

1. Select a DAST vulnerability's description. The following fields are examples of what a DAST analyzer may produce to aid investigation and rectification of the underlying cause. Each analyzer may output different fields.

   | Field            | Description                                                                                                                                                                   |
   |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------ |
   | Description      | Description of the vulnerability.                                                                                                                                             |
   | Evidence         | Evidence of the data found that verified the vulnerability. Often a snippet of the request or response, this can be used to help verify that the finding is a vulnerability.  |
   | Identifiers      | Identifiers of the vulnerability.                                                                                                                                             |
   | Links            | Links to further details of the detected vulnerability.                                                                                                                       |
   | Method           | HTTP method used to detect the vulnerability.                                                                                                                                 |
   | Project          | Namespace and project in which the vulnerability was detected.                                                                                                                |
   | Request Headers  | Headers of the request.                                                                                                                                                       |
   | Response Headers | Headers of the response received from the application.                                                                                                                        |
   | Response Status  | Response status received from the application.                                                                                                                                |
   | Scanner Type     | Type of vulnerability report.                                                                                                                                                 |
   | Severity         | Severity of the vulnerability.                                                                                                                                                |
   | Solution         | Details of a recommended solution to the vulnerability.                                                                                                                       |
   | URL              | URL at which the vulnerability was detected.                                                                                                                                  |

NOTE:
A pipeline may consist of multiple jobs, including SAST and DAST scanning. If any job
fails to finish for any reason, the security dashboard doesn't show DAST scanner output. For
example, if the DAST job finishes but the SAST job fails, the security dashboard doesn't show DAST
results. On failure, the analyzer outputs an
[exit code](../../../development/integrations/secure.md#exit-code).

#### List URLs scanned

When DAST completes scanning, the merge request page states the number of URLs scanned.
Select **View details** to view the web console output which includes the list of scanned URLs.

![DAST Widget](img/dast_urls_scanned_v12_10.png)

### Application deployment options

DAST requires a deployed application to be available to scan.

Depending on the complexity of the target application, there are a few options as to how to deploy and configure
the DAST template. A set of example applications have been provided with their configurations in the
[DAST demonstrations](https://gitlab.com/gitlab-org/security-products/demos/dast/) project.

#### Review Apps

Review Apps are the most involved method of deploying your DAST target application. To assist in the process,
we created a Review App deployment using Google Kubernetes Engine (GKE). This example can be found in our
[Review Apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) project, along with detailed
instructions in the [README.md](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md)
on how to configure Review Apps for DAST.

#### Docker Services

If your application uses Docker containers you have another option for deploying and scanning with DAST.
After your Docker build job completes and your image is added to your container registry, you can use the image as a
[service](../../../ci/services/index.md).

By using service definitions in your `.gitlab-ci.yml`, you can scan services with the DAST analyzer.

When adding a `services` section to the job, the `alias` is used to define the hostname that can be used to access the service. In the following example, the `alias: yourapp` portion of the `dast` job definition means that the URL to the deployed application uses `yourapp` as the hostname (`https://yourapp/`).

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

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

dast:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  DAST_WEBSITE: https://yourapp
  DAST_FULL_SCAN_ENABLED: "true" # do a full scan
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
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
