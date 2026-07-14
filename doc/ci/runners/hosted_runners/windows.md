---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Hosted runners on Windows
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

Hosted runners on Windows autoscale by launching virtual machines on
the Google Cloud Platform. This solution uses an
[autoscaling driver](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/blob/main/docs/README.md)
developed by GitLab for the [custom executor](https://docs.gitlab.com/runner/executors/custom/).
Hosted runners on Windows are in [beta](../../../policy/development_stages_support.md#beta).

GitLab keeps iterating to get Windows runners in a stable state and
[generally available](../../../policy/development_stages_support.md#generally-available).
You can follow the work towards this goal in the
[related epic](https://gitlab.com/groups/gitlab-org/-/epics/2162).

## Machine types available for Windows

GitLab offers the following machine type for hosted runners on Windows.

| Runner Tag                  | vCPUs | Memory | Storage |
| --------------------------- | ----- | ------ | ------- |
| `saas-windows-medium-amd64` | 2     | 7.5 GB | 75 GB   |

## Supported Windows versions

The Windows runner virtual machine instances do not use the GitLab Docker executor. This means that you can't specify
[`image`](../../yaml/_index.md#image) or [`services`](../../yaml/_index.md#services) in your pipeline configuration.

The latest Docker version is installed when the image build runs and you can use literal Docker commands in shell runner jobs.

You can execute your job in one of the following Windows versions:

| Version      | Status |
|--------------|--------|
| Windows 2022 | `GA`   |

## Available runtimes

The following files list the available pre-installed software:

- [Chocolatey](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/chocolatey/recipes/default.rb), which you can use to perform additional installs.
- [Git, Git LFS, and GitLab Runner](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/tree/main/cookbooks/gitlab-runner-dependencies/recipes)
- Pre-installed development tools:
  - [Docker](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/recipes/docker.rb)
  - [.NET Core SDK 3.1, Ruby, Go, Nodejs, OpenJDK, Python3](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/recipes/languages.rb)
  - [7-Zip, wget, curl, jq, Docker Compose, NuGet CLI, cmake, GitLab CLI (glab)](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/recipes/utils.rb)
  - [Visual C Runtimes](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/recipes/vcpkg.rb). See linked file for version.
  - [Visual Studio Build Tools](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/recipes/visual-studio-build-tools.rb). See linked file for version.

## .NET runtimes

The installed .NET Core SDK version and the specific version of Visual Studio Build Tools
together determine the pre-installed .NET runtime versions.

The following code runs on a schedule in
[PowerShell Pipelines on GitLab CI](https://gitlab.com/guided-explorations/microsoft/powershell/powershell-pipelines-on-gitlab-ci/-/pipeline)
and produces this example list:

For all three runtimes (`Microsoft.AspNetCore.App`, `Microsoft.NETCore.App`, `Microsoft.WindowsDesktop.App`), the available versions are:

- 3.1.32
- 8.0.24
- 9.0.13

.NET Framework is version 4.8.04161.

To discover the current state, run the following code or look at a recent log of
[PowerShell Pipelines on GitLab CI](https://gitlab.com/guided-explorations/microsoft/powershell/powershell-pipelines-on-gitlab-ci/-/pipeline):

```powershell

Write-Host "=== Modern .NET (Core 3.1, 5, 6, 7, 8+) runtimes ===" -ForegroundColor Cyan
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    dotnet --list-runtimes
} else {
    Write-Host "Not present"
}

Write-Host "`n=== .NET Framework versions ===" -ForegroundColor Cyan
$ndp = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP"
if (Test-Path $ndp) {
    $found = Get-ChildItem $ndp -Recurse |
        Get-ItemProperty -Name Version, Release -ErrorAction SilentlyContinue |
        Where-Object { $_.Version -and $_.PSChildName -notmatch '^S' } |
        Select-Object @{n='Component';e={$_.PSChildName}}, Version, Release |
        Sort-Object Version -Unique
    if ($found) { $found } else { Write-Host "Not present" }
} else {
    Write-Host "Not present"
}
```

## Docker runtimes

The latest Docker version is installed when the image build runs and you can use literal Docker commands in shell runner jobs.

To discover versions, run the following code or look at pipelines from
[PowerShell Pipelines on GitLab CI](https://gitlab.com/guided-explorations/microsoft/powershell/powershell-pipelines-on-gitlab-ci/-/pipeline):

```powershell
      write-host "Docker client and service version:"
      docker version
```

## Supported shell

Hosted runners on Windows have PowerShell configured as the shell.
The `script` section of your `.gitlab-ci.yml` file therefore requires PowerShell commands.

## Elevated permissions

Hosted runners on Windows for GitLab.com run CI/CD jobs as an elevated admin 
process. This process lets you install additional software or configure the OS 
before job execution.
This permission level is acceptable because the runner creates a new VM for each individual
job and discards it after the job completes. This process is essentially the same
as how container jobs work for security and disposal.

## Example `.gitlab-ci.yml` file

Use this example `.gitlab-ci.yml` file to get started with hosted runners on Windows:

```yaml
.windows_job:
  tags:
    - saas-windows-medium-amd64
  before_script:
    - Set-Variable -Name "time" -Value (date -Format "%H:%m")
    - echo ${time}
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

build:
  extends:
    - .windows_job
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .windows_job
  stage: test
  script:
    - echo "running scripts in the test job"
```

## Known issues

- For more information about support for beta features, see [beta](../../../policy/development_stages_support.md#beta).
- The average provisioning time for a new Windows virtual machine (VM) is five minutes, so
  you might notice slower start times for builds on the Windows runner
  fleet during the beta. Updating the autoscaler to enable the pre-provisioning
  of virtual machines is proposed in a future release. This update is intended to
  significantly reduce the time it takes to provision a VM on the Windows fleet.
  For more information, see [issue 32](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/issues/32).
- The Windows runner fleet may be unavailable occasionally
  for maintenance or updates.
- The job may stay in a pending state for longer than the
  Linux runners.
- There is the possibility that we introduce breaking changes which will
  require updates to pipelines that are using the Windows runner
  fleet.
