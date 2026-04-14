---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD変数
---

CI/CD変数を使用して、Auto DevOpsドメインを設定したり、カスタムHelmチャートを提供したり、アプリケーションをスケールすることができます。

## ビルドおよびデプロイメント変数 {#build-and-deployment-variables}

これらの変数を使用して、ビルドをカスタマイズしてデプロイします。

| **CI/CD変数**                      | **説明** |
|-----------------------------------------|-----------------|
| `ADDITIONAL_HOSTS`                      | カンマ区切りのリストとして指定され、Ingressホストに追加される完全修飾ドメイン名。 |
| `<ENVIRONMENT>_ADDITIONAL_HOSTS`        | 特定の環境の場合、カンマ区切りのリストとして指定され、Ingressホストに追加される完全修飾ドメイン名。これは、`ADDITIONAL_HOSTS`よりも優先されます。 |
| `AUTO_BUILD_IMAGE_VERSION`              | `build`ジョブに使用されるイメージバージョンをカスタマイズします。[バージョンのリスト](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/releases)を参照してください。 |
| `AUTO_DEPLOY_IMAGE_VERSION`             | Kubernetesデプロイメントジョブに使用されるイメージバージョンをカスタマイズします。[バージョンのリスト](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/releases)を参照してください。 |
| `AUTO_DEVOPS_ATOMIC_RELEASE`            | Auto DevOpsは、Helmデプロイにデフォルトで[`--atomic`](https://v2.helm.sh/docs/helm/#options-43)を使用します。この変数を`false`に設定すると、`--atomic`の使用が無効になります。 |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`   | Cloud Native Buildpacksでビルドする際に使用されるビルダー。デフォルトのビルダーは`heroku/buildpacks:22`です。[詳細](stages.md#auto-build-using-cloud-native-buildpacks)。 |
| `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`    | `docker build`コマンドに渡す追加の引数。クォーテーションを使用しても単語の分割は防止されません。[詳細](customize.md#pass-arguments-to-docker-build)。 |
| `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` | ビルド環境（buildpackビルダーまたは`docker build`）に転送される[カンマ区切りのCI/CD変数名](customize.md#forward-cicd-variables-to-the-build-environment)。 |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_PORT`      | GitLab 15.0以降で、生成されたDockerイメージによって公開されるポート。`false`に設定すると、ポートの公開が防止されます。`5000`がデフォルトです。 |
| `AUTO_DEVOPS_BUILD_IMAGE_CONTEXT`       | DockerfileとCloud Native Buildpacksのビルドコンテキストディレクトリを設定するために使用されます。ルートディレクトリにデフォルト設定されます。 |
| `AUTO_DEVOPS_CHART`                     | アプリケーションをデプロイするために使用されるHelm Chart。GitLabによって[提供される](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)ものにデフォルト設定されます。 |
| `AUTO_DEVOPS_CHART_REPOSITORY`          | チャートを検索するために使用されるHelm Chartリポジトリ。`https://charts.gitlab.io`がデフォルトです。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_NAME`     | Helmリポジトリの名前を設定するために使用されます。`gitlab`がデフォルトです。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME` | Helmリポジトリに接続するためのユーザー名を設定するために使用されます。認証情報なしにデフォルト設定されます。`AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD`も設定してください。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD` | Helmリポジトリに接続するためのパスワードを設定するために使用されます。認証情報なしにデフォルト設定されます。`AUTO_DEVOPS_CHART_REPOSITORY_USERNAME`も設定してください。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASS_CREDENTIALS` | 空でない値に設定すると、チャートアーティファクトがリポジトリとは異なるホスト上にある場合に、Helmリポジトリの認証情報をチャートサーバーに転送できるようになります。 |
| `AUTO_DEVOPS_CHART_REPOSITORY_INSECURE` | 空でない値に設定すると、Helmコマンドに`--insecure-skip-tls-verify`引数が追加されます。デフォルトでは、HelmはTLS検証を使用します。 |
| `AUTO_DEVOPS_CHART_CUSTOM_ONLY`         | 空でない値に設定すると、カスタムチャートのみを使用するようになります。デフォルトでは、最新のチャートがGitLabからダウンロードされます。 |
| `AUTO_DEVOPS_CHART_VERSION`             | デプロイチャートのバージョンを設定します。利用可能な最新バージョンにデフォルト設定されます。 |
| `AUTO_DEVOPS_COMMON_NAME`               | GitLab 15.5以降、TLS証明書に使用される共通名をカスタマイズするために、有効なドメイン名を設定します。`le-$CI_PROJECT_ID.$KUBE_INGRESS_BASE_DOMAIN`がデフォルトです。`false`に設定すると、Ingressにこの代替ホストが設定されません。 |
| `AUTO_DEVOPS_DEPLOY_DEBUG`              | この変数が存在する場合、Helmはデバッグログを出力します。 |
| `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V<N>` | [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) v1.0.0以降、この変数が存在する場合、チャートの新しいメジャーバージョンが強制的にデプロイされます。詳細については、[警告を無視してデプロイを続行する](upgrading_auto_deploy_dependencies.md#ignore-warnings-and-continue-deploying)を参照してください。 |
| `BUILDPACK_URL`                         | 完全なBuildpack URL。[PackがサポートするURL](customize.md#custom-buildpacks)を指している必要があります。 |
| `CANARY_ENABLED`                        | カナリア環境の[デプロイポリシー](#deploy-policy-for-canary-environments)を定義するために使用されます。 |
| `BUILDPACK_VOLUMES`                     | 1つ以上の[Buildpackボリュームをマウントする](stages.md#mount-volumes-into-the-build-container)ように指定します。パイプ`\|`をリスト区切り文字として使用します。 |
| `CANARY_PRODUCTION_REPLICAS`            | 本番環境で[カナリアデプロイ](../../user/project/canary_deployments.md)のためにデプロイするカナリアレプリカの数。これは`CANARY_REPLICAS`よりも優先されます。デフォルトは1です。 |
| `CANARY_REPLICAS`                       | [カナリアデプロイ](../../user/project/canary_deployments.md)のためにデプロイするカナリアレプリカの数。デフォルトは1です。 |
| `CI_APPLICATION_REPOSITORY`             | ビルドまたはデプロイされるコンテナイメージのリポジトリ。`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`詳細については、[カスタムコンテナイメージ](customize.md#custom-container-image)を参照してください。 |
| `CI_APPLICATION_TAG`                    | ビルドまたはデプロイされるコンテナイメージのタグ。`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`詳細については、[カスタムコンテナイメージ](customize.md#custom-container-image)を参照してください。 |
| `DAST_AUTO_DEPLOY_IMAGE_VERSION`        | デフォルトブランチ上のDASTデプロイに使用されるイメージバージョンをカスタマイズします。通常、`AUTO_DEPLOY_IMAGE_VERSION`と同じである必要があります。[バージョンのリスト](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/releases)を参照してください。 |
| `DOCKERFILE_PATH`                       | [デフォルトDockerfileのビルドステージ](customize.md#custom-dockerfiles)パスをオーバーライドできます。 |
| `HELM_RELEASE_NAME`                     | `helm`リリース名をオーバーライドできます。複数のプロジェクトを単一のネームスペースにデプロイする際に、一意のリリース名を割り当てるために使用できます。 |
| `HELM_UPGRADE_VALUES_FILE`              | `helm upgrade`値ファイルをオーバーライドできます。`.gitlab/auto-deploy-values.yaml`がデフォルトです。 |
| `HELM_UPGRADE_EXTRA_ARGS`               | アプリケーションをデプロイする際に、`helm upgrade`コマンドで追加オプションを使用できます。クォーテーションを使用しても単語の分割は防止されません。 |
| `INCREMENTAL_ROLLOUT_MODE`              | 存在する場合、本番環境のアプリケーションの[インクリメンタルロールアウト](#incremental-rollout-to-production)を有効にするために使用できます。手動デプロイメントジョブの場合は`manual`に、自動ロールアウトデプロイ（それぞれ5分間の遅延あり）の場合は`timed`に設定します。 |
| `K8S_SECRET_*`                          | [`K8S_SECRET_`](#configure-application-secret-variables)でプレフィックスされたすべての変数は、Auto DevOpsによってデプロイされたアプリケーションに環境変数として利用可能になります。 |
| `KUBE_CONTEXT`                          | `KUBECONFIG`から使用するコンテキストを選択するために使用できます。`KUBE_CONTEXT`が空白の場合、`KUBECONFIG`のデフォルトコンテキスト（存在する場合）が使用されます。[Kubernetes用エージェントと連携して](../../user/clusters/agent/ci_cd_workflow.md)使用する場合は、コンテキストを選択する必要があります。 |
| `KUBE_INGRESS_BASE_DOMAIN`              | クラスターごとにドメインを設定するために使用できます。詳細については、[クラスタードメイン](../../user/project/clusters/gitlab_managed_clusters.md#base-domain)を参照してください。 |
| `KUBE_NAMESPACE`                        | デプロイに使用されるネームスペース。証明書ベースのクラスターを使用する場合、[この値を直接上書きしないでください](../../user/project/clusters/deploy_to_cluster.md#custom-namespace)。 |
| `KUBECONFIG`                            | デプロイに使用するkubeconfig。ユーザーが提供する値は、GitLabが提供する値よりも優先されます。 |
| `PRODUCTION_REPLICAS`                   | 本番環境にデプロイするレプリカの数。`REPLICAS`よりも優先され、デフォルトで1になります。ゼロダウンタイムアップグレードの場合、2以上に設定します。 |
| `REPLICAS`                              | デプロイするレプリカの数。デフォルトは1です。[変更](customize.md#customize-helm-chart-values)する代わりに、この変数を`replicaCount`してください。 |
| `ROLLOUT_RESOURCE_TYPE`                 | カスタムHelmチャートを使用する場合にデプロイされるリソースタイプの仕様を許可します。デフォルト値は`deployment`です。 |
| `ROLLOUT_STATUS_DISABLED`               | ロールアウトステータスチェックを無効にするために使用されます。これは、すべてのリソースタイプ（例: `cronjob`）をサポートしていないためです。 |
| `STAGING_ENABLED`                       | ステージングおよび本番環境の[デプロイポリシー](#deploy-policy-for-staging-and-production-environments)を定義するために使用されます。 |
| `TRACE`                                 | Helmコマンドが詳細な出力を生成するように、任意の値に設定します。この設定を使用して、Auto DevOpsデプロイの問題を診断できます。 |

## データベース変数 {#database-variables}

> [!warning]
> [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/343988)以降、`POSTGRES_ENABLED`はデフォルトで設定されなくなりました。

これらの変数を使用して、CI/CDをPostgreSQLデータベースと統合します。

| **CI/CD変数**                            | **説明**                    |
|-----------------------------------------|------------------------------------|
| `DB_INITIALIZE`                         | アプリケーションのPostgreSQLデータベースを初期化するために実行するコマンドを指定するために使用されます。アプリケーションポッド内で実行されます。 |
| `DB_MIGRATE`                            | アプリケーションのPostgreSQLデータベースを移行するために実行するコマンドを指定するために使用されます。アプリケーションポッド内で実行されます。 |
| `POSTGRES_ENABLED`                      | PostgreSQLが有効になっているかどうか。`true`に設定すると、PostgreSQLの自動デプロイが有効になります。 |
| `POSTGRES_USER`                         | PostgreSQLユーザー。`user`がデフォルトです。カスタムユーザー名を使用するように設定します。 |
| `POSTGRES_PASSWORD`                     | PostgreSQLパスワード。`testing-password`がデフォルトです。カスタムパスワードを使用するように設定します。 |
| `POSTGRES_DB`                           | PostgreSQLデータベース名。[`$CI_ENVIRONMENT_SLUG`](../../ci/variables/_index.md#predefined-cicd-variables)の値にデフォルト設定されます。カスタムデータベース名を使用するように設定します。 |
| `POSTGRES_VERSION`                      | 使用する[`postgres` Dockerイメージ](https://hub.docker.com/_/postgres)のタグ。テストとデプロイのために`9.6.16`にデフォルト設定されます。`AUTO_DEVOPS_POSTGRES_CHANNEL`が`1`に設定されている場合、デプロイはデフォルトバージョン`9.6.2`を使用します。 |
| `POSTGRES_HELM_UPGRADE_VALUES_FILE`     | [auto-deploy-image v2](upgrading_auto_deploy_dependencies.md)を使用する場合、この変数を使用すると、PostgreSQLの`helm upgrade`値ファイルをオーバーライドできます。`.gitlab/auto-deploy-postgres-values.yaml`がデフォルトです。 |
| `POSTGRES_HELM_UPGRADE_EXTRA_ARGS`      | [auto-deploy-image v2](upgrading_auto_deploy_dependencies.md)を使用する場合、この変数を使用すると、アプリケーションをデプロイする際に`helm upgrade`コマンドで追加のPostgreSQLオプションを使用できます。クォーテーションを使用しても単語の分割は防止されません。 |
| `POSTGRES_CHART_REPOSITORY`             | PostgreSQLチャートを検索するために使用されるHelm Chartリポジトリ。`https://raw.githubusercontent.com/bitnami/charts/eb5f9a9513d987b519f0ecd732e7031241c50328/bitnami`がデフォルトです。 |
| `POSTGRES_CHART_VERSION`                | PostgreSQLチャートに使用されるHelm Chartバージョン。`8.2.1`がデフォルトです。 |

## ジョブスキップ変数 {#job-skipping-variables}

 これらの変数を使用して、特定の種類のCI/CDジョブをスキップします。スキップされた場合、CI/CDジョブは作成または実行されません。

| **ジョブ名**                           | **CI/CD変数**              | **GitLabのバージョン**    | **説明** |
|----------------------------------------|---------------------------------|-----------------------|-----------------|
| `.fuzz_base`                           | `COVFUZZ_DISABLED`              |                       | `.fuzz_base`が独自のジョブに機能を提供する方法について[詳しく読む](../../user/application_security/coverage_fuzzing/_index.md)。値が`"true"`の場合、ジョブは作成されません。 |
| `apifuzzer_fuzz`                       | `API_FUZZING_DISABLED`          |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `build`                                | `BUILD_DISABLED`                |                       | この変数が存在する場合、ジョブは作成されません。 |
| `build_artifact`                       | `BUILD_DISABLED`                |                       | この変数が存在する場合、ジョブは作成されません。 |
| `brakeman-sast`                        | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `canary`                               | `CANARY_ENABLED`                |                       | この変数が存在する場合、この手動ジョブが作成されます。 |
| `code_intelligence`                    | `CODE_INTELLIGENCE_DISABLED`    |                       | この変数が存在する場合、ジョブは作成されません。 |
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
| `license_management`                   | `LICENSE_MANAGEMENT_DISABLED`   | GitLab 12.7以前 | この変数が存在する場合、ジョブは作成されません。ジョブは[GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22773)から非推奨になりました。 |
| `license_scanning`                     | `LICENSE_MANAGEMENT_DISABLED`   |                       | 値が`"true"`の場合、ジョブは作成されません。ジョブは[GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111071)から非推奨になりました。 |
| `load_performance`                     | `LOAD_PERFORMANCE_DISABLED`     |                       | この変数が存在する場合、ジョブは作成されません。 |
| `nodejs-scan-sast`                     | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `performance`                          | `PERFORMANCE_DISABLED`          | GitLab 13.12以前 | ブラウザのパフォーマンス。この変数が存在する場合、ジョブは作成されません。`browser_performance`に置き換えられました。 |
| `browser_performance`                  | `BROWSER_PERFORMANCE_DISABLED`  |                       | ブラウザのパフォーマンス。この変数が存在する場合、ジョブは作成されません。`performance`を置き換えます。 |
| `phpcs-security-audit-sast`            | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `pmd-apex-sast`                        | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `review`                               | `REVIEW_DISABLED`               |                       | この変数が存在する場合、ジョブは作成されません。 |
| `review:stop`                          | `REVIEW_DISABLED`               |                       | 手動ジョブ。この変数が存在する場合、ジョブは作成されません。 |
| `secret_detection`                     | `SECRET_DETECTION_DISABLED`     |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `secret_detection_default_branch`      | `SECRET_DETECTION_DISABLED`     |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `semgrep-sast`                         | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `sobelow-sast`                         | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `stop_dast_environment`                | `DAST_DISABLED_FOR_DEFAULT_BRANCH`または`DAST_DISABLED` |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `spotbugs-sast`                        | `SAST_DISABLED`                 |                       | 値が`"true"`の場合、ジョブは作成されません。 |
| `test`                                 | `TEST_DISABLED`                 |                       | この変数が存在する場合、ジョブは作成されません。 |
| `staging`                              | `STAGING_ENABLED`               |                       | この変数が存在する場合、ジョブが作成されます。 |
| `stop_review`                          | `REVIEW_DISABLED`               |                       | この変数が存在する場合、ジョブは作成されません。 |

## アプリケーションシークレット変数の設定 {#configure-application-secret-variables}

一部のデプロイされたアプリケーションでは、シークレット変数へのアクセスが必要です。Auto DevOpsは`K8S_SECRET_`で始まるCI/CD変数を検出し、デプロイされたアプリケーションに環境変数として利用可能にします。

前提条件: 

- 変数の値は単一行である必要があります。

シークレット変数を設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. `K8S_SECRET_`のプレフィックスを持つCI/CD変数を作成します。たとえば、`K8S_SECRET_RAILS_MASTER_KEY`という変数を作成できます。
1. 新しいパイプラインを手動で作成するか、codeコードの変更をGitLabにプッシュすることによって、Auto DevOpsパイプラインを実行します。

### Kubernetes Secrets {#kubernetes-secrets}

Auto DevOpsパイプラインは、アプリケーションのシークレット変数を使用してKubernetesシークレットを設定します。このシークレットは環境ごとに一意です。アプリケーションをデプロイする際、シークレットはアプリケーションを実行しているコンテナに環境変数として読み込まれます。たとえば、`K8S_SECRET_RAILS_MASTER_KEY`というシークレットを作成した場合、Kubernetesシークレットは次のようになります:

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

## アプリケーションシークレットを更新する {#update-application-secrets}

環境変数は通常、Kubernetesポッド内ではイミュータブルです。アプリケーションシークレットを更新し、新しいパイプラインを手動で作成した場合、実行中のアプリケーションは更新されたシークレットを受け取りません。

アプリケーションシークレットを更新するには、次のいずれかを実行します:

- codeコードの更新をGitLabにプッシュすることで、Kubernetesデプロイを強制的にポッドを再作成させます。
- 実行中のポッドを手動で削除して、Kubernetesに更新されたシークレットを持つ新しいポッドを作成させます。

複数行の値を持つ変数は、Auto DevOpsスクリプティング環境の制限によりサポートされていません。

## レプリカ変数の設定 {#configure-replica-variables}

デプロイをスケールする場合は、レプリカ変数を追加します:

1. [プロジェクトCI/CD変数](../../ci/variables/_index.md#for-a-project)としてレプリカ変数を追加します。
1. アプリケーションをスケールするには、再デプロイします。

   > [!warning]
   > Kubernetesを直接使用してアプリケーションをスケールすることは避けてください。Helmが変更を検出しない可能性があり、その後のAuto DevOpsによるデプロイで変更が元に戻される可能性があります。

### カスタムレプリカ変数 {#custom-replica-variables}

`<TRACK>_<ENV>_REPLICAS`の形式でカスタムレプリカ変数を作成できます:

- `<TRACK>`は、Helm Chartアプリケーション定義で設定された`track` [Kubernetesラベル](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)の大文字の値です。`track`が設定されていない場合、カスタム変数から`<TRACK>`を省略します。
- `<ENV>`は、`.gitlab-ci.yml`で設定されたデプロイジョブのすべて大文字の環境名です。

たとえば、環境が`qa`でトラックが`foo`の場合、`FOO_QA_REPLICAS`という環境変数を作成します:

```yaml
QA testing:
  stage: deploy
  environment:
    name: qa
  script:
    - deploy foo
```

トラック`foo`は、アプリケーションのHelmチャートで定義されている必要があります。例: 

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

## ステージングおよび本番環境のデプロイポリシー {#deploy-policy-for-staging-and-production-environments}

Auto DevOpsは通常、継続的デプロイを使用し、新しいパイプラインがデフォルトブランチで実行されるたびに自動的に`production`環境にプッシュする。手動で本番環境にデプロイするには、`STAGING_ENABLED` CI/CD変数を使用できます。

`STAGING_ENABLED`を設定すると、GitLabは自動的にアプリケーションを`staging`環境にデプロイします。本番環境にデプロイする準備ができたら、GitLabは`production_manual`ジョブを作成します。

また、[プロジェクト設定](requirements.md#auto-devops-deployment-strategy)で手動デプロイを有効にすることもできます。

## カナリア環境のデプロイポリシー {#deploy-policy-for-canary-environments}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

本番環境に変更をデプロイする前に、[カナリア環境](../../user/project/canary_deployments.md)を使用できます。

`CANARY_ENABLED`を設定すると、GitLabは2つの[手動ジョブ](../../ci/pipelines/_index.md#add-manual-interaction-to-your-pipeline)を作成します:

- `canary` - アプリケーションをカナリア環境にデプロイします。
- `production_manual` - アプリケーションを本番環境にデプロイします。

## 本番環境へのインクリメンタルロールアウト {#incremental-rollout-to-production}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インクリメンタルロールアウトを使用して、少数のポッドから開始してアプリケーションを継続的にデプロイします。手動でポッドの数を増やすことができます。

[プロジェクト設定](requirements.md#auto-devops-deployment-strategy)で手動デプロイを有効にするか、`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定することで有効にできます。

`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定すると、GitLabは4つの手動ジョブを作成します:

1. `rollout 10%`
1. `rollout 25%`
1. `rollout 50%`
1. `rollout 100%`

このパーセンテージは`REPLICAS` CI/CD変数に基づいており、デプロイに使用されるポッドの数を定義します。たとえば、値が`10`で、`10%`ロールアウトジョブを実行すると、アプリケーションは1つのポッドのみにデプロイされます。

ロールアウトジョブは任意の順序で実行できます。スケールダウンするには、より低いパーセンテージのジョブを再実行します。

`rollout 100%`ジョブを実行した後、スケールダウンすることはできず、[デプロイをロールバック](../../ci/environments/deployments.md#retry-or-roll-back-a-deployment)する必要があります。

### インクリメンタルロールアウトの設定例 {#example-incremental-rollout-configurations}

`INCREMENTAL_ROLLOUT_MODE`なし、および`STAGING_ENABLED`なし:

![インクリメンタルロールアウトとステージングの両方が無効化されたCI/CDワークフローの可視化グラフ](img/rollout_staging_disabled_v11_0.png)

`INCREMENTAL_ROLLOUT_MODE`なし、`STAGING_ENABLED`あり:

![インクリメンタルロールアウトが無効化され、ステージングが有効化されたCI/CDワークフローの可視化グラフ](img/staging_enabled_v11_0.png)

`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定し、`STAGING_ENABLED`なし:

![インクリメンタルロールアウトが有効化され、ステージングが無効化されたCI/CDワークフローの可視化グラフ](img/rollout_enabled_v10_8.png)

`INCREMENTAL_ROLLOUT_MODE`を`manual`に設定し、`STAGING_ENABLED`あり:

![インクリメンタルロールアウトとステージングの両方が有効化されたCI/CDワークフローの可視化グラフ](img/rollout_staging_enabled_v11_0.png)

## 本番環境への時間指定インクリメンタルロールアウト {#timed-incremental-rollout-to-production}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

時間指定インクリメンタルロールアウトを使用して、少数のポッドから開始してアプリケーションを継続的にデプロイします。

[プロジェクト設定](requirements.md#auto-devops-deployment-strategy)で時間指定インクリメンタルデプロイを有効にするか、`INCREMENTAL_ROLLOUT_MODE` CI/CD変数を`timed`に設定することで有効にできます。

`INCREMENTAL_ROLLOUT_MODE`を`timed`に設定すると、GitLabは4つのジョブを作成します:

1. `timed rollout 10%`
1. `timed rollout 25%`
1. `timed rollout 50%`
1. `timed rollout 100%`

ジョブ間に5分間の遅延があります。
