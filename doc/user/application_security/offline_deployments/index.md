---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Offline environments **(ULTIMATE SELF)**

It's possible to run most of the GitLab security scanners when not connected to the internet.

This document describes how to operate Secure Categories (that is, scanner types) in an offline
environment. These instructions also apply to self-managed installations that are secured, have
security policies (for example, firewall policies), or are otherwise restricted from accessing the
full internet. GitLab refers to these environments as _offline environments_. Other common names
include:

- Air-gapped environments
- Limited connectivity environments
- Local area network (LAN) environments
- Intranet environments

These environments have physical barriers or security policies (for example, firewalls) that prevent
or limit internet access. These instructions are designed for physically disconnected networks, but
can also be followed in these other use cases.

## Defining offline environments

In an offline environment, the GitLab instance can be one or more servers and services that can
communicate on a local network, but with no or very restricted access to the internet. Assume
anything within the GitLab instance and supporting infrastructure (for example, a private Maven
repository) can be accessed through a local network connection. Assume any files from the internet
must come in through physical media (USB drive, hard drive, writeable DVD, etc.).

## Overview

GitLab scanners usually connect to the internet to download the
latest sets of signatures, rules, and patches. A few extra steps are necessary
to configure the tools to function properly by using resources available on your local network.

### Container registries and package repositories

At a high-level, the security analyzers are delivered as Docker images and
may leverage various package repositories. When you run a job on
an internet-connected GitLab installation, GitLab checks the GitLab.com-hosted
container registry to check that you have the latest versions of these Docker images
and possibly connect to package repositories to install necessary dependencies.

In an offline environment, these checks must be disabled so that GitLab.com isn't
queried. Because the GitLab.com registry and repositories are not available,
you must update each of the scanners to either reference a different,
internally-hosted registry or provide access to the individual scanner images.

You must also ensure that your app has access to common package repositories
that are not hosted on GitLab.com, such as npm, yarn, or Ruby gems. Packages
from these repositories can be obtained by temporarily connecting to a network or by
mirroring the packages inside your own offline network.

### Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[address the vulnerabilities](../vulnerabilities/index.md).

Please note that in some cases the reported vulnerabilities provide metadata that can contain
external links exposed in the UI. These links might not be accessible within an offline environment.

### Resolving vulnerabilities

