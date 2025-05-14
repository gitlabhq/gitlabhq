---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サポート対象のオペレーティングシステム
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、オペレーティングシステムの長期サポート(LTS)バージョンを正式にサポートしています。Ubuntuなど、一部のオペレーティングシステムには、LTSバージョンと非LTSバージョンの明確な区別があります。ただし、openSUSEなど、LTSの概念に従わないオペレーティングシステムもあります。

混乱を避けるため、GitLabでサポートされているすべてのオペレーティングシステムは、[インストールページ](https://about.gitlab.com/install/)に記載されています。

{{< alert type="note" >}}

`amd64`と`x86_64`は同じ64ビットアーキテクチャを指します。名前`arm64`と`aarch64`も互換性があり、同じアーキテクチャを指します。

{{< /alert >}}

## AlmaLinux

AlmaLinuxの次のバージョンがサポートされています。

| オペレーティングシステム | 最初にサポートされたGitLabバージョン | アーキテクチャ        | インストールに関するドキュメント                                                          | オペレーティングシステムのEOL | 詳細 |
|:-----------------|:-------------------------------|:--------------------|:------------------------------------------------------------------------------------|:---------------------|:--------|
| AlmaLinux 8      | GitLab CE / GitLab EE 14.5.0   | `x86_64`、`aarch64` | [AlmaLinuxインストールに関するドキュメント](https://about.gitlab.com/install/#almalinux) | 2029                 | [AlmaLinuxの詳細](https://almalinux.org/) |
| AlmaLinux 9      | GitLab CE / GitLab EE 16.0.0   | `x86_64`、`aarch64` | [AlmaLinuxインストールに関するドキュメント](https://about.gitlab.com/install/#almalinux) | 2032                 | [AlmaLinuxの詳細](https://almalinux.org/) |

## Amazon Linux

Amazon Linuxの次のバージョンがサポートされています。

| オペレーティングシステム  | 最初にサポートされたGitLabバージョン | アーキテクチャ     | インストールに関するドキュメント                                                                         | オペレーティングシステムのEOL | 詳細 |
|:------------------|:-------------------------------|:-----------------|:---------------------------------------------------------------------------------------------------|:---------------------|:--------|
| Amazon Linux 2    | GitLab CE / GitLab EE 14.9.0   | `amd64`、`arm64` | [Amazon Linux 2インストールに関するドキュメント](https://about.gitlab.com/install/#amazonlinux-2)       | 2026年6月            | [Amazon Linuxの詳細](https://aws.amazon.com/amazon-linux-2/faqs/) |
| Amazon Linux 2023 | GitLab CE / GitLab EE 16.3.0   | `amd64`、`arm64` | [Amazon Linux 2023インストールに関するドキュメント](https://about.gitlab.com/install/#amazonlinux-2023) | 2028                 | [Amazon Linuxの詳細](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html) |

## Debian

Debianの次のバージョンがサポートされています。

| オペレーティングシステム | 最初にサポートされたGitLabバージョン | アーキテクチャ     | インストールに関するドキュメント                                                    | オペレーティングシステムのEOL | 詳細 |
|:-----------------|:-------------------------------|:-----------------|:------------------------------------------------------------------------------|:---------------------|:--------|
| Debian 11        | GitLab CE / GitLab EE 14.6.0   | `amd64`、`arm64` | [Debianインストールに関するドキュメント](https://about.gitlab.com/install/#debian) | 2026                 | [Debian Linuxの詳細](https://wiki.debian.org/LTS) |
| Debian 12        | GitLab CE / GitLab EE 16.1.0   | `amd64`、`arm64` | [Debianインストールに関するドキュメント](https://about.gitlab.com/install/#debian) | TBD                  | [Debian Linuxの詳細](https://wiki.debian.org/LTS) |

## openSUSE LeapおよびSUSE Linux Enterprise Server

openSUSE LeapおよびSUSE Linux Enterprise Serverの次のバージョンがサポートされています。

| オペレーティングシステムのバージョン        | 最初にサポートされたGitLabバージョン | アーキテクチャ        | インストールに関するドキュメント                                                                 | オペレーティングシステムのEOL | 詳細 |
|:--------------------------------|:-------------------------------|:--------------------|:-------------------------------------------------------------------------------------------|:---------------------|:--------|
| openSUSE Leap 15.6              | GitLab CE / GitLab EE 17.6.0   | `x86_64`、`aarch64` | [openSUSEインストールに関するドキュメント](https://about.gitlab.com/install/#opensuse-leap)     | 2025年12月             | [openSUSEの詳細](https://en.opensuse.org/Lifetime) |
| SUSE Linux Enterprise Server 12 | GitLab EE 9.0.0                | `x86_64`            | [OpenSUSEインストールに関するドキュメント](https://about.gitlab.com/install/#opensuse-leap)を使用してください | 2027年10月             | [SUSE Linux Enterprise Serverの詳細](https://www.suse.com/lifecycle/) |
| SUSE Linux Enterprise Server 15 | GitLab EE 14.8.0               | `x86_64`            | [OpenSUSEインストールに関するドキュメント](https://about.gitlab.com/install/#opensuse-leap)を使用してください | 2024年12月             | [SUSE Linux Enterprise Serverの詳細](https://www.suse.com/lifecycle/) |

## Oracle Linux

Oracle Linuxの次のバージョンがサポートされています。

| オペレーティングシステム | 最初にサポートされたGitLabバージョン | アーキテクチャ | インストールに関するドキュメント                                                              | オペレーティングシステムのEOL | 詳細 |
|:-----------------|:-------------------------------|:-------------|:----------------------------------------------------------------------------------------|:---------------------|:--------|
| Oracle Linux 8   | GitLab CE / GitLab EE 12.8.1   | `x86_64`     | [AlmaLinuxインストールに関するドキュメント](https://about.gitlab.com/install/#almalinux)を使用してください | 2029年7月            | [Oracle Linuxの詳細](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf) |
| Oracle Linux 9   | GitLab CE / GitLab EE 16.2.0   | `x86_64`     | [AlmaLinuxインストールに関するドキュメント](https://about.gitlab.com/install/#almalinux)を使用してください | 2032年6月            | [Oracle Linuxの詳細](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf) |

## Raspberry Pi OS

Raspberry Pi OSの次のバージョンがサポートされています。

| オペレーティングシステムのバージョン                                     | 最初にサポートされたGitLabバージョン | アーキテクチャ | インストールに関するドキュメント                                                                   | オペレーティングシステムのEOL | 詳細 |
|:-------------------------------------------------------------|:-------------------------------|:-------------|:---------------------------------------------------------------------------------------------|:---------------------|:--------|
| Raspberry Pi OS (Bullseye)                                   | GitLab CE 15.5.0               | `armhf`      | [Raspberry Piインストールに関するドキュメント](https://about.gitlab.com/install/#raspberry-pi-os) | 2026                 | [Raspberry Piの詳細](https://www.raspberrypi.com/news/raspberry-pi-os-debian-bullseye/) |

## Red Hat Enterprise Linux

Red Hat Enterprise Linuxの次のバージョンがサポートされています。

| オペレーティングシステムのバージョン   | 最初にサポートされたGitLabバージョン | アーキテクチャ      | インストールに関するドキュメント                                                          | オペレーティングシステムのEOL | 詳細 |
|:---------------------------|:-------------------------------|:------------------|:------------------------------------------------------------------------------------|:---------------------|:--------|
| Red Hat Enterprise Linux 8 | GitLab CE / GitLab EE 12.8.1   | `x86_64`、`arm64` | [CentOSインストールに関するドキュメント](https://about.gitlab.com/install/#centos-7)を使用してください | 2029年5月             | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| Red Hat Enterprise Linux 9 | GitLab CE / GitLab EE 16.0.0   | `x86_64`、`arm64` | [CentOSインストールに関するドキュメント](https://about.gitlab.com/install/#centos-7)を使用してください | 2032年5月             | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |

## Ubuntu

Ubuntuの次のバージョンがサポートされています。

| オペレーティングシステム | 最初にサポートされたGitLabバージョン | アーキテクチャ     | インストールに関するドキュメント                                                    | オペレーティングシステムのEOL | 詳細 |
|:-----------------|:-------------------------------|:-----------------|:------------------------------------------------------------------------------|:---------------------|:--------|
| Ubuntu 20.04     | GitLab CE / GitLab EE 13.2.0   | `amd64`、`arm64` | [Ubuntuインストールに関するドキュメント](https://about.gitlab.com/install/#ubuntu) | 2025年4月           | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases) |
| Ubuntu 22.04     | GitLab CE / GitLab EE 15.5.0   | `amd64`、`arm64` | [Ubuntuインストールに関するドキュメント](https://about.gitlab.com/install/#ubuntu) | 2027年4月           | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases) |
| Ubuntu 24.04     | GitLab CE / GitLab EE 17.1.0   | `amd64`、`arm64` | [Ubuntuインストールに関するドキュメント](https://about.gitlab.com/install/#ubuntu) | 2029年4月           | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases) |

## OSのアップグレード後にGitLabパッケージソースを更新する

オペレーティングシステムをアップグレードした後、パッケージマネージャの設定でGitLabパッケージソースURLの更新が必要な場合もあります。

パッケージマネージャが、これ以上のアップデートはないと報告するにもかかわらず、アップデートが存在することがわかっている場合は、[Linuxパッケージインストールガイド](https://about.gitlab.com/install/#content)の手順を繰り返して、GitLabパッケージリポジトリを追加してください。今後のGitLabアップグレードは、アップグレードされたオペレーティングシステムに従って取得されます。

## GitLabとオペレーティングシステムの両方を更新する

オペレーティングシステム(OS)とGitLabの両方をアップグレードするには:

1. OSをアップグレードします。
1. [GitLabパッケージソースを更新する](#update-gitlab-package-sources-after-upgrading-the-os)必要があるかどうかを確認します。
1. [GitLabをアップグレード](../../update/_index.md)します。

## OSのアップグレード後にPostgresインデックスが破損する

オペレーティングシステムのアップグレードの一環として、`glibc`のバージョンが変更された場合は、インデックスの破損を避けるために、[PostgreSQLのオペレーティングシステムのアップグレード](../postgresql/upgrading_os.md)に従う必要があります。

## ARM64のパッケージ

GitLabは、サポートされている一部のオペレーティングシステム向けにarm64/aarch64パッケージを提供しています。お使いのオペレーティングシステムのアーキテクチャがサポートされているかどうかは、上記の表で確認できます。

{{< alert type="warning" >}}

ARMでGitLabを実行する場合、[既知の問題](https://gitlab.com/groups/gitlab-org/-/epics/4397)が存在します。

{{< /alert >}}

## サポート終了したOSバージョン

GitLabは、オペレーティングシステムのサポート終了日(EOL)まで、オペレーティングシステム用のLinuxパッケージを提供します。EOL日を過ぎると、GitLabは公式パッケージのリリースを停止します。サポートが終了したオペレーティングシステムのリストと、それらに対する最終的なGitLabリリースは、以下のとおりです。

| OSバージョン       | サポート終了                                                                         | 最後にサポートされたGitLabバージョン |
|:-----------------|:------------------------------------------------------------------------------------|:------------------------------|
| CentOS 6         | [2020年11月](https://www.centos.org/about/)                                      | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=13.6&filter=all&filter=all&dist=el%2F6) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=13.6&filter=all&filter=all&dist=el%2F6) 13.6 |
| CentOS 7         | [2024年6月](https://www.centos.org/about/)                                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=el%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=el%2F7) 17.7 |
| CentOS 8         | [2021年12月](https://www.centos.org/about/)                                      | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=14.6&filter=all&filter=all&dist=el%2F8) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=14.6&filter=all&filter=all&dist=el%2F8) 14.6 |
| Oracle Linux 7   | [2024年12月](https://endoflife.date/oracle-linux)                                | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=ol%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=ol%2F7) 17.7 |
| Scientific Linux 7 | [2024年6月](https://scientificlinux.org/downloads/sl-versions/sl7/)               | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=scientific%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=scientific%2F7) 17.7 |
| Debian 7 Wheezy  | [2018年5月](https://www.debian.org/News/2018/20180601)                               | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.6&dist=debian%2Fwheezy) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.6&dist=debian%2Fwheezy) 11.6 |
| Debian 8 Jessie  | [2020年6月](https://www.debian.org/News/2020/20200709)                              | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.2&dist=debian%2Fjessie) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.2&dist=debian%2Fjessie) 13.3 |
| Debian 9 Stretch | [2022年6月](https://lists.debian.org/debian-lts-announce/2022/07/msg00002.html)     | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_15.2&dist=debian%2Fstretch) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_15.2&dist=debian%2Fstretch) 15.2 |
| Debian 10 Buster | [2024年6月](https://www.debian.org/News/2024/20240615)                              | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_17.5&dist=debian%2Fbuster) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_17.5&dist=debian%2Fbuster) 17.5 |
| OpenSUSE 42.1    | [2017年5月](https://en.opensuse.org/Lifetime#Discontinued_distributions)             | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.3&dist=opensuse%2F42.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.3&dist=opensuse%2F42.1) 9.3 |
| OpenSUSE 42.2    | [2018年1月](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-10.4&dist=opensuse%2F42.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-10.4&dist=opensuse%2F42.2) 10.4 |
| OpenSUSE 42.3    | [2019年7月](https://en.opensuse.org/Lifetime#Discontinued_distributions)            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.1&dist=opensuse%2F42.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.1&dist=opensuse%2F42.3) 12.1 |
| OpenSUSE 13.2    | [2017年1月](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.1&dist=opensuse%2F13.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.1&dist=opensuse%2F13.2) 9.1 |
| OpenSUSE 15.0    | [2019年12月](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.5&dist=opensuse%2F15.0) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.5&dist=opensuse%2F15.0) 12.5 |
| OpenSUSE 15.1    | [2020年11月](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-13.12&dist=opensuse%2F15.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-13.12&dist=opensuse%2F15.1) 13.12 |
| OpenSUSE 15.2    | [2021年12月](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-14.7&dist=opensuse%2F15.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-14.7&dist=opensuse%2F15.2) 14.7 |
| OpenSUSE 15.3    | [2022年12月](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-15.10&dist=opensuse%2F15.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-15.10&dist=opensuse%2F15.3) 15.10 |
| OpenSUSE 15.4    | [2023年12月](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-16.7&dist=opensuse%2F15.4) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-16.7&dist=opensuse%2F15.4) 16.7 |
| OpenSUSE 15.5    | [2024年12月](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-17.8&dist=opensuse%2F15.5) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-17.8&dist=opensuse%2F15.5) 17.8 |
| Raspbian Wheezy  | [2015年5月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_8.17&dist=debian%2Fwheezy) 8.17 |
| Raspbian Jessie  | [2017年5月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_11.7&dist=debian%2Fjessie) 11.7 |
| Raspbian Stretch | [2020年6月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.3&dist=raspbian%2Fstretch) 13.3 |
| Raspberry Pi OS Buster | [2024年6月](https://www.debian.org/News/2024/20240615)                        | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_17.7&dist=raspbian%2Fbuster) 17.7 |
| Ubuntu 12.04     | [2017年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_9.1&dist=ubuntu%2Fprecise) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_9.1&dist=ubuntu%2Fprecise) 9.1 |
| Ubuntu 14.04     | [2019年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.10&dist=ubuntu%2Ftrusty) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.10&dist=ubuntu%2Ftrusty) 11.10 |
| Ubuntu 16.04     | [2021年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.12&dist=ubuntu%2Fxenial) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.12&dist=ubuntu%2Fxenial) 13.12 |
| Ubuntu 18.04     | [2023年6月](https://ubuntu.com/info/release-end-of-life)                            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_16.11&dist=ubuntu%2Fbionic) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=ggitlab-ee_16.11&dist=ubuntu%2Fbionic) 16.11 |

{{< alert type="note" >}}

このサポート終了ポリシーの例外となるのは、次のバージョンのオペレーティングシステム向けにパッケージを提供できない場合です。この最も一般的な理由としては、パッケージリポジトリプロバイダーであるPackageCloudが新しいバージョンをサポートしていないため、パッケージをアップロードできないことが挙げられます。

{{< /alert >}}
