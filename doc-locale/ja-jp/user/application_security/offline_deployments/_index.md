---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: オフライン環境
description: オフラインのセキュリティスキャンと脆弱性の解決。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!note]
> オフライン環境をセットアップするには、購入前に[クラウドライセンスのオプトアウト免除](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)を受ける必要があります。詳細については、GitLabの営業担当者にお問い合わせください。

インターネットに接続されていない場合でも、ほとんどのGitLabセキュリティスキャナーを実行できます。

このドキュメントでは、オフライン環境でセキュアカテゴリ（すなわち、スキャナータイプ）を操作する方法について説明します。これらの手順は、保護されたGitLabSelf-Managedインスタンス、セキュリティポリシー（例えば、ファイアウォールポリシー）を持つインスタンス、またはインターネット全体へのアクセスが制限されているインスタンスにも適用されます。GitLabでは、これらの環境を_オフライン環境_と呼びます。その他の一般的な名称は次のとおりです:

- エアギャップ環境
- 接続が制限された環境
- ローカルエリアネットワーク（LAN）環境
- イントラネット環境

これらの環境には、物理的な障壁またはセキュリティポリシー（例：ファイアウォール）があり、インターネットアクセスを防止または制限します。これらの手順は、物理的に切断されたネットワーク向けに設計されていますが、他のユースケースでも従うことができます。

## オフライン環境の定義 {#defining-offline-environments}

オフライン環境では、GitLabインスタンスは、ローカルネットワークで通信できる1つまたは複数のサーバーとサービスである場合がありますが、インターネットへのアクセスは不可能または非常に制限されています。GitLabインスタンス内のすべておよびサポートするインフラストラクチャ（例：プライベートMavenリポジトリ）は、ローカルネットワーク接続を介してアクセスできるものと仮定します。インターネットからのファイルはすべて、物理メディア（USBドライブ、ハードドライブ、書き込み可能DVDなど）を介して取得する必要があるものと仮定します。

## オフラインスキャナーの使用 {#use-offline-scanners}

GitLabスキャナーは通常、最新のシグネチャ、ルール、およびパッチのセットをダウンロードするためにインターネットに接続します。ツールがローカルネットワークで利用可能なリソースを使用して適切に機能するように設定するには、いくつかの追加手順が必要です。

### コンテナレジストリとパッケージリポジトリ {#container-registries-and-package-repositories}

大まかに言えば、アナライザーはDockerイメージとして提供され、さまざまなパッケージリポジトリを利用する場合があります。インターネットに接続されたGitLabインストールでジョブを実行すると、GitLabはGitLab.comでホストされているコンテナレジストリをチェックして、これらのDockerイメージの最新バージョンがあることを確認し、必要に応じてパッケージリポジトリに接続して必要な依存関係をインストールします。

オフライン環境では、GitLab.comへのクエリが行われないように、これらのチェックを無効にする必要があります。GitLab.comレジストリおよびリポジトリが利用できないため、各スキャナーを更新して、別の内部ホストレジストリを参照するか、個々のスキャナーイメージへのアクセスを提供する必要があります。

また、NPM、yarn、またはRubygemなど、GitLab.comでホストされていない一般的なパッケージリポジトリにアプリがアクセスできることを確認する必要があります。これらのリポジトリからのパッケージは、一時的にネットワークに接続するか、独自のオフラインネットワーク内でパッケージをミラーリングすることによって取得できます。

### 脆弱性との対話 {#interacting-with-the-vulnerabilities}

脆弱性が見つかると、それと対話できます。[脆弱性に対処する方法](../vulnerabilities/_index.md)の詳細については、こちらをご覧ください。

場合によっては、報告された脆弱性は、UIで公開されている外部リンクを含むメタデータを提供する場合があります。これらのリンクは、オフライン環境内ではアクセスできない場合があります。

### 脆弱性の解決 {#resolving-vulnerabilities}

