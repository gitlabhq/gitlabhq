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
and tools required to run GitLab. See the [installation requirements](../requirements.md)
to learn about the minimum hardware requirements.

Linux packages are available in our packages repository for:

- [GitLab Enterprise Edition](https://packages.gitlab.com/gitlab/gitlab-ee).
- [GitLab Community Edition](https://packages.gitlab.com/gitlab/gitlab-ce).

Check that the required GitLab version is available for your host operating system.

## Supported platforms

GitLab officially supports long term support (LTS) versions of operating
systems. Some operating systems, such as Ubuntu, have a clear distinction
between LTS and non-LTS versions. However, there are other operating systems,
openSUSE for example, that don't follow the LTS concept.

We will usually provide support for a version of an operating system until it
is no longer supported by its vendor, where support is defined as standard or
maintenance support and not as expanded, extended, or premium support. However,
we might end support earlier than the operating system's vendor in these
circumstances:

- Business considerations: Including but not limited to low customer adoption,
  disproportionate maintenance costs, or strategic product direction changes.
- Technical constraints: When third-party dependencies, security requirements,
  or underlying technology changes make continued support impractical or
  impossible.
- Vendor actions: When operating system vendors make changes that fundamentally
  impact our software's functionality or when required components become
  unavailable.

We will usually issue a deprecation notice at least 6 months before support for
any operating system version is discontinued, on a best-effort basis. In cases
where technical constraints, vendor actions, or other external factors require
that we provide shorter notice periods, we will communicate any support changes
as soon as reasonably possible.

{{< alert type="note" >}}

`amd64` and `x86_64` refer to the same 64-bit architecture. The names `arm64` and `aarch64` are also interchangeable
and refer to the same architecture.

{{< /alert >}}

| Operating system                                                                   | First supported GitLab version | Architecture          | Operating system EOL | Proposed last supported GitLab version  | Upstream release notes                                                                                        |
|------------------------------------------------------------------------------------|--------------------------------|-----------------------|----------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------|
| [AlmaLinux 8](almalinux.md)                         | GitLab CE / GitLab EE 14.5.0   | `x86_64`, `aarch64` <sup>1</sup> | Mar 2029             | GitLab CE / GitLab EE 21.10.0 | [AlmaLinux details](https://almalinux.org/)                                                                   |
| [AlmaLinux 9](almalinux.md)                         | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `aarch64` <sup>1</sup> | May 2032             | GitLab CE / GitLab EE 25.0.0  | [AlmaLinux details](https://almalinux.org/)                                                                   |
| [AlmaLinux 10](almalinux.md)                         | GitLab CE / GitLab EE 18.6.0   | `x86_64`, `aarch64` <sup>1</sup> | May 2035             | GitLab CE / GitLab EE 28.0.0  | [AlmaLinux details](https://almalinux.org/)                                                                  |
| [Amazon Linux 2](amazonlinux_2.md)                  | GitLab CE / GitLab EE 14.9.0   | `amd64`, `arm64` <sup>1</sup>    | June 2026            | GitLab CE / GitLab EE 19.1.0  | [Amazon Linux details](https://aws.amazon.com/amazon-linux-2/faqs/)                                           |
| [Amazon Linux 2023](amazonlinux_2023.md)            | GitLab CE / GitLab EE 16.3.0   | `amd64`, `arm64` <sup>1</sup>    | June 2029            | GitLab CE / GitLab EE 22.1.0  | [Amazon Linux details](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html)                      |
| [Debian 11](debian.md)                              | GitLab CE / GitLab EE 14.6.0   | `amd64`, `arm64` <sup>1</sup>    | Aug 2026             | GitLab CE / GitLab EE 19.3.0  | [Debian Linux details](https://wiki.debian.org/LTS)                                                           |
| [Debian 12](debian.md)                              | GitLab CE / GitLab EE 16.1.0   | `amd64`, `arm64` <sup>1</sup>    | June 2028            | GitLab CE / GitLab EE 19.3.0  | [Debian Linux details](https://wiki.debian.org/LTS)                                                           |
| [Debian 13](debian.md)                              | GitLab CE / GitLab EE 18.5.0   | `amd64`, `arm64` <sup>1</sup>    | June 2030            | GitLab CE / GitLab EE 23.1.0  | [Debian Linux details](https://wiki.debian.org/LTS)                                                           |
| [openSUSE Leap 15.6](suse.md)              | GitLab CE / GitLab EE 17.6.0   | `x86_64`, `aarch64` <sup>1</sup> | Dec 2025             | TBD  | [openSUSE details](https://en.opensuse.org/Lifetime)                                                          |
| [SUSE Linux Enterprise Server 12](suse.md) | GitLab EE 9.0.0                | `x86_64`              | Oct 2027             | TBD  | [SUSE Linux Enterprise Server details](https://www.suse.com/lifecycle/)                                       |
| [SUSE Linux Enterprise Server 15](suse.md) | GitLab EE 14.8.0               | `x86_64`              | Dec 2024             | TBD  | [SUSE Linux Enterprise Server details](https://www.suse.com/lifecycle/)                                       |
| [Oracle Linux 8](almalinux.md)                      | GitLab CE / GitLab EE 12.8.1   | `x86_64`              | July 2029            | GitLab CE / GitLab EE 22.2.0  | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 9](almalinux.md)                      | GitLab CE / GitLab EE 16.2.0   | `x86_64`              | June 2032            | GitLab CE / GitLab EE 25.1.0  | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 10](almalinux.md)                      | GitLab CE / GitLab EE 18.6.0   | `x86_64`              | June 2035            | GitLab CE / GitLab EE 28.1.0  | [Oracle Linux details](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Red Hat Enterprise Linux 8](almalinux.md)          | GitLab CE / GitLab EE 12.8.1   | `x86_64`, `arm64` <sup>1</sup>   | May 2029             | GitLab CE / GitLab EE 22.0.0  | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 9](almalinux.md)          | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `arm64` <sup>1</sup>   | May 2032             | GitLab CE / GitLab EE 25.0.0  | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 10](almalinux.md)          | GitLab CE / GitLab EE 18.6.0   | `x86_64`, `arm64` <sup>1</sup>   | May 2035             | GitLab CE / GitLab EE 28.0.0  | [Red Hat Enterprise Linux details](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Ubuntu 20.04](ubuntu.md)                           | GitLab CE / GitLab EE 13.2.0   | `amd64`, `arm64` <sup>1</sup>    | April 2025           | GitLab CE / GitLab EE 18.8.0  | [Ubuntu details](https://wiki.ubuntu.com/Releases)                                                            |
| [Ubuntu 22.04](ubuntu.md)                           | GitLab CE / GitLab EE 15.5.0   | `amd64`, `arm64` <sup>1</sup>    | April 2027           | GitLab CE / GitLab EE 19.11.0 | [Ubuntu details](https://wiki.ubuntu.com/Releases). FIPS packages were added in GitLab 18.4. Before upgrading from Ubuntu 20.04, view the [upgrade notes](#ubuntu-2204-fips). |
| [Ubuntu 24.04](ubuntu.md)                           | GitLab CE / GitLab EE 17.1.0   | `amd64`, `arm64` <sup>1</sup>    | April 2029           | GitLab CE / GitLab EE 21.11.0 | [Ubuntu details](https://wiki.ubuntu.com/Releases)                                                            |

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
| SLES 15 SP2      | [December 2024](https://www.suse.com/lifecycle/#suse-linux-enterprise-server-15)    | [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-18.1&filter=all&filter=all&dist=sles%2F15.2) |
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
[Debian arm64 package](debian.md).

For information on backing up data on a 32-bit OS and restoring it to a 64-bit
OS, see [Upgrading operating systems for PostgreSQL](../../administration/postgresql/upgrading_os.md).

## Uninstall the Linux package

To uninstall the Linux package, you can opt to either keep your data (repositories,
database, configuration) or remove all of them:

1. Optional. To remove
   [all users and groups created by the Linux package](https://docs.gitlab.com/omnibus/settings/configuration/#disable-user-and-group-account-management)
   before removing the package:

   ```shell
   sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts
   ```

   {{< alert type="note" >}}

   If you have a problem removing accounts or groups, run `userdel` or `groupdel` manually
   to delete them. You might also want to manually remove the leftover user home directories
   from `/home/`.

   {{< /alert >}}

1. Choose whether to keep your data or remove all of them:

   - To preserve your data (repositories, database, configuration), stop GitLab and
     remove its supervision process:

     ```shell
     sudo systemctl stop gitlab-runsvdir
     sudo systemctl disable gitlab-runsvdir
     sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
     sudo systemctl daemon-reload
     sudo systemctl reset-failed
     sudo gitlab-ctl uninstall
     ```

   - To remove all data:

     ```shell
     sudo gitlab-ctl cleanse && sudo rm -r /opt/gitlab
     ```

1. Uninstall the package (replace with `gitlab-ce` if you have GitLab FOSS installed):

   {{< tabs >}}

   {{< tab title="apt" >}}

   ```shell
   # Debian/Ubuntu
   sudo apt remove gitlab-ee
   ```

   {{< /tab >}}

   {{< tab title="dnf" >}}

   ```shell
   # AlmaLinux/RHEL/Oracle Linux/Amazon Linux 2023
   sudo dnf remove gitlab-ee
   ```

   {{< /tab >}}

   {{< tab title="zypper" >}}

   ```shell
   # OpenSUSE Leap/SLES
   sudo zypper remove gitlab-ee
   ```

   {{< /tab >}}

   {{< tab title="yum" >}}

   ```shell
   # Amazon Linux 2
   sudo yum remove gitlab-ee
   ```

   {{< /tab >}}

   {{< /tabs >}}

### Ubuntu 22.04 FIPS

In GitLab 18.4 and later, FIPS builds are available for Ubuntu 22.04.

Before you upgrade:

1. Verify password hash migration for all active users: In GitLab 17.11 and later,
   user passwords are automatically rehashed with enhanced salt when users sign in.

   Any users who haven't completed this hash migration will be unable to sign in to
   Ubuntu 22 FIPS installations and will need to perform a password reset.

   To find for users who have not migrated, use [this Rake task](../../administration/raketasks/password.md#check-password-hashes)
   before upgrading to Ubuntu 22.04.

1. Check the GitLab secrets JSON: Rails now requires stronger active dispatch salts to
   issue cookies. The Linux package uses static values with sufficient length by default on
   Ubuntu 22.04. However, you can customize these salts by setting the following keys
   in your Linux package configuration:

   ```ruby
   gitlab_rails['signed_cookie_salt'] = 'custom value'
   gitlab_rails['authenticated_encrypted_cookie_salt'] = 'another custom value'
   ```

   The values are written to the `gitlab-secrets.json` and must be synchronized across
   all Rails nodes.
