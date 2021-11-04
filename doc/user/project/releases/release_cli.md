---
type: reference, howto
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install the `release-cli` for the Shell executor

> - [Introduced](https://gitlab.com/gitlab-org/release-cli/-/issues/21) in GitLab 13.8.
> - [Changed](https://gitlab.com/gitlab-org/release-cli/-/merge_requests/108) in GitLab 14.2, the `release-cli` binaries are also [available in the Package Registry](https://gitlab.com/jaime/release-cli/-/packages).

When you use a runner with the Shell executor, you can download and install
the `release-cli` manually for your [supported OS and architecture](https://release-cli-downloads.s3.amazonaws.com/latest/index.html).
Once installed, [the `release` keyword](../../../ci/yaml/index.md#release) is available to use in your CI/CD jobs.

## Install on Unix/Linux

1. Download the binary for your system from S3, in the following example for amd64 systems:

   ```shell
   curl --location --output /usr/local/bin/release-cli "https://release-cli-downloads.s3.amazonaws.com/latest/release-cli-linux-amd64"
   ```

   Or from the GitLab Package Registry:

   ```shell
   curl --location --output /usr/local/bin/release-cli "https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/release-cli-darwin-amd64"
   ```

1. Give it permissions to execute:

   ```shell
   sudo chmod +x /usr/local/bin/release-cli
   ```

1. Verify `release-cli` is available:

   ```shell
   $ release-cli -v

   release-cli version 0.6.0
   ```

## Install on Windows PowerShell

1. Create a folder somewhere in your system, for example `C:\GitLab\Release-CLI\bin`

   ```shell
   New-Item -Path 'C:\GitLab\Release-CLI\bin' -ItemType Directory
   ```

1. Download the executable file:

   ```shell
   PS C:\> Invoke-WebRequest -Uri "https://release-cli-downloads.s3.amazonaws.com/latest/release-cli-windows-amd64.exe" -OutFile "C:\GitLab\Release-CLI\bin\release-cli.exe"

       Directory: C:\GitLab\Release-CLI
   Mode                LastWriteTime         Length Name
   ----                -------------         ------ ----
   d-----        3/16/2021   4:17 AM                bin
   ```

1. Add the directory to your `$env:PATH`:

   ```shell
   $env:PATH += ";C:\GitLab\Release-CLI\bin"
   ```

1. Verify `release-cli` is available:

   ```shell
   PS C:\> release-cli -v

   release-cli version 0.6.0
   ```
