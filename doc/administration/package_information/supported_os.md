---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Supported operating systems

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

GitLab officially supports LTS versions of operating systems. While OSs like
Ubuntu have a clear distinction between LTS and non-LTS versions, there are
other OSs, openSUSE for example, that don't follow the LTS concept. Hence to
avoid confusion, the official policy is that at any point of time, all the
operating systems supported by GitLab are listed in the
[installation page](https://about.gitlab.com/install/).

The following lists the currently supported OSs and their possible EOL dates.

NOTE:
`amd64` and `x86_64` refer to the same 64-bit architecture.
The names `arm64` and `aarch64` are also interchangeable and refer to the same
architecture.

| OS Version                                                   | First supported GitLab version | Arch            |                         Install Documentation                | OS EOL     | Details                                                      |
| ------------------------------------------------------------ | ------------------------------ | --------------- | :----------------------------------------------------------: | ---------- | ------------------------------------------------------------ |
| AlmaLinux 8                                                  | GitLab CE / GitLab EE 14.5.0   | x86_64, aarch64 | [AlmaLinux Install Documentation](https://about.gitlab.com/install/#almalinux) | 2029       | <https://almalinux.org/>                                     |
| AlmaLinux 9                                                  | GitLab CE / GitLab EE 16.0.0   | x86_64, aarch64 | [AlmaLinux Install Documentation](https://about.gitlab.com/install/#almalinux) | 2032       | <https://almalinux.org/>                                     |
| CentOS 7                                                     | GitLab CE / GitLab EE 7.10.0   | x86_64          | [CentOS Install Documentation](https://about.gitlab.com/install/#centos-7) | June 2024  | <https://www.centos.org/about/>                      |
| Debian 10                                                    | GitLab CE / GitLab EE 12.2.0   | amd64, arm64    | [Debian Install Documentation](https://about.gitlab.com/install/#debian) | 2024       | <https://wiki.debian.org/LTS>                                |
| Debian 11                                                    | GitLab CE / GitLab EE 14.6.0   | amd64, arm64    | [Debian Install Documentation](https://about.gitlab.com/install/#debian) | 2026       | <https://wiki.debian.org/LTS>                                |
| Debian 12                                                   | GitLab CE / GitLab EE 16.1.0   | amd64, arm64    | [Debian Install Documentation](https://about.gitlab.com/install/#debian) | TBD       | <https://wiki.debian.org/LTS>                                |
| OpenSUSE 15.5                                                | GitLab CE / GitLab EE 16.4.0   | x86_64, aarch64 | [OpenSUSE Install Documentation](https://about.gitlab.com/install/#opensuse-leap) | Dec 2024   | <https://en.opensuse.org/Lifetime>                           |
| RHEL 8                                                       | GitLab CE / GitLab EE 12.8.1   | x86_64, arm64   | [Use CentOS Install Documentation](https://about.gitlab.com/install/#centos-7) | May 2029   | [RHEL Details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| RHEL 9                                                      | GitLab CE / GitLab EE 16.0.0   | x86_64, arm64   | [Use CentOS Install Documentation](https://about.gitlab.com/install/#centos-7) | May 2032   | [RHEL Details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| SLES 12                                                      | GitLab EE 9.0.0                | x86_64          | [Use OpenSUSE Install Documentation](https://about.gitlab.com/install/#opensuse-leap) | Oct 2027   | <https://www.suse.com/lifecycle/>                            |
| SLES 15                                                      | GitLab EE 14.8.0                | x86_64          | [Use OpenSUSE Install Documentation](https://about.gitlab.com/install/#opensuse-leap) | Dec 2024   | <https://www.suse.com/lifecycle/>                            |
| Oracle Linux 7                                               | GitLab CE / GitLab EE 8.14.0   | x86_64          | [Use CentOS Install Documentation](https://about.gitlab.com/install/#centos-7) | Dec 2024         | <https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf>                                                           |
| Scientific Linux                                             | GitLab CE / GitLab EE 8.14.0   | x86_64          | [Use CentOS Install Documentation](https://about.gitlab.com/install/#centos-7) | June 2024         | <https://scientificlinux.org/downloads/sl-versions/sl7/>                                                           |
| Ubuntu 18.04                                                 | GitLab CE / GitLab EE 10.7.0   | amd64           | [Ubuntu Install Documentation](https://about.gitlab.com/install/#ubuntu) | April 2023 | <https://wiki.ubuntu.com/Releases>                           |
| Ubuntu 20.04                                                 | GitLab CE / GitLab EE 13.2.0   | amd64, arm64    | [Ubuntu Install Documentation](https://about.gitlab.com/install/#ubuntu) | April 2025 | <https://wiki.ubuntu.com/Releases>                           |
| Ubuntu 22.04                                                 | GitLab CE / GitLab EE 15.5.0   | amd64, arm64    | [Ubuntu Install Documentation](https://about.gitlab.com/install/#ubuntu) | April 2027 | <https://wiki.ubuntu.com/Releases>                           |
| Amazon Linux 2                                               | GitLab CE / GitLab EE 14.9.0   | amd64, arm64    | [Amazon Linux 2 Install Documentation](https://about.gitlab.com/install/#amazonlinux-2) | June 2025  | <https://aws.amazon.com/amazon-linux-2/faqs/>                |
| Amazon Linux 2023                                            | GitLab CE / GitLab EE 16.3.0   | amd64, arm64    | [Amazon Linux 2023 Install Documentation](https://about.gitlab.com/install/#amazonlinux-2023) | 2028  | <https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html>                |
| Raspberry Pi OS (Buster) (formerly known as Raspbian Buster) | GitLab CE 12.2.0               | armhf           | [Raspberry Pi Install Documentation](https://about.gitlab.com/install/#raspberry-pi-os) | June 2024       | [Raspberry Pi Details](https://www.raspberrypi.com/news/new-old-functionality-with-raspberry-pi-os-legacy/) |
| Raspberry Pi OS (Bullseye) | GitLab CE 15.5.0               | armhf           | [Raspberry Pi Install Documentation](https://about.gitlab.com/install/#raspberry-pi-os) | 2026       | [Raspberry Pi Details](https://www.raspberrypi.com/news/raspberry-pi-os-debian-bullseye/) |

NOTE:
CentOS 8 was EOL on December 31, 2021. In GitLab 14.5 and later,
[CentOS builds work in AlmaLinux](https://gitlab.com/gitlab-org/distribution/team-tasks/-/issues/954#note_730198505).
We officially support all distributions that are binary compatible with Red Hat Enterprise Linux.
This gives users a path forward for their CentOS 8 builds at its end of life.

NOTE:
The [CentOS major version and a minor version](https://en.wikipedia.org/wiki/CentOS#CentOS_releases) up to CentOS8 ([when CentOS Stream](https://en.wikipedia.org/wiki/CentOS#CentOS_Stream) was released) correspond to the set of major version and update versions of RHEL.

## Update GitLab package sources after upgrading the OS

After upgrading the Operating System (OS) as per its own documentation,
it may be necessary to also update the GitLab package source URL
in your package manager configuration.
If your package manager reports that no further updates are available,
although [new versions have been released](https://about.gitlab.com/releases/categories/releases/), repeat the
"Add the GitLab package repository" instructions
of the [Linux package install guide](https://about.gitlab.com/install/#content).
Future GitLab upgrades are fetched according to your upgraded OS.

## Update both GitLab and the operating system

To upgrade both the operating system (OS) and GitLab:

1. Upgrade the OS.
1. Check if it's necessary to [update the GitLab package sources](#update-gitlab-package-sources-after-upgrading-the-os).
1. [Upgrade GitLab](../../update/index.md).

## Packages for ARM64

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/issues/27) in GitLab 13.4.

GitLab provides arm64/aarch64 packages for some supported operating systems.
You can see if your operating system architecture is supported in the table
above.

WARNING:
There are currently still some [known issues and limitation](https://gitlab.com/groups/gitlab-org/-/epics/4397)
running GitLab on ARM.

## OS Versions that are no longer supported

GitLab provides Linux packages for operating systems only until their
EOL (End-Of-Life). After the EOL date of the OS, GitLab stops releasing
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
| Raspbian Stretch | [June 2020](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.3&dist=raspbian%2Fstretch) 13.3                                                                                                           |
| Debian Jessie   | [June 2020](https://www.debian.org/News/2020/20200709)                             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.2&dist=debian%2Fjessie) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.2&dist=debian%2Fjessie) 13.3       |
| CentOS 6        | [November 2020](https://www.centos.org/about/)                             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=13.6&filter=all&filter=all&dist=el%2F6) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=13.6&filter=all&filter=all&dist=el%2F6) 13.6 |
| CentOS 8        | [December 2021](https://www.centos.org/about/)                             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=14.6&filter=all&filter=all&dist=el%2F8) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=14.6&filter=all&filter=all&dist=el%2F8) 14.6 |
| OpenSUSE 15.1   | [November 2020](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-13.12&dist=opensuse%2F15.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-13.12&dist=opensuse%2F15.1) 13.12    |
| Ubuntu 16.04    | [April 2021](https://ubuntu.com/info/release-end-of-life)                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.12&dist=ubuntu%2Fxenial) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.12&dist=ubuntu%2Fxenial) 13.12    |
| OpenSUSE 15.2   | [December 2021](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-14.7&dist=opensuse%2F15.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-14.7&dist=opensuse%2F15.2) 14.7       |
| Debian 9 "Stretch" | [June 2022](https://lists.debian.org/debian-lts-announce/2022/07/msg00002.html) | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_15.2&dist=debian%2Fstretch) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_15.2&dist=debian%2Fstretch) 15.2     |
| OpenSUSE 15.3   | [December 2022](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-15.10&dist=opensuse%2F15.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-15.10&dist=opensuse%2F15.3) 15.10    |
| OpenSUSE 15.4   | [December 2023](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-16.7&dist=opensuse%2F15.4) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-16.7&dist=opensuse%2F15.4) 16.7       |

NOTE:
An exception to this deprecation policy is when we are unable to provide
packages for the next version of the operating system. The most common reason
for this our package repository provider, PackageCloud, not supporting newer
versions and hence we can't upload packages to it.
