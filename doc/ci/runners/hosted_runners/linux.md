---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Hosted runners on Linux

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

When you run jobs on hosted runners on Linux, the runners are on auto-scaled ephemeral virtual machine (VM) instances.
The default region for the VMs is `us-east1`.

Each VM uses the Google Container-Optimized OS (COS) and the latest version of Docker Engine running the `docker+machine`
[executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor).

## Machine types available for Linux (x86-64)

For the hosted runners on Linux, GitLab offers a range of machine types for use.
For Free, Premium, and Ultimate plan customers, jobs on these instances consume the compute quota allocated to your namespace.

| Runner Tag                                    | vCPUs | Memory | Storage |
|-----------------------------------------------|-------|--------|---------|
| `saas-linux-small-amd64`                      | 2     | 8 GB   | 25 GB   |
| `saas-linux-medium-amd64`                     | 4     | 16 GB  | 50 GB   |
| `saas-linux-large-amd64` (Premium and Ultimate only)  | 8     | 32 GB  | 100 GB  |
| `saas-linux-xlarge-amd64` (Premium and Ultimate only) | 16    | 64 GB  | 200 GB  |
| `saas-linux-2xlarge-amd64` (Premium and Ultimate only) | 32    | 128 GB | 200 GB  |

The `small` machine type is set as default. If no [tag](../../yaml/index.md#tags) keyword in your `.gitlab-ci.yml` file is specified,
the jobs will run on this default runner.

There are [different rates of compute minutes consumption](../../pipelines/cicd_minutes.md#gitlab-hosted-runner-costs), based on the type of machine that is used.

All hosted runners on Linux currently run on
[`n2d-standard`](https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machines) general-purpose compute from GCP.
The machine type and underlying processor type can change. Jobs optimized for a specific processor design could behave inconsistently.

## Container images

As runners on Linux are using the `docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor),
you can choose any container image by defining the [`image`](../../../ci/yaml/index.md#image) in your `.gitlab-ci.yml` file.

If no image is set, the default is `ruby:3.1`.

## Docker in Docker support

The runners are configured to run in `privileged` mode to support
[Docker in Docker](../../../ci/docker/using_docker_build.md#use-docker-in-docker)
to build Docker images natively or run multiple containers within your isolated job.

## Caching on hosted runners

The hosted runners share a [distributed cache](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)
stored in a Google Cloud Storage (GCS) bucket. Cache contents not updated in the last 14 days are automatically
removed, based on the [object lifecycle management policy](https://cloud.google.com/storage/docs/lifecycle).
The maximum size of an uploaded cache artifact can be 5 GB after the cache becomes a compressed archive.

For more information about how caching works, see [Caching in GitLab CI/CD](../../caching/index.md).

## Example `.gitlab-ci.yml` file

To use a machine type other than `small`, add a `tags:` keyword to your job.
For example:

```yaml
job_small:
  script:
    - echo "this job runs on the default (small) Linux instance"

job_medium:
  tags:
    - saas-linux-medium-amd64
  script:
    - echo "this job runs on the medium Linux instance"

job_large:
  tags:
    - saas-linux-large-amd64
  script:
    - echo "this job runs on the large Linux instance"
```

## Hosted runners for GitLab community contributions

If you want to [contribute to GitLab](https://about.gitlab.com/community/contribute/), jobs will be picked up by the
`gitlab-shared-runners-manager-X.gitlab.com` fleet of runners, dedicated for GitLab projects and related community forks.

These runners are backed by the same machine type as our `small` runners.
Unlike the most commonly used hosted runners on Linux, each virtual machine is re-used up to 40 times.

As we want to encourage people to contribute, these runners are free of charge.

## Pre-clone script (deprecated)

This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/391896) in GitLab 15.9
and [will be removed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29405) in 17.0.
Use [`pre_get_sources_script`](../../../ci/yaml/index.md#hookspre_get_sources_script) instead.
