---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Release CLI tool
---

WARNING:
**The `release-cli` is in maintenance mode**.
The `release-cli` does not accept new features.
All new feature development happens in the `glab` CLI,
so you should use the [`glab` CLI](../../../editor_extensions/gitlab_cli/_index.md) whenever possible.
The `release-cli` is in maintenance mode, and [issue cli#7450](https://gitlab.com/gitlab-org/cli/-/issues/7450) proposes to deprecate it as the `glab` CLI matures.

The [GitLab Release CLI (`release-cli`)](https://gitlab.com/gitlab-org/release-cli)
is a command-line tool for managing releases from the command line or from a CI/CD pipeline.
You can use the release CLI to create, update, modify, and delete releases.

When you [use a CI/CD job to create a release](_index.md#creating-a-release-by-using-a-cicd-job),
the `release` keyword entries are transformed into Bash commands and sent to the Docker
container containing the `release-cli` tool. The tool then creates the release.

You can also call the `release-cli` tool directly from a [`script`](../../../ci/yaml/_index.md#script).
For example:

```shell
release-cli create --name "Release $CI_COMMIT_SHA" --description \
  "Created using the release-cli $EXTRA_DESCRIPTION" \
  --tag-name "v${MAJOR}.${MINOR}.${REVISION}" --ref "$CI_COMMIT_SHA" \
  --released-at "2020-07-15T08:00:00Z" --milestone "m1" --milestone "m2" --milestone "m3" \
  --assets-link "{\"name\":\"asset1\",\"url\":\"https://example.com/assets/1\",\"link_type\":\"other\"}"
```

## Install the `release-cli` for the Shell executor

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The `release-cli` binaries are [available in the package registry](https://gitlab.com/gitlab-org/release-cli/-/packages).

When you use a runner with the Shell executor, you can download and install
the `release-cli` manually for your [supported OS and architecture](https://gitlab.com/gitlab-org/release-cli/-/packages).
Once installed, [the `release` keyword](../../../ci/yaml/_index.md#release) is available to use in your CI/CD jobs.

### Install on Unix/Linux

1. Download the binary for your system from the GitLab package registry.
   For example, if you use an amd64 system:

   ```shell
   curl --location --output /usr/local/bin/release-cli "https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/release-cli-linux-amd64"
   ```

1. Give it permissions to execute:

   ```shell
   sudo chmod +x /usr/local/bin/release-cli
   ```

1. Verify `release-cli` is available:

   ```shell
   $ release-cli -v

   release-cli version 0.15.0
   ```

### Install on Windows PowerShell

1. Create a folder somewhere in your system, for example `C:\GitLab\Release-CLI\bin`

   ```shell
   New-Item -Path 'C:\GitLab\Release-CLI\bin' -ItemType Directory
   ```

1. Download the executable file:

   ```shell
   PS C:\> Invoke-WebRequest -Uri "https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/release-cli-windows-amd64.exe" -OutFile "C:\GitLab\Release-CLI\bin\release-cli.exe"

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

   release-cli version 0.15.0
   ```
