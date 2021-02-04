---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Windows Development

There are times in development where a Windows development machine is needed.
This is a guide for how to get a Windows development virtual machine on Google Cloud Platform
(GCP) with the same preinstalled tools as the GitLab shared Windows runners.

## Why Windows in Google Cloud?

Use of Microsoft Windows operating systems on company laptops is banned under the GitLab [Approved Operating Systems policy](https://about.gitlab.com/handbook/security/approved_os.html#windows).

This can make it difficult to develop features for the Windows platforms. Using GCP allows us to have a temporary Windows machine that can be removed once we're done with it.

## Shared Windows runners

You can use the shared Windows runners in the case that you don't need a full Windows development machine.
The [GitLab 12.7 Release Post](https://about.gitlab.com/releases/2020/01/22/gitlab-12-7-released/#windows-shared-runners-on-gitlabcom-beta)
and [Windows shared runner beta blog post](https://about.gitlab.com/blog/2020/01/21/windows-shared-runner-beta/#getting-started) both
outline quite a bit of useful information.

To use the shared Windows runners add the following `tags` to relevant jobs in your `.gitlab-ci.yml` file:

```yaml
tags:
  - shared-windows
  - windows
  - windows-1809
```

A list of software preinstalled on the Windows images is available at: [Preinstalled software](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/blob/master/cookbooks/preinstalled-software/README.md).

## GCP Windows image for development

The [shared Windows GitLab
runners](https://about.gitlab.com/releases/2020/01/22/gitlab-12-7-released/#windows-shared-runners-on-gitlabcom-beta)
are built with [Packer](https://www.packer.io/).

The Infrastructure as Code repository for building the Google Cloud images is available at:
[GitLab Google Cloud Platform Shared Runner Images](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers).

### Build image

There is a chance that your Google Cloud group may already have an image
built. Search the available images before you do the work to build your
own.

Build a Google Cloud image with the above shared runners repository by doing the following:

1. Install [Packer](https://www.packer.io/) (tested to work with version 1.5.1).
1. Install Packer Windows Update Provisioner.
   1. Clone the repository <https://github.com/rgl/packer-provisioner-windows-update> and `cd` into the cloned directory.
   1. Run the command `go build -o packer-provisioner-windows-update` (requires `go` to be installed).
   1. Verify `packer-provisioner-windows-update` is in the `PATH` environment variable.
1. Add all [required environment variables](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/master/packer.json#L2-10)
   in the `packer.json` file to your environment (perhaps use [`direnv`](https://direnv.net/)).
1. Build the image by running the command: `packer build packer.json`.

## How to use a Windows image in GCP

1. In a web browser, go to the [Google Cloud Platform console](https://console.cloud.google.com/compute/images).
1. Filter images by the name you used when creating image, `windows` is likely all you need to filter by.
1. Click the image's name.
1. Click the **CREATE INSTANCE** link.
1. Important: Change name to what you'd like as you can't change it later.
1. Optional: Change Region to be closest to you as well as any other option you'd like.
1. Click **Create** at the bottom of the page.
1. Click the name of your newly created VM Instance (optionally you can filter to find it).
1. Click **Set Windows password**.
1. Optional: Set a username or use default.
1. Click **Next**.
1. Copy and save the password as it is not shown again.
1. Click **RDP** down arrow.
1. Click **Download the RDP file**.
1. Open the downloaded RDP file with the Windows remote desktop app (<https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-clients>).
1. Click **Continue** to accept the certificate.
1. Enter the password and click **Next**.

You should now be connected into a Windows machine with a command prompt.

### Optional: Use GCP VM Instance as a runner

- Register the runner with a project: `gitlab-runner.exe register`.
- Install the runner:`gitlab-runner.exe install`.
- Start the runner: `gitlab-runner.exe start`.

For more information, see [Install GitLab Runner on Windows](https://docs.gitlab.com/runner/install/windows.html)
and [Registering runners](https://docs.gitlab.com/runner/register/index.html).

## Developer tips

Here are a few tips on GCP and Windows.

### GCP cost savings

To minimize the cost of your GCP VM instance, stop it when you're not using it.
If you do, you must download the RDP file again from the console as the IP
address changes every time you stop and start it.

### chocolatey

Chocolatey is a package manager for Windows. You can search for packages on <https://chocolatey.org/>.

- `choco install vim`

### Visual Studio (install / usage for full GUI)

You can install Visual Studio and run it within the Windows Remote Desktop app.

Install it by running: `choco install visualstudio2019community`

Start it by running: `"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" .`

### .NET 3 support

You can install .NET version 3 support with the following `DISM` command:

`DISM /Online /Enable-Feature /FeatureName:NetFx3 /All`

### nix -> Windows `cmd` tips

The first tip for using the Windows command shell is to open PowerShell and use that instead.

Start PowerShell: `start powershell`.

PowerShell has aliases for all of the following commands so you don't have to learn the native commands:

- `ls` ---> `dir`
- `rm` ---> `del`
- `rm -rf nonemptydir` ---> `rmdir /S nonemptydir`
- `/` ---> `\` (path separator)
- `cat` ---> `type`
- `mv` ---> `move`
- Redirection works the same (i.e. `>` and `2>&1`)
- `.\some.exe` to call a local executable
- curl is available
- `..` and `.` are available
