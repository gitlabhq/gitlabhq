---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SaaS runners on Linux

When you run jobs on SaaS runners on Linux, the runners are on auto-scaled ephemeral virtual machine (VM) instances.
Each VM uses the Google Container-Optimized OS (COS) and the latest version of Docker Engine.
The default region for the VMs is `us-east1`.

## Machine types available for private projects (x86-64)

For the SaaS runners on Linux, GitLab offers a range of machine types for use in private projects.
For Free, Premium, and Ultimate plan customers, jobs on these instances consume the CI/CD minutes allocated to your namespace.

|                   | Small                     | Medium                    | Large                    |
|-------------------|---------------------------|---------------------------|--------------------------|
| Specs             | 2 vCPU, 8 GB RAM        | 4 vCPUs, 16 GB RAM          | 8 vCPUs, 32 GB RAM        |
| GitLab CI/CD tags | `saas-linux-small-amd64` | `saas-linux-medium-amd64` | `saas-linux-large-amd64` |
| Subscription      | Free, Premium, Ultimate   | Free, Premium, Ultimate   | Premium, Ultimate        |

The `small` machine type is the default. Your job runs on this machine type if you don't specify
a [tags:](../../yaml/index.md#tags) keyword in your `.gitlab-ci.yml` file.

CI/CD jobs that run on `medium` and `large` machine types consumes CI minutes at a different rate than CI/CD jobs on the `small` machine type.

Refer to the CI/CD minutes [cost factor](../../../ci/pipelines/cicd_minutes.md#cost-factor) for the cost factor applied to the machine type based on size.

## GPU-enabled SaaS runners on Linux **(PREMIUM SAAS)**

We offer GPU-enabled SaaS runners for heavy compute including ModelOps or HPC workloads. Available to Premium and Ultimate plan customers, jobs on these instances consume the CI/CD minutes allocated to your namespace.

|                   | Standard                   |
|-------------------|---------------------------|
| Specs             | 4 vCPU, 16 GB RAM, 1 Nvidia Tesla T4 GPU (or similar) |
| GitLab CI/CD tags | `saas-linux-medium-amd64-gpu-standard` |

## Example of how to tag a job

To use a machine type other than `small`, add a `tags:` keyword to your job.
For example:

```yaml
stages:
  - Prebuild
  - Build
  - Unit Test

job_001:
 stage: Prebuild
 script:
  - echo "this job runs on the default (small) instance"

job_002:
 tags: [ saas-linux-medium-amd64 ]
 stage: Build
 script:
  - echo "this job runs on the medium instance"


job_003:
 tags: [ saas-linux-large-amd64 ]
 stage: Unit Test
 script:
  - echo "this job runs on the large instance"

```

## SaaS runners for GitLab projects

The `gitlab-shared-runners-manager-X.gitlab.com` fleet of runners are dedicated for
GitLab projects and related community forks. These runners are backed by a Google Compute
`n1-standard-2` machine type and do not run untagged jobs. Unlike the machine types used
for private projects, each virtual machine is re-used up to 40 times.

## SaaS runners on Linux settings

Below are the settings for SaaS runners on Linux.

| Setting                                                                 | GitLab.com       | Default |
|-------------------------------------------------------------------------|------------------|---------|
| Executor                                                                | `docker+machine` | -       |
| Default Docker image                                                    | `ruby:3.1`       | -       |
| `privileged` (run [Docker in Docker](https://hub.docker.com/_/docker/)) | `true`           | `false` |

- **Cache**: These runners share a
  [distributed cache](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)
  that's stored in a Google Cloud Storage (GCS) bucket. Cache contents not updated in
  the last 14 days are automatically removed, based on the
  [object lifecycle management policy](https://cloud.google.com/storage/docs/lifecycle). The maximum size of an 
  uploaded cache artifact can be 5GB after the cache becomes a compressed archive.

- **Timeout settings**: Jobs handled by the SaaS Runners on Linux
  **time out after 3 hours**, regardless of the timeout configured in a
  project. For details, see issues [#4010](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/4010)
  and [#4070](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/4070).

NOTE:
Typical SaaS runner instances are provisioned with a 25 GB storage volume. GPU-enabled runners
are provisioned with a 50 GB storage volume. The underlying disk space of the storage volume
is shared by the operating system, the Docker image, and a copy of your cloned repository.
This means that the available free disk space that your jobs can use is **less than 25 (or 50) GB**.

<!--- start_remove The following content will be removed on remove_date: '2023-08-22' -->

## Pre-clone script (removed)

This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/391896) in GitLab 15.9
and [removed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29405) in 16.0.
Use [`pre_get_sources_script`](../../../ci/yaml/index.md#hookspre_get_sources_script) instead.

<!--- end_remove -->

## `config.toml`

The full contents of our `config.toml` are:

NOTE:
Settings that are not public are shown as `X`.

**Google Cloud Platform**

```toml
concurrent = X
check_interval = 1
metrics_server = "X"
sentry_dsn = "X"

[[runners]]
  name = "docker-auto-scale"
  request_concurrency = X
  url = "https://gitlab.com/"
  token = "SHARED_RUNNER_TOKEN"
  pre_clone_script = "eval \"$CI_PRE_CLONE_SCRIPT\""
  executor = "docker+machine"
  environment = [
    "DOCKER_DRIVER=overlay2",
    "DOCKER_TLS_CERTDIR="
  ]
  limit = X
  [runners.docker]
    image = "ruby:3.1"
    privileged = true
    volumes = [
      "/certs/client",
      "/dummy-sys-class-dmi-id:/sys/class/dmi/id:ro" # Make kaniko builds work on GCP.
    ]
  [runners.machine]
    IdleCount = 50
    IdleTime = 3600
    MaxBuilds = 1 # For security reasons we delete the VM after job has finished so it's not reused.
    MachineName = "srm-%s"
    MachineDriver = "google"
    MachineOptions = [
      "google-project=PROJECT",
      "google-disk-size=25",
      "google-machine-type=n1-standard-1",
      "google-username=core",
      "google-tags=gitlab-com,srm",
      "google-use-internal-ip",
      "google-zone=us-east1-d",
      "engine-opt=mtu=1460", # Set MTU for container interface, for more information check https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3214#note_82892928
      "google-machine-image=PROJECT/global/images/IMAGE",
      "engine-opt=ipv6", # This will create IPv6 interfaces in the containers.
      "engine-opt=fixed-cidr-v6=fc00::/7",
      "google-operation-backoff-initial-interval=2" # Custom flag from forked docker-machine, for more information check https://github.com/docker/machine/pull/4600
    ]
    [[runners.machine.autoscaling]]
      Periods = ["* * * * * sat,sun *"]
      Timezone = "UTC"
      IdleCount = 70
      IdleTime = 3600
    [[runners.machine.autoscaling]]
      Periods = ["* 30-59 3 * * * *", "* 0-30 4 * * * *"]
      Timezone = "UTC"
      IdleCount = 700
      IdleTime = 3600
  [runners.cache]
    Type = "gcs"
    Shared = true
    [runners.cache.gcs]
      CredentialsFile = "/path/to/file"
      BucketName = "bucket-name"
```
