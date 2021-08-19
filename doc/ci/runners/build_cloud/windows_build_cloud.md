---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Build Cloud runners for Windows (beta)

GitLab Build Cloud runners for Windows are in [beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta)
and shouldn't be used for production workloads.

During this beta period, the [shared runner pipeline quota](../../../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota)
applies for groups and projects in the same manner as Linux runners. This may
change when the beta period ends, as discussed in this [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30834).

Windows runners on GitLab.com autoscale by launching virtual machines on
the Google Cloud Platform. This solution uses an
[autoscaling driver](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/tree/master/docs/readme.md)
developed by GitLab for the [custom executor](https://docs.gitlab.com/runner/executors/custom.html).
Windows runners execute your CI/CD jobs on `n1-standard-2` instances with
2 vCPUs and 7.5 GB RAM. You can find a full list of available Windows packages in
the [package documentation](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/blob/master/cookbooks/preinstalled-software/README.md).

We want to keep iterating to get Windows runners in a stable state and
[generally available](https://about.gitlab.com/handbook/product/gitlab-the-product/#generally-available-ga).
You can follow our work towards this goal in the
[related epic](https://gitlab.com/groups/gitlab-org/-/epics/2162).

## Configuration

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

## Example `.gitlab-ci.yml` file

Below is a sample `.gitlab-ci.yml` file that shows how to start using the runners for Windows:

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

## Limitations and known issues

- All the limitations mentioned in our [beta
  definition](https://about.gitlab.com/handbook/product/#beta).
- The average provisioning time for a new Windows VM is 5 minutes.
  This means that you may notice slower build start times
  on the Windows runner fleet during the beta. In a future
  release we intend to update the autoscaler to enable
  the pre-provisioning of virtual machines. This is intended to significantly reduce
  the time it takes to provision a VM on the Windows fleet. You can
  follow along in the [related issue](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/issues/32).
- The Windows runner fleet may be unavailable occasionally
  for maintenance or updates.
- The Windows runner virtual machine instances do not use the
  GitLab Docker executor. This means that you can't specify
  [`image`](../../../ci/yaml/index.md#image) or [`services`](../../../ci/yaml/index.md#services) in
  your pipeline configuration.
- For the beta release, we have included a set of software packages in
  the base VM image. If your CI job requires additional software that's
  not included in this list, then you must add installation
  commands to [`before_script`](../../../ci/yaml/index.md#before_script) or [`script`](../../../ci/yaml/index.md#script) to install the required
  software. Note that each job runs on a new VM instance, so the
  installation of additional software packages needs to be repeated for
  each job in your pipeline.
- The job may stay in a pending state for longer than the
  Linux runners.
- There is the possibility that we introduce breaking changes which will
  require updates to pipelines that are using the Windows runner
  fleet.
