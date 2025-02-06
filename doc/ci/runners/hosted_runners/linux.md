---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hosted runners on Linux
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

Hosted runners on Linux for GitLab.com run on Google Cloud Compute Engine. Each job gets a fully isolated, ephemeral virtual machine (VM). The default region is `us-east1`.

Each VM uses the Google Container-Optimized OS (COS) and the latest version of Docker Engine running the `docker+machine`
[executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor).
The machine type and underlying processor type might change. Jobs optimized for a specific processor design might behave inconsistently.

[Untagged](../../yaml/_index.md#tags) jobs will run on the `small` Linux x86-64 runner.

## Machine types available for Linux - x86-64

GitLab offers the following machine types for hosted runners on Linux x86-64.

| Runner Tag                                             | vCPUs | Memory | Storage |
|--------------------------------------------------------|-------|--------|---------|
| `saas-linux-small-amd64` (default)                     | 2     | 8 GB   | 30 GB   |
| `saas-linux-medium-amd64`                              | 4     | 16 GB  | 50 GB   |
| `saas-linux-large-amd64` (Premium and Ultimate only)   | 8     | 32 GB  | 100 GB  |
| `saas-linux-xlarge-amd64` (Premium and Ultimate only)  | 16    | 64 GB  | 200 GB  |
| `saas-linux-2xlarge-amd64` (Premium and Ultimate only) | 32    | 128 GB | 200 GB  |

## Machine types available for Linux - Arm64

GitLab offers the following machine type for hosted runners on Linux Arm64.

| Runner Tag                                            | vCPUs | Memory | Storage |
|-------------------------------------------------------|-------|--------|---------|
| `saas-linux-small-arm64`                              | 2     | 8 GB   | 30 GB   |
| `saas-linux-medium-arm64` (Premium and Ultimate only) | 4     | 16 GB  | 50 GB   |
| `saas-linux-large-arm64` (Premium and Ultimate only)  | 8     | 32 GB  | 100 GB  |

NOTE:
Users can experience network connectivity issues when they use Docker-in-Docker with hosted runners on Linux
Arm. This issue occurs when the maximum transmission unit (MTU) value in Google Cloud and Docker don't match.
To resolve this issue, set `--mtu=1400` in the client side Docker configuration.
For more details, see [issue 473739](https://gitlab.com/gitlab-org/gitlab/-/issues/473739#workaround).

## Container images

As runners on Linux are using the `docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor),
you can choose any container image by defining the [`image`](../../yaml/_index.md#image) in your `.gitlab-ci.yml` file.
Please be mindful that the selected Docker image is compatible with the underlying processor architecture.

If no image is set, the default is `ruby:3.1`.

## Docker-in-Docker support

Runners with any of the `saas-linux-<size>-<architecture>` tags are configured to run in `privileged` mode
to support [Docker-in-Docker](../../docker/using_docker_build.md#use-docker-in-docker).
With these runners, you can build Docker images natively or run multiple containers in your isolated job.

Runners with the `gitlab-org` tag do not run in `privileged` mode and cannot be used for Docker-in-Docker builds.

## Example `.gitlab-ci.yml` file

To use a machine type other than `small`, add a `tags:` keyword to your job.
For example:

```yaml
job_small:
  script:
    - echo "This job is untagged and runs on the default small Linux x86-64 instance"

job_medium:
  tags:
    - saas-linux-medium-amd64
  script:
    - echo "This job runs on the medium Linux x86-64 instance"

job_large:
  tags:
    - saas-linux-large-arm64
  script:
    - echo "This job runs on the large Linux Arm64 instance"
```
