---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 自動DevOpsを使用して、アプリケーションをAmazon Elastic Kubernetes Service（EKS）にデプロイする
---

このチュートリアルでは、アプリケーションをAmazon Elastic Kubernetes Service（EKS）にデプロイする方法の例を通して、[Auto DevOps](../_index.md)の開始方法を説明します。

このチュートリアルでは、GitLabネイティブのKubernetesインテグレーションを使用しているため、AWSコンソールを使用してKubernetesクラスタリングを手動で作成する必要はありません。

このチュートリアルは、GitLab Self-Managedインスタンスでも実行できます。独自の[Runnerが構成されていることを確認](../../../ci/runners/_index.md)してください。

プロジェクトをEKSにデプロイするには:

1. [Amazonアカウントを構成する](#configure-your-amazon-account)
1. [Kubernetesクラスタリングを作成してエージェントをデプロイする](#create-a-kubernetes-cluster)
1. [テンプレートから新しいプロジェクトを作成する](#create-an-application-project-from-a-template)
1. [エージェントを設定する](#configure-the-agent)
1. [Ingressをインストールする](#install-ingress)
1. [Auto DevOpsを設定する](#configure-auto-devops)
1. [Auto DevOpsを有効にしてパイプラインを実行する](#enable-auto-devops-and-run-the-pipeline)
1. [アプリケーションをデプロイする](#deploy-the-application)

## Amazonアカウントを構成する {#configure-your-amazon-account}

KubernetesクラスタリングをGitLabプロジェクトに作成して接続する前に、[Amazon Web Servicesアカウント](https://aws.amazon.com/)が必要です。既存のAmazonアカウントでサインインするか、新しいアカウントを作成してください。

## Kubernetesクラスタリングを作成する {#create-a-kubernetes-cluster}

Amazon EKSに新しいクラスタリングを作成するには:

- [Amazon EKSクラスタリングの作成](../../../user/infrastructure/clusters/connect/new_eks_cluster.md)の手順に従ってください。

必要に応じて、`eksctl`を使用して手動でクラスタリングを作成することもできます。

## テンプレートからアプリケーションプロジェクトを作成する {#create-an-application-project-from-a-template}

GitLabプロジェクトテンプレートを使用して開始します。名前が示すように、これらのプロジェクトは、定評のあるフレームワーク上に構築された、必要最小限のアプリケーションを提供します。

{{< alert type="warning" >}}

クラスタ管理用のプロジェクトと同じレベルまたは下のグループ階層にアプリケーションプロジェクトを作成します。そうしないと、[エージェントを承認](../../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access)できません。

{{< /alert >}}

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. **Ruby on Rails**テンプレートを選択します。
1. プロジェクトに名前を付け、必要に応じて説明を追加し、[GitLab Ultimateプラン](https://about.gitlab.com/pricing/)で利用可能な機能を活用できるように、公開します。
1. **プロジェクトを作成**を選択します。

これで、EKSクラスタリングにデプロイするアプリケーションプロジェクトができました。

## エージェントを設定する {#configure-the-agent}

次に、Kubernetes用のGitLabエージェントを構成して、アプリケーションプロジェクトのデプロイに使用できるようにします。

1. [クラスタリングを管理するために作成した](#create-a-kubernetes-cluster)プロジェクトに移動します。
1. [エージェント構成ファイル](../../../user/clusters/agent/install/_index.md#create-an-agent-configuration-file)（`.gitlab/agents/eks-agent/config.yaml`）に移動し、編集します。
1. `ci_access:projects`属性を構成します。アプリケーションプロジェクトのパスを`id`として使用します:

```yaml
ci_access:
  projects:
    - id: path/to/application-project
```

## Ingressをインストールする {#install-ingress}

クラスタリングの実行後、インターネットからアプリケーションにトラフィックをルーティングするために、ロードバランサーとしてNGINX Ingressコントローラーをインストールする必要があります。GitLabの[クラスタリング管理プロジェクトテンプレート](../../../user/clusters/management_project_template.md)、またはコマンドラインから手動で、NGINX Ingressコントローラーをインストールします:

1. マシンに`kubectl`とHelmがインストールされていることを確認します。
1. クラスタリングにアクセスするためのIAMロールを作成します。
1. クラスタリングにアクセスするためのアクセストークンを作成します。
1. `kubectl`を使用してクラスタリングに接続します:

   ```shell
   helm upgrade --install ingress-nginx ingress-nginx \
   --repo https://kubernetes.github.io/ingress-nginx \
   --namespace gitlab-managed-apps --create-namespace

   # Check that the ingress controller is installed successfully
   kubectl get service ingress-nginx-controller -n gitlab-managed-apps
   ```

## Auto DevOpsを設定する {#configure-auto-devops}

次の手順に従って、自動DevOpsに必要なベースドメインおよびその他の設定を構成します。

1. NGINXをインストールしてから数分後、ロードバランサーはIPアドレスを取得し、次のコマンドで外部IPアドレスを取得できます:

   ```shell
   kubectl get all -n gitlab-managed-apps --selector app.kubernetes.io/instance=ingress-nginx
   ```

   ネームスペースを上書きした場合は、`gitlab-managed-apps`を置き換えてください。

   次に、次のコマンドを使用して、クラスタリングの実際の外部IPアドレスを見つけます:

   ```shell
   nslookup [External IP]
   ```

   ここで、`[External IP]`は、前のコマンドで見つかったホスト名です。

   IPアドレスは、応答の`Non-authoritative answer:`セクションにリストされている可能性があります。

   次の手順で必要になるため、このIPアドレスをコピーします。

1. アプリケーションプロジェクトに戻ります。
1. 左側のサイドバーで、**設定** > **CI/CD**を選択し、**変数**を展開します。
   - `KUBE_INGRESS_BASE_DOMAIN`というキーを、値としてアプリケーションデプロイドメインと共に追加します。この例では、ドメイン`<IP address>.nip.io`を使用します。
   - `KUBE_NAMESPACE`というキーを、ターゲットとするデプロイのKubernetesネームスペースの値と共に追加します。環境ごとに異なるネームスペースを使用できます。環境を構成し、環境スコープを使用します。
   - `KUBE_CONTEXT`というキーを、`path/to/agent/project:eks-agent`のような値と共に追加します。任意の環境スコープを選択します。
   - **変更を保存**を選択します。

## Auto DevOpsを有効にしてパイプラインを実行する {#enable-auto-devops-and-run-the-pipeline}

Auto DevOpsはデフォルトで有効になっていますが、インスタンス全体（GitLab Self-Managedインスタンスの場合）および個々のグループに対してAuto DevOpsを無効にすることができます。Auto DevOpsが無効になっている場合は、次の手順に従ってAuto DevOpsを有効にします:

1. 左側のサイドバーで、**検索または移動先**を選択して、アプリケーションプロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. **デフォルトのAuto DevOpsパイプライン**を選択して、その他のオプションを表示します。
1. **デプロイ戦略**で、デフォルトブランチでパイプラインが正常に実行された後、アプリケーションを本番環境にデプロイするための、目的の[継続的デプロイ戦略](../requirements.md#auto-devops-deployment-strategy)を選択します。
1. **変更を保存**を選択します。
1. `.gitlab-ci.yml`ファイルを編集してAuto DevOpsテンプレートを含め、変更をデフォルトブランチにコミットします:

   ```yaml
   include:
   - template: Auto-DevOps.gitlab-ci.yml
   ```

このコミットにより、パイプラインがトリガーされるはずです。次のセクションでは、パイプライン内の各ジョブの機能を説明します。

## アプリケーションをデプロイする {#deploy-the-application}

パイプラインが実行されている場合、何が行われていますか？

パイプライン内のジョブを表示するには、パイプラインのステータスバッジを選択します。{{< icon name="status_running" >}}アイコンは、パイプラインジョブの実行中に表示され、ジョブが完了すると、ページを更新せずに{{< icon name="status_success" >}}（成功の場合）または{{< icon name="status_failed" >}}（失敗の場合）に更新されます。

ジョブはステージに分割されます:

![パイプラインステージ](img/guide_pipeline_stages_v13_0.png)

- **ビルド** \- アプリケーションはDockerイメージをビルドし、プロジェクトの[コンテナレジストリ](../../../user/packages/container_registry/_index.md) （[自動ビルド](../stages.md#auto-build)）にアップロードします。
- **テスト** \- GitLabはアプリケーションに対してさまざまなチェックを実行しますが、`test`を除くすべてのジョブは、テストステージで失敗することが許可されています:

  - `test`ジョブは、言語とフレームワークを検出することにより、ユニットテストとインテグレーションテストを実行します（[自動テスト](../stages.md#auto-test)）
  - `code_quality`ジョブは、Code Qualityをチェックし、失敗することが許可されています（[自動Code Quality](../stages.md#auto-code-quality)）
  - `container_scanning`ジョブは、Dockerコンテナに脆弱性があるかどうかをチェックし、失敗することが許可されています（[自動コンテナスキャン](../stages.md#auto-container-scanning)）
  - `dependency_scanning`ジョブは、アプリケーションに脆弱性の影響を受けやすい依存関係があるかどうかをチェックし、失敗することが許可されています（[自動依存関係スキャン](../stages.md#auto-dependency-scanning)）
  - `-sast`で終わるジョブは、現在のコードで静的な解析を実行して、潜在的なセキュリティ上の問題を確認し、失敗することが許可されています（[自動SAST](../stages.md#auto-sast)）
  - `secret-detection`ジョブは、流出したシークレットがないかチェックし、失敗することが許可されています（[自動シークレット検出](../stages.md#auto-secret-detection)）

- **Review** \- デフォルトブランチのパイプラインには、`dast_environment_deploy`ジョブを含むこのステージが含まれています。詳細については、[動的アプリケーションセキュリティテスト（DAST）](../../../user/application_security/dast/_index.md)を参照してください。

- **Production**（Review） - テストとチェックが終了すると、アプリケーションはKubernetesにデプロイされます（[自動デプロイ](../stages.md#auto-deploy)）。

- **パフォーマンス** \- パフォーマンステストは、デプロイされたアプリケーション（[自動ブラウザパフォーマンステスト](../stages.md#auto-browser-performance-testing)）で実行されます。

- **Cleanup**（Cleanup） - デフォルトブランチのパイプラインには、`stop_dast_environment`ジョブを含むこのステージが含まれています。

パイプラインを実行した後、デプロイされたWebサイトを表示し、モニタリングする方法を学ぶ必要があります。

### プロジェクトをモニタリングする {#monitor-your-project}

アプリケーションを正常にデプロイした後、**環境** > **操作**に移動して、**環境**ページでWebサイトを表示し、そのヘルスチェックを行うことができます。このページには、デプロイされたアプリケーションに関する詳細が表示され、右側の列には、一般的な環境タスクにリンクするアイコンが表示されます:

![環境](img/guide_environments_v12_3.png)

- **ライブ環境を開く**（{{< icon name="external-link" >}}）-本番環境にデプロイされたアプリケーションのURLを開きます
- **モニタリング**（{{< icon name="chart" >}}）-PrometheusがKubernetesクラスタリングに関するデータと、アプリケーションがメモリ使用量、CPU使用量、およびレイテンシーにどのように影響するかに関するデータを収集するメトリクスページを開きます
- **デプロイ先**（{{< icon name="play" >}} {{< icon name="chevron-lg-down" >}}）-デプロイできる環境のリストを表示します
- **ターミナル**（{{< icon name="terminal" >}}）-アプリケーションが実行されているコンテナ内で、[Web端末](../../../ci/environments/_index.md#web-terminals-deprecated)セッションを開きます
- **環境に再デプロイ**（{{< icon name="repeat" >}}）-詳細については、[再試行とロールバック](../../../ci/environments/deployments.md#retry-or-roll-back-a-deployment)を参照してください
- **環境を停止**（{{< icon name="stop" >}}）-詳細については、[環境の停止](../../../ci/environments/_index.md#stopping-an-environment)を参照してください

GitLabは環境情報の下に[デプロイボード](../../../user/project/deploy_boards.md)を表示します。正方形はKubernetesクラスタリング内のポッドを表し、ステータスを示すために色分けされています。デプロイボードの正方形にカーソルを合わせるとデプロイの状態が表示され、正方形を選択するとポッドのログページに移動します。

この例では、アプリケーションをホストするポッドが1つだけ示されていますが、[`REPLICAS` CI/CD変数](../cicd_variables.md)を**設定 > CI/CD > 変数**で定義することにより、より多くのポッドを追加できます。

### ブランチを操作する {#work-with-branches}

次に、フィーチャーブランチを作成して、アプリケーションにコンテンツを追加します:

1. プロジェクトのリポジトリで、次のファイルに移動します：`app/views/welcome/index.html.erb`。このファイルには、段落`<p>You're on Rails!</p>`のみが含まれている必要があります。
1. GitLab [Web IDE](../../../user/project/web_ide/_index.md)を開いて、変更を加えます。
1. ファイルを編集して、次の内容を含めます:

   ```html
   <p>You're on Rails! Powered by GitLab Auto DevOps.</p>
   ```

1. ファイルをステージングします。コミットメッセージを追加し、**コミット**を選択して、新しいブランチとマージリクエストを作成します。

   ![Web IDEコミット](img/guide_ide_commit_v12_3.png)

マージリクエストを送信すると、GitLabはパイプラインを実行し、その中のすべてのジョブは、[前に説明した](#deploy-the-application)ように、デフォルトブランチ以外のブランチでのみ実行されるいくつかのジョブに加えて実行されます。

数分後、テストが失敗します。これは、変更によってテストが「壊れた」ことを意味します。失敗した`test`ジョブを選択して、詳細を表示します。

```plaintext
Failure:
WelcomeControllerTest#test_should_get_index [/app/test/controllers/welcome_controller_test.rb:7]:
<You're on Rails!> expected but was
<You're on Rails! Powered by GitLab Auto DevOps.>..
Expected 0 to be >= 1.

bin/rails test test/controllers/welcome_controller_test.rb:4
```

破損したテストを修正するには:

1. マージリクエストに戻ります。
1. 右上隅で、**コード**を選択し、次に**Web IDEで開く**を選択します。
1. 左側のファイルのディレクトリで、`test/controllers/welcome_controller_test.rb`ファイルを見つけ、それを選択して開きます。
1. 7行目を`You're on Rails! Powered by GitLab Auto DevOps.`に変更します
1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="merge" >}}）を選択します。
1. コミットメッセージを入力し、**コミット**を選択します。

マージリクエストの**概要**ページに戻ると、テストの合格だけでなく、アプリケーションが[レビューアプリケーション](../stages.md#auto-review-apps)としてデプロイされていることもわかります。**アプリを表示**{{< icon name="external-link" >}}ボタンを選択してアクセスし、変更がデプロイされていることを確認できます。

マージリクエストをマージした後、GitLabはデフォルトブランチでパイプラインを実行し、アプリケーションを本番環境にデプロイします。

## まとめ {#conclusion}

このプロジェクトを実装すると、Auto DevOpsの基本をしっかりと理解できるようになります。GitLabですべてのアプリケーションをビルドおよびテストからデプロイ、モニタリングまで開始しました。自動化された性質にもかかわらず、ワークフローに合わせてAuto DevOpsを構成およびカスタマイズすることもできます。参考になるリソースを以下に示します:

1. [Auto DevOps](../_index.md)
1. [複数のKubernetesクラスター](../multiple_clusters_auto_devops.md)
1. [本番環境への段階的なロールアウト](../cicd_variables.md#incremental-rollout-to-production)
1. [CI/CD変数を使用して、不要なジョブを無効にする](../cicd_variables.md)
1. [独自のビルドパックを使用してアプリケーションをビルドする](../customize.md#custom-buildpacks)
