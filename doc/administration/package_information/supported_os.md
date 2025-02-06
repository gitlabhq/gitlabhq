---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Supported operating systems
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab officially supports long term support (LTS) versions of operating systems. Some operating systems, such as Ubuntu,
have a clear distinction between LTS and non-LTS versions. However, there are other operating systems, openSUSE for
example, that don't follow the LTS concept.

To avoid confusion, all the operating systems supported by GitLab are listed on the
[installation page](https://about.gitlab.com/install/).

NOTE:
`amd64` and `x86_64` refer to the same 64-bit architecture. The names `arm64` and `aarch64` are also interchangeable
and refer to the same architecture.

## AlmaLinux

These versions of AlmaLinux are supported.

| Operating system | First supported GitLab version | Architecture        | Installation documentation                                                          | Operating system EOL | Details |
|:-----------------|:-------------------------------|:--------------------|:------------------------------------------------------------------------------------|:---------------------|:--------|
| AlmaLinux 8      | GitLab CE / GitLab EE 14.5.0   | `x86_64`, `aarch64` | [AlmaLinux installation documentation](https://about.gitlab.com/install/#almalinux) | 2029                 | [AlmaLinux details](https://almalinux.org/) |
| AlmaLinux 9      | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `aarch64` | [AlmaLinux installation documentation](https://about.gitlab.com/install/#almalinux) | 2032                 | [AlmaLinux details](https://almalinux.org/) |

## Amazon Linux

These versions of Amazon Linux are supported.

| Operating system  | First supported GitLab version | Architecture     | Installation documentation                                                                         | Operating system EOL | Details |
|:------------------|:-------------------------------|:-----------------|:---------------------------------------------------------------------------------------------------|:---------------------|:--------|
| Amazon Linux 2    | GitLab CE / GitLab EE 14.9.0   | `amd64`, `arm64` | [Amazon Linux 2 installation documentation](https://about.gitlab.com/install/#amazonlinux-2)       | June 2026            | [Amazon Linux details](https://aws.amazon.com/amazon-linux-2/faqs/) |
| Amazon Linux 2023 | GitLab CE / GitLab EE 16.3.0   | `amd64`, `arm64` | [Amazon Linux 2023 installation documentation](https://about.gitlab.com/install/#amazonlinux-2023) | 2028                 | [Amazon Linux details](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html) |

## Debian

These versions of Debian are supported.

| Operating system | First supported GitLab version | Architecture     | Installation documentation                                                    | Operating system EOL | Details |
|:-----------------|:-------------------------------|:-----------------|:------------------------------------------------------------------------------|:---------------------|:--------|
| Debian 11        | GitLab CE / GitLab EE 14.6.0   | `amd64`, `arm64` | [Debian installation documentation](https://about.gitlab.com/install/#debian) | 2026                 | [Debian Linux details](https://wiki.debian.org/LTS) |
| Debian 12        | GitLab CE / GitLab EE 16.1.0   | `amd64`, `arm64` | [Debian installation documentation](https://about.gitlab.com/install/#debian) | TBD                  | [Debian Linux details](https://wiki.debian.org/LTS) |

## openSUSE Leap and SUSE Linux Enterprise Server

These versions of openSUSE Leap and SUSE Linux Enterprise Server are supported.

| Operating system version        | First supported GitLab version | Architecture        | Installation documentation                                                                 | Operating system EOL | Details |
|:--------------------------------|:-------------------------------|:--------------------|:-------------------------------------------------------------------------------------------|:---------------------|:--------|
| openSUSE Leap 15.6              | GitLab CE / GitLab EE 17.6.0   | `x86_64`, `aarch64` | [openSUSE installation documentation](https://about.gitlab.com/install/#opensuse-leap)     | Dec 2025             | [openSUSE details](https://en.opensuse.org/Lifetime) |
| SUSE Linux Enterprise Server 12 | GitLab EE 9.0.0                | `x86_64`            | [Use OpenSUSE installation documentation](https://about.gitlab.com/install/#opensuse-leap) | Oct 2027             | [SUSE Linux Enterprise Server details](https://www.suse.com/lifecycle/) |
| SUSE Linux Enterprise Server 15 | GitLab EE 14.8.0               | `x86_64`            | [Use OpenSUSE installation documentation](https://about.gitlab.com/install/#opensuse-leap) | Dec 2024             | [SUSE Linux Enterprise Server details](https://www.suse.com/lifecycle/) |

## Oracle Linux

These versions of Oracle Linux are supported.

| Operating system | First supported GitLab version | Architecture | Installation documentation                                                              | Operating system EOL | Details |
|:-----------------|:-------------------------------|:-------------|:----------------------------------------------------------------------------------------|:---------------------|:--------|
| Oracle Linux 8   | GitLab CE / GitLab EE 12.8.1   | `x86_64`     | [Use AlmaLinux installation documentation](https://about.gitlab.com/install/#almalinux) | July 2029            | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf) |
| Oracle Linux 9   | GitLab CE / GitLab EE 16.2.0   | `x86_64`     | [Use AlmaLinux installation documentation](https://about.gitlab.com/install/#almalinux) | June 2032            | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf) |

## Raspberry Pi OS

These versions of Raspberry Pi OS are supported.

| Operating system version                                     | First supported GitLab version | Architecture | Installation documentation                                                                   | Operating system EOL | Details |
|:-------------------------------------------------------------|:-------------------------------|:-------------|:---------------------------------------------------------------------------------------------|:---------------------|:--------|
| Raspberry Pi OS (Bullseye)                                   | GitLab CE 15.5.0               | `armhf`      | [Raspberry Pi installation documentation](https://about.gitlab.com/install/#raspberry-pi-os) | 2026                 | [Raspberry Pi details](https://www.raspberrypi.com/news/raspberry-pi-os-debian-bullseye/) |

## Red Hat Enterprise Linux

These versions of Red Hat Enterprise Linux are supported.

| Operating system version   | First supported GitLab version | Architecture      | Installation documentation                                                          | Operating system EOL | Details |
|:---------------------------|:-------------------------------|:------------------|:------------------------------------------------------------------------------------|:---------------------|:--------|
| Red Hat Enterprise Linux 8 | GitLab CE / GitLab EE 12.8.1   | `x86_64`, `arm64` | [Use CentOS installation documentation](https://about.gitlab.com/install/#centos-7) | May 2029             | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| Red Hat Enterprise Linux 9 | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `arm64` | [Use CentOS installation documentation](https://about.gitlab.com/install/#centos-7) | May 2032             | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |

## Ubuntu

These versions of Ubuntu are supported.

| Operating system | First supported GitLab version | Architecture     | Installation documentation                                                    | Operating system EOL | Details |
|:-----------------|:-------------------------------|:-----------------|:------------------------------------------------------------------------------|:---------------------|:--------|
| Ubuntu 20.04     | GitLab CE / GitLab EE 13.2.0   | `amd64`, `arm64` | [Ubuntu installation documentation](https://about.gitlab.com/install/#ubuntu) | April 2025           | [Ubuntu details](https://wiki.ubuntu.com/Releases) |
| Ubuntu 22.04     | GitLab CE / GitLab EE 15.5.0   | `amd64`, `arm64` | [Ubuntu installation documentation](https://about.gitlab.com/install/#ubuntu) | April 2027           | [Ubuntu details](https://wiki.ubuntu.com/Releases) |
| Ubuntu 24.04     | GitLab CE / GitLab EE 17.1.0   | `amd64`, `arm64` | [Ubuntu installation documentation](https://about.gitlab.com/install/#ubuntu) | April 2029           | [Ubuntu details](https://wiki.ubuntu.com/Releases) |

## Update GitLab package sources after upgrading the OS

After upgrading the operating system, you might also need to update the GitLab package source URL in your package
manager configuration.

If your package manager reports that no further updates are available, but you know updates exist, repeat the
instructions on the [Linux package install guide](https://about.gitlab.com/install/#content) to add the GitLab
package repository. Future GitLab upgrades are fetched according to your upgraded operating system.

## Update both GitLab and the operating system

To upgrade both the operating system (OS) and GitLab:

1. Upgrade the OS.
1. Check if it's necessary to [update the GitLab package sources](#update-gitlab-package-sources-after-upgrading-the-os).
1. [Upgrade GitLab](../../update/_index.md).

## Corrupted Postgres indexes after upgrading the OS

As part of upgrading the operating system, if your `glibc` version changes, then you must follow
[Upgrading operating systems for PostgreSQL](../postgresql/upgrading_os.md) to avoid corrupted
indexes.

## Packages for ARM64

GitLab provides arm64/aarch64 packages for some supported operating systems.
You can see if your operating system architecture is supported in the table
above.

WARNING:
[Known issues](https://gitlab.com/groups/gitlab-org/-/epics/4397) exist for running GitLab on ARM.

## OS versions that are no longer supported

GitLab provides Linux packages for operating systems only until their
end-of-life (EOL) date. After the EOL date, GitLab stops releasing
official packages. The list of deprecated operating systems and the final GitLab
release for them can be found below:

| OS version       | End of life                                                                         | Last supported GitLab version |
|:-----------------|:------------------------------------------------------------------------------------|:------------------------------|
| CentOS 6         | [November 2020](https://www.centos.org/about/)                                      | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=13.6&filter=all&filter=all&dist=el%2F6) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=13.6&filter=all&filter=all&dist=el%2F6) 13.6 |
| CentOS 7         | [June 2024](https://www.centos.org/about/)                                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=el%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=el%2F7) 17.7 |
| CentOS 8         | [December 2021](https://www.centos.org/about/)                                      | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=14.6&filter=all&filter=all&dist=el%2F8) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=14.6&filter=all&filter=all&dist=el%2F8) 14.6 |
| Oracle Linux 7   | [December 2024](https://endoflife.date/oracle-linux)                                | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=ol%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=ol%2F7) 17.7 |
| Scientific Linux 7 | [June 2024](https://scientificlinux.org/downloads/sl-versions/sl7/)               | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=scientific%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=scientific%2F7) 17.7 |
| Debian 7 Wheezy  | [May 2018](https://www.debian.org/News/2018/20180601)                               | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.6&dist=debian%2Fwheezy) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.6&dist=debian%2Fwheezy) 11.6 |
| Debian 8 Jessie  | [June 2020](https://www.debian.org/News/2020/20200709)                              | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.2&dist=debian%2Fjessie) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.2&dist=debian%2Fjessie) 13.3 |
| Debian 9 Stretch | [June 2022](https://lists.debian.org/debian-lts-announce/2022/07/msg00002.html)     | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_15.2&dist=debian%2Fstretch) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_15.2&dist=debian%2Fstretch) 15.2 |
| Debian 10 Buster | [June 2024](https://www.debian.org/News/2024/20240615)                              | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_17.5&dist=debian%2Fbuster) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_17.5&dist=debian%2Fbuster) 17.5 |
| OpenSUSE 42.1    | [May 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.3&dist=opensuse%2F42.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.3&dist=opensuse%2F42.1) 9.3 |
| OpenSUSE 42.2    | [January 2018](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-10.4&dist=opensuse%2F42.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-10.4&dist=opensuse%2F42.2) 10.4 |
| OpenSUSE 42.3    | [July 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.1&dist=opensuse%2F42.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.1&dist=opensuse%2F42.3) 12.1 |
| OpenSUSE 13.2    | [January 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.1&dist=opensuse%2F13.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.1&dist=opensuse%2F13.2) 9.1 |
| OpenSUSE 15.0    | [December 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.5&dist=opensuse%2F15.0) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.5&dist=opensuse%2F15.0) 12.5 |
| OpenSUSE 15.1    | [November 2020](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-13.12&dist=opensuse%2F15.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-13.12&dist=opensuse%2F15.1) 13.12 |
| OpenSUSE 15.2    | [December 2021](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-14.7&dist=opensuse%2F15.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-14.7&dist=opensuse%2F15.2) 14.7 |
| OpenSUSE 15.3    | [December 2022](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-15.10&dist=opensuse%2F15.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-15.10&dist=opensuse%2F15.3) 15.10 |
| OpenSUSE 15.4    | [December 2023](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-16.7&dist=opensuse%2F15.4) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-16.7&dist=opensuse%2F15.4) 16.7 |
| OpenSUSE 15.5    | [December 2024](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-17.8&dist=opensuse%2F15.5) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-17.8&dist=opensuse%2F15.5) 17.8 |
| Raspbian Wheezy  | [May 2015](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_8.17&dist=debian%2Fwheezy) 8.17 |
| Raspbian Jessie  | [May 2017](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_11.7&dist=debian%2Fjessie) 11.7 |
| Raspbian Stretch | [June 2020](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.3&dist=raspbian%2Fstretch) 13.3 |
| Raspberry Pi OS Buster | [June 2024](https://www.debian.org/News/2024/20240615)                        | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_17.7&dist=raspbian%2Fbuster) 17.7 |
| Ubuntu 12.04     | [April 2017](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_9.1&dist=ubuntu%2Fprecise) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_9.1&dist=ubuntu%2Fprecise) 9.1 |
| Ubuntu 14.04     | [April 2019](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.10&dist=ubuntu%2Ftrusty) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.10&dist=ubuntu%2Ftrusty) 11.10 |
| Ubuntu 16.04     | [April 2021](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.12&dist=ubuntu%2Fxenial) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.12&dist=ubuntu%2Fxenial) 13.12 |
| Ubuntu 18.04     | [June 2023](https://ubuntu.com/info/release-end-of-life)                            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_16.11&dist=ubuntu%2Fbionic) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=ggitlab-ee_16.11&dist=ubuntu%2Fbionic) 16.11 |

NOTE:
An exception to this deprecation policy is when we are unable to provide
packages for the next version of the operating system. The most common reason
for this our package repository provider, PackageCloud, not supporting newer
versions and hence we can't upload packages to it.
