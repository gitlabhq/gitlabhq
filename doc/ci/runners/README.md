---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Runners

In GitLab CI/CD, runners run the code defined in [`.gitlab-ci.yml`](../yaml/README.md).
A runner is a lightweight, highly-scalable agent that picks up a CI job through
the coordinator API of GitLab CI/CD, runs the job, and sends the result back to the GitLab instance.

If you are using GitLab SaaS (GitLab.com), your CI jobs automatically run on shared runners. No configuration is required.

If you are using self-managed GitLab or you want to use your own runners on GitLab.com, you can
[install and configure your own runners](https://docs.gitlab.com/runner/install/).

## Runners on GitLab.com

On GitLab.com, your jobs can run on [Linux](#linux-shared-runners) or [Windows](#windows-shared-runners-beta).

### Linux shared runners

Linux shared runners on GitLab.com run in autoscale mode and are powered by Google Cloud Platform.

Autoscaling means reduced queue times to spin up CI/CD jobs, and isolated VMs for each project, thus maximizing security. These shared runners are available for users and customers on GitLab.com.

GitLab offers Ultimate tier capabilities and included CI/CD minutes per group per month for our [Open Source](https://about.gitlab.com/solutions/open-source/join/), [Education](https://about.gitlab.com/solutions/education/), and [Startups](https://about.gitlab.com/solutions/startups/) programs. For private projects, GitLab offers various [plans](https://about.gitlab.com/pricing/), starting with a Free tier.

All your CI/CD jobs run on [n1-standard-1 instances](https://cloud.google.com/compute/docs/machine-types) with 3.75GB of RAM, CoreOS and the latest Docker Engine
installed. Instances provide 1 vCPU and 25GB of HDD disk space. The default
region of the VMs is US East1.
Each instance is used only for one job, this ensures any sensitive data left on the system can't be accessed by other people their CI jobs.

The `gitlab-shared-runners-manager-X.gitlab.com` fleet of runners are dedicated for GitLab projects as well as community forks of them. They use a slightly larger machine type (n1-standard-2) and have a bigger SSD disk size. They don't run untagged jobs and unlike the general fleet of shared runners, the instances are re-used up to 40 times.

Jobs handled by the shared runners on GitLab.com (`shared-runners-manager-X.gitlab.com`),
**time out after 3 hours**, regardless of the timeout configured in a
project. Check the issues [4010](https://gitlab.com/gitlab-com/infrastructure/-/issues/4010) and [4070](https://gitlab.com/gitlab-com/infrastructure/-/issues/4070) for the reference.

Below are the shared runners settings.

| Setting                               | GitLab.com                                        | Default    |
| -----------                           | -----------------                                 | ---------- |
| [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) | [Runner versions dashboard](https://dashboards.gitlab.com/d/000000159/ci?from=now-1h&to=now&refresh=5m&orgId=1&panelId=12&fullscreen&theme=light) | - |
| Executor                              | `docker+machine`                                  | -          |
| Default Docker image                  | `ruby:2.5`                                        | -          |
| `privileged` (run [Docker in Docker](https://hub.docker.com/_/docker/)) | `true`          | `false`    |

#### Pre-clone script

Linux shared runners on GitLab.com provide a way to run commands in a CI
job before the runner attempts to run `git init` and `git fetch` to
download a GitLab repository. The
[`pre_clone_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
can be used for:

- Seeding the build directory with repository data
- Sending a request to a server
- Downloading assets from a CDN
- Any other commands that must run before the `git init`

To use this feature, define a [CI/CD variable](../../ci/variables/README.md#custom-cicd-variables) called
`CI_PRE_CLONE_SCRIPT` that contains a bash script.

[This example](../../development/pipelines.md#pre-clone-step)
demonstrates how you might use a pre-clone step to seed the build
directory.

#### `config.toml`

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
    image = "ruby:2.5"
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

### Windows shared runners (beta)

The Windows shared runners are in [beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta)
and shouldn't be used for production workloads.

During this beta period, the [shared runner pipeline quota](../../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota)
applies for groups and projects in the same manner as Linux runners. This may
change when the beta period ends, as discussed in this [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30834).

Windows shared runners on GitLab.com autoscale by launching virtual machines on
the Google Cloud Platform. This solution uses an
[autoscaling driver](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/tree/master/docs/readme.md)
developed by GitLab for the [custom executor](https://docs.gitlab.com/runner/executors/custom.html).
Windows shared runners execute your CI/CD jobs on `n1-standard-2` instances with
2 vCPUs and 7.5 GB RAM. You can find a full list of available Windows packages in
the [package documentation](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/blob/master/cookbooks/preinstalled-software/README.md).

We want to keep iterating to get Windows shared runners in a stable state and
[generally available](https://about.gitlab.com/handbook/product/gitlab-the-product/#generally-available-ga).
You can follow our work towards this goal in the
[related epic](https://gitlab.com/groups/gitlab-org/-/epics/2162).

#### Configuration

The full contents of our `config.toml` are:

NOTE:
Settings that aren't public are shown as `X`.

```toml
concurrent = X
check_interval = 3

[[runners]]
  name = "windows-runner"
  url = "https://gitlab.com/"
  token = "TOKEN"
  executor = "custom"
  builds_dir = "C:\\GitLab-Runner\\builds"
  cache_dir = "C:\\GitLab-Runner\\cache"
  shell  = "powershell"
  [runners.custom]
    config_exec = "C:\\GitLab-Runner\\autoscaler\\autoscaler.exe"
    config_args = ["--config", "C:\\GitLab-Runner\\autoscaler\\config.toml", "custom", "config"]
    prepare_exec = "C:\\GitLab-Runner\\autoscaler\\autoscaler.exe"
    prepare_args = ["--config", "C:\\GitLab-Runner\\autoscaler\\config.toml", "custom", "prepare"]
    run_exec = "C:\\GitLab-Runner\\autoscaler\\autoscaler.exe"
    run_args = ["--config", "C:\\GitLab-Runner\\autoscaler\\config.toml", "custom", "run"]
    cleanup_exec = "C:\\GitLab-Runner\\autoscaler\\autoscaler.exe"
    cleanup_args = ["--config", "C:\\GitLab-Runner\\autoscaler\\config.toml", "custom", "cleanup"]
```

The full contents of our `autoscaler/config.toml` are:

```toml
Provider = "gcp"
Executor = "winrm"
OS = "windows"
LogLevel = "info"
LogFormat = "text"
LogFile = "C:\\GitLab-Runner\\autoscaler\\autoscaler.log"
VMTag = "windows"

[GCP]
  ServiceAccountFile = "PATH"
  Project = "some-project-df9323"
  Zone = "us-east1-c"
  MachineType = "n1-standard-2"
  Image = "IMAGE"
  DiskSize = 50
  DiskType = "pd-standard"
  Subnetwork = "default"
  Network = "default"
  Tags = ["TAGS"]
  Username = "gitlab_runner"

[WinRM]
  MaximumTimeout = 3600
  ExecutionMaxRetries = 0

[ProviderCache]
  Enabled = true
  Directory = "C:\\GitLab-Runner\\autoscaler\\machines"
```

#### Example

Below is a simple `.gitlab-ci.yml` file to show how to start using the
Windows shared runners:

```yaml
.shared_windows_runners:
  tags:
    - shared-windows
    - windows
    - windows-1809

stages:
  - build
  - test

before_script:
 - Set-Variable -Name "time" -Value (date -Format "%H:%m")
 - echo ${time}
 - echo "started by ${GITLAB_USER_NAME}"

build:
  extends:
    - .shared_windows_runners
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .shared_windows_runners
  stage: test
  script:
    - echo "running scripts in the test job"
```

#### Limitations and known issues

- All the limitations mentioned in our [beta
  definition](https://about.gitlab.com/handbook/product/#beta).
- The average provisioning time for a new Windows VM is 5 minutes.
  This means that you may notice slower build start times
  on the Windows shared runner fleet during the beta. In a future
  release we intend to update the autoscaler to enable
  the pre-provisioning of virtual machines. This is intended to significantly reduce
  the time it takes to provision a VM on the Windows fleet. You can
  follow along in the [related issue](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/issues/32).
- The Windows shared runner fleet may be unavailable occasionally
  for maintenance or updates.
- The Windows shared runner virtual machine instances do not use the
  GitLab Docker executor. This means that you can't specify
  [`image`](../../ci/yaml/README.md#image) or [`services`](../../ci/yaml/README.md#services) in
  your pipeline configuration.
- For the beta release, we have included a set of software packages in
  the base VM image. If your CI job requires additional software that's
  not included in this list, then you must add installation
  commands to [`before_script`](../../ci/yaml/README.md#before_script) or [`script`](../../ci/yaml/README.md#script) to install the required
  software. Note that each job runs on a new VM instance, so the
  installation of additional software packages needs to be repeated for
  each job in your pipeline.
- The job may stay in a pending state for longer than the
  Linux shared runners.
- There is the possibility that we introduce breaking changes which will
  require updates to pipelines that are using the Windows shared runner
  fleet.
