---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install GitLab using the Linux package
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The Linux packages are mature, scalable, and are used on GitLab.com. If you need additional
flexibility and resilience, we recommend deploying GitLab as described in the
[reference architecture documentation](../../administration/reference_architectures/_index.md).

The Linux package is quicker to install, easier to upgrade, and contains
features to enhance reliability not found in other installation methods. Install through a
single package (also known as Omnibus GitLab) that bundles all the different services
and tools required to run GitLab. You should have at least 4 GiB of RAM. For more information,
see [minimum requirements](../requirements.md).

Linux packages are available in our packages repository for:

- [GitLab Enterprise Edition](https://packages.gitlab.com/gitlab/gitlab-ee).
- [GitLab Community Edition](https://packages.gitlab.com/gitlab/gitlab-ce).

Check that the required GitLab version is available for your host operating system.

## Supported platforms

GitLab officially supports long term support (LTS) versions of operating
systems. Some operating systems, such as Ubuntu, have a clear distinction
between LTS and non-LTS versions. However, there are other operating systems,
openSUSE for example, that don't follow the LTS concept.

{{< alert type="note" >}}

`amd64` and `x86_64` refer to the same 64-bit architecture. The names `arm64` and `aarch64` are also interchangeable
and refer to the same architecture.

{{< /alert >}}

| Operating system | First supported GitLab version | Architecture        | Operating system EOL | Upstream release notes |
|:-----------------|:-------------------------------|:--------------------|:---------------------|:--------|
| [AlmaLinux 8](https://about.gitlab.com/install/#almalinux)      | GitLab CE / GitLab EE 14.5.0   | `x86_64`, `aarch64` <sup>1</sup> | 2029                 | [AlmaLinux details](https://almalinux.org/) |
| [AlmaLinux 9](https://about.gitlab.com/install/#almalinux)      | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `aarch64` <sup>1</sup> | 2032                 | [AlmaLinux details](https://almalinux.org/) |
| [Amazon Linux 2](https://about.gitlab.com/install/#amazonlinux-2)    | GitLab CE / GitLab EE 14.9.0   | `amd64`, `arm64` <sup>1</sup> | June 2026            | [Amazon Linux details](https://aws.amazon.com/amazon-linux-2/faqs/) |
| [Amazon Linux 2023](https://about.gitlab.com/install/#amazonlinux-2023) | GitLab CE / GitLab EE 16.3.0   | `amd64`, `arm64` <sup>1</sup> | 2028                 | [Amazon Linux details](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html) |
| [Debian 11](https://about.gitlab.com/install/#debian)        | GitLab CE / GitLab EE 14.6.0   | `amd64`, `arm64` <sup>1</sup> | 2026                 | [Debian Linux details](https://wiki.debian.org/LTS) |
| [Debian 12](https://about.gitlab.com/install/#debian)        | GitLab CE / GitLab EE 16.1.0   | `amd64`, `arm64` <sup>1</sup> | TBD                  | [Debian Linux details](https://wiki.debian.org/LTS) |
| [openSUSE Leap 15.6](https://about.gitlab.com/install/#opensuse-leap)              | GitLab CE / GitLab EE 17.6.0   | `x86_64`, `aarch64` <sup>1</sup> | Dec 2025             | [openSUSE details](https://en.opensuse.org/Lifetime) |
| [SUSE Linux Enterprise Server 12](https://about.gitlab.com/install/#opensuse-leap) | GitLab EE 9.0.0                | `x86_64`            | Oct 2027             | [SUSE Linux Enterprise Server details](https://www.suse.com/lifecycle/) |
| [SUSE Linux Enterprise Server 15](https://about.gitlab.com/install/#opensuse-leap) | GitLab EE 14.8.0               | `x86_64`            | Dec 2024             | [SUSE Linux Enterprise Server details](https://www.suse.com/lifecycle/) |
| [Oracle Linux 8](https://about.gitlab.com/install/#almalinux)   | GitLab CE / GitLab EE 12.8.1   | `x86_64`     | July 2029            | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf) |
| [Oracle Linux 9](https://about.gitlab.com/install/#almalinux)   | GitLab CE / GitLab EE 16.2.0   | `x86_64`     | June 2032            | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf) |
| [Red Hat Enterprise Linux 8](https://about.gitlab.com/install/#almalinux) | GitLab CE / GitLab EE 12.8.1   | `x86_64`, `arm64` <sup>1</sup> | May 2029             | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 9](https://about.gitlab.com/install/#almalinux) | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `arm64` <sup>1</sup> | May 2032             | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Ubuntu 20.04](https://about.gitlab.com/install/#ubuntu)     | GitLab CE / GitLab EE 13.2.0   | `amd64`, `arm64` <sup>1</sup> | April 2025           | [Ubuntu details](https://wiki.ubuntu.com/Releases) |
| [Ubuntu 22.04](https://about.gitlab.com/install/#ubuntu)     | GitLab CE / GitLab EE 15.5.0   | `amd64`, `arm64` <sup>1</sup> | April 2027           | [Ubuntu details](https://wiki.ubuntu.com/Releases) |
| [Ubuntu 24.04](https://about.gitlab.com/install/#ubuntu)     | GitLab CE / GitLab EE 17.1.0   | `amd64`, `arm64` <sup>1</sup> | April 2029           | [Ubuntu details](https://wiki.ubuntu.com/Releases) |

**Footnotes**:

1. [Known issues](https://gitlab.com/groups/gitlab-org/-/epics/4397) exist for running GitLab on ARM.

### Unofficial, unsupported installation methods

The following installation methods are provided as-is by the wider GitLab
community and are not supported by GitLab:

- [Debian native package](https://wiki.debian.org/gitlab/) (by Pirate Praveen)
- [FreeBSD package](http://www.freshports.org/www/gitlab-ce) (by Torsten Zühlsdorff)
- [Arch Linux package](https://archlinux.org/packages/extra/x86_64/gitlab/) (by the Arch Linux community)
- [Puppet module](https://forge.puppet.com/puppet/gitlab) (by Vox Pupuli)
- [Ansible playbook](https://github.com/geerlingguy/ansible-role-gitlab) (by Jeff Geerling)
- [GitLab virtual appliance (KVM)](https://marketplace.opennebula.io/appliance/6b54a412-03a5-11e9-8652-f0def1753696) (by OpenNebula)
- [GitLab on Cloudron](https://cloudron.io/store/com.gitlab.cloudronapp.html) (via Cloudron App Library)

## End-of-life versions

GitLab provides Linux packages for operating systems only until their
end-of-life (EOL) date. After the EOL date, GitLab stops releasing
official packages.

However, sometimes we don't deprecate an operating system even after it's EOL
because we can't provide packages for a newer version.
The most common reason for this is PackageCloud, our package repository provider,
not supporting newer versions and so we can't upload packages to it.

The list of deprecated operating systems and the final GitLab
release for them can be found below:

| OS version       | End of life                                                                         | Last supported GitLab version |
|:-----------------|:------------------------------------------------------------------------------------|:------------------------------|
| CentOS 6 and RHEL 6 | [November 2020](https://www.centos.org/about/)                                   | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=13.6&filter=all&filter=all&dist=el%2F6) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=13.6&filter=all&filter=all&dist=el%2F6) 13.6 |
| CentOS 7 and RHEL 7 | [June 2024](https://www.centos.org/about/)                                       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=el%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=el%2F7) 17.7 |
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

### Raspberry Pi OS (32-bit - Raspbian)

GitLab dropped support for Raspberry Pi OS (32 bit - Raspbian) with GitLab
17.11 being the last version available for the 32-bit platform. Starting with
GitLab 18.0, you should move to Raspberry Pi OS (64 bit) and use the
[Debian arm64 package](https://about.gitlab.com/install/#debian).

For information on backing up data on a 32-bit OS and restoring it to a 64-bit
OS, see [Upgrading operating systems for PostgreSQL](../../administration/postgresql/upgrading_os.md).