[脆弱性を解決する](../vulnerabilities/_index.md#resolve-a-vulnerability)機能は、オフラインの依存関係スキャンおよびコンテナスキャンで利用できますが、インスタンスの設定によっては機能しない場合があります。GitLabは、その依存関係またはイメージの最新バージョンをホストしている最新のレジストリサービスにアクセスできる場合にのみ、ソリューション（通常はより最新のパッチ適用済みバージョン）を提案できます。

### スキャナーのシグネチャとルールの更新 {#scanner-signature-and-rule-updates}

インターネットに接続されている場合、一部のスキャナーは、最新のシグネチャとルールのセットをチェックするために公開データベースを参照します。接続がない場合、これは不可能です。したがって、スキャナーに応じて、これらの自動更新チェックを無効にし、付属のデータベースを使用し、それらのデータベースを手動で更新するか、ネットワーク内でホストされている独自のコピーへのアクセスを提供する必要があります。

## 特定のスキャナーの手順 {#specific-scanner-instructions}

個々のスキャナーは、以前に説明した手順と若干異なる場合があります。以下の各ページで詳細を確認できます:

- [コンテナスキャンのオフライン手順](../container_scanning/_index.md#offline-environment)
- [SASTのオフライン手順](../sast/_index.md#running-sast-in-an-offline-environment)
- [シークレット検出のオフライン手順](../secret_detection/pipeline/configure.md#offline-configuration)
- [DASTのオフライン手順](../dast/browser/configuration/offline_configuration.md)
- [APIファジングのオフライン手順](../api_fuzzing/configuration/offline_configuration.md)
- [ライセンススキャンのオフライン手順](../../compliance/license_scanning_of_cyclonedx_files/_index.md#running-in-an-offline-environment)
- [Gemnasium: 依存関係スキャンのオフライン手順](../dependency_scanning/_index.md#offline-environment)
- [IaCスキャンのオフライン手順](../iac_scanning/_index.md#offline-configuration)

## オフラインホストへのDockerイメージの読み込み {#loading-docker-images-onto-your-offline-host}

セキュリティスキャンや[Auto DevOps](../../../topics/autodevops/_index.md)を含む多くのGitLab機能を使用するには、Runnerが関連するDockerイメージをフェッチできる必要があります。

これらのイメージをパブリックインターネットに直接アクセスせずに利用可能にするプロセスには、イメージをダウンロードし、次にそれらをパック化するしてオフラインホストに転送することが含まれます。そのような転送の例を以下に示します:

1. パブリックインターネットからDockerイメージをダウンロードします。
1. Dockerイメージをtarアーカイブとしてパッケージします。
1. イメージをオフライン環境に転送します。
1. 転送されたイメージをオフラインDockerレジストリに読み込みます。

### 公式GitLabテンプレートの使用 {#using-the-official-gitlab-template}

GitLabは、このプロセスを容易にするための[ベンダーテンプレート](../../../ci/yaml/_index.md#includetemplate)を提供します。

このテンプレートは、`.gitlab-ci.yml`ファイルを含む新規の空のプロジェクトで使用する必要があります:

```yaml
include:
  - template: Security/Secure-Binaries.gitlab-ci.yml
```

このパイプラインは、セキュリティスキャナーに必要なDockerイメージをダウンロードし、それらを[ジョブアーティファクト](../../../ci/jobs/job_artifacts.md)として保存するか、パイプラインが実行されるプロジェクトの[コンテナレジistry](../../packages/container_registry/_index.md)にプッシュします。これらのアーカイブは別の場所に転送し、Dockerデーモンに[読み込む](https://docs.docker.com/reference/cli/docker/image/load/)ことができます。この方法では、`gitlab.com`（`registry.gitlab.com`を含む）とローカルオフラインインスタンスの両方にアクセスできるRunnerが必要です。このRunnerは、ジョブ内で`docker`コマンドを使用できるように、[特権モード](https://docs.gitlab.com/runner/executors/docker/#use-docker-in-docker-with-privileged-mode)で実行する必要があります。このRunnerはDMZまたは踏み台にインストールでき、この特定のプロジェクトのみに使用されます。

> [!warning]
> このテンプレートには、コンテナスキャンアナライザーの更新は含まれていません。[コンテナスキャンのオフライン手順](../container_scanning/_index.md#offline-environment)を参照してください。

#### 更新のスケジュール設定 {#scheduling-the-updates}

デフォルトでは、このプロジェクトのパイプラインは、`.gitlab-ci.yml`がリポジトリに追加されたときに一度だけ実行されます。GitLabセキュリティスキャナーとシグネチャを更新するには、このパイプラインを定期的に実行する必要があります。GitLabは[パイプラインをスケジュールする](../../../ci/pipelines/schedules.md)方法を提供します。例えば、Dockerイメージを毎週ダウンロードして保存するように設定できます。

#### 作成されたセキュアバンドルの使用 {#using-the-secure-bundle-created}

`Secure-Binaries.gitlab-ci.yml`テンプレートを使用するプロジェクトは、GitLabセキュリティ機能を実行するために必要なすべてのイメージとリソースをホストするようになりました。

次に、オフラインインスタンスに、GitLab.comのデフォルトのリソースではなく、これらのリソースを使用するように指示する必要があります。そのためには、プロジェクトの[コンテナレジストリ](../../packages/container_registry/_index.md)のURLを使用して、CI/CD変数`SECURE_ANALYZERS_PREFIX`を設定します。

この変数は、プロジェクトの`.gitlab-ci.yml`、またはプロジェクトまたはグループ内のGitLabUIで設定できます。詳細については、[GitLabCI/CD変数のページ](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)を参照してください。

#### 変数 {#variables}

次の表は、`Secure-Binaries.gitlab-ci.yml`テンプレートで使用できるCI/CD変数を示しています:

| CI/CD変数                            | 説明                                   | デフォルト値                     |
|-------------------------------------------|-----------------------------------------------|-----------------------------------|
| `SECURE_BINARIES_ANALYZERS`               | ダウンロードするアナライザーのコンマ区切りリスト | `"bandit, brakeman, gosec, ..."` |
| `SECURE_BINARIES_DOWNLOAD_IMAGES`         | ジョブを無効にするために使用されます                          | `"true"`                          |
| `SECURE_BINARIES_PUSH_IMAGES`             | ファイルをプロジェクトレジストリにプッシュします            | `"true"`                          |
| `SECURE_BINARIES_SAVE_ARTIFACTS`          | イメージアーカイブをアーティファクトとして保存することもできます         | `"false"`                         |
| `SECURE_BINARIES_ANALYZER_VERSION`        | デフォルトアナライザーバージョン（Dockerタグ）         | `"2"`                             |

### 公式テンプレートを使用しない代替方法 {#alternate-way-without-the-official-template}

以前の方法に従うことができない場合、イメージを手動で転送できます:

#### イメージパッケージャースクリプトの例 {#example-image-packager-script}

```shell
#!/bin/bash
set -ux

# Specify needed analyzer images
analyzers=${SAST_ANALYZERS:-"bandit eslint gosec"}
gitlab=registry.gitlab.com/security-products/

for i in "${analyzers[@]}"
do
  tarname="${i}_2.tar"
  docker pull $gitlab$i:2
  docker save $gitlab$i:2 -o ./analyzers/${tarname}
  chmod +r ./analyzers/${tarname}
done
```

#### イメージローダースクリプトの例 {#example-image-loader-script}

この例では、踏み台ホストからオフラインホストにイメージを読み込みます。特定の設定では、このような転送に物理メディアが必要になる場合があります:

```shell
#!/bin/bash
set -ux

# Specify needed analyzer images
analyzers=${SAST_ANALYZERS:-"bandit eslint gosec"}
registry=$GITLAB_HOST:4567

for i in "${analyzers[@]}"
do
  tarname="${i}_2.tar"
  scp ./analyzers/${tarname} ${GITLAB_HOST}:~/${tarname}
  ssh $GITLAB_HOST "sudo docker load -i ${tarname}"
  ssh $GITLAB_HOST "sudo docker tag $(sudo docker images | grep $i | awk '{print $3}') ${registry}/analyzers/${i}:2"
  ssh $GITLAB_HOST "sudo docker push ${registry}/analyzers/${i}:2"
done
```

### オフライン環境でのAuto DevOpsとGitLab Secureの使用 {#using-gitlab-secure-with-autodevops-in-an-offline-environment}

オフライン環境でセキュリティスキャンにGitLabAuto DevOpsを使用できます。ただし、まず以下の手順を実行する必要があります:

1. コンテナイメージをローカルレジストリに読み込みます。GitLab Secureは、さまざまなスキャンを実行するためにアナライザーコンテナイメージを利用します。これらのイメージは、Auto DevOpsの実行の一部として利用可能である必要があります。Auto DevOpsを実行する前に、[公式GitLabテンプレート](#using-the-official-gitlab-template)の手順に従って、それらのコンテナイメージをローカルコンテナレジストリに読み込みます。

1. Auto DevOpsがそれらのイメージを適切な場所で検索するように、CI/CD変数を設定します。Auto DevOpsテンプレートは、アナライザーイメージの場所を特定するために変数`SECURE_ANALYZERS_PREFIX`を利用します。詳細については、[作成されたセキュアバンドルの使用](#using-the-secure-bundle-created)を参照してください。この変数を、アナライザーイメージを読み込みんだ場所の正しい値に設定してください。これをプロジェクトCI/CD変数で行うか、`.gitlab-ci.yml`ファイルを直接[変更](../../../topics/autodevops/customize.md#customize-gitlab-ciyml)することを検討できます。

これらの手順が完了すると、GitLabはSecureアナライザーのローカルコピーを所有し、インターネットホストされたコンテナイメージの代わりにそれらを使用するように設定されます。これにより、オフライン環境でAuto DevOpsでSecureを実行できます。

これらの手順は、GitLab SecureとAuto DevOpsに固有のものです。他のパイプラインステージをAuto DevOpsで使用するには、[Auto DevOpsドキュメント](../../../topics/autodevops/_index.md)で説明されている他の手順が必要になる場合があります。
