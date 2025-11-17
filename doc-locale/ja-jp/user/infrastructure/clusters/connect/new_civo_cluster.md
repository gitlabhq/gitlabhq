---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Civo Kubernetesクラスターの作成
---

すべての新しいCivoアカウントは、Civo KubernetesとのGitLabインテグレーションを開始するために[250ドルのクレジット](https://dashboard.civo.com/signup)を受け取ります。マーケットプレイスアプリを使用して、Civo KubernetesクラスターにGitLabをインストールすることもできます。

[Infrastructure as Code（IaC）](../../_index.md)を使用してCivo Kubernetesに新しいクラスターを作成する方法をご覧ください。このプロセスでは、CivoおよびKubernetes Terraformプロバイダーを使用して、Civo Kubernetesクラスターを作成します。Kubernetes向けGitLabエージェントを使用して、クラスターをGitLabに接続します。

**はじめる前**:

- [Civoアカウント](https://dashboard.civo.com/signup)。
- GitLab CI/CDパイプラインの実行に使用できる[ランナー](https://docs.gitlab.com/runner/install/)。

**ステップ**:

1. [サンプルプロジェクトをインポートする](#import-the-example-project)。
1. [Kubernetes用エージェントを登録](#register-the-agent)します。
1. [プロジェクトを設定する](#configure-your-project)。
1. [クラスターをプロビジョニングする](#provision-your-cluster)。

## サンプルプロジェクトをインポートする {#import-the-example-project}

Infrastructure as Codeを使用してGitLabからクラスターを作成するには、クラスターを管理するためのプロジェクトを作成する必要があります。このチュートリアルでは、サンプルプロジェクトから開始し、必要に応じて変更します。

[URLでサンプルプロジェクトをインポートする](../../../project/import/repo_by_url.md)ことから始めましょう。

プロジェクトをインポートするには:

1. GitLabの左側のサイドバーで、**検索または移動先**を選択します。
1. **すべてのプロジェクトを表示**を選択します。
1. ページの右側で、**新規プロジェクト**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **リポジトリのURL**を選択します。
1. **GitリポジトリのURL**には、`https://gitlab.com/civocloud/gitlab-terraform-civo.git`を入力してください。
1. フィールドに入力し、**プロジェクトを作成**を選択します。

このプロジェクトでは、以下を使用できます:

- 名前、リージョン、ノード数、Kubernetesバージョンのデフォルト設定を使用した[Civo上のクラスター](https://gitlab.com/civocloud/gitlab-terraform-civo/-/blob/master/civo.tf)。
- クラスターにインストールされている[Kubernetes向けGitLabエージェント](https://gitlab.com/civocloud/gitlab-terraform-civo/-/blob/master/agent.tf)。

## エージェントを登録する {#register-the-agent}

Kubernetes向けGitLabエージェントを作成するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. **クラスターに接続**を選択します。
1. **Select an agent**（エージェントを選択）ドロップダウンリストから、`civo-agent`を選択し、**登録する**を選択します。
1. GitLabは、エージェントのエージェントアクセストークンを生成します。このシークレットトークンは、後で必要になるため、安全に保管してください。
1. GitLabは、エージェントサーバー（KAS）のアドレスを提供します。これも後で必要になります。

## プロジェクトを設定する {#configure-your-project}

CI/CD環境変数を使用して、プロジェクトを設定します。

**Required configuration**（必要な設定）:

1. 左側のサイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. `CIVO_TOKEN`変数をCivoアカウントからのトークンに設定します。
1. `TF_VAR_agent_token`変数を、前のタスクで受信したエージェントトークンに設定します。
1. `TF_VAR_kas_address`変数を、前のタスクのエージェントサーバーアドレスに設定します。

![必要な設定](img/variables_civo_v17_3.png)

**Optional configuration**（オプションの設定）:

ファイル[`variables.tf`](https://gitlab.com/civocloud/gitlab-terraform-civo/-/blob/master/variables.tf)には、必要に応じてオーバーライドできる他の変数が含まれています:

- `TF_VAR_civo_region`: クラスターのリージョンを設定します。
- `TF_VAR_cluster_name`: クラスターの名前を設定します。
- `TF_VAR_cluster_description`: クラスターの説明を設定します。Civoクラスターの詳細ページでGitLabプロジェクトへの参照を作成するには、この値を`$CI_PROJECT_URL`に設定します。この値は、Civoダッシュボードに表示されるクラスターのプロビジョニングを担当したプロジェクトを特定するのに役立ちます。
- `TF_VAR_target_nodes_size`: クラスターに使用するノードのサイズを設定します
- `TF_VAR_num_target_nodes`: Kubernetesノードの数を設定します。
- `TF_VAR_agent_version`: Kubernetes向けGitLabエージェントのバージョンを設定します。
- `TF_VAR_agent_namespace`: Kubernetes向けGitLabエージェントのKubernetesネームスペースを設定します。

その他のリソースオプションについては、[Civo Terraformプロバイダー](https://registry.terraform.io/providers/civo/civo/latest/docs/resources/kubernetes_cluster)および[Kubernetes Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)のドキュメントを参照してください。

## クラスターをプロビジョニングする {#provision-your-cluster}

プロジェクトを設定した後、手動でクラスターのプロビジョニングをトリガーします。GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. **パイプラインを新規作成**を選択します。
1. **パイプラインの実行**を選択し、リストから新しく作成したパイプラインを選択します。
1. **デプロイ**ジョブの横にある**Manual action**（手動アクション）（{{< icon name="status_manual" >}}）を選択します。

パイプラインが正常に終了すると、新しいクラスターが表示されます:

- Civoダッシュボード内：Kubernetesタブ。
- GitLabの場合：プロジェクトのサイドバーから、**操作** > **Kubernetesクラスター**を選択します。

`TF_VAR_civo_region`変数を設定しなかった場合、クラスターは「lon1」リージョンに作成されます。

## クラスターを使用する {#use-your-cluster}

クラスターをプロビジョニングすると、GitLabに接続され、デプロイの準備ができます。接続を確認するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. リストで、**接続ステータス**列を表示します。

接続の機能の詳細については、[Kubernetes向けGitLabエージェントのドキュメント](../_index.md)を参照してください。

## クラスターを削除する {#remove-the-cluster}

クリーンアップジョブは、デフォルトでパイプラインに含まれています。

作成されたすべてのリソースを削除するには:

1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択し、最新のパイプラインを選択します。
1. **destroy-environment**（環境を削除）ジョブの横にある**Manual action**（手動アクション）（{{< icon name="status_manual" >}}）を選択します。

## Civoのサポート {#civo-support}

このCivoインテグレーションはCivoによってサポートされています。[Civoサポート](https://www.civo.com/contact)にサポートリクエストを送信してください。
