---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オフライン環境
description: オフラインセキュリティスキャンおよび脆弱性の解決
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

オフライン環境をセットアップするには、購入前に[クラウドライセンスのオプトアウト免除](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)を受ける必要があります。詳細については、GitLabの営業担当者にお問い合わせください。

{{< /alert >}}

インターネットに接続していなくても、ほとんどのGitLabセキュリティスキャナーを実行できます。

このドキュメントでは、セキュアカテゴリー（つまり、スキャナーの種類）をオフライン環境で操作する方法について説明します。これらの手順は、保護されている、セキュリティポリシー（ファイアウォールポリシーなど）がある、またはインターネットへのフルアクセスが制限されているGitLab Self-Managedインスタンスにも適用されます。GitLabでは、これらの環境を_オフライン環境_と呼んでいます。その他の一般的な名前は次のとおりです:

- エアギャップ環境
- 接続が制限された環境
- ローカルエリアネットワーク（LAN）環境
- イントラネット環境

これらの環境には、インターネットアクセスを防止または制限する物理的な障壁またはセキュリティポリシー（ファイアウォールなど）があります。これらの手順は、物理的に切断されたネットワーク向けに設計されていますが、他のユースケースでも実行できます。

## オフライン環境の定義 {#defining-offline-environments}

オフライン環境では、GitLabインスタンスは、ローカルネットワーク上で通信できる1つ以上のサーバーとサービスである可能性がありますが、インターネットへのアクセスはまったくないか、非常に制限されています。GitLabインスタンスおよびサポートインフラストラクチャ（プライベートMavenリポジトリなど）内のものはすべて、ローカルネットワーク接続を介してアクセスできると想定します。インターネットからのファイルは、物理メディア（USBドライブ、ハードドライブ、書き込み可能なDVDなど）を介して入手する必要があると想定します。

## オフラインスキャナーの使用 {#use-offline-scanners}

GitLabスキャナーは通常、インターネットに接続して、署名、ルール、パッチの最新セットをダウンロードします。ローカルネットワーク上で利用可能なリソースを使用してツールが適切に機能するように設定するには、いくつかの追加手順が必要です。

### コンテナイメージレジストリとパッケージリポジトリ {#container-registries-and-package-repositories}

大まかに言うと、セキュリティスキャナーはDockerイメージとして提供され、さまざまなパッケージリポジトリを利用する場合があります。インターネットに接続されたGitLabインストールでジョブを実行すると、GitLabはGitLab.comでホストされているコンテナイメージレジストリをチェックし、これらのDockerイメージの最新バージョンがあることを確認し、必要に応じてパッケージリポジトリに接続して必要な依存関係をインストールします。

オフライン環境では、GitLab.comにクエリが送信されないように、これらのチェックを無効にする必要があります。GitLab.comのレジストリとリポジトリは利用できないため、異なる内部ホストレジストリを参照するか、個々のスキャナーイメージへのアクセスを提供するために、各スキャナーを更新する必要があります。

また、npm、yarn、Ruby gemなど、GitLab.comでホストされていない一般的なパッケージリポジトリにアプリがアクセスできることを確認する必要があります。これらのリポジトリからのパッケージは、一時的にネットワークに接続するか、独自のオフラインネットワーク内でパッケージをミラーリングすることで取得できます。

### 脆弱性との対話 {#interacting-with-the-vulnerabilities}

脆弱性が見つかると、それを操作できます。[脆弱性に対処する](../vulnerabilities/_index.md)方法の詳細をお読みください。

場合によっては、報告された脆弱性に、UIに公開されている外部リンクを含むメタデータが含まれることがあります。これらのリンクは、オフライン環境内ではアクセスできない可能性があります。

### 脆弱性の解決 {#resolving-vulnerabilities}

