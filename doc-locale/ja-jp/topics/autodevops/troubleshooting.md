---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントページの情報では、Auto DevOpsの使用時に発生する一般的なエラーと、利用可能な回避策について説明します。

## Helmコマンドのトレース {#trace-helm-commands}

詳細な出力を生成するために、任意の値を`TRACE` CI/CD変数に設定して、Helmコマンドを作成します。この出力を使用すると、Auto DevOpsのデプロイに関する問題を診断できます。

高度なAuto DevOps設定変数を変更することで、Auto DevOpsデプロイに関するいくつかの問題を解決できます。[Auto DevOps CI/CD変数のカスタマイズ](cicd_variables.md)の詳細をお読みください。

## ビルドパックを選択できません {#unable-to-select-a-buildpack}

自動テストは、次のエラーで言語またはフレームワークを検出できない場合があります:

```plaintext
Step 5/11 : RUN /bin/herokuish buildpack build
 ---> Running in eb468cd46085
    -----> Unable to select a buildpack
The command '/bin/sh -c /bin/herokuish buildpack build' returned a non-zero code: 1
```

考えられる理由は次のとおりです:

- アプリケーションに、ビルドパックが探しているキーファイルがない可能性があります。Rubyアプリケーションは、`Gemfile`を適切に検出するために必要です。`Gemfile`がなくてもRubyアプリを作成できます。
- アプリケーション用のビルドパックが存在しない可能性があります。[カスタムビルドパック](customize.md#custom-buildpacks)を指定してみてください。

## Builderのサンセットエラー {#builder-sunset-error}

この[Herokuの更新](https://github.com/heroku/cnb-builder-images/pull/478)のため、レガシーのShimmed `heroku/buildpacks:20`イメージと`heroku/builder-classic:22`イメージで、警告の代わりにエラーが生成されるようになりました。

この問題を解決するには、`heroku/builder:*`ビルダーイメージに移行する必要があります。一時的な回避策として、環境変数を設定してエラーをスキップすることもできます。

### `heroku/builder:*`移行します {#migrating-to-herokubuilder}

移行する前に、潜在的な破壊的な変更を判断するために、各[仕様リリースのリリースノート](https://github.com/buildpacks/spec/releases)を読む必要があります。この場合、関連するビルドパックAPIバージョンは0.6と0.7です。これらの破壊的な変更は、ビルドパックメンテナーに特に関連します。

変更の詳細については、[仕様自体](https://github.com/buildpacks/spec/compare/buildpack/v0.5...buildpack/v0.7#files_bucket)の差分を確認することもできます。

### エラーのスキップ {#skipping-errors}

一時的な回避策として、`ALLOW_EOL_SHIMMED_BUILDER`環境変数を設定して転送することにより、エラーをスキップできます:

```yaml
  variables:
    ALLOW_EOL_SHIMMED_BUILDER: "1"
    AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES: ALLOW_EOL_SHIMMED_BUILDER
```

## \`only\` / \`except\` でAuto DevOpsを拡張するパイプラインが失敗する {#pipeline-that-extends-auto-devops-with-only--except-fails}

パイプラインが次のメッセージで失敗した場合:

```plaintext
Unable to create pipeline

  jobs:test config key may not be used with `rules`: only
```

このエラーは、インクルードされたジョブのルール設定が`only`または`except`構文でオーバーライドされた場合に表示されます。この問題を修正するには、次のいずれかを実行する必要があります:

- `only/except`構文をルールに移行します。
- （一時的に）テンプレートを[GitLab 12.10ベースのテンプレート](https://gitlab.com/gitlab-org/auto-devops-v12-10)にピン留めします。

## Kubernetesネームスペースを作成できません {#failure-to-create-a-kubernetes-namespace}

プロジェクトのKubernetesネームスペースとサービスアカウントをGitLabが作成できない場合、自動デプロイは失敗します。この問題をデバッグする方法については、[失敗したデプロイメントジョブのトラブルシューティング](../../user/project/clusters/deploy_to_cluster.md#troubleshooting)を参照してください。

## 既存のPostgreSQLデータベースが検出されました {#detected-an-existing-postgresql-database}

GitLab 13.0にアップグレードした後、Auto DevOpsでデプロイすると、このメッセージが表示される場合があります:

```plaintext
Detected an existing PostgreSQL database installed on the
deprecated channel 1, but the current channel is set to 2. The default
channel changed to 2 in GitLab 13.0.
[...]
```

Auto DevOpsは、デフォルトでは、アプリケーションと一緒にクラスター内のPostgreSQLデータベースをインストールします。デフォルトのインストール方法はGitLab 13.0で変更され、既存のデータベースをアップグレードするには、ユーザーの関与が必要です。2つのインストール方法があります:

- **channel 1 (deprecated)**（チャネル1（非推奨））: データベースを、関連付けられたHelmチャートの依存関係としてプルします。Kubernetesバージョン1.15までのバージョンのみをサポートします。
- **channel 2 (current)**（チャネル2（現在））: データベースを独立したHelmチャートとしてインストールします。Kubernetesバージョン1.16以降でクラスター内データベース機能を使用するために必要です。

このエラーが表示された場合は、次のいずれかのアクションを実行できます:

- `AUTO_DEVOPS_POSTGRES_CHANNEL`を`1`に設定して再デプロイすると、警告を無視して、チャネル1のPostgreSQLデータベースを引き続き安全に使用できます。

- `AUTO_DEVOPS_POSTGRES_DELETE_V1`を空でない値に設定して再デプロイすると、チャネル1のPostgreSQLデータベースを削除し、新しいチャネル2データベースをインストールできます。

  {{< alert type="warning" >}}

  チャネル1のPostgreSQLデータベースを削除すると、既存のチャネル1データベースとそのすべてのデータが完全に削除されます。データベースのバックアップとアップグレードの詳細については、[PostgreSQLのアップグレード](upgrading_postgresql.md)を参照してください。

  {{< /alert >}}

- クラスター内データベースを使用していない場合は、`POSTGRES_ENABLED`を`false`に設定して再デプロイできます。このオプションは、チャート内のPostgreSQL依存関係を持たないカスタムチャートのユーザーに特に関連します。データベースの自動検出は、リリースの`postgresql.enabled`Helm値に基づいています。この値は、チャートがその変数を使用するかどうかにかかわらず、`POSTGRES_ENABLED` CI/CD変数に基づいて設定され、Helmによって永続化されます。

{{< alert type="warning" >}}

`POSTGRES_ENABLED`を`false`に設定すると、環境の既存のチャネル1データベースが完全に削除されます。

{{< /alert >}}

## プロジェクトに対してAuto DevOpsが自動的に無効になります {#auto-devops-is-automatically-disabled-for-a-project}

Auto DevOpsがプロジェクトに対して自動的に無効になっている場合、次の理由が考えられます:

- Auto DevOps設定が[プロジェクト](_index.md#per-project)自体で明示的に有効になっていません。これは、親[グループ](_index.md#per-group)またはその[インスタンス](../../administration/settings/continuous_integration.md#configure-auto-devops-for-all-projects)でのみ有効になります。
- プロジェクトには、Auto DevOpsパイプラインの成功履歴がありません。
- Auto DevOpsパイプラインが失敗しました。

この問題を解決するには、以下を実行します:

- プロジェクトでAuto DevOps設定を有効にします。
- パイプラインを中断しているエラーを修正して、パイプラインを再実行できるようにします。

## エラー: `unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"` {#error-unable-to-recognize--no-matches-for-kind-deployment-in-version-extensionsv1beta1}

[v1.16+](stages.md#kubernetes-116)にKubernetesクラスタリングをアップグレードした後、Auto DevOpsでデプロイすると、このメッセージが表示される場合があります:

```plaintext
UPGRADE FAILED
Error: failed decoding reader into objects: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"
```

これは、環境ネームスペース上の現在のデプロイが、Kubernetes v1.16+に存在しない非推奨/削除されたAPIでデプロイされた場合に発生する可能性があります。たとえば、[クラスター内のPostgreSQLがレガシーな方法でインストールされている](#detected-an-existing-postgresql-database)場合、リソースは`extensions/v1beta1` APIを使用して作成されました。ただし、デプロイリソースはv1.16で`app/v1` APIに移植されました。

このような古いリソースを復元するには、レガシーAPIを新しいAPIにマッピングして、現在のデプロイを変換する必要があります。この問題に対処する[`mapkubeapis`](https://github.com/hickeyma/helm-mapkubeapis)というヘルパーツールがあります。Auto DevOpsでツールを使用するには、次の手順に従います:

1. `.gitlab-ci.yml`を次のように変更します:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
     - remote: https://gitlab.com/shinya.maeda/ci-templates/-/raw/master/map-deprecated-api.gitlab-ci.yml

   variables:
     HELM_VERSION_FOR_MAPKUBEAPIS: "v2" # If you're using auto-depoy-image v2 or later, please specify "v3".
   ```

1. ジョブ`<environment-name>:map-deprecated-api`を実行します。次の手順に進む前に、このジョブが成功することを確認してください。次のような出力が得られるはずです:

   ```shell
   2020/10/06 07:20:49 Found deprecated or removed Kubernetes API:
   "apiVersion: extensions/v1beta1
   kind: Deployment"
   Supported API equivalent:
   "apiVersion: apps/v1
   kind: Deployment"
   ```

1. `.gitlab-ci.yml`を以前のバージョンに戻します。補足テンプレート`map-deprecated-api`を含める必要はなくなりました。

1. デプロイを通常どおり続行します。

## `Error: not a valid chart repository or cannot be reached` {#error-not-a-valid-chart-repository-or-cannot-be-reached}

[CNCFの公式ブログ投稿で発表された](https://www.cncf.io/blog/2020/10/07/important-reminder-for-all-helm-users-stable-incubator-repos-are-deprecated-and-all-images-are-changing-location/)ように、安定したHelmチャートリポジトリは非推奨になり、2020年11月13日に削除されました。その日以降、このエラーが発生する可能性があります:

```plaintext
Error: error initializing: Looks like "https://kubernetes-charts.storage.googleapis.com"
is not a valid chart repository or cannot be reached
```

一部のGitLab機能には、安定したチャートの依存関係がありました。影響を軽減するために、新しい公式リポジトリ、または[GitLabが管理するHelm Stable Archiveリポジトリ](https://gitlab.com/gitlab-org/cluster-integration/helm-stable-archive)を使用するように変更しました。Autoデプロイには[修正の例](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/merge_requests/127)が含まれています。

自動デプロイでは、`auto-deploy-image`の`v1.0.6+`は、非推奨の安定したリポジトリを`helm`コマンドに追加しなくなりました。カスタムチャートを使用し、非推奨の安定したリポジトリに依存している場合は、次の例のように古い`auto-deploy-image`を指定します:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

.auto-deploy:
  image: "registry.gitlab.com/gitlab-org/cluster-integration/auto-deploy-image:v1.0.5"
```

このアプローチは、安定したリポジトリが削除されると機能しなくなるため、最終的にはカスタムチャートを修正する必要があります。

カスタムチャートを修正するには:

1. チャートディレクトリで、`requirements.yaml`ファイルの`repository`値を次のように更新します:

   ```yaml
   repository: "https://kubernetes-charts.storage.googleapis.com/"
   ```

   からに変更します:

   ```yaml
   repository: "https://charts.helm.sh/stable"
   ```

1. チャートディレクトリで、Auto DevOpsと同じHelmメジャーバージョンを使用して`helm dep update .`を実行します。
1. `requirements.yaml`ファイルの変更をコミットします。
1. 以前に`requirements.lock`ファイルがあった場合は、ファイルへの変更をコミットします。以前にチャートに`requirements.lock`ファイルがなかった場合は、新しいファイルをコミットする必要はありません。このファイルはオプションですが、存在する場合は、ダウンロードされた依存関係の整合性を確認するために使用されます。

[イシュー #263778、「安定したHelmリポジトリからPostgreSQLを移行する」](https://gitlab.com/gitlab-org/gitlab/-/issues/263778)で詳細を確認できます。

## `Error: release .... failed: timed out waiting for the condition` {#error-release--failed-timed-out-waiting-for-the-condition}

Auto DevOpsの使用を開始すると、最初にアプリケーションをデプロイするときに、このエラーが発生する場合があります:

```plaintext
INSTALL FAILED
PURGING CHART
Error: release staging failed: timed out waiting for the condition
```

これは、デプロイプロセス中に試行された、失敗した活性（または準備）プローブが原因である可能性が最も高くなります。デフォルトでは、これらのプローブはポート5000でデプロイされたアプリケーションのルートページに対して実行されます。アプリケーションがルートページで何かを提供するように設定されていない場合、または5000*以外*の特定のポートで実行するように設定されている場合、このチェックは失敗します。

失敗した場合は、関連するKubernetesネームスペースのイベントでこれらのエラーが表示されるはずです。これらのイベントは、次の例のようになります:

```plaintext
LAST SEEN   TYPE      REASON                   OBJECT                                            MESSAGE
3m20s       Warning   Unhealthy                pod/staging-85db88dcb6-rxd6g                      Readiness probe failed: Get http://10.192.0.6:5000/: dial tcp 10.192.0.6:5000: connect: connection refused
3m32s       Warning   Unhealthy                pod/staging-85db88dcb6-rxd6g                      Liveness probe failed: Get http://10.192.0.6:5000/: dial tcp 10.192.0.6:5000: connect: connection refused
```

活性チェックに使用されるポートを変更するには、Auto DevOpsで使用される[Helmチャートにカスタム値を渡します](customize.md#customize-helm-chart-values):

1. `.gitlab/auto-deploy-values.yaml`という名前のディレクトリとファイルをリポジトリのルートに作成します。

1. ファイルに次のコンテンツを入力されたし、アプリケーションを使用するように設定されている実際のポート番号でポート値を置き換えます:

   ```yaml
   service:
     internalPort: <port_value>
     externalPort: <port_value>
   ```

1. 変更をコミットしてください。

変更をコミットした後、後続のプローブは新しく定義されたポートを使用する必要があります。プローブされるページは、同じ方法で（[デフォルトの`values.yaml`](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/blob/master/assets/auto-deploy-app/values.yaml)ファイルに表示されている）`livenessProbe.path`値と`readinessProbe.path`値をオーバーライドすることによっても変更できます。
