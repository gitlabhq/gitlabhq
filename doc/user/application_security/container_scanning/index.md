# Container Scanning **[ULTIMATE]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3672)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.4.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can check your Docker
images (or more precisely the containers) for known vulnerabilities by using
[Clair](https://github.com/coreos/clair) and [clair-scanner](https://github.com/arminc/clair-scanner),
two open source tools for Vulnerability Static Analysis for containers.

You can take advantage of Container Scanning by either [including the CI job](#including-the-provided-template) in
your existing `.gitlab-ci.yml` file or by implicitly using
[Auto Container Scanning](../../../topics/autodevops/index.md#auto-container-scanning)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the Container Scanning report, compares the found vulnerabilities
between the source and target branches, and shows the information right on the
merge request.

![Container Scanning Widget](img/container_scanning.png)

## Use cases

If you distribute your application with Docker, then there's a great chance
that your image is based on other Docker images that may in turn contain some
known vulnerabilities that could be exploited.

Having an extra job in your pipeline that checks for those vulnerabilities,
and the fact that they are displayed inside a merge request, makes it very easy
to perform audits for your Docker-based apps.

## Requirements

To enable Container Scanning in your pipeline, you need:

- A GitLab Runner with the
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html#running-privileged-containers-for-the-runners)
  executor running in privileged mode. If you're using the shared Runners on GitLab.com,
  this is enabled by default.
- To [build and push](../../../ci/docker/using_docker_build.md#container-registry-examples)
  your Docker image to your project's [Container Registry](../../project/container_registry.md).
  The name of the Docker image should match the following scheme:

  ```
  $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  ```

  The variables above can be found in the
  [predefined environment variables](../../../ci/variables/predefined_variables.md)
  document.

## Configuring Container Scanning

To enable Container Scanning in your project, define a job in your
`.gitlab-ci.yml` file that generates the
[Container Scanning report artifact](../../../ci/yaml/README.md#artifactsreportscontainer_scanning-ultimate).

This can be done in two ways:

- For GitLab 11.9 and later, including the provided
  `Container-Scanning.gitlab-ci.yml` template (recommended).
- Manually specifying the job definition. Not recommended unless using GitLab
  11.8 and earlier.

### Including the provided template

NOTE: **Note:**
The CI/CD Container Scanning template is supported on GitLab 11.9 and later versions.
For earlier versions, use the [manual job definition](#manual-job-definition-for-gitlab-115-and-later).

A CI/CD [Container Scanning template](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml)
with the default Container Scanning job definition is provided as a part of your GitLab
installation that you can [include](../../../ci/yaml/README.md#includetemplate)
in your `.gitlab-ci.yml` file.

To enable Container Scanning using the provided template, add the following to
your `.gitlab-ci.yml` file:

```yaml
include:
  template: Container-Scanning.gitlab-ci.yml
```

The included template will:

- Create a `container_scanning` job in your CI/CD pipeline.
- Pull the already built Docker image from your project's
  [Container Registry](../../project/container_registry.md) (see [requirements](#requirements))
  and scan it for possible vulnerabilities.

The report will be saved as a
[Container Scanning report artifact](../../../ci/yaml/README.md#artifactsreportscontainer_scanning-ultimate)
that you can later download and analyze.
Due to implementation limitations, we always take the latest Container Scanning
artifact available. Behind the scenes, the
[GitLab Container Scanning analyzer](https://gitlab.com/gitlab-org/security-products/container-scanning)
is used and runs the scans.

If you want to whitelist some specific vulnerabilities, you can do so by defining
them in a YAML file named `clair-whitelist.yml`. Read more in the
[Clair documentation](https://github.com/arminc/clair-scanner/blob/master/README.md#example-whitelist-yaml-file).

### Manual job definition for GitLab 11.5 and later

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions.
However, if you're using GitLab 11.9+, it's recommended to use
[the provided Container Scanning template](#including-the-provided-template).

For GitLab 11.5 and GitLab Runner 11.5 and later, the following `container_scanning`
job can be added:

```yaml
container_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
    ## Define two new variables based on GitLab's CI/CD predefined variables
    ## https://docs.gitlab.com/ee/ci/variables/README.html#predefined-environment-variables
    CI_APPLICATION_REPOSITORY: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
    CI_APPLICATION_TAG: $CI_COMMIT_SHA
    CLAIR_LOCAL_SCAN_VERSION: v2.0.8_fe9b059d930314b54c78f75afe265955faf4fdc1
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - docker run -d --name db arminc/clair-db:latest
    - docker run -p 6060:6060 --link db:postgres -d --name clair --restart on-failure arminc/clair-local-scan:${CLAIR_LOCAL_SCAN_VERSION}
    - apk add -U wget ca-certificates
    - docker pull ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG}
    - wget https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
    - mv clair-scanner_linux_amd64 clair-scanner
    - chmod +x clair-scanner
    - touch clair-whitelist.yml
    - while( ! wget -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; done
    - retries=0
    - echo "Waiting for clair daemon to start"
    - while( ! wget -T 10 -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; echo -n "." ; if [ $retries -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; retries=$(($retries+1)) ; done
    - ./clair-scanner -c http://docker:6060 --ip $(hostname -i) -r gl-container-scanning-report.json -l clair.log -w clair-whitelist.yml ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG} || true
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
```

### Manual job definition for GitLab 11.4 and earlier (deprecated)

CAUTION: **Deprecated:**
Before GitLab 11.5, the Container Scanning job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained, they have been deprecated
and may be removed in the next major release, GitLab 12.0. You are strongly
advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the Container Scanning job should look like:

```yaml
container_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
    ## Define two new variables based on GitLab's CI/CD predefined variables
    ## https://docs.gitlab.com/ee/ci/variables/README.html#predefined-environment-variables
    CI_APPLICATION_REPOSITORY: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
    CI_APPLICATION_TAG: $CI_COMMIT_SHA
    CLAIR_LOCAL_SCAN_VERSION: v2.0.8_fe9b059d930314b54c78f75afe265955faf4fdc1
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - docker run -d --name db arminc/clair-db:latest
    - docker run -p 6060:6060 --link db:postgres -d --name clair --restart on-failure arminc/clair-local-scan:${CLAIR_LOCAL_SCAN_VERSION}
    - apk add -U wget ca-certificates
    - docker pull ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG}
    - wget https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
    - mv clair-scanner_linux_amd64 clair-scanner
    - chmod +x clair-scanner
    - touch clair-whitelist.yml
    - while( ! wget -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; done
    - retries=0
    - echo "Waiting for clair daemon to start"
    - while( ! wget -T 10 -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; echo -n "." ; if [ $retries -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; retries=$(($retries+1)) ; done
    - ./clair-scanner -c http://docker:6060 --ip $(hostname -i) -r gl-container-scanning-report.json -l clair.log -w clair-whitelist.yml ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG} || true
  artifacts:
    paths: [gl-container-scanning-report.json]
```

Alternatively, the job name could be `sast:container`
and the artifact name could be `gl-sast-container-report.json`.
These names have been deprecated with GitLab 11.0
and may be removed in the next major release, GitLab 12.0.

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups and projects. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).
