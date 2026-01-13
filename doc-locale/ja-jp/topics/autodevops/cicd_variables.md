---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD変数
---

CI/CD変数を使用して、Auto DevOpsドメインをセットアップし、カスタムHelmチャートを提供するか、アプリケーションをスケールします。

## ビルドおよびデプロイの変数 {#build-and-deployment-variables}

これらの変数を使用して、ビルドをカスタマイズおよびデプロイします。

<!-- markdownlint-disable MD056 -->

| **CI/CD variable**（CI/CD変数）                      | **説明** |
|-----------------------------------------|-----------------|
| `ADDITIONAL_HOSTS`                      | コンマ区切りのリストとして指定され、Ingressホストに追加される完全修飾ドメイン名。 |
| `<ENVIRONMENT>_ADDITIONAL_HOSTS`        | 特定の環境の場合、コンマ区切りのリストとして指定され、Ingressホストに追加される完全修飾ドメイン名。これは、`ADDITIONAL_HOSTS`よりも優先されます。 |
| `AUTO_BUILD_IMAGE_VERSION`              | `build`ジョブに使用されるイメージバージョンをカスタマイズします。[バージョンのリスト](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/releases)を参照してください。 |
| `AUTO_DEPLOY_IMAGE_VERSION`             | Kubernetesデプロイメントジョブに使用されるイメージバージョンをカスタマイズします。[バージョンのリスト](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/releases)を参照してください。 |
| `AUTO_DEVOPS_ATOMIC_RELEASE`            | Auto DevOpsは、Helmデプロイメントで[`--atomic`](https://v2.helm.sh/docs/helm/#options-43)をデフォルトで使用します。この変数を`false`に設定して、`--atomic`の使用を無効にします |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`   | Cloud Native Buildpacksでビルドするときに使用されるビルドツール。デフォルトのビルドツールは`heroku/buildpacks:22`です。[詳細情報](stages.md#auto-build-using-cloud-native-buildpacks)。 |
| `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`    | `docker build`コマンドに渡される追加の引数。引用符を使用しても、ワード分割は防止されません。[詳細情報](customize.md#pass-arguments-to-docker-build)。 |
| `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` | ビルド環境（ビルドパックビルドツールまたは`docker build`）に転送される[コンマ区切りのCI/CD変数名](customize.md#forward-cicd-variables-to-the-build-environment)。 |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_PORT`      | GitLab 15.0以降では、生成されたDockerイメージによって公開されるポート。いずれのポートも公開しないようにするには、`false`に設定します。`5000`がデフォルトです。 |
| `AUTO_DEVOPS_BUILD_IMAGE_CONTEXT`       | DockerfileとCloud Native Buildpacksのビルドコンテキストディレクトリを設定するために使用されます。ルートディレクトリがデフォルトです。 |
| `AUTO_DEVOPS_CHART`                     | アプリのデプロイに使用されるHelmチャート。[GitLabによって提供](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)されるデフォルトのHelmチャート。 |
| `AUTO_DEVOPS_CHART_REPOSITORY`          | チャートの検索に使用されるHelmチャートリポジトリ。`https://charts.gitlab.io`がデフォルトです。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_NAME`     | Helmリポジトリの名前を設定するために使用されます。`gitlab`がデフォルトです。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME` | Helmリポジトリに接続するためのユーザー名を設定するために使用されます。認証情報はデフォルトではありません。`AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD`も設定します。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD` | Helmリポジトリに接続するためのパスワードを設定するために使用されます。認証情報はデフォルトではありません。`AUTO_DEVOPS_CHART_REPOSITORY_USERNAME`も設定します。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASS_CREDENTIALS` | チャートアーティファクトがリポジトリとは異なるホスト上にある場合に、Helmリポジトリの認証情報をチャートサーバーに転送できるように、空でない値を設定します。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_INSECURE` | `--insecure-skip-tls-verify`引数をHelmコマンドに追加するために、空でない値を設定します。デフォルトでは、HelmはTLS検証を使用します。 |
| `AUTO_DEVOPS_CHART_CUSTOM_ONLY`         | カスタムチャートのみを使用するように、空でない値を設定します。デフォルトでは、最新のチャートがGitLabからダウンロードされます。 |
| `AUTO_DEVOPS_CHART_VERSION`             | デプロイメントチャートのバージョンを設定します。デフォルトでは、利用可能な最新バージョンに設定されます。 |
| `AUTO_DEVOPS_COMMON_NAME`               | GitLab 15.5以降では、TLS証明書に使用される共通名をカスタマイズするために、有効なドメイン名に設定します。`le-$CI_PROJECT_ID.$KUBE_INGRESS_BASE_DOMAIN`がデフォルトです。Ingressでこの代替ホストを設定しないようにするには、`false`に設定します。 |
| `AUTO_DEVOPS_DEPLOY_DEBUG`              | この変数が存在する場合、Helmはデバッグログを出力します。 |
| `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V<N>` | [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) v1.0.0以降、この変数が存在する場合、チャートの新しいメジャーバージョンが強制的にデプロイされます。詳細については、[警告を無視してデプロイを続行](upgrading_auto_deploy_dependencies.md#ignore-warnings-and-continue-deploying)を参照してください。 |
| `BUILDPACK_URL`                         | 完全なビルドパックURL。[PackでサポートされているURLを指している必要があります](customize.md#custom-buildpacks)。 |
| `CANARY_ENABLED`                        | [カナリア環境のデプロイポリシー](#deploy-policy-for-canary-environments)を定義するために使用されます。 |
| `BUILDPACK_VOLUMES`                     | マウントする1つ以上の[ビルドパックボリューム](stages.md#mount-volumes-into-the-build-container)を指定します。リスト区切り文字としてパイプ`\|`を使用します。 |
| `CANARY_PRODUCTION_REPLICAS`            | 本番環境の[カナリアデプロイメント](../../user/project/canary_deployments.md)用にデプロイするレプリカの数。これは、`CANARY_REPLICAS`よりも優先されます。デフォルトは1です。 |
| `CANARY_REPLICAS`                       | [カナリアデプロイメント](../../user/project/canary_deployments.md)用にデプロイするレプリカの数。デフォルトは1です。 |
| `CI_APPLICATION_REPOSITORY`             | ビルドまたはデプロイされるコンテナイメージのリポジトリ、`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`。詳細については、[カスタムコンテナイメージ](customize.md#custom-container-image)をお読みください。 |
| `CI_APPLICATION_TAG`                    | ビルドまたはデプロイされるコンテナイメージのタグ、`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`。詳細については、[カスタムコンテナイメージ](customize.md#custom-container-image)をお読みください。 |
| `DAST_AUTO_DEPLOY_IMAGE_VERSION`        | デフォルトブランチでのDASTデプロイメントに使用されるイメージバージョンをカスタマイズします。通常は`AUTO_DEPLOY_IMAGE_VERSION`と同じである必要があります。[バージョンのリスト](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/releases)を参照してください。 |
| `DOCKERFILE_PATH`                       | [ビルドステージのデフォルトのDockerfileパスをオーバーライドすることを許可します](customize.md#custom-dockerfiles) |
| `HELM_RELEASE_NAME`                     | `helm`リリース名をオーバーライドすることを許可します。単一のネームスペースに複数のプロジェクトをデプロイするときに、一意のリリース名を割り当てるために使用できます。 |
| `HELM_UPGRADE_VALUES_FILE`              | `helm upgrade`値ファイルがオーバーライドされるようにします。`.gitlab/auto-deploy-values.yaml`がデフォルトです。 |
| `HELM_UPGRADE_EXTRA_ARGS`               | アプリケーションのデプロイ時に、`helm upgrade`コマンドで追加オプションを使用できます。引用符を使用しても、ワード分割は防止されません。 |
| `INCREMENTAL_ROLLOUT_MODE`              | 存在する場合、本番環境のアプリケーションの[段階的ロールアウト](#incremental-rollout-to-production)を有効にするために使用できます。手動デプロイメントジョブの場合は`manual`、またはそれぞれ5分遅延する自動ロールアウトデプロイメントの場合は`timed`に設定します。 |
| `K8S_SECRET_*`                          | [`K8S_SECRET_`](#configure-application-secret-variables)で始まる変数は、Auto DevOpsによって、デプロイされたアプリケーションへの環境変数として利用できるようになります。 |
| `KUBE_CONTEXT`                          | `KUBECONFIG`から使用するコンテキストを選択するために使用できます。`KUBE_CONTEXT`が空白の場合、`KUBECONFIG`のデフォルトのコンテキスト（存在する場合）が使用されます。[Kubernetes用エージェントを使用する場合](../../user/clusters/agent/ci_cd_workflow.md)は、コンテキストを選択する必要があります。 |
| `KUBE_INGRESS_BASE_DOMAIN`              | クラスタごとにドメインを設定するために使用できます。詳細については、[クラスタドメイン](../../user/project/clusters/gitlab_managed_clusters.md#base-domain)を参照してください。 |
| `KUBE_NAMESPACE`                        | デプロイメントに使用されるネームスペース。証明書ベースのクラスタを使用している場合、[この値を直接上書きしないでください](../../user/project/clusters/deploy_to_cluster.md#custom-namespace)。 |
| `KUBECONFIG`                            | デプロイメントに使用するkubeconfig。ユーザーが指定した値は、GitLabが指定した値よりも優先されます。 |
| `PRODUCTION_REPLICAS`                   | 本番環境にデプロイするレプリカの数。`REPLICAS`よりも優先され、デフォルトは1です。ゼロダウンタイムのアップグレードの場合、2以上に設定します。 |
| `REPLICAS`                              | デプロイするレプリカの数。デフォルトは1です。`replicaCount`を[変更](customize.md#customize-helm-chart-values)する代わりに、この変数を変更します。 |
| `ROLLOUT_RESOURCE_TYPE`                 | カスタムHelmチャートを使用する場合に、デプロイされるリソースタイプ仕様を許可します。デフォルト値は`deployment`です。 |
| `ROLLOUT_STATUS_DISABLED`               | すべてのリソースタイプ（たとえば、`cronjob`）をサポートしていないため、ロールアウトステータスチェックを無効にするために使用されます。 |
| `STAGING_ENABLED`                       | [ステージング環境と本番環境のデプロイポリシー](#deploy-policy-for-staging-and-production-environments)を定義するために使用されます。 |
| `TRACE`                                 | 詳細な出力を生成するようにHelmコマンドを設定するための値に設定します。この設定を使用して、Auto DevOpsデプロイメントの問題を診断できます。 |

<!-- markdownlint-enable MD056 -->

## データベース変数 {#database-variables}

{{< alert type="warning" >}}

[GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/343988)以降、`POSTGRES_ENABLED`はデフォルトで設定されなくなりました。

{{< /alert >}}

これらの変数を使用して、CI/CDをPostgreSQLデータベースと統合します。

| **CI/CD variable**（CI/CD変数）                            | **説明**                    |
|-----------------------------------------|------------------------------------|
| `DB_INITIALIZE`                         | アプリケーションのPostgreSQLデータベースを初期化するために実行するコマンドを指定するために使用されます。アプリケーションポッド内で実行されます。 |
| `DB_MIGRATE`                            | アプリケーションのPostgreSQLデータベースを移行するために実行するコマンドを指定するために使用されます。アプリケーションポッド内で実行されます。 |
| `POSTGRES_ENABLED`                      | PostgreSQLが有効かどうか。`true`に設定すると、PostgreSQLの自動デプロイメントが有効になります。 |
| `POSTGRES_USER`                         | PostgreSQLのユーザー名。`user`がデフォルトです。カスタムユーザー名を使用するように設定します。 |
| `POSTGRES_PASSWORD`                     | PostgreSQLパスワード。`testing-password`がデフォルトです。カスタムパスワードを使用するように設定します。 |
| `POSTGRES_DB`                           | PostgreSQLデータベース名。デフォルトは[`$CI_ENVIRONMENT_SLUG`](../../ci/variables/_index.md#predefined-cicd-variables)の値です。カスタムデータベース名を使用するように設定します。 |
| `POSTGRES_VERSION`                      | 使用する[`postgres` Dockerイメージ](https://hub.docker.com/_/postgres)のタグ。テストとデプロイメントの場合、デフォルトは`9.6.16`です。`AUTO_DEVOPS_POSTGRES_CHANNEL`が`1`に設定されている場合、デプロイメントはデフォルトバージョン`9.6.2`を使用します。 |
| `POSTGRES_HELM_UPGRADE_VALUES_FILE`     | [auto-deploy-image v2](upgrading_auto_deploy_dependencies.md)を使用する場合、この変数を使用すると、PostgreSQLの`helm upgrade`値ファイルをオーバーライドできます。`.gitlab/auto-deploy-postgres-values.yaml`がデフォルトです。 |
| `POSTGRES_HELM_UPGRADE_EXTRA_ARGS`      | [auto-deploy-image v2](upgrading_auto_deploy_dependencies.md)を使用する場合、この変数を使用すると、アプリケーションのデプロイ時に`helm upgrade`コマンドで追加のPostgreSQLオプションを使用できます。引用符を使用しても、ワード分割は防止されません。 |
| `POSTGRES_CHART_REPOSITORY`             | PostgreSQLチャートの検索に使用されるHelmチャートリポジトリ。`https://raw.githubusercontent.com/bitnami/charts/eb5f9a9513d987b519f0ecd732e7031241c50328/bitnami`がデフォルトです。 |
| `POSTGRES_CHART_VERSION`                | PostgreSQLチャートに使用されるHelmチャートバージョン。`8.2.1`がデフォルトです。 |

## ジョブスキップ変数 {#job-skipping-variables}

 これらの変数を使用して、特定のタイプのCI/CDジョブをスキップします。スキップすると、CI/CDジョブは作成または実行されません。

| **ジョブ名**                           | **CI/CD variable**（CI/CD変数）              | **GitLabバージョン**    | **説明** |
|----------------------------------------|---------------------------------|-----------------------|-----------------|
| `.fuzz_base`                           | `COVFUZZ_DISABLED`              |                       | `.fuzz_base`が独自のジョブの機能を提供する方法の詳細については、[こちらをお読みください](../../user/application_security/coverage_fuzzing/_index.md)。値が`"true"`の場合、ジョブは作成されません。 |
| `apifuzzer_fuzz`                       | `API_FUZZING_DISABLED`          |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `build`                                | `BUILD_DISABLED`                |                       | 変数が存在する場合、ジョブは作成されません。 |
| `build_artifact`                       | `BUILD_DISABLED`                |                       | 変数が存在する場合、ジョブは作成されません。 |
| `brakeman-sast`                        | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `canary`                               | `CANARY_ENABLED`                |                       | この手動ジョブは、変数が存在する場合に作成されます。 |
| `code_intelligence`                    | `CODE_INTELLIGENCE_DISABLED`    |                       | 変数が存在する場合、ジョブは作成されません。 |
| `code_quality`                         | `CODE_QUALITY_DISABLED`         |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `container_scanning`                   | `CONTAINER_SCANNING_DISABLED`   |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `dast`                                 | `DAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `dast_environment_deploy`              | `DAST_DISABLED_FOR_DEFAULT_BRANCH`または`DAST_DISABLED`  |                        | 値が`"true"`の場合、ジョブは作成されません。 |
| `dependency_scanning`                  | `DEPENDENCY_SCANNING_DISABLED`  |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `flawfinder-sast`                      | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `gemnasium-dependency_scanning`        | `DEPENDENCY_SCANNING_DISABLED`  |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `gemnasium-maven-dependency_scanning`  | `DEPENDENCY_SCANNING_DISABLED`  |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `gemnasium-python-dependency_scanning` | `DEPENDENCY_SCANNING_DISABLED`  |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `kubesec-sast`                         | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `license_management`                   | `LICENSE_MANAGEMENT_DISABLED`   | GitLab 12.7以前 | 変数が存在する場合、ジョブは作成されません。[GitLab 12.8からの](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22773)ジョブは非推奨です |
| `license_scanning`                     | `LICENSE_MANAGEMENT_DISABLED`   |                       | 値が`"true"`の場合、ジョブは作成されません。[GitLab 15.9からの](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111071)ジョブは非推奨です |
| `load_performance`                     | `LOAD_PERFORMANCE_DISABLED`     |                       | 変数が存在する場合、ジョブは作成されません。 |
| `nodejs-scan-sast`                     | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `performance`                          | `PERFORMANCE_DISABLED`          | GitLab 13.12以前 | ブラウザのパフォーマンス。変数が存在する場合、ジョブは作成されません。`browser_performance`に置き換えられました。 |
| `browser_performance`                  | `BROWSER_PERFORMANCE_DISABLED`  |                       | ブラウザのパフォーマンス。変数が存在する場合、ジョブは作成されません。`performance`を置き換えます。 |
| `phpcs-security-audit-sast`            | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `pmd-apex-sast`                        | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `review`                               | `REVIEW_DISABLED`               |                       | 変数が存在する場合、ジョブは作成されません。 |
| `review:stop`                          | `REVIEW_DISABLED`               |                       | 手動ジョブ。変数が存在する場合、ジョブは作成されません。 |
| `secret_detection`                     | `SECRET_DETECTION_DISABLED`     |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `secret_detection_default_branch`      | `SECRET_DETECTION_DISABLED`     |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `semgrep-sast`                         | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `sobelow-sast`                         | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `stop_dast_environment`                | `DAST_DISABLED_FOR_DEFAULT_BRANCH`または`DAST_DISABLED` |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `spotbugs-sast`                        | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `test`                                 | `TEST_DISABLED`                 |                       | 変数が存在する場合、ジョブは作成されません。 |
| `staging`                              | `STAGING_ENABLED`               |                       | 変数が存在する場合、ジョブが作成されます。 |
| `stop_review`                          | `REVIEW_DISABLED`               |                       | 変数が存在する場合、ジョブは作成されません。 |

## アプリケーションシークレット変数を設定する {#configure-application-secret-variables}

一部のデプロイされたアプリケーションでは、シークレット変数へのアクセスが必要です。Auto DevOpsは`K8S_SECRET_`で始まるCI/CD変数を検出し、環境変数としてデプロイされたアプリケーションで利用できるようにします。

前提要件: 

- 変数の値は1行である必要があります。

シークレット変数を設定するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. プレフィックス`K8S_SECRET_`を持つCI/CD変数を作成します。たとえば、`K8S_SECRET_RAILS_MASTER_KEY`という変数を作成できます。
1. 新しいパイプラインを手動で作成するか、コード変更をGitLabにプッシュして、Auto DevOpsパイプラインを実行します。

### Kubernetesシークレット {#kubernetes-secrets}

Auto DevOpsパイプラインは、アプリケーションのシークレット変数を使用して、Kubernetesシークレットに入力された状態にします。このシークレットは環境ごとに一意です。アプリケーションのデプロイ時、シークレットは、アプリケーションを実行しているコンテナ内の環境変数として読み込まれます。例えば、`K8S_SECRET_RAILS_MASTER_KEY`という名前のシークレットを作成した場合、Kubernetesのシークレットは次のようになります:

```shell
$ kubectl get secret production-secret -n minimal-ruby-app-54 -o yaml

apiVersion: v1
data:
  RAILS_MASTER_KEY: MTIzNC10ZXN0
kind: Secret
metadata:
  creationTimestamp: 2018-12-20T01:48:26Z
  name: production-secret
  namespace: minimal-ruby-app-54
  resourceVersion: "429422"
  selfLink: /api/v1/namespaces/minimal-ruby-app-54/secrets/production-secret
  uid: 57ac2bfd-03f9-11e9-b812-42010a9400e4
type: Opaque
```

## アプリケーションシークレットの更新 {#update-application-secrets}

環境変数は通常、Kubernetesのポッド内でイミュータブルです。アプリケーションシークレットを更新し、手動で新しいパイプラインを作成した場合、実行中のアプリケーションは更新されたシークレットを受け取りません。

アプリケーションシークレットを更新するには、次のいずれかの方法を実行します:

- GitLabにプッシュしてコードを更新し、Kubernetesのデプロイにポッドを再作成させます。
- シークレットが更新された新しいポッドをKubernetesに作成させるために、実行中のポッドを手動で削除します。

複数行の値を持つ変数は、Auto DevOpsのスクリプト環境の制限によりサポートされていません。

## レプリカ変数の設定 {#configure-replica-variables}

デプロイをスケールする場合は、レプリカ変数を追加します:

1. [プロジェクトCI/CD変数](../../ci/variables/_index.md#for-a-project)としてレプリカ変数を追加します。
1. アプリケーションをスケールするには、再デプロイします。

   {{< alert type="warning" >}}

   Kubernetesを直接使用してアプリケーションをスケールしないでください。Helmが変更を検出せず、後続のAuto DevOpsでのデプロイで変更が元に戻る可能性があります。

   {{< /alert >}}

### カスタムレプリカ変数 {#custom-replica-variables}

`<TRACK>_<ENV>_REPLICAS`の形式で、カスタムレプリカ変数を作成できます:

- `<TRACK>`は、Helmチャートアプリケーション定義で設定された`track` [Kubernetesラベル](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)の大文字の値です。`track`が設定されていない場合は、カスタム変数から`<TRACK>`を省略してください。
- `<ENV>`は、`.gitlab-ci.yml`で設定されたデプロイジョブのすべて大文字の環境名です。

たとえば、環境が`qa`で、トラックが`foo`の場合、`FOO_QA_REPLICAS`という環境変数を作成します:

```yaml
QA testing:
  stage: deploy
  environment:
    name: qa
  script:
    - deploy foo
```

トラック`foo`は、アプリケーションのHelmチャートで定義されている必要があります。次に例を示します: 

```yaml
replicaCount: 1
image:
  repository: gitlab.example.com/group/project
  tag: stable
  pullPolicy: Always
  secrets:
    - name: gitlab-registry
application:
  track: foo
  tier: web
service:
  enabled: true
  name: web
  type: ClusterIP
  url: http://my.host.com/
  externalPort: 5000
  internalPort: 5000
```

## ステージング環境と本番環境のデプロイポリシー {#deploy-policy-for-staging-and-production-environments}

Auto DevOpsは通常、継続的デプロイを使用し、デフォルトブランチで新しいパイプラインが実行されるたびに、`production`本番環境に自動的にプッシュします。本番環境に手動でデプロイするには、`STAGING_ENABLED`CI/CD変数を使用できます。

`STAGING_ENABLED`を設定すると、GitLabはアプリケーションを`staging`ステージング環境に自動的にデプロイします。本番環境にデプロイする準備ができたら、GitLabは`production_manual`ジョブを作成します。

[プロジェクト設定](requirements.md#auto-devops-deployment-strategy)で手動デプロイを有効にすることもできます。

## カナリア環境のデプロイポリシー {#deploy-policy-for-canary-environments}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

本番環境に変更をデプロイする前に、[カナリア環境](../../user/project/canary_deployments.md)を使用できます。

`CANARY_ENABLED`を設定すると、GitLabは2つの[手動ジョブ](../../ci/pipelines/_index.md#add-manual-interaction-to-your-pipeline)を作成します:

- `canary` - アプリケーションをカナリア環境にデプロイします。
- `production_manual` - アプリケーションを本番環境にデプロイします。

## 本番環境への段階的ロールアウト {#incremental-rollout-to-production}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

段階的ロールアウトを使用して、少数のポッドから始めて、アプリケーションを継続的にデプロイします。ポッドの数は手動で増やすことができます。

[プロジェクト設定](requirements.md#auto-devops-deployment-strategy)で手動デプロイを有効にするか、`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定します。

`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定すると、GitLabは4つの手動ジョブを作成します:

1. `rollout 10%`
1. `rollout 25%`
1. `rollout 50%`
1. `rollout 100%`

パーセンテージは`REPLICAS`CI/CD変数に基づいており、デプロイに使用されるポッドの数を定義します。たとえば、値が`10`で、`10%`ロールアウトジョブを実行すると、アプリケーションは1つのポッドにのみデプロイされます。

ロールアウトジョブは任意の順序で実行できます。スケールダウンするには、より低いパーセンテージのジョブを再実行します。

`rollout 100%`ジョブを実行した後、スケールダウンできず、[デプロイをロールバックする](../../ci/environments/deployments.md#retry-or-roll-back-a-deployment)必要があります。

### 段階的ロールアウト構成の例 {#example-incremental-rollout-configurations}

`INCREMENTAL_ROLLOUT_MODE`なし、`STAGING_ENABLED`なし:

![段階的ロールアウトとステージングの両方が無効になっているCI/CDワークフローの可視化グラフ](img/rollout_staging_disabled_v11_0.png)

`INCREMENTAL_ROLLOUT_MODE`なし、`STAGING_ENABLED`あり:

![段階的ロールアウトが無効でステージングが有効になっているCI/CDワークフローの可視化グラフ](img/staging_enabled_v11_0.png)

`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定し、`STAGING_ENABLED`がない場合:

![段階的ロールアウトが有効でステージングが無効になっているCI/CDワークフローの可視化グラフ](img/rollout_enabled_v10_8.png)

`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定し、`STAGING_ENABLED`がある場合:

![段階的ロールアウトとステージングの両方が有効になっているCI/CDワークフローの可視化グラフ](img/rollout_staging_enabled_v11_0.png)

## 本番環境への時間指定段階的ロールアウト {#timed-incremental-rollout-to-production}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

時間指定段階的ロールアウトを使用して、少数のポッドから始めて、アプリケーションを継続的にデプロイします。

[プロジェクト設定](requirements.md#auto-devops-deployment-strategy)で時間指定段階的デプロイを有効にするか、`INCREMENTAL_ROLLOUT_MODE`CI/CD変数を`timed`に設定します。

`INCREMENTAL_ROLLOUT_MODE`を`timed`に設定すると、GitLabは4つのジョブを作成します:

1. `timed rollout 10%`
1. `timed rollout 25%`
1. `timed rollout 50%`
1. `timed rollout 100%`

ジョブの間には5分間の遅延があります。
