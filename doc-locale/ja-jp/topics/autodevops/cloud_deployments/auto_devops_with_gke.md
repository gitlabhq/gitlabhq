---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsを使用して、アプリケーションをGoogle Kubernetes Engineにデプロイします
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、アプリケーションをGoogle Kubernetes Engine (GKE) にデプロイする方法の例を通して、[Auto DevOps](../_index.md)の概要を説明します。

ここではKubernetesのインテグレーションをネイティブに使用しているため、Google Cloud Platformコンソールを使用してKubernetesクラスタを手動で作成する必要はありません。GitLabテンプレートから作成するアプリケーションを作成し、デプロイします。

これらの手順は、GitLabセルフマネージド版にも適用されます。ご自身の[Runnerが構成されている](../../../ci/runners/_index.md)ことと、[Google OAuthが有効になっている](../../../integration/google.md)ことを確認してください。

プロジェクトをGoogle Kubernetes Engineにデプロイするには、以下の手順に従ってください。:

1. [Googleアカウントを設定する](#configure-your-google-account)
1. [Kubernetesクラスタを作成してエージェントをデプロイする](#create-a-kubernetes-cluster)
1. [テンプレートから新しいプロジェクトを作成する](#create-an-application-project-from-a-template)
1. [GitLabエージェント](#configure-the-agent)を設定します
1. [Ingressをインストールする](#install-ingress)
1. [Auto DevOpsを設定する](#configure-auto-devops)
1. [Auto DevOpsを有効にしてパイプラインを実行する](#enable-auto-devops-and-run-the-pipeline)
1. [アプリケーションをデプロイする](#deploy-the-application)

## Googleアカウントを設定する {#configure-your-google-account}

Kubernetesクラスタを作成してGitLabプロジェクトに接続する前に、[Google Cloud Platformアカウント](https://console.cloud.google.com)が必要です。GmailやGoogleドライブへのアクセスに使用しているGoogleアカウントなどの既存のGoogleアカウントでサインインするか、新しいアカウントを作成してください。

1. 必要なAPIと関連サービスを有効にするには、Kubernetes Engineのドキュメントの[「始める前に」セクション](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster#before-you-begin)に記載されている手順に従ってください。
1. Google Cloud Platformで[課金アカウント](https://cloud.google.com/billing/docs/how-to/manage-billing-account)を作成済みであることを確認してください。

{{< alert type="note" >}}

すべての新しいGoogle Cloud Platform (GCP) アカウントは[300ドルのクレジット](https://console.cloud.google.com/freetrial)を受け取り、Googleとの提携により、GitLabは、Google Kubernetes EngineとのGitLabインテグレーションを開始するために、新しいGCPアカウントに追加で200ドルを提供することができます。[このリンクをたどって](https://cloud.google.com/partners?pcn_code=0014M00001h35gDQAQ#contact-form)クレジットを申請してください。

{{< /alert >}}

## Kubernetesクラスタを作成する {#create-a-kubernetes-cluster}

このガイドでは、GKEクラスタを作成し、Kubernetes向けGitLabエージェントをインストールするために、[Terraform](https://www.terraform.io/)を使用する新しいプロジェクトを作成する必要があります。このプロジェクトは、Kubernetes向けGitLabエージェントの設定が格納されている場所です。

## テンプレートからアプリケーションプロジェクトを作成する {#create-an-application-project-from-a-template}

GitLabプロジェクトのテンプレートを使用して開始します。名前が示すように、これらのプロジェクトは、よく知られたフレームワーク上に構築された、むき出しのアプリケーションを提供します。

{{< alert type="warning" >}}

クラスタ管理用のプロジェクトと同じレベルまたはそれ以下のグループ階層にアプリケーションプロジェクトを作成します。そうしないと、[エージェントのアクセス権を承認する](../../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access)ことができません。

{{< /alert >}}

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. **Ruby on Rails**テンプレートを選択します。
1. プロジェクトに名前を付け、必要に応じて説明を追加し、[GitLab Ultimateプラン](https://about.gitlab.com/pricing/)で利用できる機能を活用できるように公開します。
1. **プロジェクトを作成**を選択します。

これで、GKEクラスタにデプロイするアプリケーションプロジェクトができました。

## GitLabエージェントを設定します {#configure-the-agent}

ここで、アプリケーションプロジェクトをデプロイするために使用できるように、Kubernetes向けGitLabエージェントを構成する必要があります。

1. [クラスタの管理用に作成した](#create-a-kubernetes-cluster)プロジェクトに移動します。
1. [エージェント設定ファイル](../../../user/clusters/agent/install/_index.md#create-an-agent-configuration-file) (`.gitlab/agents/<agent-name>/config.yaml`)に移動して編集します。
1. `ci_access:projects`属性を構成します。アプリケーションのプロジェクトパスを`id`として使用します:

```yaml
ci_access:
  projects:
    - id: path/to/application-project
```

## Ingressをインストールする {#install-ingress}

クラスタが実行されたら、インターネットからアプリケーションにトラフィックをルーティングするために、ロードバランサーとしてNGINX Ingressコントローラーをインストールする必要があります。GitLabの[クラスタ管理プロジェクトのテンプレート](../../../user/clusters/management_project_template.md)を使用するか、Google Cloud Shellで手動で、NGINX Ingressコントローラーをインストールします。:

1. クラスタの詳細ページに移動し、**高度な設定**タブを選択します。
1. Google Kubernetes Engineへのリンクを選択して、Google Cloud Consoleでクラスタにアクセスします。
1. GKEクラスタページで、**接続**を選択し、**Run in Cloud Shell**（Cloud Shellで実行）を選択します。
1. Cloud Shellが起動したら、次のコマンドを実行してNGINX Ingressコントローラーをインストールします。:

   ```shell
   helm upgrade --install ingress-nginx ingress-nginx \
   --repo https://kubernetes.github.io/ingress-nginx \
   --namespace gitlab-managed-apps --create-namespace

   # Check that the ingress controller is installed successfully
   kubectl get service ingress-nginx-controller -n gitlab-managed-apps
   ```

## Auto DevOpsを設定する {#configure-auto-devops}

これらの手順に従って、Auto DevOpsに必要なベースドメインおよびその他の設定を構成します。

1. NGINXをインストールしてから数分後、ロードバランサーがIPアドレスを取得し、次のコマンドで外部IPアドレスを取得できます。:

   ```shell
   kubectl get service ingress-nginx-controller -n gitlab-managed-apps -ojson | jq -r '.status.loadBalancer.ingress[].ip'
   ```

   `gitlab-managed-apps`を上書きした場合は、ネームスペースを置き換えてください。

   次の手順で必要になるため、このIPアドレスをコピーします。

1. アプリケーションプロジェクトに戻ります。
1. 左側のサイドバーで、**設定** > **CI/CD**を選択し、**変数**を展開します。
   - アプリケーションデプロイドメインを値として、`KUBE_INGRESS_BASE_DOMAIN`というキーを追加します。この例では、`<IP address>.nip.io`ドメインを使用します。
   - デプロイのターゲットとなるKubernetesのネームスペースの値を指定して、`KUBE_NAMESPACE`というキーを追加します。環境ごとに異なるネームスペースを使用できます。環境を構成し、環境スコープを使用します。
   - 値`<path/to/agent/project>:<agent-name>`を持つ`KUBE_CONTEXT`というキーを追加します。任意の環境スコープを選択します。
   - **変更を保存**を選択します。

## Auto DevOpsを有効にしてパイプラインを実行する {#enable-auto-devops-and-run-the-pipeline}

Auto DevOpsはデフォルトで有効になっていますが、Auto DevOpsは、インスタンス (GitLabセルフマネージドインスタンスの場合) とグループの両方で無効にすることができます。Auto DevOpsが無効になっている場合は、次の手順を実行してAuto DevOpsを有効にします。:

1. 左側のサイドバーで、**検索または移動先**を選択して、アプリケーションプロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. **デフォルトのAuto DevOpsパイプライン**を選択すると、より多くのオプションが表示されます。
1. **デプロイ戦略**で、デフォルトのブランチでパイプラインが正常に実行された後、アプリケーションを本番環境にデプロイするために、目的の[継続的デプロイ戦略](../requirements.md#auto-devops-deployment-strategy)を選択します。
1. **変更を保存**を選択します。
1. Auto DevOpsテンプレートを含めるように`.gitlab-ci.yml`ファイルを編集し、変更を`master`ブランチにコミットします。:

   ```yaml
   include:
   - template: Auto-DevOps.gitlab-ci.yml
   ```

このコミットにより、パイプラインがトリガーされるはずです。次のセクションでは、パイプライン内の各ジョブの機能について説明します。

## アプリケーションをデプロイする {#deploy-the-application}

パイプラインが実行されているとき、何をしているのですか？

パイプライン内のジョブを表示するには、パイプラインのステータスバッジを選択します。パイプラインのジョブが実行されているときは{{< icon name="status_running" >}}アイコンが表示され、ジョブが完了すると、ページを更新せずに{{< icon name="status_success" >}} (成功の場合) または{{< icon name="status_failed" >}} (失敗の場合) に更新されます。

ジョブはステージに分けられています。:

![パイプラインステージ](img/guide_pipeline_stages_v13_0.png)

- **ビルド** \- アプリケーションは、Dockerイメージをビルドし、プロジェクトの[コンテナレジストリ](../../../user/packages/container_registry/_index.md)にアップロードします([自動ビルド](../stages.md#auto-build))。
- **テスト** \- GitLabはアプリケーションに対してさまざまなチェックを実行しますが、`test`を除くすべてのジョブは、テストステージで失敗してもかまいません。:

  - `test`ジョブは、言語とフレームワークを検出することにより、ユニットテストとインテグレーションテストを実行します ([自動テスト](../stages.md#auto-test))
  - `code_quality`ジョブはCode Qualityをチェックし、失敗してもかまいません ([自動Code Quality](../stages.md#auto-code-quality))
  - `container_scanning`ジョブは、Dockerコンテナに脆弱性があるかどうかをチェックし、失敗してもかまいません ([自動コンテナスキャン](../stages.md#auto-container-scanning))
  - `dependency_scanning`ジョブは、アプリケーションに脆弱性の影響を受けやすい依存があるかどうかをチェックし、失敗してもかまいません ([自動依存関係スキャン](../stages.md#auto-dependency-scanning))
  - `-sast`で終わるジョブは、現在のコードに対して静的な解析を実行して、潜在的なセキュリティ上の問題をチェックし、失敗してもかまいません ([自動SAST](../stages.md#auto-sast))
  - `secret-detection`ジョブは、流出したシークレットをチェックし、失敗してもかまいません ([自動シークレット検出](../stages.md#auto-secret-detection))

- **Review** \- デフォルトのブランチのパイプラインには、`dast_environment_deploy`ジョブを含むこのステージが含まれています。詳細については、[動的アプリケーションセキュリティテスト（DAST）](../../../user/application_security/dast/_index.md)を参照してください。

- **Production**（本番） - テストとチェックが終了すると、アプリケーションはKubernetesにデプロイされます ([自動デプロイ](../stages.md#auto-deploy))。

- **パフォーマンス** \- デプロイされたアプリケーションでパフォーマンステストが実行されます ([自動ブラウザパフォーマンステスト](../stages.md#auto-browser-performance-testing))。

- **Cleanup**（クリーンアップ） - デフォルトのブランチのパイプラインには、`stop_dast_environment`ジョブを含むこのステージが含まれています。

パイプラインを実行した後、デプロイされたWebサイトを表示し、そのモニタリング方法を学ぶ必要があります。

### プロジェクトをモニタリングする {#monitor-your-project}

アプリケーションのデプロイが成功すると、**環境**ページでWebサイトを表示し、その健全性を確認できます。**操作** > **環境**に移動します。このページには、デプロイされたアプリケーションに関する詳細が表示され、右側の列には、一般的な環境タスクにリンクするアイコンが表示されます。:

![環境](img/guide_environments_v12_3.png)

- **ライブ環境を開く** ({{< icon name="external-link" >}}) - 本番環境にデプロイされたアプリケーションのURLを開きます
- **モニタリング** ({{< icon name="chart" >}}) - PrometheusがKubernetesクラスタに関するデータと、メモリ使用量、CPU使用率、レイテンシーの点でアプリケーションがそれにどのように影響するかに関するデータを収集するメトリクスページを開きます
- **デプロイ先** ({{< icon name="play" >}} {{< icon name="chevron-lg-down" >}}) - デプロイできる環境のリストを表示します
- **ターミナル** ({{< icon name="terminal" >}}) - アプリケーションが実行されているコンテナ内で、[Web端末](../../../ci/environments/_index.md#web-terminals-deprecated)セッションを開きます
- **環境に再デプロイ** ({{< icon name="repeat" >}}) - 詳細については、[再試行とロールバック](../../../ci/environments/deployments.md#retry-or-roll-back-a-deployment)を参照してください
- **環境を停止** ({{< icon name="stop" >}}) - 詳細については、[環境の停止](../../../ci/environments/_index.md#stopping-an-environment)を参照してください

GitLabは、環境情報の下に[デプロイボード](../../../user/project/deploy_boards.md)を表示します。四角はKubernetesクラスタ内のポッドを表し、色分けによってそのステータスを示します。[デプロイボード]の正方形にカーソルを合わせると、デプロイの状態が表示され、正方形を選択すると、ポッドのログページに移動します。

{{< alert type="note" >}}

この例では、現時点でアプリケーションをホストしているポッドは1つだけですが、[`REPLICAS` CI/CD変数](../cicd_variables.md)を**設定** > **CI/CD** > **変数**で定義すると、ポッドをさらに追加できます。

{{< /alert >}}

### ブランチを操作する {#work-with-branches}

次に、フィーチャーブランチを作成して、コンテンツをアプリケーションに追加します。:

1. プロジェクトのリポジトリで、次のファイルに移動します:`app/views/welcome/index.html.erb`。このファイルには、段落`<p>You're on Rails!</p>`のみが含まれている必要があります。
1. GitLab [Web IDE](../../../user/project/web_ide/_index.md)を開き、変更を加えます。
1. ファイルに次の内容が含まれるように編集します。:

   ```html
   <p>You're on Rails! Powered by GitLab Auto DevOps.</p>
   ```

1. ファイルをステージングします。コミットメッセージを追加し、**コミット**を選択して新しいブランチとマージリクエストを作成します。

   ![Web IDE](img/guide_ide_commit_v12_3.png)コミット

マージリクエストを送信すると、GitLabはパイプラインとその中のすべてのジョブを、[前に説明した](#deploy-the-application)ように実行します。さらに、デフォルトのブランチ以外のブランチでのみ実行されるジョブもいくつかあります。

数分後、テストが失敗します。これは、変更によってテストが「破損」したことを意味します。失敗した`test`ジョブを選択して、詳細情報を表示します。

```plaintext
Failure:
WelcomeControllerTest#test_should_get_index [/app/test/controllers/welcome_controller_test.rb:7]:
<You're on Rails!> expected but was
<You're on Rails! Powered by GitLab Auto DevOps.>..
Expected 0 to be >= 1.

bin/rails test test/controllers/welcome_controller_test.rb:4
```

破損したテストを修正するには、次のようにします。:

1. マージリクエストに戻ります。
1. 右上隅で、**コード**を選択し、**Web IDEで開く**を選択します。
1. 左側のファイルのディレクトリで、`test/controllers/welcome_controller_test.rb`ファイルを見つけて選択し、開きます。
1. 7行目を`You're on Rails! Powered by GitLab Auto DevOps.`と言うように変更します
1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="merge" >}}）を選択します。
1. コミットメッセージを記述し、**コミット**を選択します。

マージリクエストの**概要**ページに戻ると、テストに合格するだけでなく、アプリケーションが[レビューアプリケーション](../stages.md#auto-review-apps)としてデプロイされていることもわかります。**アプリを表示** {{< icon name="external-link" >}}ボタンを選択してアクセスし、変更がデプロイされていることを確認できます。

マージリクエストをマージした後、GitLabはデフォルトのブランチでパイプラインを実行し、アプリケーションを本番環境にデプロイします。

## まとめ {#conclusion}

このプロジェクトを実装すると、Auto DevOpsの基本をしっかりと理解できるようになります。GitLabでのアプリケーションのビルドとテストから、デプロイとモニタリングまでを開始しました。自動的な性質にもかかわらず、Auto DevOpsは、ワークフローに合わせて構成およびカスタマイズすることもできます。以下は、さらに詳しく学習するための役立つリソースです。:

1. [Auto DevOps](../_index.md)
1. [複数のKubernetesクラスター](../multiple_clusters_auto_devops.md)
1. [本番環境への段階的ロールアウト](../cicd_variables.md#incremental-rollout-to-production)
1. [CI/CD変数を使用して不要なジョブを無効にする](../cicd_variables.md)
1. [独自のビルドパックを使用してアプリケーションをビルドする](../customize.md#custom-buildpacks)
