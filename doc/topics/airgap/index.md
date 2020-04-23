# Offline GitLab

Computers in an offline environment are isolated from the public internet as a security measure. This
page lists all the information available for running GitLab in an offline environment.

## Quick start

If you plan to deploy a GitLab instance on a physically-isolated and offline network, see the
[quick start guide](quick_start_guide.md) for configuration steps.

## Features

Follow these best practices to use GitLab's features in an offline environment:

- [Operating the GitLab Secure scanners in an offline environment](../../user/application_security/offline_deployments/index.md).

## Loading Docker images onto your offline host

To use many GitLab features, including
[security scans](../../user/application_security/index.md#working-in-an-offline-environment)
and [Auto DevOps](../autodevops/), the GitLab Runner must be able to fetch the
relevant Docker images.

The process for making these images available without direct access to the public internet
involves downloading the images then packaging and transferring them to the offline host. Here's an
example of such a transfer:

1. Download Docker images from public internet.
1. Package Docker images as tar archives.
1. Transfer images to offline environment.
1. Load transferred images into offline Docker registry.

### Using the official GitLab template

GitLab provides a [vendored template](../../ci/yaml/README.md#includetemplate)
to ease this process.

This template should be used in a new, empty project, with a `gitlab-ci.yml` file containing:

```yaml
include:
  - template: Secure-Binaries.gitlab-ci.yml
```

The pipeline downloads the Docker images needed for the Security Scanners and saves them as
[job artifacts](../../ci/pipelines/job_artifacts.md) or pushes them to the [Container Registry](../../user/packages/container_registry/index.md)
of the project where the pipeline is executed. These archives can be transferred to another location
and [loaded](https://docs.docker.com/engine/reference/commandline/load/) in a Docker daemon.
This method requires a GitLab Runner with access to both `gitlab.com` (including
`registry.gitlab.com`) and the local offline instance. This runner must run in
[privileged mode](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode)
to be able to use the `docker` command inside the jobs. This runner can be installed in a DMZ or on
a bastion, and used only for this specific project.

#### Scheduling the updates

By default, this project's pipeline will run only once, when the `.gitlab-ci.yml` is added to the
repo. To update the GitLab security scanners and signatures, it's necessary to run this pipeline
regularly. GitLab provides a way to [schedule pipelines](../../ci/pipelines/schedules.md). For
example, you can set this up to download and store the Docker images every week.

Some images can be updated more frequently than others. For example, the [vulnerability database](https://hub.docker.com/r/arminc/clair-db/tags)
for Container Scanning is updated daily. To update this single image, create a new Scheduled
Pipeline that runs daily and set `SECURE_BINARIES_ANALYZERS` to `clair-vulnerabilities-db`. Only
this job will be triggered, and the image will be updated daily and made available in the project
registry.

#### Using the secure bundle created

The project using the `Secure-Binaries.gitlab-ci.yml` template should now host all the required
images and resources needed to run GitLab Security features.

The next step is to tell the offline instance to use these resources instead of the default ones on
`gitlab.com`. This can be done by setting the right environment variables:
`SAST_ANALYZER_IMAGE_PREFIX` for SAST analyzers, `DS_ANALYZER_IMAGE_PREFIX` for Dependency Scanning,
and so on.

You can set these variables in the project's `.gitlab-ci.yml` files by using the bundle directly, or
in the GitLab UI at the project or group level. See the [GitLab CI/CD environment variables page](../../ci/variables/README.md#creating-a-custom-environment-variable)
for more information.

#### Variables

The following table shows which variables you can use with the `Secure-Binaries.gitlab-ci.yml`
template:

| VARIABLE                                  | Description                                   | Default value                     |
|-------------------------------------------|-----------------------------------------------|-----------------------------------|
| `SECURE_BINARIES_ANALYZERS`               | Comma-separated list of analyzers to download | `"bandit, brakeman, gosec, and so on..."` |
| `SECURE_BINARIES_DOWNLOAD_IMAGES`         | Used to disable jobs                          | `"true"`                          |
| `SECURE_BINARIES_PUSH_IMAGES`             | Push files to the project registry            | `"true"`                          |
| `SECURE_BINARIES_SAVE_ARTIFACTS`          | Also save image archives as artifacts         | `"false"`                         |
| `SECURE_BINARIES_ANALYZER_VERSION`        | Default analyzer version (docker tag)         | `"2"`                             |

### Alternate way without the official template

If it's not possible to follow the above method, the images can be transferred manually instead:

#### Example image packager script

```sh
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

```sh
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
