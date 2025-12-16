---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージインスタンスをアップグレードする
description: 単一ノードのLinuxパッケージベースのインスタンスをアップグレードします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージインスタンスをアップグレードする手順は、単一ノードのGitLabインスタンスか、マルチノードのGitLabインスタンスかによって異なります。マルチノードのLinuxパッケージGitLabインスタンスをアップグレードするには、以下を参照してください:

- [ダウンタイム](../with_downtime.md)を設けてマルチノードインスタンスをアップグレードする
- [ダウンタイム](../zero_downtime.md)なしでマルチノードインスタンスをアップグレードする

単一ノードのLinuxパッケージGitLabインスタンスをアップグレードするには、このページの情報を参照してください。

{{< alert type="note" >}}

製品ドキュメントをホストしている場合は、[以降のバージョンにアップグレードすることもできます](../../administration/docs_self_host.md#upgrade-the-product-documentation-to-a-later-version)。

{{< /alert >}}

## 前提要件 {#prerequisites}

単一ノードのLinuxパッケージGitLabインスタンスをアップグレードする前に:

- [必要な情報を読み取り、必要な手順を実行する](../plan_your_upgrade.md)必要があります。
- 必要に応じて、[サポートされているオペレーティングシステム](../../install/package/_index.md)にアップグレードします。
- オペレーティングシステムのアップグレードの際に`glibc`のバージョンが変更された場合は、インデックスの破損を避けるために、[PostgreSQLのオペレーティングシステムのアップグレード](../../administration/postgresql/upgrading_os.md)に従う必要があります。
- PostgreSQL、Redis、およびGitalyが実行されていることを確認します。

GitLabデータベースは、新しいGitLabバージョンをインストールする前にバックアップされます。次の場所に空のファイルを作成すると、このデータベースの自動バックアップをスキップできます（`/etc/gitlab/skip-auto-backup`）:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

ただし、ご自身で最新の完全な[バックアップ](../../administration/backup_restore/_index.md)を保持しておく必要があります。

## 単一ノードのLinuxパッケージインスタンスをアップグレードします {#upgrade-a-single-node-linux-package-instance}

単一ノードのLinuxパッケージインスタンスをアップグレードするには:

1. アップグレード中に[メンテナンスモードをオンにすること](../../administration/maintenance_mode/_index.md)を検討してください。
1. [実行中のCI/CDパイプラインとジョブ](../plan_your_upgrade.md#pause-cicd-pipelines-and-jobs)を一時停止します。
1. GitLabのバージョンと同じバージョンに[GitLab Runner](https://docs.gitlab.com/runner/install/)をアップグレードします。
1. [LinuxパッケージでGitLabをアップグレードする](#upgrade-with-the-linux-package)。

アップグレード後:

1. [実行中のCI/CDパイプラインとジョブ](../plan_your_upgrade.md#pause-cicd-pipelines-and-jobs)の一時停止を解除します。
1. 有効になっている場合は、[メンテナンスモードをオフにします](../../administration/maintenance_mode/_index.md#disable-maintenance-mode)。
1. [アップグレードヘルスチェックを実行します](../plan_your_upgrade.md#run-upgrade-health-checks)。

## Linuxパッケージでアップグレードする {#upgrade-with-the-linux-package}

単一ノードで実行されているGitLabをアップグレードするか、マルチノードのGitLabインスタンスの一部であるノードをアップグレードするには、次のいずれかの方法でアップグレードします:

- [公式リポジトリを使用する](#upgrade-with-the-official-repositories-recommended)。
- [ダウンロードしたパッケージを使用する](#upgrade-with-a-downloaded-package)。

### 公式リポジトリでアップグレードする（推奨） {#upgrade-with-the-official-repositories-recommended}

すべてのGitLabパッケージは、GitLab[パッケージサーバー](https://packages.gitlab.com/gitlab/)に公開されています。

| リポジトリ                                                                             | 説明 |
|:---------------------------------------------------------------------------------------|:------------|
| [`gitlab/gitlab-ce`](https://packages.gitlab.com/gitlab/gitlab-ce)                     | Community Edition機能のみを含む簡素化されたパッケージ。 |
| [`gitlab/gitlab-ee`](https://packages.gitlab.com/gitlab/gitlab-ee)                     | すべてのCommunity Edition機能に加えて、Enterprise Edition機能を含む完全なGitLabパッケージ。 |
| [`gitlab/nightly-builds`](https://packages.gitlab.com/gitlab/nightly-builds)           | 毎日夜間に作成されるビルド。 |
| [`gitlab/nightly-fips-builds`](https://packages.gitlab.com/gitlab/nightly-fips-builds) | 毎晩FIPS準拠ビルド。 |
| [`gitlab/gitlab-fips`](https://packages.gitlab.com/gitlab/gitlab-fips)                 | FIPS準拠ビルド。 |

デフォルトでは、Linuxディストリビューションパッケージマネージャーは、利用可能な最新バージョンのパッケージをインストールします。[アップグレード](../upgrade_paths.md)で複数の停止が必要な場合、GitLabの最新メジャーバージョンに直接アップグレードすることはできません。アップグレードに複数のバージョンが含まれている場合は、アップグレードごとに特定のGitLabパッケージバージョンを指定する必要があります。

アップグレードに中間ステップがない場合は、最新バージョンに直接アップグレードできます。

{{< tabs >}}

{{< tab title="Ubuntu/Debian" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo apt update && sudo apt install gitlab-ee=<version>-ee.0

# GitLab Community Edition (specific version)
sudo apt update && sudo apt install gitlab-ce=<version>-ce.0

# GitLab Enterprise Edition (latest version)
sudo apt update && sudo apt install gitlab-ee

# GitLab Community Edition (latest version)
sudo apt update && sudo apt install gitlab-ce
```

{{< /tab >}}

{{< tab title="Amazon Linux 2" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo yum install gitlab-ee-<version>-ee.0.amazon2

# GitLab Community Edition (specific version)
sudo yum install gitlab-ce-<version>-ce.0.amazon2

# GitLab Enterprise Edition (latest version)
sudo yum install gitlab-ee

# GitLab Community Edition (latest version)
sudo yum install gitlab-ce
```

{{< /tab >}}

{{< tab title="RHEL/Oracle Linux/AlmaLinux 8/9" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo dnf install gitlab-ee-<version>-ee.0.el9

# GitLab Enterprise Edition (specific version)
sudo dnf install gitlab-ee-<version>-ee.0.el8

# GitLab Community Edition (specific version)
sudo dnf install gitlab-ce-<version>-ce.0.el9

# GitLab Community Edition (specific version)
sudo dnf install gitlab-ce-<version>-ce.0.el8

# GitLab Enterprise Edition (latest version)
sudo dnf install gitlab-ee

# GitLab Community Edition (latest version)
sudo dnf install gitlab-ce
```

{{< /tab >}}

{{< tab title="Amazon Linux 2023" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo dnf install gitlab-ee-<version>-ee.0.amazon2023

# GitLab Community Edition (specific version)
sudo dnf install gitlab-ce-<version>-ce.0.amazon2023

# GitLab Enterprise Edition (latest version)
sudo dnf install gitlab-ee

# GitLab Community Edition (latest version)
sudo dnf install gitlab-ce
```

{{< /tab >}}

{{< tab title="OpenSUSE Leap 15.5" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo zypper install gitlab-ee=<version>-ee.sles15

# GitLab Community Edition (specific version)
sudo zypper install gitlab-ce=<version>-ce.sles15

# GitLab Enterprise Edition (latest version)
sudo zypper install gitlab-ee

# GitLab Community Edition (latest version)
sudo zypper install gitlab-ce
```

{{< /tab >}}

{{< tab title="SUSE Enterprise Server 12.2/12.5" >}}

```shell
# GitLab Enterprise Edition (specific version)
sudo zypper install gitlab-ee=<version>-ee.0.sles12

# GitLab Community Edition (specific version)
sudo zypper install gitlab-ce=<version>-ce.0.sles12

# GitLab Enterprise Edition (latest version)
sudo zypper install gitlab-ee

# GitLab Community Edition (latest version)
sudo zypper install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

### ダウンロードしたパッケージでアップグレードする {#upgrade-with-a-downloaded-package}

公式リポジトリを使用したくない場合は、パッケージをダウンロードして手動でインストールできます。この方法は、GitLabを初めてインストールするか、アップグレードする場合に使用できます。

GitLabをダウンロードしてインストールまたはアップグレードするには、次の手順に従います:

1. お使いの[パッケージ](#upgrade-with-the-official-repositories-recommended)の公式リポジトリに移動します。
1. インストールするバージョンを検索して、リストをフィルタリングします。たとえば、`18.4.1`です。単一バージョンに対して複数のパッケージ（サポートされているディストリビューションとアーキテクチャにそれぞれ1つ）が存在する場合があります。一部のファイルは複数のLinuxディストリビューションに関連するため、ファイル名の横にLinuxディストリビューションを示すラベルがあります。
1. インストールするバージョンのパッケージを探し、リストからファイル名を選択します。
1. 右上隅で、**ダウンロード**を選択します。
1. パッケージのダウンロード後、次のいずれかのコマンドを使用して、`<package_name>`を、ダウンロードしたパッケージ名に置き換えてインストールします:

   {{< tabs >}}

   {{< tab title="Ubuntu/Debian" >}}

   ```shell
   dpkg -i <package_name>
   ```

   {{< /tab >}}

   {{< tab title="Amazon Linux 2" >}}

   ```shell
   rpm -Uvh <package_name>
   ```

   {{< /tab >}}

   {{< tab title="RHEL/Oracle Linux/AlmaLinux 8/9およびAmazon Linux 2023" >}}

   ```shell
   dnf install <package_name>
   ```

   {{< /tab >}}

   {{< tab title="SUSEとOpenSUSE" >}}

   ```shell
   zypper install <package_name>
   ```

   {{< /tab >}}

   {{< /tabs >}}
