---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージインスタンスをアップグレードする
description: Linuxパッケージベースのインスタンスをアップグレードします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

LinuxパッケージインストールをGitLabの新しいバージョンにアップグレードします。

## オペレーティングシステムをアップグレードする（オプション） {#upgrade-the-operating-system-optional}

必要に応じて、GitLab自体をアップグレードする前に、[サポートされているオペレーティングシステム](../../administration/package_information/supported_os.md)にアップグレードしてください。

オペレーティングシステムをアップグレードした後、パッケージマネージャーの設定でGitLabパッケージソースURLの更新が必要となる場合もあります。パッケージマネージャーでこれ以上の更新はないと報告されているが、更新が存在することがわかっている場合は、[Linuxパッケージインストールガイド](https://about.gitlab.com/install/#content)の手順を繰り返して、GitLabパッケージリポジトリを追加してください。今後のGitLabアップグレードは、アップグレードされたオペレーティングシステムに従って取得されます。

### OSをアップグレードした後のPostgreSQLインデックスの破損 {#corrupted-postgresql-indexes-after-upgrading-the-os}

オペレーティングシステムのアップグレードの一環として、`glibc`のバージョンが変更された場合は、インデックスの破損を避けるために、[PostgreSQLのオペレーティングシステムのアップグレード](../../administration/postgresql/upgrading_os.md)に従う必要があります。

## GitLabの以前のバージョン {#earlier-gitlab-versions}

GitLabの以前のバージョンのバージョン固有の情報については、[ドキュメントアーカイブ](https://archives.docs.gitlab.com)を参照してください。アーカイブ内のドキュメントのバージョンには、さらに以前のバージョンのGitLabに関するバージョン固有の情報が含まれています。

たとえば、[GitLab 15.11のドキュメント](https://archives.docs.gitlab.com/15.11/ee/update/package/#version-specific-changes)には、GitLab 11までのバージョンに関する情報が含まれています。

## 自動データベースバックアップをスキップする {#skip-automatic-database-backups}

GitLabデータベースは、新しいGitLabバージョンをインストールする前にバックアップされます。次の場所に空のファイルを作成すると、このデータベースの自動バックアップをスキップできます（`/etc/gitlab/skip-auto-backup`）。

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

ただし、ご自身で最新の完全な[バックアップ](../../administration/backup_restore/_index.md)を保持しておく必要があります。

## Linuxパッケージインスタンスをアップグレードする {#upgrade-a-linux-package-instance}

Linuxパッケージインスタンスをアップグレードするには、次の手順に従います。

1. メインのGitLabアップグレードドキュメントの[初期手順を完了](../upgrade.md#upgrade-gitlab)します。
1. パッケージ以外のインストールからGitLabパッケージインストールにアップグレードする場合は、[パッケージ以外のインストールからGitLabパッケージインストールにアップグレードする](https://docs.gitlab.com/omnibus/update/convert_to_omnibus.html)の手順に従ってください。
1. 以降のセクションに従って、アップグレードを続行します。

### 必須サービス {#required-services}

GitLabインスタンスをオンラインにした状態でアップグレードを実行できます。アップグレードコマンドを実行するときは、PostgreSQL、Redis、Gitalyが実行されている必要があります。

### 公式リポジトリを使用する（推奨） {#by-using-the-official-repositories-recommended}

すべてのGitLabパッケージは、GitLab[パッケージサーバー](https://packages.gitlab.com/gitlab/)に公開されています。6つのリポジトリが保持されています。

- [`gitlab/gitlab-ee`](https://packages.gitlab.com/gitlab/gitlab-ee): すべてのCommunity Edition機能に加えて、[Enterprise Edition](https://about.gitlab.com/pricing/)機能を含む完全なGitLabパッケージ。
- [`gitlab/gitlab-ce`](https://packages.gitlab.com/gitlab/gitlab-ce): Community Edition機能のみを含む簡素化されたパッケージ。
- [`gitlab/gitlab-fips`](https://packages.gitlab.com/gitlab/gitlab-fips): FIPS準拠ビルド。
- [`gitlab/unstable`](https://packages.gitlab.com/gitlab/unstable): リリース候補およびその他の不安定なバージョン。
- [`gitlab/nightly-builds`](https://packages.gitlab.com/gitlab/nightly-builds): 毎日夜間に作成されるビルド。
- [`gitlab/raspberry-pi2`](https://packages.gitlab.com/gitlab/raspberry-pi2): [Raspberry Pi](https://www.raspberrypi.org)パッケージ用に構築された公式Community Editionリリース。

GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)またはGitLab [Enterprise Edition](https://about.gitlab.com/install/)をインストールしている場合、公式GitLabリポジトリがすでに設定されているはずです。

#### 最新バージョンにアップグレードする {#upgrade-to-the-latest-version}

GitLabを定期的に（たとえば、毎月）アップグレードする場合は、Linuxディストリビューション用のパッケージマネージャーを使用して最新バージョンにアップグレードできます。

最新のGitLabバージョンにアップグレードするには、次のコマンドを実行します。

```shell
# Ubuntu/Debian
sudo apt update && sudo apt install gitlab-ee

# RHEL/CentOS 7 and Amazon Linux 2
sudo yum install gitlab-ee

# RHEL/Almalinux 8/9 and Amazon Linux 2023
sudo dnf install gitlab-ee

# SUSE
sudo zypper install gitlab-ee
```

{{< alert type="note" >}}

GitLab Community Editionの場合、`gitlab-ee`を`gitlab-ce`に置き換えます。

{{< /alert >}}

#### 特定のバージョンにアップグレードする {#upgrade-to-a-specific-version}

Linuxパッケージマネージャーは、インストールおよびアップグレードに使用できる最新バージョンのパッケージをデフォルトでインストールします。最新のメジャーバージョンに直接アップグレードすると、複数段階の[アップグレードパス](../upgrade_paths.md)を必要とする以前のGitLabバージョンで問題が発生する可能性があります。アップグレードパスは複数のバージョンにまたがる可能性があるため、アップグレードごとに特定のGitLabパッケージを指定する必要があります。

パッケージマネージャーのインストールまたはアップグレードコマンドで目的のGitLabバージョン番号を指定するには、次の手順に従います。

1. インストールされているパッケージのバージョン番号を特定します。

   ```shell
   # Ubuntu/Debian
   sudo apt-cache madison gitlab-ee

   # RHEL/CentOS 7 and Amazon Linux 2
   yum --showduplicates list gitlab-ee

   # RHEL/Almalinux 8/9 and Amazon Linux 2023
   dnf --showduplicates list gitlab-ee

   # SUSE
   zypper search -s gitlab-ee
   ```

1. 次のいずれかのコマンドを使用して、`<version>`を、インストールする次のサポートバージョンに置き換えて、特定の`gitlab-ee`パッケージをインストールします（インストールするバージョンがサポートされているパスの一部であることを確認するには、[アップグレードパス](../upgrade_paths.md)を確認してください）。

   ```shell
   # Ubuntu/Debian
   sudo apt install gitlab-ee=<version>-ee.0

   # RHEL/CentOS 7 and Amazon Linux 2
   sudo yum install gitlab-ee-<version>-ee.0.el7

   # RHEL/Almalinux 8/9
   sudo dnf install gitlab-ee-<version>-ee.0.el8

   # Amazon Linux 2023
   sudo dnf install gitlab-ee-<version>-ee.0.amazon2023

   # OpenSUSE Leap 15.5
   sudo zypper install gitlab-ee=<version>-ee.sles15

   # SUSE Enterprise Server 12.2/12.5
   sudo zypper install gitlab-ee=<version>-ee.0.sles12
   ```

{{< alert type="note" >}}

GitLab Community Editionの場合、`ee`を`ce`に置き換えます。

{{< /alert >}}

### ダウンロードしたパッケージを使用する {#by-using-a-downloaded-package}

公式リポジトリを使用したくない場合は、パッケージをダウンロードして手動でインストールできます。この方法は、GitLabを初めてインストールするか、アップグレードする場合に使用できます。

GitLabをダウンロードしてインストールまたはアップグレードするには、次の手順に従います。

1. お使いの[パッケージ](#by-using-the-official-repositories-recommended)の公式リポジトリに移動します。
1. インストールするバージョンを検索して、リストをフィルタリングします。たとえば、`14.1.8`です。単一バージョンに対して複数のパッケージ（サポートされているディストリビューションとアーキテクチャにそれぞれ1つ）が存在する場合があります。ファイル名が同じ場合があるため、ファイル名の横にはディストリビューションを示すラベルがあります。
1. インストールするバージョンのパッケージを探し、リストからファイル名を選択します。
1. 右上隅で、**ダウンロード**を選択します。
1. パッケージのダウンロード後、次のいずれかのコマンドを使用して、`<package_name>`を、ダウンロードしたパッケージ名に置き換えてインストールします。

   ```shell
   # Debian/Ubuntu
   dpkg -i <package_name>

   # RHEL/CentOS 7 and Amazon Linux 2
   rpm -Uvh <package_name>

   # RHEL/Almalinux 8/9 and Amazon Linux 2023
   dnf install <package_name>

   # SUSE
   zypper install <package_name>
   ```

{{< alert type="note" >}}

GitLab Community Editionの場合、`gitlab-ee`を`gitlab-ce`に置き換えます。

{{< /alert >}}

## 製品ドキュメントをアップグレードする（オプション） {#upgrade-the-product-documentation-optional}

[製品ドキュメントをインストール](../../administration/docs_self_host.md)した場合は、[新しいバージョンにアップグレードする](../../administration/docs_self_host.md#upgrade-using-docker)方法を参照してください。

## トラブルシューティング {#troubleshooting}

詳細については、[トラブルシューティング](package_troubleshooting.md)を参照してください。
