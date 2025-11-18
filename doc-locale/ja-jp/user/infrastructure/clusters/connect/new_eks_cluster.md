---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Amazon EKSクラスターを作成する
---

[Infrastructure as Code (IaC)](../../_index.md)を使用して、Amazon Elastic Kubernetes Service (EKS)上にクラスターを作成できます。このプロセスでは、AWSとKubernetes Terraformプロバイダーを使用して、EKSクラスターを作成します。Kubernetes向けGitLabエージェントを使用して、GitLabにクラスターを接続します。

**はじめる前**:

- 設定済みの[セキュリティ認証情報](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html)を持つAmazon Web Services（AWS）アカウント。
- [Runner](https://docs.gitlab.com/runner/install/)を使用して、GitLab CI/CDパイプラインを実行できます。

**ステップ**:

1. [サンプルプロジェクトをインポートします](#import-the-example-project)。
1. [Kubernetes用エージェントを登録する](#register-the-agent)。
1. [プロジェクトを設定します](#configure-your-project)。
1. [クラスターをプロビジョニングします](#provision-your-cluster)。

## サンプルプロジェクトをインポートします {#import-the-example-project}

Infrastructure as Codeを使用してGitLabからクラスターを作成するには、クラスターを管理するためのプロジェクトを作成する必要があります。このチュートリアルでは、サンプルプロジェクトから始めて、必要に応じて変更します。

[URLでサンプルプロジェクトをインポートする](../../../project/import/repo_by_url.md)ことから始めます。

プロジェクトをインポートするには:

1. GitLabの左側のサイドバーで、**検索または移動先**を選択します。
1. **すべてのプロジェクトを表示**を選択します。
1. ページの右側にある**新規プロジェクト**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **リポジトリのURL**を選択します。
1. **GitリポジトリのURL**には、`https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks.git`を入力します。
1. フィールドに入力し、**プロジェクトを作成**を選択します。

このプロジェクトは以下を提供します:

- Amazon [Virtual Private Cloud (VPC)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/vpc.tf)。
- Amazon [Elastic Kubernetes Service (Amazon EKS)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/eks.tf)クラスター。
- クラスターにインストールされている[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/agent.tf)。

## エージェントを登録 {#register-the-agent}

{{< history >}}

- GitLab 14.9で[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81054)。`certificate_based_clusters`という名前の[フラグ](../../../../administration/feature_flags/_index.md)は、**アクション**メニューを証明書ではなく、エージェントに焦点を当てるように変更しました。デフォルトでは無効になっています。

{{< /history >}}

Kubernetes用GitLabエージェントを作成するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. **クラスターに接続(エージェント)**を選択します。
1. **Select an agent**（エージェントを選択）ドロップダウンリストから、`eks-agent`を選択し、**エージェントの登録**を選択します。
1. GitLabは、エージェントの登録トークンを生成します。後で必要になるため、このシークレットトークンを安全に保管してください。
1. GitLabは、エージェントサーバー（KAS）のアドレスを提供します。これも後で必要になります。

## AWS認証情報をセットアップ {#set-up-aws-credentials}

GitLabでAWSを認証する場合は、AWS認証情報をセットアップします。

1. [IAMユーザー](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)または[IAMロール](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)を作成します。
1. IAMユーザーまたはロールに、プロジェクトに適した権限があることを確認してください。このサンプルプロジェクトでは、次のJSONブロックにリストされている権限が必要です。独自のプロジェクトをセットアップするときに、これらの権限を展開できます。

   ```json
   // IAM custom Policy definition
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "VisualEditor0",
         "Effect": "Allow",
         "Action": [
           "ec2:*",
           "eks:*",
           "elasticloadbalancing:*",
           "autoscaling:*",
           "cloudwatch:*",
           "logs:*",
           "kms:DescribeKey",
           "kms:TagResource",
           "kms:UntagResource",
           "kms:ListResourceTags",
           "kms:CreateKey",
           "kms:CreateAlias",
           "kms:ListAliases",
           "kms:DeleteAlias",
           "iam:AddRoleToInstanceProfile",
           "iam:AttachRolePolicy",
           "iam:CreateInstanceProfile",
           "iam:CreateRole",
           "iam:CreateServiceLinkedRole",
           "iam:GetRole",
           "iam:ListAttachedRolePolicies",
           "iam:ListRolePolicies",
           "iam:ListRoles",
           "iam:PassRole",
           "iam:DetachRolePolicy",
           "iam:ListInstanceProfilesForRole",
           "iam:DeleteRole",
           "iam:CreateOpenIDConnectProvider",
           "iam:CreatePolicy",
           "iam:TagOpenIDConnectProvider",
           "iam:GetPolicy",
           "iam:GetPolicyVersion",
           "iam:GetOpenIDConnectProvider",
           "iam:DeleteOpenIDConnectProvider",
           "iam:ListPolicyVersions",
           "iam:DeletePolicy"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

1. [ユーザーまたはロールのアクセスキーを作成する](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)。
1. アクセスキーとシークレットを保存します。GitLabでAWSを認証するには、これらが必要です。

## プロジェクトを設定する {#configure-your-project}

CI/CD環境変数を使用して、プロジェクトを設定します。

**Required configuration**（必要な設定）:

1. 左側のサイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. `AWS_ACCESS_KEY_ID`変数をAWSアクセスキーIDに設定します。
1. `AWS_SECRET_ACCESS_KEY`変数をAWSシークレットアクセスキーに設定します。
1. `TF_VAR_agent_token`変数を、前のタスクに表示されるエージェントトークンに設定します。
1. `TF_VAR_kas_address`変数を、前のタスクに表示されるエージェントサーバーアドレスに設定します。

**Optional configuration**（オプションの設定）:

ファイル[`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/variables.tf)には、必要に応じてオーバーライドできる他の変数が含まれています:

- `TF_VAR_region`: クラスターのリージョンを設定します。
- `TF_VAR_cluster_name`: クラスターの名前を設定します。
- `TF_VAR_cluster_version`: Kubernetesのバージョンを設定します。
- `TF_VAR_instance_type`: Kubernetesノードのインスタンスタイプを設定します。
- `TF_VAR_instance_count`: Kubernetesノードの数を設定します。
- `TF_VAR_agent_namespace`: Kubernetes向けGitLabエージェントのKubernetesネームスペースを設定します。

詳細なリソースオプションについては、[AWS Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)および[Kubernetes Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)のドキュメントをご覧ください。

## クラスターをプロビジョニングする {#provision-your-cluster}

プロジェクトを設定したら、クラスターのプロビジョニングを手動でトリガーします。GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**ビルド** > **パイプライン**に移動します。
1. **Play**（Play）（{{< icon name="play" >}}）の横にあるドロップダウンリストアイコン（{{< icon name="chevron-lg-down" >}}）を選択します。
1. **デプロイ**を選択して、デプロイメントジョブを手動でトリガーします。

パイプラインが正常に終了すると、新しいクラスターを表示できます:

- AWS内: [EKSコンソール](https://console.aws.amazon.com/eks/home)から、**Amazon EKS > Clusters**（Amazon EKS > クラスター）を選択します。
- GitLabで、次の手順を実行します: 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。

## クラスターを使用する {#use-your-cluster}

クラスターをプロビジョニングすると、GitLabに接続され、デプロイの準備が整います。接続を確認するには:

1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. リストで、**接続ステータス**列を表示します。

接続の機能の詳細については、[Kubernetes向けGitLabエージェントのドキュメント](../_index.md)を参照してください。

## クラスターを削除 {#remove-the-cluster}

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
1. `destroy`ジョブの場合は、**Play**（Play）（{{< icon name="play" >}}）を選択します。
