---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ内のDebianパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [機能フラグ](../../../administration/feature_flags/list.md)の背後にデプロイされ、デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="warning" >}}

GitLabのDebianパッケージレジストリは開発中であり、本番環境での使用には対応していません。この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/6057)では、本番環境で使用できるようになるまでの残りの作業とタイムラインについて詳しく説明します。[Debianパッケージのサポートは実験的](../package_registry/supported_functionality.md)であり、既知の脆弱性があります。

{{< /alert >}}

プロジェクトのパッケージレジストリにDebianパッケージを公開します。これにより、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

プロジェクトおよびグループパッケージがサポートされています。

Debianパッケージマネージャーのクライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Debian APIドキュメント](../../../api/packages/debian.md)を参照してください。

前提要件: 

- `dpkg-deb`バイナリは、GitLabインスタンスにインストールされている必要があります。このバイナリは通常、Debianとその派生物にデフォルトでインストールされる[`dpkg`パッケージ](https://wiki.debian.org/Teams/Dpkg/Downstream)によって提供されます。
- （推奨）`dpkg-deb` 1.22.21以降を使用してください。`dpkg-deb` 1.22.20以前のバージョンでは、バイナリは、書き込み不可能なディレクトリを含むアーカイブから一時ファイルを削除できません。これらのファイルはディスク容量を消費し、サービス拒否を引き起こす可能性があります。
- 圧縮アルゴリズムZStandardのサポートには、Debian 12 Bookwormの`dpkg >= 1.21.18`またはUbuntu 18.04 Bionic Beaverの`dpkg >= 1.19.0.5ubuntu2`のバージョンが必要です。

## Debian APIを有効にする {#enable-the-debian-api}

Debianリポジトリのサポートはまだ開発中です。これは、デフォルトで無効になっている機能フラグの背後にゲートで保護されています。[GitLab管理者は、GitLab Railsコンソールへのアクセス](../../../administration/feature_flags/_index.md)により、有効にすることを選択できます。

{{< alert type="warning" >}}

[開発中の機能を有効にする場合の安定性とセキュリティのリスク](../../../administration/feature_flags/_index.md#risks-when-enabling-features-still-in-development)を理解してください。

{{< /alert >}}

有効にするには、次の手順に従います:

```ruby
Feature.enable(:debian_packages)
```

無効にするには、次の手順に従います: 

```ruby
Feature.disable(:debian_packages)
```

## DebianグループAPIを有効にする {#enable-the-debian-group-api}

Debianグループリポジトリも、デフォルトで無効になっている2番目の機能フラグの背後にあります。

{{< alert type="warning" >}}

[開発中の機能を有効にする場合の安定性とセキュリティのリスク](../../../administration/feature_flags/_index.md#risks-when-enabling-features-still-in-development)を理解してください。

{{< /alert >}}

有効にするには、次の手順に従います:

```ruby
Feature.enable(:debian_group_packages)
```

無効にするには、次の手順に従います: 

```ruby
Feature.disable(:debian_group_packages)
```

## Debianパッケージをビルドする {#build-a-debian-package}

Debianパッケージの作成については、[Debian Wiki](https://wiki.debian.org/Packaging)に記載されています。

## Debianエンドポイントへの認証 {#authenticate-to-the-debian-endpoints}

認証方式は、[ディストリビューションAPI](#authenticate-to-the-debian-distributions-apis)と[パッケージリポジトリ](#authenticate-to-the-debian-package-repositories)で異なります。

### DebianディストリビューションAPIへの認証 {#authenticate-to-the-debian-distributions-apis}

ディストリビューションを作成、読み取り、更新、または削除するには、次のいずれかが必要です:

- [パーソナルアクセストークン](../../../api/rest/authentication.md#personalprojectgroup-access-tokens)を、`--header "PRIVATE-TOKEN: <personal_access_token>"`で使用します。
- [デプロイトークン](../../project/deploy_tokens/_index.md)（`--header "Deploy-Token: <deploy_token>"`を使用）
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)（`--header "Job-Token: <job_token>"`を使用）

### Debianパッケージリポジトリへの認証 {#authenticate-to-the-debian-package-repositories}

パッケージの公開、またはプライベートパッケージのインストールを行うには、次のいずれかを使用してBasic認証を使用する必要があります:

- [パーソナルアクセストークン](../../../api/rest/authentication.md#personalprojectgroup-access-tokens)を、`<username>:<personal_access_token>`で使用します。
- [デプロイトークン](../../project/deploy_tokens/_index.md)（`<deploy_token_name>:<deploy_token>`を使用）
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)（`gitlab-ci-token:<job_token>`を使用）

## ディストリビューションを作成する {#create-a-distribution}

プロジェクトレベルでは、DebianパッケージはDebianディストリビューションで公開されます。グループレベルでは、Debianパッケージは、以下を条件として、グループ内のプロジェクトから集約されます:

- プロジェクトの表示レベルを`public`に設定します。
- グループのDebian `codename`が、プロジェクトのDebian `codename`と一致すること。

パーソナルアクセストークンを使用してプロジェクトレベルのディストリビューションを作成するには:

```shell
curl --fail-with-body --request POST --header "PRIVATE-TOKEN: <personal_access_token>" \
  "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions?codename=<codename>"
```

`codename=sid`が指定されたレスポンスの例:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

DebianディストリビューションAPIの詳細情報:

- [DebianプロジェクトディストリビューションAPI](../../../api/packages/debian_project_distributions.md)
- [DebianグループディストリビューションAPI](../../../api/packages/debian_group_distributions.md)

## パッケージを公開する {#publish-a-package}

がビルドされると、いくつかのファイルが作成されます:

- `.deb`ファイル: バイナリパッケージ
- `.udeb`ファイル: 軽量化された.debファイル。Debianインストーラーに使用されます（必要な場合）
- `.ddeb`ファイル: Ubuntuのデバッグ.debファイル（必要な場合）
- `.tar.{gz,bz2,xz,...}`ファイル: ソースファイル
- `.dsc`ファイル: ソースメタデータ、およびソースファイル（ハッシュ付き）のリスト
- `.buildinfo`ファイル: 再現可能なビルドに使用（オプション）
- `.changes`ファイル: アップロードメタデータ、およびアップロードされたファイル（上記すべて）のリスト

これらのファイルをアップロードするには、`dput-ng >= 1.32`（Debian bullseye）を使用できます。`<username>`と`<password>`は、[Debianパッケージリポジトリ](#authenticate-to-the-debian-package-repositories)のように定義されています:

```shell
cat <<EOF > dput.cf
[gitlab]
method = https
fqdn = <username>:<password>@gitlab.example.com
incoming = /api/v4/projects/<project_id>/packages/debian
EOF

dput --config=dput.cf --unchecked --no-upload-log gitlab <your_package>.changes
```

## 明示的なディストリビューションとコンポーネントを使用してパッケージをアップロードする {#upload-a-package-with-explicit-distribution-and-component}

{{< history >}}

- 明示的なディストリビューションとコンポーネントを使用したアップロード（GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101838)）。

{{< /history >}}

`.changes`ファイルにアクセスできない場合は、`codename`ディストリビューションとターゲット`component`をパラメータとして[認証情報](#authenticate-to-the-debian-package-repositories)と共に渡すことで、`.deb`を直接アップロードできます。たとえば、パーソナルアクセストークンを使用して、ディストリビューション`sid`のコンポーネント`main`にアップロードするには:

```shell
curl --fail-with-body --request PUT --user "<username>:<personal_access_token>" \
  "https://gitlab.example.com/api/v4/projects/<project_id>/packages/debian/your.deb?distribution=sid&component=main" \
  --upload-file  /path/to/your.deb
```

## パッケージをインストールする {#install-a-package}

パッケージをインストールするには:

1. リポジトリを設定します:

   プライベートプロジェクトを使用している場合は、[認証情報](#authenticate-to-the-debian-package-repositories)をapt設定に追加します:

   ```shell
   echo 'machine gitlab.example.com login <username> password <password>' \
     | sudo tee /etc/apt/auth.conf.d/gitlab_project.conf
   ```

   [認証情報](#authenticate-to-the-debian-distributions-apis)を使用して、ディストリビューションキーをダウンロードします:

   ```shell
   sudo mkdir -p /etc/apt/keyrings
   sudo curl --fail --silent --show-error --header "PRIVATE-TOKEN: <your_access_token>" \
        --output /etc/apt/keyrings/<codename>-archive-keyring.asc \
        --url "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions/<codename>/key.asc"
   ```

   プロジェクトをソースとして追加します:

   ```shell
   echo 'deb [ signed-by=/etc/apt/keyrings/<codename>-archive-keyring.asc ] https://gitlab.example.com/api/v4/projects/<project_id>/packages/debian <codename> <component1> <component2>' |
       sudo tee /etc/apt/sources.list.d/gitlab_project.list
   sudo apt-get update
   ```

1. パッケージをインストールします:

   ```shell
   sudo apt-get -y install -t <codename> <package-name>
   ```

## ソースパッケージをダウンロードする {#download-a-source-package}

ソースパッケージをダウンロードするには:

1. リポジトリを設定します:

   プライベートプロジェクトを使用している場合は、[認証情報](#authenticate-to-the-debian-package-repositories)をapt設定に追加します:

   ```shell
   echo 'machine gitlab.example.com login <username> password <password>' \
     | sudo tee /etc/apt/auth.conf.d/gitlab_project.conf
   ```

   [認証情報](#authenticate-to-the-debian-distributions-apis)を使用して、ディストリビューションキーをダウンロードします:

   ```shell
   sudo mkdir -p /etc/apt/keyrings
   sudo curl --fail --silent --show-error --header "PRIVATE-TOKEN: <your_access_token>" \
        --output /etc/apt/keyrings/<codename>-archive-keyring.asc \
        --url "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions/<codename>/key.asc"
   ```

   プロジェクトをソースとして追加します:

   ```shell
   echo 'deb-src [ signed-by=/etc/apt/keyrings/<codename>-archive-keyring.asc ] https://gitlab.example.com/api/v4/projects/<project_id>/packages/debian <codename> <component1> <component2>' |
       sudo tee /etc/apt/sources.list.d/gitlab_project-sources.list
   sudo apt-get update
   ```

1. ソースパッケージをダウンロードします:

   ```shell
   sudo apt-get source -t <codename> <package-name>
   ```
