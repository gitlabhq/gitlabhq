---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Supported operating systems **(FREE SELF)**

GitLab officially supports LTS versions of operating systems. While OSs like
Ubuntu have a clear distinction between LTS and non-LTS versions, there are
other OSs, openSUSE for example, that don't follow the LTS concept. Hence to
avoid confusion, the official policy is that at any point of time, all the
operating systems supported by GitLab are listed in the [installation
page](https://about.gitlab.com/install/).

The following lists the currently supported OSs and their possible EOL dates.

| OS Version       | First supported GitLab version | Arch            | OS EOL        | Details                                                      |
| ---------------- | ------------------------------ | --------------- | ------------- | ------------------------------------------------------------ |
| AlmaLinux 8      | GitLab CE / GitLab EE 14.5.0   | x86_64, aarch64 | 2029          | <https://almalinux.org/>                                     |
| CentOS 7         | GitLab CE / GitLab EE 7.10.0   | x86_64          | June 2024     | <https://wiki.centos.org/About/Product>                      |
| CentOS 8         | GitLab CE / GitLab EE 12.8.1   | x86_64, aarch64 | Dec 2021      | <https://wiki.centos.org/About/Product>                      |
| Debian 9         | GitLab CE / GitLab EE 9.3.0    | amd64           | 2022          | <https://wiki.debian.org/LTS>                                |
| Debian 10        | GitLab CE / GitLab EE 12.2.0   | amd64, arm64    | 2024          | <https://wiki.debian.org/LTS>                                |
| Debian 11        | GitLab CE / GitLab EE 14.6.0   | amd64, arm64    | 2026          | <https://wiki.debian.org/LTS>                                |
| OpenSUSE 15.3    | GitLab CE / GitLab EE 14.5.0   | x86_64, aarch64 | Nov 2022      | <https://en.opensuse.org/Lifetime>                           |
| SLES 12          | GitLab EE 9.0.0                | x86_64          | Oct 2027      | <https://www.suse.com/lifecycle/>                            |
| Ubuntu 18.04     | GitLab CE / GitLab EE 10.7.0   | amd64           | April 2023    | <https://wiki.ubuntu.com/Releases>                           |
| Ubuntu 20.04     | GitLab CE / GitLab EE 13.2.0   | amd64, arm64    | April 2025    | <https://wiki.ubuntu.com/Releases>                           |
| Raspbian Buster  | GitLab CE 12.2.0               | armhf           | 2022          | <https://wiki.debian.org/DebianReleases#Production_Releases> |

NOTE:
CentOS 8 will be EOL on December 31, 2021. In GitLab 14.5 and later,
[CentOS builds work in AlmaLinux](https://gitlab.com/gitlab-org/distribution/team-tasks/-/issues/954#note_730198505).
We will officially support all distributions that are binary compatible with Red Hat Enterprise Linux.
This gives users a path forward for their CentOS 8 builds at its end of life.

## Update GitLab package sources after upgrading the OS

After upgrading the Operating System (OS) as per its own documentation,
it may be necessary to also update the GitLab package source URL
in your package manager configuration.
If your package manager reports that no further updates are available,
although [new versions have been released](https://about.gitlab.com/releases/categories/releases/), repeat the
"Add the GitLab package repository" instructions
of the [Linux package install guide](https://about.gitlab.com/install/#content).
Future GitLab upgrades will now be fetched according to your upgraded OS.

## Packages for ARM64

> [Introduced](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/issues/27) in GitLab 13.4.

GitLab provides arm64/aarch64 packages for some supported operating systems.
You can see if your operating system architecture is supported in the table
above.

WARNING:
There are currently still some [known issues and limitation](https://gitlab.com/groups/gitlab-org/-/epics/4397)
running GitLab on ARM.

## OS Versions that are no longer supported

GitLab provides omnibus packages for operating systems only until their
EOL (End-Of-Life). After the EOL date of the OS, GitLab will stop releasing
official packages. The list of deprecated operating systems and the final GitLab
release for them can be found below:

| OS Version      | End Of Life                                                                        | Last supported GitLab version                                                                                                                                                                                                      |
| --------------- | ---------------------------------------------------------------------------------- | -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Raspbian Wheezy | [May 2015](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_8.17&dist=debian%2Fwheezy) 8.17                                                                                                                |
| OpenSUSE 13.2   | [January 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.1&dist=opensuse%2F13.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.1&dist=opensuse%2F13.2) 9.1          |
| Ubuntu 12.04    | [April 2017](https://ubuntu.com/info/release-end-of-life)                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_9.1&dist=ubuntu%2Fprecise) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_9.1&dist=ubuntu%2Fprecise) 9.1        |
| OpenSUSE 42.1   | [May 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.3&dist=opensuse%2F42.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.3&dist=opensuse%2F42.1) 9.3          |
| OpenSUSE 42.2   | [January 2018](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-10.4&dist=opensuse%2F42.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-10.4&dist=opensuse%2F42.2) 10.4       |
| Debian Wheezy   | [May 2018](https://www.debian.org/News/2018/20180601)                              | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.6&dist=debian%2Fwheezy) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.6&dist=debian%2Fwheezy) 11.6       |
| Raspbian Jessie | [May 2017](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_11.7&dist=debian%2Fjessie) 11.7                                                                                                                |
| Ubuntu 14.04    | [April 2019](https://ubuntu.com/info/release-end-of-life)                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.10&dist=ubuntu%2Ftrusty) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.10&dist=ubuntu%2Ftrusty) 11.10    |
| OpenSUSE 42.3   | [July 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.1&dist=opensuse%2F42.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.1&dist=opensuse%2F42.3) 12.1       |
| OpenSUSE 15.0   | [December 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.5&dist=opensuse%2F15.0) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.5&dist=opensuse%2F15.0) 12.5       |
| Raspbian Stretch | [June 2020](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.2&dist=raspbian%2Fstretch) 13.3                                                                                                           |
| Debian Jessie   | [June 2020](https://www.debian.org/News/2020/20200709)                             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.2&dist=debian%2Fjessie) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.2&dist=debian%2Fjessie) 13.3       |
| CentOS 6        | [November 2020](https://wiki.centos.org/About/Product)                             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=13.6&filter=all&filter=all&dist=el%2F6) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=13.6&filter=all&filter=all&dist=el%2F6) 13.6 |
| OpenSUSE 15.1   | [November 2020](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-13.12&dist=opensuse%2F15.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-13.12&dist=opensuse%2F15.1) 13.12    |
| Ubuntu 16.04    | [April 2021](https://ubuntu.com/info/release-end-of-life)                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.12&dist=ubuntu%2Fxenial) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.12&dist=ubuntu%2Fxenial) 13.12    |
| OpenSUSE 15.2   | [December 2021](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-14.7&dist=opensuse%2F15.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-14.7&dist=opensuse%2F15.2) 14.7       |

NOTE:
An exception to this deprecation policy is when we are unable to provide
packages for the next version of the operating system. The most common reason
for this our package repository provider, PackageCloud, not supporting newer
versions and hence we can't upload packages to it.
