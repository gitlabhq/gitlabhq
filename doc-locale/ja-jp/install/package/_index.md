---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージを使用してGitLabをインストール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージは成熟しており、スケーラブルで、GitLab.comで使用されています。さらに柔軟性と回復力が必要な場合は、[リファレンスアーキテクチャ](../../administration/reference_architectures/_index.md)ドキュメントの説明に従ってGitLabをデプロイすることをお勧めします。

Linuxパッケージは、インストールが迅速で、アップグレードが容易であり、他のインストール方法にはない信頼性を高めるための機能が含まれています。GitLabを実行するために必要なすべての異なるサービスとツールをバンドルする単一のパッケージ（Omnibus GitLabとも呼ばれます）を介してインストールします。最小ハードウェア要件については、[インストールの要件](../requirements.md)を参照してください。

Linuxパッケージは、パッケージリポジトリで次のものに使用できます:

- [GitLab Enterprise Edition](https://packages.gitlab.com/gitlab/gitlab-ee)（EE）
- [GitLab Community Edition](https://packages.gitlab.com/gitlab/gitlab-ce)

必要なGitLabバージョンが、ホストのオペレーティングシステムで使用可能であることを確認してください。

## サポートされているプラットフォーム {#supported-platforms}

GitLabは、オペレーティングシステムの長期サポート(LTS)バージョンを正式にサポートしています。Ubuntuなど、一部のオペレーティングシステムには、LTSバージョンと非LTSバージョンの明確な区別があります。ただし、openSUSEなど、LTSの概念に従わないオペレーティングシステムもあります。

通常、オペレーティングシステムのバージョンのサポートは、ベンダーによるサポートが終了するまで提供されます。サポートは、拡張サポート、延長サポート、またはプレミアムサポートではなく、標準サポートまたはメンテナンスサポートとして定義されます。ただし、次のような状況では、オペレーティングシステムのベンダーよりも早くサポートを終了する場合があります:

- ビジネス上の考慮事項: 顧客の採用率の低さ、不均衡なメンテナンスコスト、戦略的な製品方向の変更などが含まれますが、これらに限定されません。
- 技術的な制約: サードパーティの依存関係、セキュリティ要件、または基盤となるテクノロジーの変更により、継続的なサポートが非現実的または不可能になる場合。
- ベンダーのアクション: オペレーティングシステムのベンダーが、当社のソフトウェアの機能に根本的な影響を与える変更を加えたり、必要なコンポーネントが使用できなくなったりした場合。

通常、オペレーティングシステムのバージョンのサポートを中止する少なくとも6か月前に、できる限り非推奨通知を発行します。技術的な制約、ベンダーのアクション、またはその他の外部要因により、より短い通知期間を提供する必要がある場合、合理的に可能な限り迅速にサポートの変更を通知します。

{{< alert type="note" >}}

`amd64`と`x86_64`は同じ64ビットアーキテクチャを指します。名前`arm64`と`aarch64`も互換性があり、同じアーキテクチャを指します。

{{< /alert >}}

| オペレーティングシステム                                                                   | 最初にサポートされたGitLabバージョン | アーキテクチャ          | オペレーティングシステムのEOL | 提案されている最後にサポートされるGitLabのバージョン  | アップストリームリリースノート                                                                                        |
|------------------------------------------------------------------------------------|--------------------------------|-----------------------|----------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------|
| [AlmaLinux 8](almalinux.md)                         | GitLab CE / GitLab EE 14.5.0   | `x86_64`、`aarch64` <sup>1</sup> | 2029年3月             | GitLab CE / GitLab EE 21.10.0 | [AlmaLinuxの詳細](https://almalinux.org/)                                                                   |
| [AlmaLinux 9](almalinux.md)                         | GitLab CE / GitLab EE 16.0.0   | `x86_64`、`aarch64` <sup>1</sup> | 2032年5月             | GitLab CE / GitLab EE 25.0.0  | [AlmaLinuxの詳細](https://almalinux.org/)                                                                   |
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
| [Red Hat Enterprise Linux 8](almalinux.md)          | GitLab CE / GitLab EE 12.8.1   | `x86_64`、`arm64` <sup>1</sup>   | 2029年5月             | GitLab CE / GitLab EE 22.0.0  | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 9](almalinux.md)          | GitLab CE / GitLab EE 16.0.0   | `x86_64`、`arm64` <sup>1</sup>   | 2032年5月             | GitLab CE / GitLab EE 25.0.0  | [Red Hat Enterprise Linuxの詳細](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Ubuntu 20.04](ubuntu.md)                           | GitLab CE / GitLab EE 13.2.0   | `amd64`、`arm64` <sup>1</sup>    | 2025年4月           | GitLab CE / GitLab EE 18.8.0  | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases)                                                            |
| [Ubuntu 22.04](ubuntu.md)                           | GitLab CE / GitLab EE 15.5.0   | `amd64`、`arm64` <sup>1</sup>    | 2027年4月           | GitLab CE / GitLab EE 19.11.0 | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases)。FIPSパッケージは、GitLab 18.4で追加されました。Ubuntu 20.04からアップグレードする前に、[アップグレードノート](#ubuntu-2204-fips)をご覧ください。 |
| [Ubuntu 24.04](ubuntu.md)                           | GitLab CE / GitLab EE 17.1.0   | `amd64`、`arm64` <sup>1</sup>    | 2029年4月           | GitLab CE / GitLab EE 21.11.0 | [Ubuntuの詳細](https://wiki.ubuntu.com/Releases)                                                            |

**Footnotes**（脚注）: 

1. ARMでGitLabを実行する場合、[既知の問題](https://gitlab.com/groups/gitlab-org/-/epics/4397)が存在します。

### 非公式でサポートされていないインストール方法 {#unofficial-unsupported-installation-methods}

次のインストール方法は、より広範なGitLabコミュニティによって現状のまま提供されており、GitLabによってサポートされていません:

- [Debianネイティブパッケージ](https://wiki.debian.org/gitlab/)（Pirate Praveen著）
- [FreeBSDパッケージ](http://www.freshports.org/www/gitlab-ce)（Torsten Zühlsdorff著）
- [Arch Linuxパッケージ](https://archlinux.org/packages/extra/x86_64/gitlab/)（Arch Linuxコミュニティによる）
- [Puppetモジュール](https://forge.puppet.com/puppet/gitlab)（Vox Pupuli著）
- [Ansibleプレイブック](https://github.com/geerlingguy/ansible-role-gitlab)（Jeff Geerling著）
- [GitLab仮想アプライアンス（KVM）](https://marketplace.opennebula.io/appliance/6b54a412-03a5-11e9-8652-f0def1753696)（OpenNebula著）
- [CloudronのGitLab](https://cloudron.io/store/com.gitlab.cloudronapp.html)（Cloudron App Library経由）

## エンドオブライフバージョン {#end-of-life-versions}

GitLabは、オペレーティングシステムのサポート終了日(EOL)まで、オペレーティングシステム用のLinuxパッケージを提供します。EOL日を過ぎると、GitLabは公式パッケージのリリースを停止します。

ただし、オペレーティングシステムがエンドオブライフになった後でも、新しいバージョンのパッケージを提供できないため、非推奨にならない場合があります。この最も一般的な理由としては、パッケージリポジトリプロバイダーであるPackageCloudが新しいバージョンをサポートしていないため、パッケージをアップロードできないことが挙げられます。

サポートが終了したオペレーティングシステムのリストと、それらに対する最終的なGitLabリリースは、以下のとおりです:

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
| SLES 15 SP2      | [2024年12月](https://www.suse.com/lifecycle/#suse-linux-enterprise-server-15)    | [GitLab Enterprise Edition](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-18.1&filter=all&filter=all&dist=sles%2F15.2) |
| Raspbian Wheezy  | [2015年5月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_8.17&dist=debian%2Fwheezy) 8.17 |
| Raspbian Jessie  | [2017年5月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_11.7&dist=debian%2Fjessie) 11.7 |
| Raspbian Stretch | [2020年6月](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.3&dist=raspbian%2Fstretch) 13.3 |
| Raspberry Pi OS Buster | [2024年6月](https://www.debian.org/News/2024/20240615)                        | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_17.7&dist=raspbian%2Fbuster) 17.7 |
| Ubuntu 12.04     | [2017年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_9.1&dist=ubuntu%2Fprecise) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_9.1&dist=ubuntu%2Fprecise) 9.1 |
| Ubuntu 14.04     | [2019年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.10&dist=ubuntu%2Ftrusty) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.10&dist=ubuntu%2Ftrusty) 11.10 |
| Ubuntu 16.04     | [2021年4月](https://ubuntu.com/info/release-end-of-life)                           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.12&dist=ubuntu%2Fxenial) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.12&dist=ubuntu%2Fxenial) 13.12 |
| Ubuntu 18.04     | [2023年6月](https://ubuntu.com/info/release-end-of-life)                            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_16.11&dist=ubuntu%2Fbionic) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=ggitlab-ee_16.11&dist=ubuntu%2Fbionic) 16.11 |

### Raspberry Pi OS（32ビット - Raspbian） {#raspberry-pi-os-32-bit---raspbian}

GitLabは、Raspberry Pi OS（32ビット - Raspbian）のサポートをGitLab 17.11で廃止しました。これが32ビットプラットフォームで利用できる最後のバージョンです。GitLab 18.0以降、Raspberry Pi OS（64ビット）に移行し、[Debian arm64パッケージ](debian.md)を使用する必要があります。

32ビットOSでのデータのバックアップと64ビットOSへの復元については、[PostgreSQLが動作しているオペレーティングシステムをアップグレードする](../../administration/postgresql/upgrading_os.md)を参照してください。

## Linuxパッケージをアンインストールする {#uninstall-the-linux-package}

Linuxパッケージをアンインストールするには、データ（リポジトリ、データベース、設定）を保持するか、すべて削除するかを選択できます:

1. オプション。パッケージを削除する前に、[Linuxパッケージによって作成されたすべてのユーザーとグループ](https://docs.gitlab.com/omnibus/settings/configuration/#disable-user-and-group-account-management)を削除するには:

   ```shell
   sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts
   ```

   {{< alert type="note" >}}

   アカウントまたはグループの削除で問題が発生した場合は、`userdel`または`groupdel`を手動で実行して削除してください。また、`/home/`から残りのユーザーホームディレクトリを手動で削除することもできます。

   {{< /alert >}}

1. データを保持するか、すべて削除するかを選択します:

   - データ（リポジトリ、データベース、設定）を保持するには、GitLabを停止し、その監視プロセスを削除します:

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

1. パッケージをアンインストールします（GitLab FOSSがインストールされている場合は、`gitlab-ce`に置き換えます）:

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

GitLab 18.4以降では、Ubuntu 22.04でFIPSビルドを使用できます。

アップグレードの前に:

1. すべてのアクティブユーザーのパスワードハッシュの移行を確認します: GitLab 17.11以降では、ユーザーパスワードは、ユーザーがサインインすると、強化されたソルトで自動的に再ハッシュされます。

   このハッシュの移行を完了していないユーザーは、Ubuntu 22 FIPSインストールにサインインできなくなり、パスワードのリセットを実行する必要があります。

   移行していないユーザーを見つけるには、Ubuntu 22.04にアップグレードする前に、[このRakeタスク](../../administration/raketasks/password.md#check-password-hashes)を使用してください。

1. GitLabシークレットJSONを確認します: RailsでCookieを発行するには、より強力なアクティブディスパッチソルトが必要になりました。Linuxパッケージは、Ubuntu 22.04でデフォルトで十分な長さの静的な値を使用します。ただし、Linuxパッケージの設定で次のキーを設定することにより、これらのソルトをカスタマイズできます:

   ```ruby
   gitlab_rails['signed_cookie_salt'] = 'custom value'
   gitlab_rails['authenticated_encrypted_cookie_salt'] = 'another custom value'
   ```

   これらの値は`gitlab-secrets.json`に書き込まれ、すべてのRailsノード間で同期されている必要があります。
