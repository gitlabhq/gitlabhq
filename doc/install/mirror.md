---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Mirror GitLab Linux package repositories
title: Linux package repository mirroring
---

GitLab and GitLab Runner Linux packages are available at
<https://packages.gitlab.com>. This document explains how to
maintain a local mirror of these repositories.

## Mirroring APT repositories

A local mirror of an `apt` repository can be created using the `apt-mirror` tool.

1. Install `apt-mirror`

   ```shell
   sudo apt install apt-mirror
   ```

1. Create a directory for the mirror

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. Add the following lines to the `apt-mirror` configuration file present at `/etc/apt/mirror.list`

   ```shell
   set base_path /srv/gitlab-repo-mirror
   ```

   The mirrored content is written under
   `/srv/gitlab-repo-mirror/mirror/packages.gitlab.com`.

   Check the [upstream example config file](https://github.com/apt-mirror/apt-mirror/blob/master/mirror.list)
   for other available settings.

1. At the end of the configuration file, specify the repositories to mirror in
   the `apt` sources file URL format.

   > [!note]
   > The repository structure differs between GitLab and GitLab Runner.
   >
   > ### GitLab
   >
   > GitLab uses the same version strings for packages across OS distributions (with
   > different content). That means these packages are considered
   > [Duplicate Packages as per Debian Repository Format](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages).
   >
   > To work around this, each OS distribution (like Debian Trixie or Ubuntu
   > Focal) gets a dedicated repository that hosts only that distribution. This
   > results in URLs having an extra distribution component.
   >
   > ### GitLab Runner
   >
   > GitLab Runner is a statically linked Go binary and uses the same package for
   > different OS distributions. It uses a single apt repository per OS and hosts
   > all distributions of that OS within that repository.

   {{< tabs >}}

   {{< tab title="GitLab" >}}

   ```plaintext
   deb https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   deb-src https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   ```

   {{< /tab >}}

   {{< tab title="GitLab Runner" >}}

   ```plaintext
   deb https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   deb-src https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Start the mirror process

   ```shell
   sudo apt-mirror
   ```

## Mirroring RPM repositories

A local mirror of an `rpm` repository can be created using `reposync` (to
download packages) and `createrepo` (to generate metadata).

> [!note]
> `reposync` expects the repository you want to mirror to be installed on the
> system. Follow [the installation docs](package/_index.md#supported-platforms)
> for the repository you want to mirror.
>
> To find the repository ID, list available repositories with:
>
> ```shell
> yum repolist
> ```

1. Install `createrepo` and `reposync`

   ```shell
   sudo yum install createrepo yum-utils
   ```

1. Create a directory for the mirror

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. Run `reposync`. Pass the repository ID and output directory as arguments.

   ```shell
   reposync --repoid=gitlab_gitlab-ee --download-path=/srv/gitlab-repo-mirror
   ```

1. Generate metadata for the repository using `createrepo`

   ```shell
   createrepo -o /srv/gitlab-repo-mirror /srv/gitlab-repo-mirror
   ```
