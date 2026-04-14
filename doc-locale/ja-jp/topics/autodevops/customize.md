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

Auto DevOpsのコンポーネントは、ニーズに合わせてカスタマイズできます。たとえば、次のことができます:

- カスタム[buildpacks](#custom-buildpacks) 、[Dockerfiles](#custom-dockerfiles) 、および[Helmチャート](#custom-helm-chart)を追加します。
- カスタム[CI/CD設定](#customize-gitlab-ciyml)でステージングおよびカナリアデプロイを有効にします。
- Auto DevOpsを[GitLab API](#extend-auto-devops-with-the-api)で拡張します。

## カスタムbuildpacks {#custom-buildpacks}

buildpacksは、以下のいずれかの場合にカスタマイズできます:

- プロジェクトの自動buildpack検出が失敗する場合。
- ビルドをより細かく制御する必要がある場合。

### Cloud Native Buildpacksを使用したbuildpacksのカスタマイズ {#customize-buildpacks-with-cloud-native-buildpacks}

以下いずれかを指定します:

- CI/CD変数`BUILDPACK_URL`に、[`pack`のURI仕様形式](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/)のいずれかを指定します。
- 含めるbuildpacksを指定した[`project.toml`プロジェクト記述子](https://buildpacks.io/docs/app-developer-guide/using-project-descriptor/)。

### 複数buildpacks {#multiple-buildpacks}

Auto Testは`.buildpacks`ファイルを使用できないため、Auto DevOpsは複数buildpacksをサポートしていません。buildpack [heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/)は、バックエンドで`.buildpacks`ファイルを解析するために使用されますが、必要なコマンド`bin/test-compile`および`bin/test`を提供していません。

単一のカスタムbuildpackのみを使用する場合は、代わりにプロジェクトCI/CD変数`BUILDPACK_URL`を指定する必要があります。

## カスタムDockerfiles {#custom-dockerfiles}

プロジェクトリポジトリのルートにDockerfileがある場合、Auto DevOpsはDockerfileに基づいてDockerイメージをビルドします。これはbuildpackを使用するよりも高速です。特にDockerfileが[Alpine](https://hub.docker.com/_/alpine/)に基づいている場合は、より小さなイメージになることもあります。

CI/CD変数`DOCKERFILE_PATH`を設定すると、Auto Buildは代わりにその場所でDockerfileを探します。

### `docker build`への引数渡し {#pass-arguments-to-docker-build}

CI/CD変数`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`を使用して、`docker build`に引数を渡すことができます。

たとえば、デフォルトの`ruby:latest`ではなく、`ruby:alpine`に基づいたDockerイメージをビルドするには:

1. `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`を`--build-arg=RUBY_VERSION=alpine`に設定します。
1. カスタムDockerfileに以下を追加します:

   ```dockerfile
   ARG RUBY_VERSION=latest
   FROM ruby:$RUBY_VERSION

   # Include your content here
   ```

スペースや改行などの複雑な値を渡すには、Base64エンコードを使用します。複雑な未エンコードの値は、文字エスケープの問題を引き起こす可能性があります。

> [!warning]
> シークレットをDockerビルド引数として渡さないでください。シークレットがイメージに残る可能性があります。詳細については、[シークレットに関するベストプラクティスの議論](https://github.com/moby/moby/issues/13490)を参照してください。

## カスタムコンテナイメージ {#custom-container-image}

デフォルトでは、[自動デプロイ](stages.md#auto-deploy)は、[Auto Build](stages.md#auto-build)によってビルドされGitLabレジストリにプッシュされたコンテナイメージをデプロイします。特定の変数を定義することで、この動作をオーバーライドできます:

| エントリ | デフォルト | オーバーライド元 |
| ----- | -----   | -----    |
| イメージパス | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG`はブランチパイプライン用。`$CI_REGISTRY_IMAGE`はタグパイプライン用。 | `$CI_APPLICATION_REPOSITORY` |
| イメージタグ | `$CI_COMMIT_SHA`はブランチパイプライン用。`$CI_COMMIT_TAG`はタグパイプライン用。 | `$CI_APPLICATION_TAG` |

これらの変数は、Auto Buildおよび自動コンテナスキャンにも影響します。`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`にイメージをビルドおよびプッシュしたくない場合は、`Jobs/Deploy.gitlab-ci.yml`のみを含めるか、[`build`ジョブをスキップ](cicd_variables.md#job-skipping-variables)してください。

自動コンテナスキャンを使用し、`$CI_APPLICATION_REPOSITORY`の値を設定した場合は、`$CS_DEFAULT_BRANCH_IMAGE`も更新する必要があります。詳細については、[デフォルトブランチイメージの設定](../../user/application_security/container_scanning/_index.md#setting-the-default-branch-image)を参照してください。

`.gitlab-ci.yml`における設定例を次に示します:

```yaml
variables:
  CI_APPLICATION_REPOSITORY: <your-image-repository>
  CI_APPLICATION_TAG: <the-tag>
```

## Auto DevOpsをAPIで拡張する {#extend-auto-devops-with-the-api}

GitLab APIを使用して、Auto DevOpsの設定を拡張および管理できます:

- [APIコールで設定にアクセス](../../api/settings.md#available-settings)します。`auto_devops_enabled`を含め、デフォルトでプロジェクトのAuto DevOpsを有効にします。
- [新規プロジェクトを作成](../../api/projects.md#create-a-project)します。
- [グループを編集](../../api/groups.md#update-group-attributes)します。
- [プロジェクトを編集](../../api/projects.md#edit-a-project)します。

## CI/CD変数をビルド環境に転送 {#forward-cicd-variables-to-the-build-environment}

CI/CD変数をビルド環境に転送するには、転送したい変数の名前を`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` CI/CD変数に追加します。複数の変数はカンマで区切ります。

たとえば、変数`CI_COMMIT_SHA`と`CI_ENVIRONMENT_NAME`を転送するには:

```yaml
variables:
  AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES: CI_COMMIT_SHA,CI_ENVIRONMENT_NAME
```

buildpacksを使用する場合、転送された変数は環境変数として自動的に利用可能です。

Dockerfileを使用する場合:

1. 実験的なDockerfile構文を有効にするには、Dockerfileに以下を追加します:

   ```dockerfile
   # syntax = docker/dockerfile:experimental
   ```

1. `Dockerfile`内の`RUN $COMMAND`でシークレットを利用可能にするには、シークレットファイルをマウントし、`$COMMAND`を実行する前にそれをソースとして読み込みます:

   ```dockerfile
   RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && $COMMAND
   ```

`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES`が設定されている場合、Auto DevOpsは実験的な[Docker BuildKit](https://docs.docker.com/build/buildkit/)機能で`--secret`フラグを使用できるようにします。

## カスタムHelmチャート {#custom-helm-chart}

Auto DevOpsは、[Helm](https://helm.sh/)を使用してアプリケーションをKubernetesにデプロイします。プロジェクトリポジトリにチャートをバンドルするか、プロジェクトCI/CD変数を指定することで、使用されるHelmチャートをオーバーライドできます:

- **Bundled chart** \- プロジェクトに`./chart`ディレクトリがあり、その中に`Chart.yaml`ファイルがある場合、Auto DevOpsはチャートを検出して、[デフォルトチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)の代わりに使用します。
- **Project variable** \- カスタムチャートのURLを指定して、[プロジェクトCI/CD変数](../../ci/variables/_index.md) `AUTO_DEVOPS_CHART`を作成します。また、5つのプロジェクト変数を作成できます:

  - `AUTO_DEVOPS_CHART_REPOSITORY` - カスタムチャートリポジトリのURL。
  - `AUTO_DEVOPS_CHART` - チャートへのパス。
  - `AUTO_DEVOPS_CHART_REPOSITORY_INSECURE` - 空でない値を設定すると、Helmコマンドに`--insecure-skip-tls-verify`引数が追加されます。
  - `AUTO_DEVOPS_CHART_CUSTOM_ONLY` - 空でない値を設定すると、カスタムチャートのみが使用されます。デフォルトでは、最新のチャートはGitLabからダウンロードされます。
  - `AUTO_DEVOPS_CHART_VERSION` - デプロイチャートのバージョン。

### Helmチャートの値のカスタマイズ {#customize-helm-chart-values}

[デフォルトHelmチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)の`values.yaml`ファイルにあるデフォルト値をオーバーライドするには、以下のいずれかを実行します:

- `.gitlab/auto-deploy-values.yaml`という名前のファイルをリポジトリに追加します。このファイルはデフォルトでHelmアップグレードに使用されます。
- 別の名前またはパスのファイルをリポジトリに追加します。ファイルのパスと名前を指定して、`HELM_UPGRADE_VALUES_FILE` [CI/CD変数](cicd_variables.md)を設定します。

一部の値は上記のオプションではオーバーライドできませんが、[このイシュー](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/issues/31)でこの動作を変更する提案がされています。`replicaCount`のような設定をオーバーライドするには、`REPLICAS` [ビルドおよびデプロイ](cicd_variables.md#build-and-deployment-variables) CI/CD変数を使用します。

### `helm upgrade`をカスタマイズ {#customize-helm-upgrade}

[auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image)は`helm upgrade`コマンドを使用します。このコマンドをカスタマイズするには、`HELM_UPGRADE_EXTRA_ARGS` CI/CD変数でオプションを渡します。

たとえば、`helm upgrade`の実行時にアップグレード前後のフックを無効にするには:

```yaml
variables:
  HELM_UPGRADE_EXTRA_ARGS: --no-hooks
```

オプションの完全なリストについては、[公式`helm upgrade`ドキュメント](https://helm.sh/docs/helm/helm_upgrade/)を参照してください。

### Helmチャートを1つの環境に制限する {#limit-a-helm-chart-to-one-environment}

カスタムチャートを1つの環境に制限するには、環境スコープをCI/CD変数に追加します。詳細については、[CI/CD変数の環境スコープを制限](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を参照してください。

## `.gitlab-ci.yml`をカスタマイズ {#customize-gitlab-ciyml}

[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)は`.gitlab-ci.yml`ファイルの実装であるため、Auto DevOpsは高度にカスタマイズ可能です。このテンプレートは、`.gitlab-ci.yml`の任意の実装で利用可能な機能のみを使用します。

Auto DevOpsが使用するCI/CDパイプラインにカスタム動作を追加するには:

1. リポジトリのルートに、次の内容を含む`.gitlab-ci.yml`ファイルを追加します:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
   ```

1. `.gitlab-ci.yml`ファイルに変更を追加します。変更はAuto DevOpsテンプレートにマージされます。詳細については、`include`が変更をマージする方法に関する[`include`ドキュメント](../../ci/yaml/_index.md#include)を参照してください。

Auto DevOpsパイプラインから動作を削除するには:

1. [Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)をプロジェクトにコピーします。
1. 必要に応じて、テンプレートのコピーを編集します。

### Auto DevOpsの個々のコンポーネントを使用する {#use-individual-components-of-auto-devops}

Auto DevOpsが提供する機能の一部のみが必要な場合は、個々のAuto DevOpsジョブを独自の`.gitlab-ci.yml`に含めることができます。各ジョブに必要なパイプラインステージも`.gitlab-ci.yml`ファイルで定義してください。

たとえば、[Auto Build](stages.md#auto-build)を使用するには、`.gitlab-ci.yml`に以下を追加します:

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

GitLab 14.5および以前では、`environment:kubernetes:namespace`を使用して環境のネームスペースを指定できました。しかし、この機能は証明書ベースのインテグレーションとともに[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)となりました。

現在は、`KUBE_NAMESPACE`環境変数を使用し、[その環境スコープを制限](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)する必要があります。

## ローカルDockerレジストリでホストされているイメージを使用する {#use-images-hosted-in-a-local-docker-registry}

多くのAuto DevOpsジョブを[オフライン環境](../../user/application_security/offline_deployments/_index.md)で実行するように設定できます:

1. 必要なAuto DevOps DockerイメージをDocker Hubおよび`registry.gitlab.com`からローカルのGitLabコンテナレジストリにコピーします。
1. イメージがローカルレジストリでホストされ利用可能になったら、`.gitlab-ci.yml`を編集してローカルでホストされているイメージを指すようにします。例: 

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
> デフォルトでのPostgreSQLデータベースのプロビジョニングは、GitLab 15.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/387766)となり、16.0以降ではデフォルトではなくなります。データベースのプロビジョニングを有効にするには、関連する[CI/CD変数](cicd_variables.md#database-variables)を設定します。

データベースを必要とするアプリケーションをサポートするため、[PostgreSQL](https://www.postgresql.org/)はデフォルトでプロビジョニングされます。データベースにアクセスするための認証情報は事前設定されています。

認証情報をカスタマイズするには、関連する[CI/CD変数](cicd_variables.md)を設定します。カスタム`DATABASE_URL`を定義することもできます:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### PostgreSQLのアップグレード {#upgrading-postgresql}

GitLabは、チャートバージョン8.2.1を使用して、デフォルトでPostgreSQLをプロビジョニングします。バージョンは0.7.1から8.2.1まで設定できます。

以前のチャートバージョンを使用している場合は、データベースを新しいPostgreSQLに[移行する](upgrading_postgresql.md)必要があります。

デフォルトでプロビジョニングされたPostgreSQLを制御するCI/CD変数`AUTO_DEVOPS_POSTGRES_CHANNEL`は、[GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/210499)で`2`に変更されました。以前のPostgreSQLを使用するには、`AUTO_DEVOPS_POSTGRES_CHANNEL`変数を`1`に設定します。

### PostgreSQL Helm Chartの値のカスタマイズ {#customize-values-for-postgresql-helm-chart}

カスタム値を設定するには、以下のいずれかを実行します:

- `.gitlab/auto-deploy-postgres-values.yaml`という名前のファイルをリポジトリに追加します。見つかった場合、このファイルは自動的に使用されます。このファイルはデフォルトでPostgreSQL Helmアップグレードに使用されます。
- 異なる名前またはパスのファイルをリポジトリに追加し、ファイルのパスと名前を指定して`POSTGRES_HELM_UPGRADE_VALUES_FILE` [環境変数](cicd_variables.md#database-variables)を設定します。
- `POSTGRES_HELM_UPGRADE_EXTRA_ARGS` [環境変数](cicd_variables.md#database-variables)を設定します。

### 外部PostgreSQLデータベースプロバイダーを使用する {#use-external-postgresql-database-providers}

Auto DevOpsは、本番環境向けのPostgreSQLコンテナの標準サポートを提供します。ただし、AWS Relational Database Serviceのような外部マネージドプロバイダーを使用したい場合もあります。

外部マネージドプロバイダーを使用するには:

1. 必須の環境に対して、環境スコープの[CI/CD変数](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を使用して、組み込みのPostgreSQLインストールを無効にします。レビューアプリとステージングの組み込みPostgreSQLセットアップで十分であるため、`production`のインストールのみを無効にする必要がある場合があります。

   ![Auto Metrics](img/disable_postgres_v12_4.png)

1. `DATABASE_URL`変数を、アプリケーションで利用可能な環境スコープ変数として定義します。これは、次の形式のURLである必要があります:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

1. KubernetesクラスターがPostgreSQLがホストされている場所にネットワークアクセスできることを確認してください。
