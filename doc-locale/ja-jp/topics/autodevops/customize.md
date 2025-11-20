---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsのカスタマイズ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ニーズに合わせてAuto DevOpsのコンポーネントをカスタマイズできます。たとえば、次のことができます:

- カスタム[buildpack](#custom-buildpacks) 、[Dockerfile](#custom-dockerfiles) 、および[Helm Chart](#custom-helm-chart)を追加します。
- カスタム[CI/CD](#customize-gitlab-ciyml)構成で、ステージング環境とカナリアデプロイを有効にします。
- [GitLab API](#extend-auto-devops-with-the-api)を使用してAuto DevOpsを拡張します。

## Auto DevOpsバナー {#auto-devops-banner}

Auto DevOpsが有効になっていない場合、メンテナーロール以上のユーザーにはバナーが表示されます:

![Auto DevOpsバナー](img/autodevops_banner_v12_6.png)

バナーは以下の場合に無効にできます:

- ユーザーが自分で無視した場合。
- プロジェクトで、明示的に[Auto DevOpsを無効にする](_index.md#enable-or-disable-auto-devops)場合。
- GitLabインスタンス全体:
  - Railsコンソールで以下を実行することで、管理者が無効にする場合:

    ```ruby
    Feature.enable(:auto_devops_banner_disabled)
    ```

  - 管理者アクセストークンを使用してREST APIから実行する場合:

    ```shell
    curl --data "value=true" --header "PRIVATE-TOKEN: <personal_access_token>" "https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled"
    ```

## カスタムbuildpacks {#custom-buildpacks}

buildpacksは、次の場合にカスタマイズできます:

- プロジェクトの自動buildpack検出に失敗した場合。
- ビルドをより詳細に制御する必要がある場合。

### Cloud Native Buildpacksを使用したbuildpacksのカスタマイズ {#customize-buildpacks-with-cloud-native-buildpacks}

以下を指定します:

- いずれかの[`pack`のURI仕様形式](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/)で、CI/CD変数`BUILDPACK_URL`を指定します。
- 含めるbuildpacksを含む[`project.toml`プロジェクト記述子](https://buildpacks.io/docs/app-developer-guide/using-project-descriptor/)。

### 複数のbuildpacks {#multiple-buildpacks}

Auto Testは`.buildpacks`ファイルを使用できないため、Auto DevOpsは複数のbuildpacksをサポートしていません。`.buildpacks`ファイルの解析を行うためにバックエンドで使用されるbuildpack [heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/)は、必要なコマンド`bin/test-compile`と`bin/test`を提供しません。

カスタムbuildpackを1つだけ使用するには、プロジェクトのCI/CD変数`BUILDPACK_URL`を代わりに指定する必要があります。

## カスタムDockerfiles {#custom-dockerfiles}

プロジェクトリポジトリのルートにDockerfileがある場合、Auto DevOpsはDockerfileに基づいてDockerイメージをビルドします。これは、buildpackを使用するよりも高速です。Dockerfileが[alpine](https://hub.docker.com/_/alpine/)に基づいている場合は特に、イメージが小さくなる可能性もあります。

`DOCKERFILE_PATH`CI/CD変数を設定すると、Autoビルドは代わりにそこにDockerfileを探します。

### `docker build`に引数を渡す {#pass-arguments-to-docker-build}

`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`プロジェクトCI/CD変数を使用して、`docker build`に引数を渡すことができます。

たとえば、デフォルトの`ruby:latest`ではなく、`ruby:alpine`に基づいてDockerイメージをビルドするには:

1. `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`を`--build-arg=RUBY_VERSION=alpine`に設定します。
1. カスタムDockerfileに以下を追加します:

   ```dockerfile
   ARG RUBY_VERSION=latest
   FROM ruby:$RUBY_VERSION

   # Include your content here
   ```

スペースや改行などの複雑な値を渡すには、Base64エンコードを使用します。複雑でエンコードされていない値は、文字のエスケープで問題を引き起こす可能性があります。

{{< alert type="warning" >}}

シークレットをDockerビルドの引数として渡さないでください。シークレットがイメージに残る可能性があります。詳細については、[シークレットに関するベストプラクティスのこのディスカッション](https://github.com/moby/moby/issues/13490)を参照してください。

{{< /alert >}}

## コンテナイメージのカスタマイズ {#custom-container-image}

デフォルトでは、[自動デプロイ](stages.md#auto-deploy)は、[自動ビルド](stages.md#auto-build)によってビルドされ、GitLabレジストリにプッシュされたコンテナイメージをデプロイします。特定の変数を定義することにより、この動作をオーバーライドできます:

| エントリ | デフォルト | オーバーライドできる対象 |
| ----- | -----   | -----    |
| イメージパス | ブランチパイプラインの場合は`$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG`。タグ付けパイプラインの場合は`$CI_REGISTRY_IMAGE`。 | `$CI_APPLICATION_REPOSITORY` |
| イメージタグ | ブランチパイプラインの場合は`$CI_COMMIT_SHA`。タグ付けパイプラインの場合は`$CI_COMMIT_TAG`。 | `$CI_APPLICATION_TAG` |

これらの変数は、自動ビルドと自動コンテナスキャンにも影響します。イメージを`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`にビルドしてプッシュしたくない場合は、`Jobs/Deploy.gitlab-ci.yml`のみを含めるか、[ジョブ`build`をスキップします](cicd_variables.md#job-skipping-variables)。

自動コンテナスキャンを使用し、`$CI_APPLICATION_REPOSITORY`の値を設定する場合は、`$CS_DEFAULT_BRANCH_IMAGE`も更新する必要があります。詳細については、[デフォルトのブランチイメージの設定](../../user/application_security/container_scanning/_index.md#setting-the-default-branch-image)を参照してください。

`.gitlab-ci.yml`のセットアップ例を次に示します:

```yaml
variables:
  CI_APPLICATION_REPOSITORY: <your-image-repository>
  CI_APPLICATION_TAG: <the-tag>
```

## APIによるAuto DevOpsの拡張 {#extend-auto-devops-with-the-api}

GitLab APIを使用して、Auto DevOpsの設定を拡張および管理できます:

- [APIコールを使用して設定にアクセスする](../../api/settings.md#available-settings)には、`auto_devops_enabled`を含めて、プロジェクトでAuto DevOpsをデフォルトで有効にします。
- [新しいプロジェクトを作成する](../../api/projects.md#create-a-project)。
- [グループを編集する](../../api/groups.md#update-group-attributes)。
- [プロジェクトを編集する](../../api/projects.md#edit-a-project)。

## CI/CD変数をビルド環境に転送する {#forward-cicd-variables-to-the-build-environment}

CI/CD変数をビルド環境に転送するには、`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` CI/CD変数に転送する変数の名前を追加します。複数の変数をカンマで区切ります。

たとえば、変数`CI_COMMIT_SHA`と`CI_ENVIRONMENT_NAME`を転送するには、次のようにします:

```yaml
variables:
  AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES: CI_COMMIT_SHA,CI_ENVIRONMENT_NAME
```

buildpacksを使用する場合、転送された変数は環境変数として自動的に利用できます。

Dockerfileを使用する場合:

1. 実験的なDockerfile構文をアクティブにするには、Dockerfileに以下を追加します:

   ```dockerfile
   # syntax = docker/dockerfile:experimental
   ```

1. `Dockerfile`の`RUN $COMMAND`でシークレットを利用できるようにするには、シークレットファイルをマウントし、`$COMMAND`を実行する前にそれをソースします:

   ```dockerfile
   RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && $COMMAND
   ```

`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES`が設定されている場合、Auto DevOpsは実験的な[Docker BuildKit](https://docs.docker.com/build/buildkit/)機能を有効にして、`--secret`フラグを使用します。

## カスタムHelm Chart {#custom-helm-chart}

Auto DevOpsは[Helm](https://helm.sh/)を使用して、アプリケーションをKubernetesにデプロイします。CI/CD変数を指定するか、プロジェクトリポジトリにチャートをバンドルすることで、使用されるHelm Chartをオーバーライドできます:

- **Bundled chart**（パッケージ化されたチャート）-プロジェクトに`./chart`ディレクトリがあり、その中に`Chart.yaml`ファイルがある場合、Auto DevOpsはチャートを検出し、[デフォルトのチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)の代わりにそれを使用します。
- **プロジェクト変数** \- カスタムチャートのURIを持つ[プロジェクトCI/CD変数](../../ci/variables/_index.md) `AUTO_DEVOPS_CHART`を作成します。5つのプロジェクト変数を作成することもできます:

  - `AUTO_DEVOPS_CHART_REPOSITORY` - カスタムチャートリポジトリのURI。
  - `AUTO_DEVOPS_CHART` - チャートへのパス。
  - `AUTO_DEVOPS_CHART_REPOSITORY_INSECURE` - 空でない値を設定すると、`--insecure-skip-tls-verify`引数がHelmコマンドに追加されます。
  - `AUTO_DEVOPS_CHART_CUSTOM_ONLY` - 空でない値を設定すると、カスタムチャートのみが使用されます。デフォルトでは、最新のチャートがGitLabからダウンロードされます。
  - `AUTO_DEVOPS_CHART_VERSION` - デプロイメントチャートのバージョン。

### Helm Chartの値のカスタマイズ {#customize-helm-chart-values}

[デフォルトのHelm Chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)の`values.yaml`ファイル内のデフォルト値をオーバーライドするには、次のいずれかを実行します:

- `.gitlab/auto-deploy-values.yaml`という名前のファイルをリポジトリに追加します。このファイルは、Helmのアップグレードにデフォルトで使用されます。
- 別の名前またはパスを持つファイルをリポジトリに追加します。ファイルのパスと名前を使用して、`HELM_UPGRADE_VALUES_FILE` [CI/CD変数](cicd_variables.md)を設定します。

一部の値は前のオプションではオーバーライドできませんが、[このイシュー](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/issues/31)ではこの動作を変更することが提案されています。`replicaCount`のような設定をオーバーライドするには、`REPLICAS` [ビルドとデプロイ](cicd_variables.md#build-and-deployment-variables)CI/CD変数を使用します。

### `helm upgrade`のカスタマイズ {#customize-helm-upgrade}

[自動デプロイイメージ](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image)は、`helm upgrade`コマンドを使用します。このコマンドをカスタマイズするには、`HELM_UPGRADE_EXTRA_ARGS` CI/CD変数を使用してオプションを渡します。

たとえば、`helm upgrade`の実行時にアップグレード前後のフックを無効にするには、次のようにします:

```yaml
variables:
  HELM_UPGRADE_EXTRA_ARGS: --no-hooks
```

オプションの完全なリストについては、[公式の`helm upgrade`ドキュメント](https://helm.sh/docs/helm/helm_upgrade/)を参照してください。

### 1つの環境にHelm Chartを制限する {#limit-a-helm-chart-to-one-environment}

カスタムチャートを1つの環境に制限するには、環境スコープをCI/CD変数に追加します。詳細については、[CI/CD変数の環境スコープを制限する](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を参照してください。

## `.gitlab-ci.yml`のカスタマイズ {#customize-gitlab-ciyml}

Auto DevOpsは高度にカスタマイズ可能です。[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)は、`.gitlab-ci.yml`ファイルの実装であるためです。このテンプレートは、`.gitlab-ci.yml`の任意の実装で利用可能な機能のみを使用します。

Auto DevOpsで使用されるCI/CDパイプラインにカスタム動作を追加するには:

1. リポジトリのルートに、次の内容を含む`.gitlab-ci.yml`ファイルを追加します:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
   ```

1. `.gitlab-ci.yml`ファイルに変更を追加します。変更はAuto DevOpsテンプレートとマージされます。`include`が変更をマージする方法の詳細については、[「`include`」のドキュメント](../../ci/yaml/_index.md#include)を参照してください。

Auto DevOpsパイプラインから動作を削除するには:

1. [Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)をプロジェクトにコピーします。
1. 必要に応じて、テンプレートのコピーを編集します。

### Auto DevOpsの個々のコンポーネントを使用する {#use-individual-components-of-auto-devops}

Auto DevOpsが提供する機能のサブセットのみが必要な場合は、Auto DevOpsの個々のジョブを独自の`.gitlab-ci.yml`に含めることができます。ファイル`.gitlab-ci.yml`内の各ジョブに必要なステージも必ず定義してください。

たとえば、[自動ビルド](stages.md#auto-build)を使用するには、次の内容を`.gitlab-ci.yml`に追加します:

```yaml
stages:
  - build

include:
  - template: Jobs/Build.gitlab-ci.yml
```

利用可能なジョブのリストについては、[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)を参照してください。

## 複数のKubernetesクラスタ {#use-multiple-kubernetes-clusters}

[Auto DevOpsの複数のKubernetesクラスタリング](multiple_clusters_auto_devops.md)を参照してください。

## Kubernetesネームスペースのカスタマイズ {#customizing-the-kubernetes-namespace}

GitLab 14.5以前では、`environment:kubernetes:namespace`を使用して環境のネームスペースを指定できました。ただし、この機能は、証明書ベースのインテグレーションとともに[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

現在、`KUBE_NAMESPACE`環境変数を使用し、[環境スコープを制限する](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)必要があります。

## ローカルのDockerレジストリでホストされているイメージを使用する {#use-images-hosted-in-a-local-docker-registry}

多くのAuto DevOpsジョブを[オフライン環境](../../user/application_security/offline_deployments/_index.md)で実行するように設定できます:

1. 必要なAuto DevOps DockerイメージをDocker Hubおよび`registry.gitlab.com`からローカルのGitLabコンテナレジストリにコピーします。
1. イメージがホストされ、ローカルレジストリで使用可能になったら、ローカルでホストされているイメージを指すように`.gitlab-ci.yml`を編集します。例: 

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml

   variables:
     REGISTRY_URL: "registry.gitlab.example"

   build:
     image: "$REGISTRY_URL/docker/auto-build-image:v0.6.0"
     services:
       - name: "$REGISTRY_URL/greg/docker/docker:20.10.16-dind"
         command: ['--tls=false', '--host=tcp://0.0.0.0:2375']
   ```

## PostgreSQLデータベースのサポート {#postgresql-database-support}

{{< alert type="warning" >}}

デフォルトでのPostgreSQLデータベースのプロビジョニングは、GitLab 15.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/387766)になり、16.0からはデフォルトではなくなります。PostgreSQLデータベースのプロビジョニングを有効にするには、関連付けられている[CI/CD変数](cicd_variables.md#database-variables)を設定します。

{{< /alert >}}

PostgreSQLデータベースを必要とするアプリケーションをサポートするために、[PostgreSQL](https://www.postgresql.org/)がデフォルトでプロビジョニングされます。PostgreSQLデータベースにアクセスするための認証情報は事前に設定されています。

認証情報をカスタマイズするには、関連付けられている[CI/CD変数](cicd_variables.md)を設定します。カスタム`DATABASE_URL`を定義することもできます:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### PostgreSQLのアップグレード {#upgrading-postgresql}

GitLabは、PostgreSQLデータベースをプロビジョニングするためにチャートバージョン8.2.1をデフォルトで使用します。バージョンは0.7.1から8.2.1に設定できます。

以前のチャートバージョンを使用している場合は、[PostgreSQLデータベースを移行する](upgrading_postgresql.md)必要があります新しいPostgreSQLに移行します。

デフォルトでプロビジョニングされるPostgreSQLを制御するCI/CD変数`AUTO_DEVOPS_POSTGRES_CHANNEL`は、[GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/210499)で`2`に変更されました。古いPostgreSQLを使用するには、`AUTO_DEVOPS_POSTGRES_CHANNEL`変数を`1`に設定します。

### PostgreSQL Helm Chartの値のカスタマイズ {#customize-values-for-postgresql-helm-chart}

カスタム値を設定するには、次のいずれかを実行します:

- `.gitlab/auto-deploy-postgres-values.yaml`という名前のファイルをリポジトリに追加します。見つかった場合、このファイルは自動的に使用されます。このファイルは、PostgreSQL Helmのアップグレードにデフォルトで使用されます。
- 別の名前またはパスを持つファイルをリポジトリに追加し、パスと名前を使用して`POSTGRES_HELM_UPGRADE_VALUES_FILE` [環境変数](cicd_variables.md#database-variables)を設定します。
- `POSTGRES_HELM_UPGRADE_EXTRA_ARGS` [環境変数](cicd_variables.md#database-variables)変数を設定します。

### 外部PostgreSQLデータベースプロバイダーの使用 {#use-external-postgresql-database-providers}

Auto DevOpsは、本番環境用のPostgreSQLコンテナをすぐにサポートします。ただし、AWS Relational Database Serviceのような外部マネージドプロバイダーを使用することをお勧めします。

外部マネージドプロバイダーを使用するには:

1. 環境スコープの[CI/CD変数](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を使用して、必要な環境の組み込みPostgreSQLインストールを無効にします。アプリのレビューとステージング環境の組み込みPostgreSQL設定は十分であるため、`production`のインストールのみを無効にする必要がある場合があります。

   ![自動メトリクス](img/disable_postgres_v12_4.png)

1. `DATABASE_URL`変数を、アプリケーションで利用可能な環境スコープの変数として定義します。これは、次の形式のURIである必要があります:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

1. Kubernetesクラスタリングが、PostgreSQLがホストされている場所にネットワークアクセスできることを確認します。
