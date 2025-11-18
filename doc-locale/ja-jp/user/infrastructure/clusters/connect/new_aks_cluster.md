---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Azure AKSクラスターの作成
---

[Infrastructure as Code（IaC）](../../_index.md)を使用して、Azure Kubernetes Service（AKS）でクラスターを作成できます。このプロセスでは、AzureおよびKubernetes Terraformプロバイダーを使用して、AKSクラスターを作成します。クラスターをKubernetes向けGitLabエージェントを使用してGitLabに接続します。

**はじめる前**:

- 構成済みの[セキュリティ認証情報](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli)が設定されたMicrosoft Azureアカウント。
- [Runner](https://docs.gitlab.com/runner/install/)を使用して、GitLab CI/CDパイプラインを実行できます。

**ステップ**:

1. [サンプルプロジェクトをインポートする](#import-the-example-project)。
1. [Kubernetes用エージェントを登録する](#register-the-agent)。
1. [プロジェクトを設定する](#configure-your-project)。
1. [クラスターをプロビジョニングする](#provision-your-cluster)。

## サンプルプロジェクトをインポートする {#import-the-example-project}

Infrastructure as Codeを使用してGitLabからクラスターを作成するには、クラスターを管理するプロジェクトを作成する必要があります。このチュートリアルでは、サンプルプロジェクトから開始し、必要に応じて変更します。

[URLでサンプルプロジェクトをインポートする](../../../project/import/repo_by_url.md)ことから始めます。

プロジェクトをインポートするには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **リポジトリのURL**を選択します。
1. **GitリポジトリのURL**には、`https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks.git`と入力します。
1. フィールドに入力し、**プロジェクトを作成**を選択します。

このプロジェクトでは、以下が提供されます:

- [Azure Kubernetes Service（AKS）](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks/-/blob/main/aks.tf)クラスター。
- クラスターにインストールされている[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks/-/blob/main/agent.tf)。

## エージェントを登録する {#register-the-agent}

Kubernetes用GitLabエージェントを作成するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. **クラスターに接続(エージェント)**を選択します。
1. **Select an agent**（エージェントを選択）ドロップダウンリストから`aks-agent`を選択し、**エージェントの登録**を選択します。
1. GitLabは、エージェントの登録トークンを生成します。後で必要になるため、このシークレットトークンを安全に保管してください。
1. GitLabは、エージェントサーバー（KAS）のアドレスを提供します。これも後で必要になります。

## プロジェクトを設定する {#configure-your-project}

CI/CD環境変数を使用してプロジェクトを設定します。

**Required configuration**（必要な設定）:

1. 左側のサイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. 変数`ARM_CLIENT_ID`をAzureクライアントIDに設定します。
1. 変数`ARM_CLIENT_SECRET`をAzureクライアントシークレットに設定します。
1. 変数`ARM_TENANT_ID`をサービスプリンシパルに設定します。
1. 変数`TF_VAR_agent_token`を、前のタスクに表示されるエージェントトークンに設定します。
1. 変数`TF_VAR_kas_address`を、前のタスクに表示されるエージェントサーバーアドレスに設定します。

**Optional configuration**（オプションの設定）:

ファイル[`variables.tf`](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks/-/blob/main/variables.tf)には、必要に応じてオーバーライドできる他の変数が含まれています:

- `TF_VAR_location`: クラスターのリージョンを設定します。
- `TF_VAR_cluster_name`: クラスターの名前を設定します。
- `TF_VAR_kubernetes_version`: Kubernetesのバージョンを設定します。
- `TF_VAR_create_resource_group`: 新しいリソースグループの作成を有効または無効にすることができます。（デフォルトはtrueに設定されています）。
- `TF_VAR_resource_group_name`: リソースグループの名前を設定します。
- `TF_VAR_agent_namespace`: Kubernetes向けGitLabエージェントのKubernetesネームスペースを設定します。

詳細なリソースオプションについては、[Azure Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)および[Kubernetes Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)のドキュメントを参照してください。

## クラスターをプロビジョニングする {#provision-your-cluster}

プロジェクトを設定したら、手動でクラスターのプロビジョニングをトリガーします。GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. **Play**（Play）（{{< icon name="play" >}}）の横にある、ドロップダウンリストのアイコン（{{< icon name="chevron-lg-down" >}}）を選択します。
1. **デプロイ**を選択して、デプロイメントジョブを手動でトリガーします。

パイプラインが正常に完了すると、新しいクラスターを表示できます:

- Azureの場合: [Azure portal](https://portal.azure.com/#home)から、**Kubernetes services > View**を選択します。
- GitLabで、次の手順を実行します: 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。

## クラスターを使用する {#use-your-cluster}

クラスターをプロビジョニングすると、GitLabに接続され、デプロイの準備が整います。接続を確認するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. リストで、**接続ステータス**列を表示します。

接続の機能の詳細については、[Kubernetes向けGitLabエージェントのドキュメント](../_index.md)を参照してください。

## クラスターを削除する {#remove-the-cluster}

クリーンアップジョブは、デフォルトではパイプラインに含まれていません。作成されたすべてのリソースを削除するには、クリーンアップジョブを実行する前に、GitLab CI/CDテンプレートを変更する必要があります。

すべてのリソースを削除するには:

1. 次の内容を`.gitlab-ci.yml`ファイルに追加します:

   ```yaml
   stages:
     - init
     - validate
     - test
     - build
     - deploy
     - cleanup

   destroy:
     extends: .terraform:destroy
     needs: []
   ```

1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択し、最新のパイプラインを選択します。
1. `destroy`ジョブで、**Play**（Play）（{{< icon name="play" >}}）を選択します。