[脆弱性を解決する](../vulnerabilities/_index.md#resolve-a-vulnerability)機能は、オフラインの依存関係スキャンおよびコンテナスキャンで使用できますが、インスタンスの設定によっては機能しない場合があります。その依存関係またはイメージの最新バージョンをホストする最新のレジストリサービスにアクセスできる場合にのみ、通常はパッチが適用された最新バージョンであるソリューションを提案できます。

### スキャナーの署名とルールの更新 {#scanner-signature-and-rule-updates}

インターネットに接続すると、一部のスキャナーは、チェック対象となる署名とルールの最新セットについて、公開データベースを参照します。接続がない場合、これは不可能です。スキャナーによっては、これらの自動更新チェックを無効にし、付属のデータベースを使用し、それらのデータベースを手動で更新するか、ネットワーク内でホストされている独自のコピーへのアクセスを提供する必要があります。

## 特定スキャナーの手順 {#specific-scanner-instructions}

個々のスキャナーは、前に説明した手順と若干異なる場合があります。詳細については、以下の各ページをご覧ください:

- [コンテナスキャンオフライン手順](../container_scanning/_index.md#running-container-scanning-in-an-offline-environment)
- [SASTオフライン手順](../sast/_index.md#running-sast-in-an-offline-environment)
- [シークレット検出オフライン手順](../secret_detection/pipeline/configure.md#offline-configuration)
- [DASTオフライン手順](../dast/browser/configuration/offline_configuration.md)
- [APIファジングオフライン手順](../api_fuzzing/configuration/offline_configuration.md)
- [ライセンススキャンオフライン手順](../../compliance/license_scanning_of_cyclonedx_files/_index.md#running-in-an-offline-environment)
- [Gemnasium: 依存関係スキャンオフライン手順](../dependency_scanning/_index.md#offline-environment)
- [IaCスキャンオフライン手順](../iac_scanning/_index.md#offline-configuration)

## オフラインホストへのDockerイメージの読み込む {#loading-docker-images-onto-your-offline-host}

セキュリティスキャンや[Auto DevOps](../../../topics/autodevops/_index.md)など、多くのGitLab機能を使用するには、Runnerが関連するDockerイメージをフェッチできる必要があります。

パブリックインターネットに直接アクセスせずにこれらのイメージを利用できるようにするプロセスには、イメージのダウンロード、パッケージ化、およびオフラインホストへの転送が含まれます。そのような転送の例を次に示します:

1. パブリックインターネットからDockerイメージをダウンロードします。
1. Dockerイメージをtarアーカイブとしてパッケージ化します。
1. イメージをオフライン環境に転送します。
1. 転送されたイメージをオフラインDockerレジストリに読み込むます。

### 公式GitLabテンプレートの使用 {#using-the-official-gitlab-template}

GitLabには、このプロセスを簡単にする[バンドルテンプレート](../../../ci/yaml/_index.md#includetemplate)が用意されています。

このテンプレートは、新しい空のプロジェクトで、`.gitlab-ci.yml`ファイルに次の内容を含めて使用する必要があります:

```yaml
include:
  - template: Security/Secure-Binaries.gitlab-ci.yml
```

パイプラインは、セキュリティスキャナーに必要なDockerイメージをダウンロードし、[ジョブアーティファクト](../../../ci/jobs/job_artifacts.md)として保存するか、パイプラインが実行されるプロジェクトの[コンテナレジストリ](../../packages/container_registry/_index.md)にプッシュします。これらのアーカイブは、別の場所に転送し、Dockerデーモンに[読み込む](https://docs.docker.com/reference/cli/docker/image/load/)ことができます。この方法では、`gitlab.com`（`registry.gitlab.com`を含む）とローカルコピーのオフラインインスタンスの両方にアクセスできるRunnerが必要です。このRunnerは、ジョブ内で`docker`コマンドを使用できるように、[特権モード](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode)で実行する必要があります。このRunnerは、DMZまたはバスチオンにインストールでき、この特定のプロジェクトでのみ使用できます。

{{< alert type="warning" >}}

このテンプレートには、コンテナスキャンアナライザーのアップデートは含まれていません。[コンテナスキャンオフライン手順](../container_scanning/_index.md#running-container-scanning-in-an-offline-environment)を参照してください。

{{< /alert >}}

#### 更新のスケジュール {#scheduling-the-updates}

デフォルトでは、このプロジェクトのパイプラインは、`.gitlab-ci.yml`がリポジトリに追加されたときに1回だけ実行されます。GitLabセキュリティスキャナーと署名を更新するには、このパイプラインを定期的に実行する必要があります。GitLabには、[パイプラインをスケジュール](../../../ci/pipelines/schedules.md)する方法が用意されています。たとえば、毎週Dockerイメージをダウンロードして保存するように、これをセットアップできます。

#### 作成されたセキュアバンドルの使用 {#using-the-secure-bundle-created}

`Secure-Binaries.gitlab-ci.yml`テンプレートを使用するプロジェクトは、GitLab Security機能を実行するために必要なすべてのイメージとリソースをホストするようになります。

次に、オフラインインスタンスに、GitLab.comのデフォルトのものに代えて、これらのリソースを使用するように指示する必要があります。そのためには、プロジェクトの[コンテナレジストリ](../../packages/container_registry/_index.md)のURLを使用して、CI/CD変数`SECURE_ANALYZERS_PREFIX`を設定します。

この変数は、プロジェクトの`.gitlab-ci.yml`、またはプロジェクトまたはグループのGitLab UIで設定できます。詳細については、[GitLab CI/CD変数のページ](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)を参照してください。

#### 変数 {#variables}

次の表に、`Secure-Binaries.gitlab-ci.yml`テンプレートで使用できるCI/CD変数を示します:

| CI/CD変数                            | 説明                                   | デフォルト値                     |
|-------------------------------------------|-----------------------------------------------|-----------------------------------|
| `SECURE_BINARIES_ANALYZERS`               | ダウンロードするアナライザーのカンマ区切りリスト | `"bandit, brakeman, gosec, ..."` |
| `SECURE_BINARIES_DOWNLOAD_IMAGES`         | ジョブを無効にするために使用                          | `"true"`                          |
| `SECURE_BINARIES_PUSH_IMAGES`             | ファイルをプロジェクトレジストリにプッシュ            | `"true"`                          |
| `SECURE_BINARIES_SAVE_ARTIFACTS`          | イメージアーカイブをアーティファクトとして保存         | `"false"`                         |
| `SECURE_BINARIES_ANALYZER_VERSION`        | デフォルトアナライザーバージョン（Dockerタグ）         | `"2"`                             |

### 公式テンプレートを使用しない別の方法 {#alternate-way-without-the-official-template}

上記の方法を実行できない場合は、代わりにイメージを手動で転送できます:

#### イメージパッケージャー</packageャースクリプトの例 {#example-image-packager-script}

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

この例では、バスチオンホストからオフラインホストにイメージを読み込むます。特定の設定では、そのような転送に物理メディアが必要になる場合があります:

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

### オフライン環境でのGitLab SecureとAutoDevOpsの使用 {#using-gitlab-secure-with-autodevops-in-an-offline-environment}

オフライン環境でSecureスキャンにGitLab AutoDevOpsを使用できます。ただし、最初に次の手順を実行する必要があります:

1. コンテナイメージをローカルコピーのレジストリに読み込むます。GitLab Secureは、アナライザーコンテナイメージを活用して、さまざまなスキャンを実行します。これらのイメージは、AutoDevOpsの実行の一部として使用可能である必要があります。AutoDevOpsを実行する前に、[公式GitLabテンプレート](#using-the-official-gitlab-template)の手順に従って、それらのコンテナイメージをローカルコピーのコンテナレジストリに読み込むます。

1. CI/CD変数を設定して、AutoDevOpsがそれらのイメージの適切な場所を確実に探すようにします。AutoDevOpsテンプレートは、アナライザーイメージの場所を識別するために、`SECURE_ANALYZERS_PREFIX`変数を利用します。詳細については、[作成されたセキュアバンドルの使用](#using-the-secure-bundle-created)を参照してください。この変数を、アナライザーイメージを読み込む場所に適切な値に設定してください。プロジェクトCI/CD変数を使用するか、`.gitlab-ci.yml`ファイルを直接[変更](../../../topics/autodevops/customize.md#customize-gitlab-ciyml)して、これを行うことを検討できます。

これらの手順が完了すると、GitLabにはSecureアナライザーのローカルコピーがあり、インターネットでホストされているコンテナイメージの代わりにそれらを使用するようにセットアップされます。これにより、オフライン環境でAutoDevOpsのSecureを実行できます。

これらの手順は、AutoDevOpsを使用したGitLab Secureに固有のものです。AutoDevOpsで他のステージを使用するには、[Auto DevOpsドキュメント](../../../topics/autodevops/_index.md)に記載されている他の手順が必要になる場合があります。
