---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google GKEクラスターの作成
---

[Infrastructure as Code (IaC)](../../_index.md)を使用して、Google Kubernetes Engine (GKE) で新しいクラスターを作成する方法について説明します。このプロセスでは、GoogleおよびKubernetes Terraformプロバイダーを使用してGKEクラスターを作成します。クラスターをKubernetes向けGitLabエージェントサーバーを使用してGitLabに接続します。

{{< alert type="note" >}}

すべての新しいGoogle Cloud Platform（GCP）アカウントは[$300のクレジット](https://console.cloud.google.com/freetrial)を受け取り、Googleとの提携により、GitLabはGoogle Google Kubernetes Engineとのインテグレーションを開始するために、新しいGCPアカウントにさらに$200を提供できます。[このリンクをたどって](https://cloud.google.com/partners?pcn_code=0014M00001h35gDQAQ&hl=en#contact-form)、クレジットを申請してください。

{{< /alert >}}

**はじめる前**:

- [Google Cloud Platform（GCP）サービスアカウント](https://cloud.google.com/docs/authentication#service-accounts)。
- GitLab CI/CDパイプラインを実行するために使用できる[Runner](https://docs.gitlab.com/runner/install/)。

**ステップ**:

1. [サンプルプロジェクトをインポートします](#import-the-example-project)。
1. [Kubernetes](#register-the-agent)用エージェントを登録します。
1. [GCP認証情報を作成します](#create-your-gcp-credentials)。
1. [プロジェクトを設定します](#configure-your-project)。
1. [クラスターをプロビジョニングします](#provision-your-cluster)。

## サンプルプロジェクトをインポートする {#import-the-example-project}

Infrastructure as Codeを使用してGitLabからクラスターを作成するには、クラスターを管理するためのGitLabプロジェクトを作成する必要があります。このチュートリアルでは、サンプルプロジェクトから開始し、必要に応じて変更します。

[URLでサンプルプロジェクトをインポートする](../../../project/import/repo_by_url.md)ことから始めます。

プロジェクトをインポートするには:

1. GitLabの左側のサイドバーで、**検索または移動先**を選択します。
1. **すべてのプロジェクトを表示**を選択します。
1. ページの右側で、**新規プロジェクト**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **リポジトリのURL**を選択します。
1. **GitリポジトリのURL**に、`https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke.git`と入力します。
1. フィールドに入力し、**プロジェクトを作成**を選択します。

このプロジェクトでは、次のものが提供されます:

- 名前、場所、ノード数、およびKubernetesバージョンのデフォルトを持つ、[Google Cloud Platform（GCP）上のクラスター](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/gke.tf)。
- クラスターにインストールされている[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/agent.tf)。

## エージェントを登録する {#register-the-agent}

{{< history >}}

- GitLab 14.9で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81054)されました。`certificate_based_clusters`という名前の[フラグ](../../../../administration/feature_flags/_index.md)により、**アクション**メニューが証明書ではなくエージェントに焦点を当てるように変更されました。デフォルトでは無効になっています。

{{< /history >}}

Kubernetes用GitLabエージェントを作成するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. **クラスターに接続(エージェント)**を選択します。
1. **Select an agent or enter a name to create new**（新しいエージェントを選択するか、名前を入力して作成）ドロップダウンリストから、エージェントの名前を選択し、**登録する**を選択します。
1. GitLabは、エージェントの登録トークンを生成します。このシークレットトークンは、後で必要になるため、安全に保管してください。
1. オプション。Helmを使用する場合、GitLabはHelmコマンドの例でエージェントサーバー（KAS）のアドレスを提供します。これは後で必要になります。

## GCP認証情報を作成します {#create-your-gcp-credentials}

GCPおよびGitLab APIと通信するようにプロジェクトをセットアップするには:

1. GitLabでGCPを認証するには、次のロールを持つ[GCPサービスアカウント](https://cloud.google.com/docs/authentication#service-accounts)を作成します：`Compute Network Viewer`、`Kubernetes Engine Admin`、`Service Account User`、および`Service Account Admin`。ユーザーと管理者のサービスアカウントの両方が必要です。ユーザーロールは、[デフォルトサービスアカウント](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account)を[ノードプールを作成する](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#node-pool-management)ときに偽装します。管理者ロールは、`kube-system`ネームスペースにサービスアカウントを作成します。
1. 前の手順で作成したサービスアカウントキーを含むJSONファイルをダウンロードします。
1. コンピューターで、JSONファイルを`base64`にエンコードします（`/path/to/sa-key.json`をキーへのパスに置き換えます）:

   {{< tabs >}}

   {{< tab title="MacOS" >}}

   ```shell
   base64 -i /path/to/sa-key.json | tr -d \\n
   ```

   {{< /tab >}}

   {{< tab title="Linux" >}}

   ```shell
   base64 /path/to/sa-key.json | tr -d \\n
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. このコマンドの出力を、次のステップで`BASE64_GOOGLE_CREDENTIALS`環境変数として使用します。

## プロジェクトを設定する {#configure-your-project}

CI/CD環境変数を使用して、プロジェクトを設定します。

**Required configuration**（必要な設定）:

1. 左側のサイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. 変数`BASE64_GOOGLE_CREDENTIALS`を、作成したばかりの`base64`にエンコードされたJSONファイルに設定します。
1. 変数`TF_VAR_gcp_project`をGCPの`project` IDに設定します。
1. 変数`TF_VAR_agent_token`を、前のタスクに表示されるエージェントトークンに設定します。
1. 変数`TF_VAR_kas_address`を、前のタスクに表示されるエージェントサーバーアドレスに設定します。

**Optional configuration**（オプションの設定）:

ファイル[`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/variables.tf)には、必要に応じてオーバーライドできるその他の変数が含まれています:

- `TF_VAR_gcp_region`: クラスターのリージョンを設定します。
- `TF_VAR_cluster_name`: クラスターの名前を設定します。
- `TF_VAR_cluster_description`: クラスターの説明を設定します。GCPクラスターの詳細ページでGitLabプロジェクトへの参照を作成するには、これを`$CI_PROJECT_URL`に設定することをお勧めします。これにより、GCPダッシュボードに表示されるクラスターをプロビジョニングしたプロジェクトを把握できます。
- `TF_VAR_machine_type`: Kubernetesノードのマシンタイプを設定します。
- `TF_VAR_node_count`: Kubernetesノードの数を設定します。
- `TF_VAR_agent_namespace`: Kubernetes向けGitLabエージェントのKubernetesネームスペースを設定します。

リソースオプションの詳細については、[Google Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference)および[Kubernetes Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)のドキュメントを参照してください。

## Kubernetes Engine APIを有効にする {#enable-kubernetes-engine-api}

Google Cloud Consoleから、[Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com)を有効にします。

## クラスターをプロビジョニングする {#provision-your-cluster}

プロジェクトを設定した後、手動でクラスターのプロビジョニングをトリガーします。GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. **パイプラインを新規作成**を選択します。
1. **Play**（再生）（{{< icon name="play" >}}）の横で、ドロップダウンリストアイコン（{{< icon name="chevron-lg-down" >}}）を選択します。
1. **デプロイ**を選択して、デプロイメントジョブを手動でトリガーします。

パイプラインが正常に終了すると、新しいクラスターが表示されます:

- GCPの場合：[GCPコンソールのKubernetesリスト](https://console.cloud.google.com/kubernetes/list)にあります。
- GitLabの場合：プロジェクトのサイドバーから、**操作** > **Kubernetesクラスター**を選択します。

## クラスターを使用する {#use-your-cluster}

クラスターをプロビジョニングすると、GitLabに接続され、デプロイの準備が整います。接続を確認するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. リストで、**接続ステータス**列を表示します。

接続の機能の詳細については、[Kubernetes向けGitLabエージェント](../_index.md)のドキュメントを参照してください。

## クラスターを削除する {#remove-the-cluster}

クリーンアップジョブは、デフォルトではパイプラインに含まれていません。作成したすべてのリソースを削除するには、クリーンアップジョブを実行する前に、GitLab CI/CDテンプレートを変更する必要があります。

すべてのリソースを削除するには:

1. 次の内容を`.gitlab-ci.yml`ファイルに追加します:

   ```yaml
   stages:
     - init
     - validate
     - build
     - test
     - deploy
     - cleanup

   destroy:
     extends: .terraform:destroy
     needs: []
   ```

1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択し、最新のパイプラインを選択します。
1. `destroy`ジョブの場合は、**Play**（再生）（{{< icon name="play" >}}）を選択します。
