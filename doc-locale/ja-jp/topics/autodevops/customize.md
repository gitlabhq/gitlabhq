---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Auto DevOpsをカスタマイズ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Auto DevOpsのコンポーネントは、必要に応じてカスタマイズできます。たとえば、次のことができます:

- カスタム[ビルドパック](#custom-buildpacks)、[Dockerfiles](#custom-dockerfiles)、および[Helmチャート](#custom-helm-chart)を追加します。
- カスタム[CI/CD設定](#customize-gitlab-ciyml)を使用して、ステージングおよびカナリアデプロイを有効にします。
- Auto DevOpsを[GitLab API](#extend-auto-devops-with-the-api)で拡張します。

## カスタムビルドパック {#custom-buildpacks}

次のいずれかの場合に、ビルドパックをカスタマイズできます:

- 自動ビルドパック検出がプロジェクトで失敗する場合。
- ビルドに対するより多くの制御が必要な場合。

### Cloud Native Buildpacksを使用してビルドパックをカスタマイズ {#customize-buildpacks-with-cloud-native-buildpacks}

次のいずれかを指定します:

- CI/CD変数`BUILDPACK_URL`に、[`pack`のURI仕様形式](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/)のいずれかを指定します。
- 含めるビルドパックを持つ[`project.toml`プロジェクト記述子](https://buildpacks.io/docs/app-developer-guide/using-project-descriptor/)。

### 複数のビルドパック {#multiple-buildpacks}

Auto Testが`.buildpacks`ファイルを使用できないため、Auto DevOpsは複数のビルドパックをサポートしていません。バックエンドで`.buildpacks`ファイルを解析するために使用されるビルドパック[heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/)は、必要なコマンド`bin/test-compile`と`bin/test`を提供しません。

単一のカスタムビルドパックのみを使用するには、代わりにプロジェクトCI/CD変数`BUILDPACK_URL`を指定する必要があります。

## カスタムDockerfiles {#custom-dockerfiles}

プロジェクトのリポジトリのルートにDockerfileがある場合、Auto DevOpsはDockerfileに基づいてDockerイメージをビルドします。これは、ビルドパックを使用するよりも高速です。特にDockerfileが[alpine](https://hub.docker.com/_/alpine/)に基づいている場合、より小さなイメージになる可能性もあります。

`DOCKERFILE_PATH` CI/CD変数を設定すると、Auto Buildは代わりにそこにDockerfileを探します。

### `docker build`に引数を渡す {#pass-arguments-to-docker-build}

プロジェクトCI/CD変数`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`を使用して、`docker build`に引数を渡すことができます。

例えば、デフォルトの`ruby:latest`ではなく、`ruby:alpine`に基づいてDockerイメージをビルドするには:

1. `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`を`--build-arg=RUBY_VERSION=alpine`に設定します。
1. 次の内容をカスタムDockerfileに追加します:

   ```dockerfile
   ARG RUBY_VERSION=latest
   FROM ruby:$RUBY_VERSION

   # Include your content here
   ```

スペースや改行のような複雑な値を渡すには、Base64エンコードを使用します。複雑でエンコードされていない値は、文字エスケープに関する問題を引き起こす可能性があります。

> [!warning]
> Dockerビルドの引数としてシークレットを渡さないでください。シークレットはイメージ内に永続化する可能性があります。詳細については、シークレットに関するベストプラクティスの[このディスカッション](https://github.com/moby/moby/issues/13490)を参照してください。

## カスタムコンテナイメージ {#custom-container-image}

デフォルトでは、[自動デプロイ](stages.md#auto-deploy)は、[自動ビルド](stages.md#auto-build)によってビルドされGitLabレジストリにプッシュされたコンテナイメージをデプロイします。特定の変数を定義することで、この動作を上書きできます:

| エントリ | デフォルト | 上書き元 |
| ----- | -----   | -----    |
| イメージパス | ブランチパイプラインの場合は`$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG`。タグパイプラインの場合は`$CI_REGISTRY_IMAGE`。 | `$CI_APPLICATION_REPOSITORY` |
| イメージタグ | ブランチパイプラインの場合は`$CI_COMMIT_SHA`。タグパイプラインの場合は`$CI_COMMIT_TAG`。 | `$CI_APPLICATION_TAG` |

これらの変数は、自動ビルドと自動コンテナスキャンにも影響します。`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`にイメージをビルドしてプッシュしたくない場合は、`Jobs/Deploy.gitlab-ci.yml`のみを含めるか、[`build`ジョブをスキップ](cicd_variables.md#job-skipping-variables)します。

自動コンテナスキャンを使用し、`$CI_APPLICATION_REPOSITORY`の値を設定する場合は、`$CS_DEFAULT_BRANCH_IMAGE`も更新する必要があります。詳細については、[デフォルトブランチイメージを設定する](../../user/application_security/container_scanning/_index.md#setting-the-default-branch-image)を参照してください。

`.gitlab-ci.yml`での設定例を次に示します:

```yaml
variables:
  CI_APPLICATION_REPOSITORY: <your-image-repository>
  CI_APPLICATION_TAG: <the-tag>
```

## Auto DevOpsをAPIで拡張 {#extend-auto-devops-with-the-api}

Auto DevOpsの設定をGitLab APIで拡張および管理できます:

- [APIコールを使用して設定にアクセス](../../api/settings.md#available-settings)します。`auto_devops_enabled`を含むこれらの設定により、デフォルトでプロジェクトのAuto DevOpsを有効にできます。
- [新規プロジェクトを作成する](../../api/projects.md#create-a-project)。
- [グループを編集する](../../api/groups.md#update-group-attributes)。
- [プロジェクトを編集する](../../api/projects.md#update-a-project)。

## CI/CD変数をビルド環境に転送 {#forward-cicd-variables-to-the-build-environment}

CI/CD変数をビルド環境に転送するには、転送する変数の名前を`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` CI/CD変数に追加します。複数の変数をカンマで区切ります。

例えば、変数`CI_COMMIT_SHA`と`CI_ENVIRONMENT_NAME`を転送するには:

```yaml
variables:
  AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES: CI_COMMIT_SHA,CI_ENVIRONMENT_NAME
```

ビルドパックを使用する場合、転送された変数は環境変数として自動的に利用可能です。

Dockerfileを使用する場合:

1. 実験的なDockerfile構文を有効にするには、次の内容をDockerfileに追加します:

   ```dockerfile
   # syntax = docker/dockerfile:experimental
   ```

1. `Dockerfile`内のいずれかの`RUN $COMMAND`でシークレットを利用可能にするには、シークレットファイルをマウントし、`$COMMAND`を実行する前にそれをソースします:

   ```dockerfile
   RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && $COMMAND
   ```

`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES`が設定されている場合、Auto DevOpsは実験的な[Docker BuildKit](https://docs.docker.com/build/buildkit/)機能で`--secret`フラグを使用できるようにします。

## カスタムHelmチャート {#custom-helm-chart}

Auto DevOpsは[Helm](https://helm.sh/)を使用してアプリケーションをKubernetesにデプロイします。プロジェクトリポジトリにチャートをバンドルするか、プロジェクトCI/CD変数を指定することで、使用されるHelmチャートを上書きできます:

- **バンドルされたチャート** \- プロジェクトに`./chart`ディレクトリがあり、その中に`Chart.yaml`ファイルがある場合、Auto DevOpsはチャートを検出し、[デフォルトチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)の代わりに使用します。
- **プロジェクト変数** \- カスタムチャートのURLで[プロジェクトCI/CD変数](../../ci/variables/_index.md)`AUTO_DEVOPS_CHART`を作成します。さらに5つのプロジェクト変数を作成できます:

  - `AUTO_DEVOPS_CHART_REPOSITORY` - カスタムチャートリポジトリのURL。
  - `AUTO_DEVOPS_CHART` - チャートへのパス。
  - `AUTO_DEVOPS_CHART_REPOSITORY_INSECURE` - 空ではない値に設定すると、`--insecure-skip-tls-verify`引数がHelmコマンドに追加されます。
  - `AUTO_DEVOPS_CHART_CUSTOM_ONLY` - カスタムチャートのみを使用するように空ではない値に設定します。デフォルトでは、最新のチャートがGitLabからダウンロードされます。
  - `AUTO_DEVOPS_CHART_VERSION` - デプロイチャートのバージョン。

### PostgreSQL Helmチャートの値のカスタマイズ {#customize-helm-chart-values}

[デフォルトHelmチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)の`values.yaml`ファイル内のデフォルト値を上書きするには、次のいずれかの方法を使用します:

- ファイル`.gitlab/auto-deploy-values.yaml`をリポジトリに追加します。このファイルは、Helmアップグレードでデフォルトで使用されます。
- 異なる名前またはパスのファイルをリポジトリに追加します。ファイルのパスと名前を持つ`HELM_UPGRADE_VALUES_FILE` [CI/CD変数](cicd_variables.md)を設定します。

一部の値は以前のオプションでオーバーライドできませんが、[このイシュー](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/issues/31)ではこの動作を変更することが提案されています。`replicaCount`のような設定をオーバーライドするには、`REPLICAS`[ビルドおよびデプロイ](cicd_variables.md#build-and-deployment-variables)CI/CD変数を使用します。

### `helm upgrade`をカスタマイズ {#customize-helm-upgrade}

[auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image)は`helm upgrade`コマンドを使用します。このコマンドをカスタマイズするには、`HELM_UPGRADE_EXTRA_ARGS` CI/CD変数でオプションを渡します。

例えば、`helm upgrade`が実行されるときにアップグレード前後のフックを無効にするには:

```yaml
variables:
  HELM_UPGRADE_EXTRA_ARGS: --no-hooks
```

オプションの完全なリストについては、[公式の`helm upgrade`ドキュメント](https://helm.sh/docs/helm/helm_upgrade/)を参照してください。

### 一つの環境にHelmチャートを制限する {#limit-a-helm-chart-to-one-environment}

カスタムチャートを1つの環境に制限するには、環境スコープをCI/CD変数に追加します。詳細については、[CI/CD変数の環境スコープを制限する](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を参照してください。

## `.gitlab-ci.yml`をカスタマイズ {#customize-gitlab-ciyml}

[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)が`.gitlab-ci.yml`ファイルの実装であるため、Auto DevOpsは高度にカスタマイズ可能です。このテンプレートは、`.gitlab-ci.yml`の任意の実装で利用可能な機能のみを使用します。

Auto DevOpsで使用されるCI/CDパイプラインにカスタム動作を追加するには:

1. リポジトリのルートに、次の内容の`.gitlab-ci.yml`ファイルを追加します:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
   ```

1. `.gitlab-ci.yml`ファイルに変更を追加します。変更はAuto DevOpsテンプレートにマージされます。`include`が変更をマージする方法の詳細については、[`include`ドキュメント](../../ci/yaml/_index.md#include)を参照してください。

Auto DevOpsパイプラインから動作を削除するには:

1. [Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)をプロジェクトにコピーします。
1. 必要に応じて、テンプレートのコピーを編集します。

### Auto DevOpsの個々のコンポーネントを使用する {#use-individual-components-of-auto-devops}

Auto DevOpsが提供する機能の一部のみが必要な場合は、個々のAuto DevOpsジョブを独自の`.gitlab-ci.yml`に含めることができます。各ジョブに必要なパイプラインステージも`.gitlab-ci.yml`ファイルで定義してください。

例えば、[自動ビルド](stages.md#auto-build)を使用するには、次の内容を`.gitlab-ci.yml`に追加します:

```yaml
stages:
  - build

include:
  - template: Jobs/Build.gitlab-ci.yml
```

利用可能なジョブのリストについては、[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)を参照してください。

## 複数のKubernetesクラスターを使用する {#use-multiple-kubernetes-clusters}

[Auto DevOps用の複数のKubernetesクラスター](multiple_clusters_auto_devops.md)を参照してください。

## Kubernetesネームスペースのカスタマイズ {#customizing-the-kubernetes-namespace}

GitLab 14.5以前では、環境のネームスペースを指定するために`environment:kubernetes:namespace`を使用できました。しかし、この機能は証明書ベースのインテグレーションとともに[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

現在は、`KUBE_NAMESPACE`環境変数を使用し、その[環境スコープを制限](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)する必要があります。

## ローカルDockerレジストリでホストされているイメージを使用する {#use-images-hosted-in-a-local-docker-registry}

多くのAuto DevOpsジョブを[オフライン環境](../../user/application_security/offline_deployments/_index.md)で設定して実行できます:

1. 必要なAuto DevOps DockerイメージをDocker Hubと`registry.gitlab.com`からローカルのGitLabコンテナレジストリにコピーします。
1. イメージがホストされ、ローカルレジストリで利用可能になったら、`.gitlab-ci.yml`を編集してローカルでホストされているイメージを指すようにします。例: 

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

> [!warning]
> デフォルトでのPostgreSQLデータベースのプロビジョニングはGitLab 15.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/387766)になり、16.0からはデフォルトではなくなります。データベースのプロビジョニングを有効にするには、関連する[CI/CD変数](cicd_variables.md#database-variables)を設定します。

データベースを必要とするアプリケーションをサポートするために、[PostgreSQL](https://www.postgresql.org/)はデフォルトでプロビジョニングされます。データベースにアクセスするための認証情報は事前に設定されています。

認証情報をカスタマイズするには、関連する[CI/CD変数](cicd_variables.md)を設定します。カスタム`DATABASE_URL`も定義できます:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### PostgreSQLのアップグレード {#upgrading-postgresql}

GitLabはチャートバージョン8.2.1を使用して、デフォルトでPostgreSQLをプロビジョニングします。バージョンを0.7.1から8.2.1に設定できます。

古いチャートバージョンを使用している場合は、新しいPostgreSQLに[データベースを移行](upgrading_postgresql.md)する必要があります。

デフォルトでプロビジョニングされるPostgreSQLを制御するCI/CD変数`AUTO_DEVOPS_POSTGRES_CHANNEL`は、[GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/210499)で`2`に変更されました。古いPostgreSQLを使用するには、`AUTO_DEVOPS_POSTGRES_CHANNEL`変数を`1`に設定します。

### PostgreSQL Helmチャートの値のカスタマイズ {#customize-values-for-postgresql-helm-chart}

カスタム値を設定するには、次のいずれかを実行します:

- ファイル`.gitlab/auto-deploy-postgres-values.yaml`をリポジトリに追加します。見つかった場合、このファイルは自動的に使用されます。このファイルは、PostgreSQL Helmアップグレードでデフォルトで使用されます。
- 異なる名前またはパスのファイルをリポジトリに追加し、`POSTGRES_HELM_UPGRADE_VALUES_FILE`[環境変数](cicd_variables.md#database-variables)にそのパスと名前を設定します。
- `POSTGRES_HELM_UPGRADE_EXTRA_ARGS`[環境変数](cicd_variables.md#database-variables)を設定します。

### 外部PostgreSQLデータベースプロバイダーを使用する {#use-external-postgresql-database-providers}

Auto DevOpsは、本番環境向けのPostgreSQLコンテナの既成のサポートを提供します。しかし、AWS Relational Database Serviceのような外部のマネージドプロバイダーを使用したい場合があります。

外部のマネージドプロバイダーを使用するには:

1. 必要な環境に対して、環境スコープの[CI/CD変数](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を使用して組み込みのPostgreSQLインストールを無効にします。レビューアプリとステージング用の組み込みPostgreSQLセットアップで十分であるため、`production`のインストールのみを無効にする必要がある場合があります。

   ![Auto Metrics](img/disable_postgres_v12_4.png)
1. `DATABASE_URL`変数を、アプリケーションで利用可能な環境スコープの変数として定義します。これは、次の形式のURLである必要があります:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

1. お使いのKubernetesクラスターがPostgreSQLがホストされている場所にネットワークアクセスできることを確認してください。
