---
type: reference, howto
---

# Container Scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3672)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.4.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can check your Docker
images (or more precisely the containers) for known vulnerabilities by using
[Clair](https://github.com/coreos/clair) and [clair-scanner](https://github.com/arminc/clair-scanner),
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
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html#running-privileged-containers-for-the-runners)
  executor running in privileged mode. If you're using the shared Runners on GitLab.com,
  this is enabled by default.
- Docker `18.09.03` or higher installed on the machine where the Runners are
  running. If you're using the shared Runners on GitLab.com, this is already
  the case.
- To [build and push](../../../ci/docker/using_docker_build.md#container-registry-examples)
  your Docker image to your project's [Container Registry](../../project/container_registry.md).
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
[`Container-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml)
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
   [Container Registry](../../project/container_registry.md) (see [requirements](#requirements))
   and scan it for possible vulnerabilities.

The results will be saved as a
[Container Scanning report artifact](../../../ci/yaml/README.md#artifactsreportscontainer_scanning-ultimate)
that you can later download and analyze.
Due to implementation limitations, we always take the latest Container Scanning
artifact available. Behind the scenes, the
[GitLab Container Scanning analyzer](https://gitlab.com/gitlab-org/security-products/container-scanning)
is used and runs the scans.

If you want to whitelist some specific vulnerabilities, you can do so by defining
them in a YAML file named `clair-whitelist.yml`. Read more in the
[Clair documentation](https://github.com/arminc/clair-scanner/blob/master/README.md#example-whitelist-yaml-file).

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

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups and projects. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

## Vulnerabilities database update

For more information about the vulnerabilities database update, check the
[maintenance table](../index.md#maintenance-and-update-of-the-vulnerabilities-database).

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
[issue #10241](https://gitlab.com/gitlab-org/gitlab-ee/issues/10241 "Investigate why Container Scanning is not working with NFS mounts").