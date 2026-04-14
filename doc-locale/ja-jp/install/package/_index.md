---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージを使用してGitLabをインストールします
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このLinuxパッケージは成熟しており、スケーラブルで、GitLab.comで使用されています。追加の柔軟性と回復性が必要な場合は、[リファレンスアーキテクチャのドキュメント](../../administration/reference_architectures/_index.md)に記載されているようにGitLabをデプロイすることをお勧めします。

Linuxパッケージは、インストールが迅速でアップグレードが容易であり、他のインストール方法では見られない信頼性を高める機能が含まれています。Omnibus GitLabとしても知られる単一のパッケージを通じてインストールします。これにより、GitLabの実行に必要なすべての異なるサービスとツールがバンドルされます。最小ハードウェア要件については、[インストールの要件](../requirements.md)を参照してください。

Linuxパッケージは、弊社のパッケージリポジトリで入手できます:

- [GitLab Enterprise Edition](https://packages.gitlab.com/gitlab/gitlab-ee)。
- [GitLab Community Edition](https://packages.gitlab.com/gitlab/gitlab-ce)。

必要なGitLabバージョンがホストのオペレーティングシステムで利用可能であることを確認してください。

## サポートされているプラットフォーム {#supported-platforms}

GitLabは、以下のオペレーティングシステム向けにLinuxパッケージを提供しています。これらのプラットフォーム向けにパッケージをビルドし、配布しています。この表は、各オペレーティングシステムで利用可能なGitLabバージョンを示しています。

ベンダーのサポートライフサイクルに基づいて、オペレーティングシステム向けのLinuxパッケージを提供しています。LTSバージョンが存在する場合、当社はそれらを対象としますが、すべてのオペレーティングシステムがLTSモデルに従っているわけではありません。

パッケージビルドは通常、オペレーティングシステムがベンダーのエンドオブライフ (EOL) に達するまで継続されます。当社は標準またはメンテナンスサポートのタイムラインに従い、延長またはプレミアムサポート期間は対象外です。

ベンダーのEOL前にパッケージビルドを中止する場合があります。その理由は次のとおりです:

- ビジネス上の考慮事項: 顧客の利用率の低さ、不均衡なメンテナンスコスト、戦略的な製品方向の変更などが含まれますが、これらに限定されません。
- 技術的な制約: サードパーティの依存関係、セキュリティ要件、または基盤となるテクノロジーの変更により、継続的なパッケージビルドが非現実的または不可能になった場合。
- ベンダーの対応: オペレーティングシステムベンダーが、当社のソフトウェアの機能に根本的に影響を与える変更を行う場合、または必要なコンポーネントが利用できなくなった場合。

いずれかのオペレーティングシステムバージョンのサポートを中止する前に、少なくとも6か月の通知を行うことを目指しています。技術的な制限またはベンダーの制約により、より短い通知期間が必要な場合は、可能な限り迅速に変更をお知らせします。

> [!note]
> `amd64`および`x86_64`は、同じ64ビットアーキテクチャを指します。名前`arm64`と`aarch64`も互換性があり、同じアーキテクチャを指します。

| オペレーティングシステム                                                                   | 最初にサポートされたGitLabバージョン | アーキテクチャ          | オペレーティングシステムのEOL | 提案されている最終サポートGitLabバージョン  | アップストリームリリースノート                                                                                        |
|------------------------------------------------------------------------------------|--------------------------------|-----------------------|----------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------|
| [AlmaLinux 8](almalinux.md)                         | GitLab CE / GitLab EE 14.5.0   | `x86_64`、`aarch64` <sup>1</sup> | 2029年3月             | GitLab CE / GitLab EE 21.10.0 | [AlmaLinuxの詳細](https://almalinux.org/)                                                                   |
| [AlmaLinux 9](almalinux.md)                         | GitLab CE / GitLab EE 16.0.0   | `x86_64`、`aarch64` <sup>1</sup> | 2032年5月             | GitLab CE / GitLab EE 25.0.0  | [AlmaLinuxの詳細](https://almalinux.org/)                                                                   |
| [AlmaLinux 10](almalinux.md)                         | GitLab CE / GitLab EE 18.6.0   | `x86_64`、`aarch64` <sup>1</sup> | 2035年5月             | GitLab CE / GitLab EE 28.0.0  | [AlmaLinuxの詳細](https://almalinux.org/)                                                                  |
| [Amazon Linux 2](amazonlinux_2.md)                  | GitLab CE / GitLab EE 14.9.0   | `amd64`、`arm64` <sup>1</sup>    | 2026年6月            | GitLab CE / GitLab EE 19.1.0  | [Amazon Linuxの詳細](https://aws.amazon.com/amazon-linux-2/faqs/)                                           |
| [Amazon Linux 2023](amazonlinux_2023.md)            | GitLab CE / GitLab EE 16.3.0   | `amd64`、`arm64` <sup>1</sup>    | 2029年6月            | GitLab CE / GitLab EE 22.1.0  | [Amazon Linuxの詳細](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html)                      |
| [Debian 11](debian.md)                              | GitLab CE / GitLab EE 14.6.0   | `amd64`、`arm64` <sup>1</sup>    | 2026年8月             | GitLab CE / GitLab EE 19.3.0  | [Debian Linuxの詳細](https://wiki.debian.org/LTS)                                                           |
| [Debian 12](debian.md)                              | GitLab CE / GitLab EE 16.1.0   | `amd64`、`arm64` <sup>1</sup>    | 2028年6月            | GitLab CE / GitLab EE 19.3.0  | [Debian Linuxの詳細](https://wiki.debian.org/LTS)                                                           |
| [Debian 13](debian.md)                              | GitLab CE / GitLab EE 18.5.0   | `amd64`、`arm64` <sup>1</sup>    | 2030年6月            | GitLab CE / GitLab EE 23.1.0  | [Debian Linuxの詳細](https://wiki.debian.org/LTS)                                                           |
| [openSUSE Leap 15.6](suse.md)              | GitLab CE / GitLab EE 17.6.0   | `x86_64`、`aarch64` <sup>1</sup> | 2025年12月             | TBD  | [openSUSEの詳細](https://en.opensuse.org/Lifetime)                                                          |
| [SUSE Linux Enterprise Server 12](suse.md) | GitLab EE 9.0.0                | `x86_64`              | 2027年10月             | TBD  | [SUSE Linux Enterprise Serverの詳細](https://www.suse.com/lifecycle/)                                       |
| [SUSE Linux Enterprise Server 15](suse.md) | GitLab EE 14.8.0               | `x86_64`              | 2024年12月             | TBD  | [SUSE Linux Enterprise Serverの詳細](https://www.suse.com/lifecycle/)                                       |
| [Oracle Linux 8](almalinux.md)                      | GitLab CE / GitLab EE 12.8.1   | `x86_64`              | 2029年7月            | GitLab CE / GitLab EE 22.2.0  | [Oracle Linuxの詳細](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 9](almalinux.md)                      | GitLab CE / GitLab EE 16.2.0   | `x86_64`              | 2032年6月            | GitLab CE / GitLab EE 25.1.0  | [Oracle Linuxの詳細](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 10](almalinux.md)                      | GitLab CE / GitLab EE 18.6.0   | `x86_64`              | 2035年6月            | GitLab CE / GitLab EE 28.1.0  | [Oracle Linuxの詳細](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Red Hat Enterprise Linux 8](almalinux.md)          | GitLab CE / GitLab EE 12.8.1   | `x86_64`、`arm64` <sup>1</sup>   | 2029年5月             | GitLab CE / GitLab EE 22.0.0  | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 9](almalinux.md)          | GitLab CE / GitLab EE 16.0.0   | `x86_64`、`arm64` <sup>1</sup>   | 2032年5月             | GitLab CE / GitLab EE 25.0.0  | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 10](almalinux.md)          | GitLab CE / GitLab EE 18.6.0   | `x86_64`、`arm64` <sup>1</sup>   | 2035年5月             | GitLab CE / GitLab EE 28.0.0  | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Ubuntu 20.04](ubuntu.md)                           | GitLab CE / GitLab EE 13.2.0   | `amd64`、`arm64` <sup>1</sup>    | 2025年4月           | GitLab CE / GitLab EE 18.8.0  | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases)                                                            |
| [Ubuntu 22.04](ubuntu.md)                           | GitLab CE / GitLab EE 15.5.0   | `amd64`、`arm64` <sup>1</sup>    | 2027年4月           | GitLab CE / GitLab EE 19.11.0 | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases)。GitLab 18.4でFIPSパッケージが追加されました。Ubuntu 20.04からアップグレードする前に、[アップグレードノート](#ubuntu-2204-fips)を確認してください。 |
| [Ubuntu 24.04](ubuntu.md)                           | GitLab CE / GitLab EE 17.1.0   | `amd64`、`arm64` <sup>1</sup>    | 2029年4月           | GitLab CE / GitLab EE 21.11.0 | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases)                                                            |

**脚注**: 

1. ARMでGitLabを実行する場合、[既知の問題](https://gitlab.com/groups/gitlab-org/-/epics/4397)が存在します。

### 非公式、未サポートのインストール方法 {#unofficial-unsupported-installation-methods}

以下のインストール方法は、幅広いGitLabコミュニティによって現状のまま提供されており、GitLabではサポートされていません:

- [Debianネイティブパッケージ](https://wiki.debian.org/gitlab/) (Pirate Praveen氏による)
- [FreeBSDパッケージ](http://www.freshports.org/www/gitlab-ce) (Torsten Zühlsdorff氏による)
- [Arch Linuxパッケージ](https://archlinux.org/packages/extra/x86_64/gitlab/) (Arch Linuxコミュニティによる)
- [Puppetモジュール](https://forge.puppet.com/puppet/gitlab) (Vox Pupuliによる)
- [Ansibleプレイブック](https://github.com/geerlingguy/ansible-role-gitlab) (Jeff Geerlingによる)
- [GitLab仮想アプライアンス (KVM)](https://marketplace.opennebula.io/appliance/6b54a412-03a5-11e9-8652-f0def1753696) (OpenNebulaによる)
- [Cloudron上のGitLab](https://cloudron.io/store/com.gitlab.cloudronapp.html) (Cloudron App Library経由)

## エンドオブライフバージョン {#end-of-life-versions}

非推奨のオペレーティングシステムとそれらの最終GitLabリリースのリストを以下の表で確認できます:

| OSバージョン       | サポート終了                                                                         | 最後にサポートされたGitLabバージョン |
|:-----------------|:------------------------------------------------------------------------------------|:------------------------------|
| CentOS 6およびRHEL 6 | [2020年11月](https://www.centos.org/about/)                                   | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=13.6&filter=all&filter=all&dist=el%2F6) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=13.6&filter=all&filter=all&dist=el%2F6) 13.6 |
| CentOS 7およびRHEL 7 | [2024年6月](https://www.centos.org/about/)                                       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=17.7&filter=all&filter=all&dist=el%2F7) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=17.7&filter=all&filter=all&dist=el%2F7) 17.7 |
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
| SLES 15 SP2      | [2024年12月](https://www.suse.com/lifecycle/#suse-linux-enterprise-server-15)    | [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-18.1&filter=all&filter=all&dist=sles%2F15.2) |
| Raspbian Wheezy  | [2015年5月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_8.17&dist=debian%2Fwheezy) 8.17 |
| Raspbian Jessie  | [2017年5月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_11.7&dist=debian%2Fjessie) 11.7 |
| Raspbian Stretch | [2020年6月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.3&dist=raspbian%2Fstretch) 13.3 |
| Raspberry Pi OS Buster | [2024年6月](https://www.debian.org/News/2024/20240615)                        | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_17.7&dist=raspbian%2Fbuster) 17.7 |
| Ubuntu 12.04     | [2017年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_9.1&dist=ubuntu%2Fprecise) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_9.1&dist=ubuntu%2Fprecise) 9.1 |
| Ubuntu 14.04     | [2019年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.10&dist=ubuntu%2Ftrusty) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.10&dist=ubuntu%2Ftrusty) 11.10 |
| Ubuntu 16.04     | [2021年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.12&dist=ubuntu%2Fxenial) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.12&dist=ubuntu%2Fxenial) 13.12 |
| Ubuntu 18.04     | [2023年6月](https://ubuntu.com/info/release-end-of-life)                            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_16.11&dist=ubuntu%2Fbionic) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=ggitlab-ee_16.11&dist=ubuntu%2Fbionic) 16.11 |

### Raspberry Pi OS (32ビット - Raspbian) {#raspberry-pi-os-32-bit---raspbian}

GitLabはRaspberry Pi OS (32ビット - Raspbian) のサポートを終了しました。GitLab 17.11が32ビットプラットフォームで利用可能な最後のバージョンとなります。GitLab 18.0以降、Raspberry Pi OS (64ビット) に移行し、[Debian arm64パッケージ](debian.md)を使用する必要があります。

32ビットOSでのデータのバックアップと64ビットOSへの復元については、[PostgreSQLが動作しているオペレーティングシステムをアップグレードする](../../administration/postgresql/upgrading_os.md)を参照してください。

## Linuxパッケージのアンインストール {#uninstall-the-linux-package}

Linuxパッケージをアンインストールするには、データ (リポジトリ、データベース、設定) を保持するか、すべて削除するかを選択できます:

1. オプション。パッケージを削除する前に、[Linuxパッケージによって作成されたすべてのユーザーとグループ](https://docs.gitlab.com/omnibus/settings/configuration/#disable-user-and-group-account-management)を削除するには:

   ```shell
   sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts
   ```

   > [!note]
   > アカウントまたはグループの削除に問題がある場合は、`userdel`または`groupdel`を手動で実行して削除してください。また、`/home/`から残ったユーザーのホームディレクトリを手動で削除することもできます。

1. データを保持するか、すべて削除するかを選択してください:

   - データ (リポジトリ、データベース、設定) を保持するには、GitLabを停止し、その監視プロセスを削除します:

     ```shell
     sudo systemctl stop gitlab-runsvdir
     sudo systemctl disable gitlab-runsvdir
     sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
     sudo systemctl daemon-reload
     sudo systemctl reset-failed
     sudo gitlab-ctl uninstall
     ```

   - すべてのデータを削除するには:

     ```shell
     sudo gitlab-ctl cleanse && sudo rm -r /opt/gitlab
     ```

1. パッケージをアンインストールします (GitLab FOSSがインストールされている場合は、`gitlab-ce`に置き換えます):

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

### Ubuntu 22.04 FIPS {#ubuntu-2204-fips}

> [!warning]
>
> GitLab FIPSモードとUbuntu 22.04の間には、現在既知の互換性の問題が存在します。管理者は、追って通知があるまで、ホストのオペレーティングシステムをUbuntu 22.04にアップグレードすることを控える必要があります。
>
> この勧告は、問題が特定され、解決するされ次第更新されます。

GitLab 18.4以降では、Ubuntu 22.04向けにFIPSビルドが利用可能です。

アップグレードする前に:

1. すべてのアクティブユーザーのパスワードハッシュ移行を確認します: GitLab 17.11以降では、ユーザーがサインインする際に、ユーザーのパスワードは強化されたソルトで自動的に再ハッシュされます。

   このハッシュ移行を完了していないユーザーは、Ubuntu 22 FIPSインストールにサインインできなくなり、パスワードのリセットを実行する必要があります。

   移行するしていないユーザーを見つけるには、Ubuntu 22.04にアップグレードする前に[このRakeタスク](../../administration/raketasks/password.md#check-password-hashes)を使用してください。

1. GitLabシークレットのJSONを確認します: Railsは現在、クッキーを発行するためにより強力なアクティブディスパッチソルトを必要とします。Linuxパッケージは、Ubuntu 22.04でデフォルトで十分な長さの静的値を使用します。ただし、Linuxパッケージ設定で以下のキーを設定することで、これらのソルトをカスタマイズできます:

   ```ruby
   gitlab_rails['signed_cookie_salt'] = 'custom value'
   gitlab_rails['authenticated_encrypted_cookie_salt'] = 'another custom value'
   ```

   これらの値は`gitlab-secrets.json`に書き込まれ、すべてのRailsノード間で同期される必要があります。

1. FIPS 140-3へのアップグレード時のOAuthトークン移行の準備: GitLab 18.6.0、18.5.2、および18.4.4では、FIPS 140-3要件に準拠するためにOAuthトークンのSHA512ハッシュが導入されました。以前のGitLabはソルトなしのPBKDF2を使用していましたが、これはUbuntu 22.04のようなFIPS 140-3準拠システムとは互換性がありません。

   **注:**この移行は、FIPS 140-3準拠のオペレーティングシステム (Ubuntu 22.04など) に移行する場合にのみ必要です。すでに古いFIPSバージョン (Ubuntu 20.04など) で実行している場合、または非FIPSシステムを使用している場合は、変更は必要ありません。

   非FIPSインスタンスまたは古いFIPSバージョンからFIPS 140-3インスタンスに移行する場合:

   1. GitLab 18.4以降にアップグレードします。
   1. 通常の使用中に、アクティブなOAuthアクセストークンが自動的に再ハッシュされるのに十分な時間を確保します。
   1. OAuthアプリケーションのシークレットをローテーションして、新しく発行されたすべてのトークンがFIPS準拠のハッシュアルゴリズムを使用するようにします。
   1. ユーザーに、トークンが最近使用されていない場合、OAuth統合アプリケーションで再認証する必要があるかもしれないことを通知します。
