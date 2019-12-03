---
type: reference, howto
---

# Container Scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/3672)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.4.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can check your Docker
images (or more precisely the containers) for known vulnerabilities by using
[Clair](https://github.com/coreos/clair) and [klar](https://github.com/optiopay/klar),
two open source tools for Vulnerability Static Analysis for containers.

You can take advantage of Container Scanning by either [including the CI job](#configuration) in
your existing `.gitlab-ci.yml` file or by implicitly using
[Auto Container Scanning](../../../topics/autodevops/index.md#auto-container-scanning-ultimate)
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
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html)
  executor.
- Docker `18.09.03` or higher installed on the machine where the Runners are
  running. If you're using the shared Runners on GitLab.com, this is already
  the case.
- To [build and push](../../../ci/docker/using_docker_build.md#container-registry-examples)
  your Docker image to your project's [Container Registry](../../packages/container_registry/index.md).
  The name of the Docker image should match the following scheme:

  ```text
  $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  ```

  The variables above can be found in the
  [predefined environment variables](../../../ci/variables/predefined_variables.md)
  document.

## Configuration

For GitLab 11.9 and later, to enable Container Scanning, you must
[include](../../../ci/yaml/README.md#includetemplate) the
[`Container-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml)
that's provided as a part of your GitLab installation.
For GitLab versions earlier than 11.9, you can copy and use the job as defined
in that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  template: Container-Scanning.gitlab-ci.yml
```

The included template will:

1. Create a `container_scanning` job in your CI/CD pipeline.
1. Pull the already built Docker image from your project's
   [Container Registry](../../packages/container_registry/index.md) (see [requirements](#requirements))
   and scan it for possible vulnerabilities.

The results will be saved as a
[Container Scanning report artifact](../../../ci/yaml/README.md#artifactsreportscontainer_scanning-ultimate)
that you can later download and analyze.
Due to implementation limitations, we always take the latest Container Scanning
artifact available. Behind the scenes, the
[GitLab Klar analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/klar/)
is used and runs the scans.

## Example

The following is a sample `.gitlab-ci.yml` that will build your Docker Image, push it to the container registry and run Container Scanning.

```yaml
variables:
  DOCKER_DRIVER: overlay2

services:
  - docker:stable-dind

stages:
  - build
  - test

include:
  - template: Container-Scanning.gitlab-ci.yml

build:
  image: docker:stable
  stage: build
  variables:
    IMAGE: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  script:
    - docker info
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

## Vulnerability Whitelisting

If you want to whitelist specific vulnerabilities, you'll need to:

   1. Set `GIT_STRATEGY: fetch` in your `.gitlab-ci.yml` file by following the instructions described in the
   [overriding the Container Scanning template](#overriding-the-container-scanning-template) section of this document.
   1. Define the whitelisted vulnerabilities in a YAML file named `clair-whitelist.yml` which must use the format described
   in the [following whitelist example file](https://github.com/arminc/clair-scanner/blob/v12/example-whitelist.yaml).
   1. Add the `clair-whitelist.yml` file to the Git repository of your project

### Overriding the Container Scanning template

If you want to override the job definition (for example, change properties like
`variables`), you need to declare a `container_scanning` job after the
template inclusion and specify any additional keys under it. For example:

```yaml
include:
  - template: Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

### Available variables

Container Scanning can be [configured](#overriding-the-container-scanning-template)
using environment variables.

| Environment Variable           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Default                                  |
| ------                         | ------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | ------                                   |
| `KLAR_TRACE`                   | Set to true to enable more verbose output from klar.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `"false"`                                |
| `DOCKER_USER`                  | Username for accessing a Docker registry requiring authentication.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `$CI_REGISTRY_USER`                      |
| `DOCKER_PASSWORD`              | Password for accessing a Docker registry requiring authentication.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `$CI_REGISTRY_PASSWORD`                  |
| `CLAIR_OUTPUT`                 | Severity level threshold. Vulnerabilities with severity level higher than or equal to this threshold will be outputted. Supported levels are `Unknown`, `Negligible`, `Low`, `Medium`, `High`, `Critical` and `Defcon1`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `Unknown`                                |
| `REGISTRY_INSECURE`            | Allow [Klar](https://github.com/optiopay/klar) to access insecure registries (HTTP only). Should only be set to `true` when testing the image locally.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `"false"`                                |
| `CLAIR_VULNERABILITIES_DB_URL` | This variable is explicitly set in the [services section](https://gitlab.com/gitlab-org/gitlab/blob/30522ca8b901223ac8c32b633d8d67f340b159c1/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml#L17-19) of the `Container-Scanning.gitlab-ci.yml` file and defaults to `clair-vulnerabilities-db`.  This value represents the address that the [postgres server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db) is running on and **shouldn't be changed** unless you're running the image locally as described in the [Running the scanning tool](https://gitlab.com/gitlab-org/security-products/analyzers/klar/#running-the-scanning-tool) section of the [GitLab klar analyzer readme](https://gitlab.com/gitlab-org/security-products/analyzers/klar). | `clair-vulnerabilities-db`               |
| `CI_APPLICATION_REPOSITORY`    | Docker repository URL for the image to be scanned.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` |
| `CI_APPLICATION_TAG`           | Docker respository tag for the image to be scanned.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `$CI_COMMIT_SHA`                         |
| `CLAIR_DB_IMAGE`               | The Docker image name and tag for the [postgres server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db). It can be useful to override this value with a specific version, for example, to provide a consistent set of vulnerabilities for integration testing purposes, or to refer to a locally hosted vulnerabilities database for an on-premise air-gapped installation.                                                                                                                                                                                                                                                                                                                                                                                                 | `arminc/clair-db:latest`                 |
| `CLAIR_DB_IMAGE_TAG`           | (**DEPRECATED - use `CLAIR_DB_IMAGE` instead**) The Docker image tag for the [postgres server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db). It can be useful to override this value with a specific version, for example, to provide a consistent set of vulnerabilities for integration testing purposes.                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `latest`                                 |

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups, projects and pipelines. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

## Vulnerabilities database update

For more information about the vulnerabilities database update, check the
[maintenance table](../index.md#maintenance-and-update-of-the-vulnerabilities-database).

## Running Container Scanning in an offline air-gapped installation

Container Scanning can be executed on an offline air-gapped GitLab Ultimate installation using the following process:

1. Host the following Docker images on a [local Docker container registry](../../packages/container_registry/index.md):
   - [arminc/clair-db vulnerabilities database](https://hub.docker.com/r/arminc/clair-db)
   - [GitLab klar analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/klar)
1. [Override the container scanning template](#overriding-the-container-scanning-template) in your `.gitlab-ci.yml` file to refer to the Docker images hosted on your local Docker container registry:

   ```yaml
   include:
     - template: Container-Scanning.gitlab-ci.yml

   container_scanning:
     image: $CI_REGISTRY/namespace/gitlab-klar-analyzer
     variables:
       CLAIR_DB_IMAGE: $CI_REGISTRY/namespace/clair-vulnerabilities-db
   ```

It may be worthwhile to set up a [scheduled pipeline](../../project/pipelines/schedules.md) to automatically build a new version of the vulnerabilities database on a preset schedule.  You can use the following `.gitlab-yml.ci` as a template:

```yaml
image: docker:stable

services:
  - docker:stable-dind

stages:
  - build

build_latest_vulnerabilities:
  stage: build
  script:
    - docker pull arminc/clair-db:latest
    - docker tag arminc/clair-db:latest $CI_REGISTRY/namespace/clair-vulnerabilities-db
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker push $CI_REGISTRY/namespace/clair-vulnerabilities-db
```

The above template will work for a GitLab Docker registry running on a local installation, however, if you're using a non-GitLab Docker registry, you'll need to change the `$CI_REGISTRY` value and the `docker login` credentials to match the details of your local registry.

## Troubleshooting

### docker: Error response from daemon: failed to copy xattrs

When the GitLab Runner uses the Docker executor and NFS is used
(e.g., `/var/lib/docker` is on an NFS mount), Container Scanning might fail with
an error like the following:

```text
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

This is a result of a bug in Docker which is now [fixed](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt").
To prevent the error, ensure the Docker version that the Runner is using is
`18.09.03` or higher. For more information, see
[issue #10241](https://gitlab.com/gitlab-org/gitlab/issues/10241 "Investigate why Container Scanning is not working with NFS mounts").