The [resolving vulnerabilities](../vulnerabilities/index.md#resolve-a-vulnerability) feature is available for offline Dependency Scanning and Container Scanning, but may not work
depending on your instance's configuration. We can only suggest solutions, which are generally more
current versions that have been patched, when we are able to access up-to-date registry services
hosting the latest versions of that dependency or image.

### Scanner signature and rule updates

When connected to the internet, some scanners reference public databases
for the latest sets of signatures and rules to check against. Without connectivity,
this is not possible. Depending on the scanner, you must therefore disable
these automatic update checks and either use the databases that they came
with and manually update those databases or provide access to your own copies
hosted within your network.

## Specific scanner instructions

Each individual scanner may be slightly different than the steps described
above. You can find more information at each of the pages below:

- [Container scanning offline directions](../container_scanning/index.md#running-container-scanning-in-an-offline-environment)
- [SAST offline directions](../sast/index.md#running-sast-in-an-offline-environment)
- [DAST offline directions](../dast/index.md#running-dast-in-an-offline-environment)
- [License Compliance offline directions](../../compliance/license_compliance/index.md#running-license-compliance-in-an-offline-environment)
- [Dependency Scanning offline directions](../dependency_scanning/index.md#running-dependency-scanning-in-an-offline-environment)

## Loading Docker images onto your offline host

To use many GitLab features, including security scans
and [Auto DevOps](../../../topics/autodevops/index.md), the runner must be able to fetch the
relevant Docker images.

The process for making these images available without direct access to the public internet
involves downloading the images then packaging and transferring them to the offline host. Here's an
example of such a transfer:

1. Download Docker images from public internet.
1. Package Docker images as tar archives.
1. Transfer images to offline environment.
1. Load transferred images into offline Docker registry.

### Using the official GitLab template

GitLab provides a [vendored template](../../../ci/yaml/index.md#includetemplate)
to ease this process.

This template should be used in a new, empty project, with a `gitlab-ci.yml` file containing:

```yaml
include:
  - template: Secure-Binaries.gitlab-ci.yml
```

The pipeline downloads the Docker images needed for the Security Scanners and saves them as
[job artifacts](../../../ci/pipelines/job_artifacts.md) or pushes them to the [Container Registry](../../packages/container_registry/index.md)
of the project where the pipeline is executed. These archives can be transferred to another location
and [loaded](https://docs.docker.com/engine/reference/commandline/load/) in a Docker daemon.
This method requires a runner with access to both `gitlab.com` (including
`registry.gitlab.com`) and the local offline instance. This runner must run in
[privileged mode](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode)
to be able to use the `docker` command inside the jobs. This runner can be installed in a DMZ or on
a bastion, and used only for this specific project.

WARNING:
This template does not include updates for the container scanning analyzer. Please see
[Container scanning offline directions](../container_scanning/index.md#running-container-scanning-in-an-offline-environment).

#### Scheduling the updates

By default, this project's pipeline runs only once, when the `.gitlab-ci.yml` is added to the
repository. To update the GitLab security scanners and signatures, it's necessary to run this pipeline
regularly. GitLab provides a way to [schedule pipelines](../../../ci/pipelines/schedules.md). For
example, you can set this up to download and store the Docker images every week.

#### Using the secure bundle created

The project using the `Secure-Binaries.gitlab-ci.yml` template should now host all the required
images and resources needed to run GitLab Security features.

Next, you must tell the offline instance to use these resources instead of the default ones on
GitLab.com. To do so, set the CI/CD variable `SECURE_ANALYZERS_PREFIX` with the URL of the
project [container registry](../../packages/container_registry/index.md).

You can set this variable in the projects' `.gitlab-ci.yml`, or
in the GitLab UI at the project or group level. See the [GitLab CI/CD variables page](../../../ci/variables/index.md#custom-cicd-variables)
for more information.

#### Variables

The following table shows which CI/CD variables you can use with the `Secure-Binaries.gitlab-ci.yml`
template:

| CI/CD variable                            | Description                                   | Default value                     |
|-------------------------------------------|-----------------------------------------------|-----------------------------------|
| `SECURE_BINARIES_ANALYZERS`               | Comma-separated list of analyzers to download | `"bandit, brakeman, gosec, and so on..."` |
| `SECURE_BINARIES_DOWNLOAD_IMAGES`         | Used to disable jobs                          | `"true"`                          |
| `SECURE_BINARIES_PUSH_IMAGES`             | Push files to the project registry            | `"true"`                          |
| `SECURE_BINARIES_SAVE_ARTIFACTS`          | Also save image archives as artifacts         | `"false"`                         |
| `SECURE_BINARIES_ANALYZER_VERSION`        | Default analyzer version (Docker tag)         | `"2"`                             |

### Alternate way without the official template

If it's not possible to follow the above method, the images can be transferred manually instead:

#### Example image packager script

```shell
#!/bin/bash
set -ux

# Specify needed analyzer images
analyzers=${SAST_ANALYZERS:-"bandit eslint gosec"}
gitlab=registry.gitlab.com/gitlab-org/security-products/analyzers/

for i in "${analyzers[@]}"
do
  tarname="${i}_2.tar"
  docker pull $gitlab$i:2
  docker save $gitlab$i:2 -o ./analyzers/${tarname}
  chmod +r ./analyzers/${tarname}
done
```

#### Example image loader script

This example loads the images from a bastion host to an offline host. In certain configurations,
physical media may be needed for such a transfer:

```shell
#!/bin/bash
set -ux

# Specify needed analyzer images
analyzers=${SAST_ANALYZERS:-"bandit eslint gosec"}
registry=$GITLAB_HOST:4567

for i in "${analyzers[@]}"
do
  tarname="${i}_2.tar"
  scp ./analyzers/${tarname} ${GITLAB_HOST}:~/${tarname}
  ssh $GITLAB_HOST "sudo docker load -i ${tarname}"
  ssh $GITLAB_HOST "sudo docker tag $(sudo docker images | grep $i | awk '{print $3}') ${registry}/analyzers/${i}:2"
  ssh $GITLAB_HOST "sudo docker push ${registry}/analyzers/${i}:2"
done
```

### Using GitLab Secure with AutoDevOps in an offline environment

You can use GitLab AutoDevOps for Secure scans in an offline environment. However, you must first do
these steps:

1. Load the container images into the local registry. GitLab Secure leverages analyzer container
   images to do the various scans. These images must be available as part of running AutoDevOps.
   Before running AutoDevOps, follow the [above steps](#using-the-official-gitlab-template)
   to load those container images into the local container registry.

1. Set the CI/CD variable to ensure that AutoDevOps looks in the right place for those images.
   The AutoDevOps templates leverage the `SECURE_ANALYZERS_PREFIX` variable to identify the location
   of analyzer images. This variable is discussed above in [Using the secure bundle created](#using-the-secure-bundle-created).
   Ensure that you set this variable to the correct value for where you loaded the analyzer images.
   You could consider doing this with a project CI/CD variable or by [modifying](../../../topics/autodevops/customize.md#customizing-gitlab-ciyml)
   the `.gitlab-ci.yml` file directly.

Once these steps are complete, GitLab has local copies of the Secure analyzers and is set up to use
them instead of an Internet-hosted container image. This allows you to run Secure in AutoDevOps in
an offline environment.

Note that these steps are specific to GitLab Secure with AutoDevOps. Using other stages with
AutoDevOps may require other steps covered in the
[Auto DevOps documentation](../../../topics/autodevops/).
