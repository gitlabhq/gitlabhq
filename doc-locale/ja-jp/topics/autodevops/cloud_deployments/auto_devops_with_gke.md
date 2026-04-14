---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Auto DevOpsを使用して、アプリケーションをGoogle Kubernetes Engineにデプロイします
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、[Auto DevOps](../_index.md)を使用してGoogle Kubernetes Engine（GKE）にアプリケーションをデプロイする方法の例から始めます。

GitLabネイティブのKubernetesインテグレーションを使用しているため、Google Cloud Platformコンソールを使用してKubernetesクラスターを手動で作成する必要はありません。GitLabテンプレートから作成したアプリケーションを作成し、デプロイします。

これらの手順はGitLab Self-Managedにも適用されます。ご自身の[Runnerが設定されている](../../../ci/runners/_index.md)こと、および[Google OAuthが有効になっている](../../../integration/google.md)ことを確認してください。

Google Kubernetes Engineにプロジェクトをデプロイするには、以下の手順に従ってください:

1. 1. [Googleアカウントを設定します](#configure-your-google-account)
1. 1. [Kubernetesクラスターを作成し、エージェントをデプロイします](#create-a-kubernetes-cluster)
1. 1. [テンプレートから新しいプロジェクトを作成します](#create-an-application-project-from-a-template)
1. 1. [エージェントを設定します](#configure-the-agent)
1. [Ingressをインストールする](#install-ingress)
1. [Auto DevOpsを設定する](#configure-auto-devops)
1. 1. [Auto DevOpsを有効にしてパイプラインを実行します](#enable-auto-devops-and-run-the-pipeline)
1. 1. [アプリケーションをデプロイします](#deploy-the-application)

## Googleアカウントを設定します {#configure-your-google-account}

KubernetesクラスターをGitLabプロジェクトに作成して接続する前に、[Google Cloud Platformアカウント](https://console.cloud.google.com)が必要です。GmailやGoogle Driveへのアクセスに使用している既存のGoogleアカウントでサインインするか、新しいアカウントを作成してください。

1. Kubernetes Engineのドキュメントの[「始める前に」セクション](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster#before-you-begin)に記載されている手順に従って、必要なAPIと関連サービスを有効にしてください。
1. Google Cloud Platformで[支払いアカウント](https://cloud.google.com/billing/docs/how-to/manage-billing-account)を作成したことを確認してください。

> [!note]
> 新しいGoogle Cloud Platform（GCP）アカウントはすべて[300ドルのクレジット](https://console.cloud.google.com/freetrial)を受け取ります。Googleとの提携により、GitLabは、Google Kubernetes EngineとのGitLabインテグレーションを始める新しいGCPアカウント向けに追加で200ドルを提供できます。[このリンク](https://cloud.google.com/partners?pcn_code=0014M00001h35gDQAQ#contact-form)からクレジットを申請してください。

## Kubernetesクラスターを作成します {#create-a-kubernetes-cluster}

Google Kubernetes Engine（GKE）上に新しいクラスターを作成するには、[OpenTofuとGitLabを使用したGoogle GKEクラスターの作成](../../../user/infrastructure/iac/_index.md)ガイドの手順に従ってInfrastructure as Code（IaC）アプローチを使用します。このガイドでは、[Terraform](https://www.terraform.io/)を使用してGKEクラスターを作成し、Kubernetes向けGitLabエージェントをインストールする新しいプロジェクトを作成する必要があります。このプロジェクトは、Kubernetes向けGitLabエージェントの設定が格納されている場所です。

## テンプレートからアプリケーションプロジェクトを作成します {#create-an-application-project-from-a-template}

GitLabプロジェクトテンプレートを使用して開始します。名前が示すとおり、これらのプロジェクトは、いくつかのよく知られたフレームワーク上に構築された必要最低限のアプリケーションを提供します。

> [!warning]
> クラスター管理のプロジェクトと同じレベルかそれ以下のグループ階層にアプリケーションプロジェクトを作成してください。そうしないと、[エージェントの承認](../../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access)に失敗します。

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. **Ruby on Rails**テンプレートを選択します。
1. プロジェクトに名前を付け、オプションで説明を追加し、[Ultimateプラン](https://about.gitlab.com/pricing/)で利用できる機能を活用できるように、公開設定にしてください。
1. **プロジェクトを作成**を選択します。

これで、GKEクラスターにデプロイするアプリケーションプロジェクトができました。

## エージェントを設定します {#configure-the-agent}

次に、Kubernetes向けGitLabエージェントを設定して、アプリケーションプロジェクトのデプロイに利用できるようにします。

1. [クラスターを管理するために作成したプロジェクト](#create-a-kubernetes-cluster)に移動します。
1. [エージェント設定ファイル](../../../user/clusters/agent/install/_index.md#create-an-agent-configuration-file)（`.gitlab/agents/<agent-name>/config.yaml`）に移動し、編集します。
1. `ci_access:projects`属性を設定します。アプリケーションのプロジェクトパスを`id`として使用します:

```yaml
ci_access:
  projects:
    - id: path/to/application-project
```

## Ingressをインストールします {#install-ingress}

クラスターが稼働したら、インターネットからアプリケーションへのトラフィックをルーティングするためのロードバランサーとしてNGINX Ingress Controllerをインストールする必要があります。GitLabの[クラスター管理プロジェクトテンプレート](../../../user/clusters/management_project_template.md)を介して、またはGoogle Cloud Shellで手動でNGINX Ingress Controllerをインストールします:

1. クラスターの詳細ページに移動し、**高度な設定**タブを選択します。
1. Google Kubernetes Engineへのリンクを選択して、Google Cloud Consoleでクラスターにアクセスします。
1. GKEクラスターページで**接続**を選択し、次に**Run in Cloud Shell**を選択します。
1. Cloud Shellの起動後、これらのコマンドを実行してNGINX Ingress Controllerをインストールします:

   ```shell
   helm upgrade --install ingress-nginx ingress-nginx \
   --repo https://kubernetes.github.io/ingress-nginx \
   --namespace gitlab-managed-apps --create-namespace

   # Check that the ingress controller is installed successfully
   kubectl get service ingress-nginx-controller -n gitlab-managed-apps
   ```

## Auto DevOpsを設定します {#configure-auto-devops}

ベースドメインおよびAuto DevOpsに必要なその他の設定を構成するには、次の手順に従います。

1. NGINXをインストールしてから数分後に、ロードバランサーがIPアドレスを取得します。以下のコマンドで外部IPアドレスを取得できます:

   ```shell
   kubectl get service ingress-nginx-controller -n gitlab-managed-apps -ojson | jq -r '.status.loadBalancer.ingress[].ip'
   ```

   ネームスペースを上書きした場合は、`gitlab-managed-apps`を置き換えてください。

   このIPアドレスは次のステップで必要になるため、コピーしてください。

1. アプリケーションプロジェクトに戻ります。
1. 左サイドバーで、**設定** > **CI/CD**を選択し、**変数**を展開します。
   - アプリケーションのデプロイドメインを値として、`KUBE_INGRESS_BASE_DOMAIN`というキーを追加します。この例では、`<IP address>.nip.io`ドメインを使用します。
   - `KUBE_NAMESPACE`というキーを追加し、デプロイのターゲットとなるKubernetesネームスペースの値を設定します。環境ごとに異なるネームスペースを使用できます。環境を設定し、環境スコープを使用します。
   - `KUBE_CONTEXT`というキーを`<path/to/agent/project>:<agent-name>`の値で追加します。任意の環境スコープを選択します。
   - **変更を保存**を選択します。

## Auto DevOpsを有効にしてパイプラインを実行します {#enable-auto-devops-and-run-the-pipeline}

Auto DevOpsはデフォルトで有効になっていますが、インスタンス（GitLab Self-Managedインスタンスの場合）とグループの両方でAuto DevOpsを無効にすることができます。Auto DevOpsが無効になっている場合は、以下の手順を実行して有効にしてください:

1. トップバーで**検索または移動先**を選択し、アプリケーションプロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. その他のオプションを表示するには、**デフォルトのAuto DevOpsパイプライン**を選択します。
1. **デプロイ戦略**で、デフォルトブランチでパイプラインが正常に実行された後、アプリケーションを本番環境にデプロイするための目的の[継続的デプロイ戦略](../requirements.md#auto-devops-deployment-strategy)を選択します。
1. **変更を保存**を選択します。
1. Auto DevOpsテンプレートを含めるために`.gitlab-ci.yml`ファイルを編集し、変更を`master`ブランチにコミットします:

   ```yaml
   include:
   - template: Auto-DevOps.gitlab-ci.yml
   ```

このコミットにより、パイプラインがトリガーされるはずです。次のセクションでは、パイプライン内の各ジョブの機能について説明します。

## アプリケーションをデプロイします {#deploy-the-application}

パイプラインが実行されると、何が起こるのでしょうか？

パイプラインのジョブを表示するには、パイプラインのステータスバッジを選択します。パイプラインジョブの実行中は{{< icon name="status_running" >}}アイコンが表示され、ジョブが完了するとページを更新することなく{{< icon name="status_success" >}}（成功の場合）または{{< icon name="status_failed" >}}（失敗の場合）に更新されます。

ジョブはステージに分けられます:

![パイプラインステージ](img/guide_pipeline_stages_v13_0.png)

- **ビルド** \- アプリケーションがDockerイメージをビルドし、プロジェクトの[コンテナレジストリ](../../../user/packages/container_registry/_index.md)にアップロードします（[Auto Build](../stages.md#auto-build)）。
- **Test** \- GitLabはアプリケーションに対して様々なチェックを実行しますが、`test`を除くすべてのジョブはTestステージで失敗することが許可されています:

  - `test`ジョブは、言語とフレームワークを検出して単体テストとインテグレーションテストを実行します（[Auto Test](../stages.md#auto-test)）。
  - `code_quality`ジョブはコード品質をチェックし、失敗することが許可されています（[Auto Code Quality](../stages.md#auto-code-quality)）。
  - `container_scanning`ジョブはDockerコンテナに脆弱性がないかチェックし、失敗することが許可されています（[自動コンテナスキャン](../stages.md#auto-container-scanning)）。
  - `dependency_scanning`ジョブは、アプリケーションに脆弱性の影響を受けやすい依存関係があるかどうかをチェックし、失敗することが許可されています（[自動依存関係スキャン](../stages.md#auto-dependency-scanning)）。
  - ジョブは`-sast`で終わり、現在のコードに対して静的な解析を実行して潜在的なセキュリティ問題がないかチェックし、失敗することが許可されています（[自動SAST](../stages.md#auto-sast)）。
  - The `secret-detection`ジョブは流出したシークレットをチェックし、失敗することが許可されています（[自動シークレット検出](../stages.md#auto-secret-detection)）。

- **Review** \- デフォルトブランチ上のパイプラインには、`dast_environment_deploy`ジョブを含むこのステージが含まれています。詳細については、[動的アプリケーションセキュリティテスト（DAST）](../../../user/application_security/dast/_index.md)を参照してください。

- **Production** \- テストとチェックが完了すると、アプリケーションはKubernetesにデプロイされます（[自動デプロイ](../stages.md#auto-deploy)）。

- **パフォーマンス** \- デプロイされたアプリケーションでパフォーマンステストが実行されます（[Auto Browser Performance Testing](../stages.md#auto-browser-performance-testing)）。

- **Cleanup** \- デフォルトブランチ上のパイプラインには、`stop_dast_environment`ジョブを含むこのステージが含まれます。

パイプラインを実行した後、デプロイされたウェブサイトを表示し、それを監視する方法を学ぶ必要があります。

### プロジェクトを監視します {#monitor-your-project}

アプリケーションが正常にデプロイされた後、**操作** > **環境**に移動して、**環境**ページでそのウェブサイトを表示し、健全性を確認できます。このページには、デプロイされたアプリケーションの詳細が表示され、右側の列には一般的な環境タスクへのリンクアイコンが表示されます:

![環境](img/guide_environments_v12_3.png)

- **ライブ環境を開く**（{{< icon name="external-link" >}}）- 本番環境にデプロイされたアプリケーションのURLを開きます
- **モニタリング**（{{< icon name="chart" >}}）- PrometheusがKubernetesクラスターに関するデータ、およびメモリ使用量、CPU使用量、レイテンシーに関してアプリケーションがそれにどのように影響するかを収集するメトリクスページを開きます
- **デプロイ先**（{{< icon name="play" >}} {{< icon name="chevron-lg-down" >}}）- デプロイできる環境のリストを表示します
- **ターミナル**（{{< icon name="terminal" >}}）- アプリケーションが実行されているコンテナ内で[Web端末](../../../ci/environments/_index.md#web-terminals-deprecated)セッションを開きます
- **環境に再デプロイ**（{{< icon name="repeat" >}}）- 詳細については、[再試行とロールバック](../../../ci/environments/deployments.md#retry-or-roll-back-a-deployment)を参照してください。
- **環境を停止**（{{< icon name="stop" >}}）- 詳細については、[環境の停止](../../../ci/environments/_index.md#stopping-an-environment)を参照してください。

GitLabは環境情報の下に[デプロイボード](../../../user/project/deploy_boards.md)を表示し、Kubernetesクラスター内のポッドを表す正方形がステータスを示す色分けで表示されます。デプロイボード上の正方形にカーソルを合わせるとデプロイの状態が表示され、その正方形を選択するとポッドのログページに移動します。

> [!note]
> この例では、現時点では1つのポッドのみがアプリケーションをホストしていますが、**設定** > **CI/CD** > **変数**で[`REPLICAS` CI/CD変数](../cicd_variables.md)を定義することで、さらに多くのポッドを追加できます。

### ブランチを操作します {#work-with-branches}

次に、アプリケーションにコンテンツを追加するフィーチャーブランチを作成します:

1. あなたのプロジェクトのリポジトリで、以下のファイルに移動します: `app/views/welcome/index.html.erb`。このファイルには、次の段落のみが含まれている必要があります: `<p>You're on Rails!</p>`。
1. 変更を行うには、GitLab [Web IDE](../../../user/project/web_ide/_index.md)を開きます。
1. 次の内容が含まれるようにファイルを編集します:

   ```html
   <p>You're on Rails! Powered by GitLab Auto DevOps.</p>
   ```

1. ファイルをステージングします。コミットメッセージを追加し、**コミット**を選択して新しいブランチとマージリクエストを作成します。

   ![Web IDEコミット](img/guide_ide_commit_v12_3.png)

マージリクエストを送信すると、GitLabはパイプライン、およびその中のすべてのジョブを、[前述のとおり](#deploy-the-application)、デフォルトブランチ以外のブランチでのみ実行されるいくつかの追加ジョブに加えて実行します。

数分後、テストが失敗します。これは、変更によってテストが「壊された」ことを意味します。失敗した`test`ジョブを選択して、詳細情報を確認します:

```plaintext
Failure:
WelcomeControllerTest#test_should_get_index [/app/test/controllers/welcome_controller_test.rb:7]:
<You're on Rails!> expected but was
<You're on Rails! Powered by GitLab Auto DevOps.>..
Expected 0 to be >= 1.

bin/rails test test/controllers/welcome_controller_test.rb:4
```

破損したテストを修正するには:

1. あなたのマージリクエストに戻ります。
1. 右上隅で**コード**を選択し、次に**Web IDEで開く**を選択します。
1. 左側のファイルのディレクトリで、`test/controllers/welcome_controller_test.rb`ファイルを見つけて選択し、開きます。
1. 7行目を`You're on Rails! Powered by GitLab Auto DevOps.`に変更します。
1. 左側のサイドバーで、**Source Control**（{{< icon name="merge" >}}）を選択します。
1. コミットメッセージを記述し、**コミット**を選択します。

マージリクエストの**概要**ページに戻ると、テストが合格しているだけでなく、アプリケーションが[レビューアプリケーション](../stages.md#auto-review-apps)としてデプロイされているのが確認できます。**アプリを表示** {{< icon name="external-link" >}}ボタンを選択して、デプロイされた変更を確認できます。

マージリクエストをマージした後、GitLabはデフォルトブランチでパイプラインを実行し、アプリケーションを本番環境にデプロイします。

## まとめ {#conclusion}

このプロジェクトを実装した後、Auto DevOpsの基本をしっかりと理解できたはずです。ビルドとテストから開始し、アプリケーションのデプロイとモニタリングまで、すべてGitLabで行いました。その自動的な性質にもかかわらず、Auto DevOpsはワークフローに合わせて設定およびカスタマイズすることもできます。以下に、さらに学習するための役立つリソースを示します:

1. [Auto DevOps](../_index.md)
1. [複数のKubernetesクラスター](../multiple_clusters_auto_devops.md)
1. [インクリメンタルロールアウトから本番環境へ](../cicd_variables.md#incremental-rollout-to-production)
1. [ジョブをCI/CD変数で無効にする](../cicd_variables.md)
1. [独自のビルドパックを使用してアプリケーションをビルドする](../customize.md#custom-buildpacks)
