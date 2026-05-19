---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: オンデマンドのクラウドベース開発環境向けにGitLabワークスペースをサポートするために必要なインフラストラクチャを作成します。
title: 'チュートリアル: AWSでワークスペースのインフラストラクチャをセットアップする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、GitLabワークスペースのインフラストラクチャをAWS上に、[OpenTofu](https://opentofu.org/)（Terraformのオープンソースフォーク）とInfrastructure as Code（IaC）を使用して設定する方法を説明します。

## はじめる前 {#before-you-begin}

このチュートリアルを進めるには、以下が必要です:

- Amazon Web Services（AWS）アカウント。
- ワークスペース環境用のドメイン名。

GitLabワークスペースインフラストラクチャを設定するには:

1. [リポジトリをフォークする](#fork-the-repository)
1. [AWSの認証情報を設定する](#set-up-aws-credentials)
1. [ドメインと証明書を準備する](#prepare-domain-and-certificates)
1. [必要なキーを作成する](#create-required-keys)
1. [Kubernetes向けGitLabエージェントのトークンを作成する](#create-a-gitlab-agent-for-kubernetes-token)
1. [GitLab OAuthを設定する](#configure-gitlab-oauth)
1. [CI/CD変数を設定する](#configure-cicd-variables)
1. [Kubernetes向けGitLabエージェントの設定を更新する](#update-the-gitlab-agent-for-kubernetes-configuration)
1. [パイプラインを実行する](#run-the-pipeline)
1. [DNSレコードを設定する](#configure-dns-records)
1. [エージェントを承認する](#authorize-the-agent)
1. [ワークスペースを作成してセットアップを確認する](#create-a-workspace-and-verify-setup)

## リポジトリをフォークする {#fork-the-repository}

まず、環境に合わせて設定できるように、インフラストラクチャセットアップリポジトリのコピーを作成する必要があります。

> [!note]
> 個人のネームスペースにあるプロジェクトからワークスペースを作成することはできません。代わりに、リポジトリをトップレベルグループまたはサブグループにフォークします。

リポジトリをフォークするには:

1. [Workspaces Infrastructure Setup AWS](https://gitlab.com/gitlab-org/workspaces/examples/workspaces-infrastructure-setup-aws)リポジトリにアクセスします。
1. リポジトリの[フォーク](../project/repository/forking_workflow.md#create-a-fork)を作成します。

## AWSの認証情報を設定する {#set-up-aws-credentials}

次に、インフラストラクチャが適切にプロビジョニングされるように、AWSで必要な権限を設定します。

AWSの認証情報を設定するには:

1. [IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)または[IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)を作成します。
1. 次の権限を割り当てます:

   ```json
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

1. ユーザーまたはロール用の[アクセスキー](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)を作成します。
1. アクセスキーIDとシークレットアクセスキーを保存します。これらは、CI/CD変数を設定する以降の作業で必要になります。

## ドメインと証明書を準備する {#prepare-domain-and-certificates}

ワークスペースにアクセスできるようにするには、接続を保護するためのドメインとTLS証明書が必要です。

ドメインと証明書を準備するには:

1. ワークスペース環境用のドメインを購入するか、既存のドメインを使用します。
1. 次のTLS証明書を作成します:
   - GitLabワークスペースプロキシドメイン。たとえば、`workspaces.example.dev`などです。
   - GitLabワークスペースプロキシワイルドカードドメイン。たとえば、`*.workspaces.example.dev`などです。

詳細については、[TLS証明書を生成する](set_up_gitlab_agent_and_proxies.md#generate-tls-certificates)を参照してください。

## 必要なキーを作成する {#create-required-keys}

次に、認証とSSH接続用のセキュリティキーを作成する必要があります。

必要なキーを作成するには:

1. ランダムな文字、数字、特殊文字で構成される署名キーを生成します。例: 以下を実行します:

   ```shell
   openssl rand -base64 32
   ```

1. SSHホストキーを生成します:

   ```shell
   ssh-keygen -f ssh-host-key -N '' -t rsa
   ```

## Kubernetes向けGitLabエージェントのトークンを作成する {#create-a-gitlab-agent-for-kubernetes-token}

Kubernetes向けGitLabエージェントは、AWS KubernetesクラスターをGitLabに接続します。

エージェントのトークンを作成するには:

1. あなたのグループに移動します。
1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. **クラスターに接続**を選択します。
1. エージェントの名前を入力し、以降の作業で使用するために保存します。たとえば、`gitlab-workspaces-agentk-eks`などです。
1. **作成して登録**を選択します。
1. トークンとGitLab Relay (KAS) アドレスを後で使用するために保存します。
1. **続行する**を選択します。

## GitLab OAuthを設定する {#configure-gitlab-oauth}

次に、ワークスペースに安全にアクセスするためにOAuth認証を設定します。

GitLab OAuthを設定するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **アプリケーション**を選択します。
1. **OAuth applications**までスクロールします。
1. **新しいアプリケーションを追加**を選択します。
1. 次の設定を更新します:

   - 名前: GitLabワークスペースプロキシ
   - リダイレクトURI: たとえば、`https://workspaces.example.dev/auth/callback`などです。ユーザー定義ドメインに置き換えます。
   - **非公開**チェックボックスを選択します。
   - スコープ: `api`、`read_user`、`openid`、および`profile`。

1. **アプリケーションを保存**を選択します。
1. CI/CD変数のために、**アプリケーションID**と**シークレット**を保存します。
1. **続行する**を選択します。

## CI/CD変数を設定する {#configure-cicd-variables}

次に、インフラストラクチャパイプラインが実行できるように、必要な変数をCI/CDの設定に追加する必要があります。

CI/CD変数を設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **プロジェクト変数**セクションで、次の必須変数を追加します:

   | 変数                                       | 値 |
   |------------------------------------------------|-------|
   | `AWS_ACCESS_KEY_ID`                            | AWSアクセスキーID。 |
   | `AWS_SECRET_ACCESS_KEY`                        | AWSシークレットアクセスキー。 |
   | `TF_VAR_agent_token`                           | Kubernetes向けGitLabエージェントトークン。 |
   | `TF_VAR_kas_address`                           | GitLab Relay (KAS) アドレス。GitLab Self-Managedインスタンスの場合に必須です。たとえば、`wss://kas.gitlab.com`などです。 |
   | `TF_VAR_workspaces_proxy_auth_client_id`       | OAuthアプリケーションクライアントID。 |
   | `TF_VAR_workspaces_proxy_auth_client_secret`   | OAuthアプリケーションシークレット。 |
   | `TF_VAR_workspaces_proxy_auth_redirect_uri`    | OAuthコールバックURL。たとえば、`https://workspaces.example.dev/auth/callback`などです。 |
   | `TF_VAR_workspaces_proxy_auth_signing_key`     | 生成された署名キー。 |
   | `TF_VAR_workspaces_proxy_domain`               | ワークスペースプロキシのドメイン。 |
   | `TF_VAR_workspaces_proxy_domain_cert`          | プロキシドメインのTLS証明書。 |
   | `TF_VAR_workspaces_proxy_domain_key`           | プロキシドメインのTLSキー。 |
   | `TF_VAR_workspaces_proxy_ssh_host_key`         | 生成されたSSHホストキー。 |
   | `TF_VAR_workspaces_proxy_wildcard_domain`      | ワークスペースのワイルドカードドメイン。 |
   | `TF_VAR_workspaces_proxy_wildcard_domain_cert` | ワイルドカードドメインのTLS証明書。 |
   | `TF_VAR_workspaces_proxy_wildcard_domain_key`  | ワイルドカードドメインのTLSキー。 |

1. オプション。デプロイをカスタマイズするには、次のいずれかの変数を追加します:

   | 変数                                     | 値 |
   |----------------------------------------------|-------|
   | `TF_VAR_region`                              | AWSリージョン。 |
   | `TF_VAR_zones`                               | AWSアベイラビリティゾーン。 |
   | `TF_VAR_name`                                | リソースの名前プレフィックス。 |
   | `TF_VAR_cluster_endpoint_public_access`      | クラスターエンドポイントへのパブリックアクセス。 |
   | `TF_VAR_cluster_node_instance_type`          | Kubernetesノード用のEC2インスタンスタイプ。 |
   | `TF_VAR_cluster_node_count_min`              | 最小ワーカーノード数。 |
   | `TF_VAR_cluster_node_count_max`              | 最大ワーカーノード数。 |
   | `TF_VAR_cluster_node_count`                  | ワーカーノード数。 |
   | `TF_VAR_cluster_node_labels`                 | クラスターノードに適用するラベルのマップ。 |
   | `TF_VAR_agent_namespace`                     | エージェント用のKubernetesネームスペース。 |
   | `TF_VAR_workspaces_proxy_namespace`          | ワークスペースプロキシ用のKubernetesネームスペース。 |
   | `TF_VAR_workspaces_proxy_ingress_class_name` | Ingressクラス名。 |
   | `TF_VAR_ingress_nginx_namespace`             | Ingress-NGINX用のKubernetesネームスペース。 |

素晴らしいです！インフラストラクチャのデプロイに必要なすべての変数を設定しました。

## Kubernetes向けGitLabエージェントの設定を更新する {#update-the-gitlab-agent-for-kubernetes-configuration}

次に、Kubernetes向けGitLabエージェントがワークスペースをサポートするように設定する必要があります。

エージェントの設定を更新するには:

1. フォークしたリポジトリで、`.gitlab/agents/gitlab-workspaces-agentk-eks/config.yaml`ファイルを開きます。

   > [!note]
   > `config.yaml`ファイルを含むディレクトリは、[Kubernetes向けGitLabエージェントのトークンを作成する](#create-a-gitlab-agent-for-kubernetes-token)ステップで作成したエージェント名と一致している必要があります。

1. 次の必須フィールドでファイルを更新します:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "workspaces.example.dev"  # Replace with your domain
   ```

   その他の設定オプションについては、[ワークスペースの設定](settings.md)を参照してください。

1. これらの変更をリポジトリにコミットしてプッシュします。

## パイプラインを実行する {#run-the-pipeline}

インフラストラクチャをデプロイする時が来ました。CI/CDパイプラインを実行して、AWSに必要なすべてのリソースを作成します。

パイプラインを実行するには:

1. GitLabプロジェクトで新しいパイプラインを作成します:
   1. 左サイドバーで、**ビルド** > **パイプライン**を選択します。
   1. **新しいパイプライン**を選択し、再度**新しいパイプライン**を選択して確認します。
1. `plan`ジョブが成功したことを確認し、`apply`ジョブを手動でトリガーします。

OpenTofuコードが実行されると、AWSに次のリソースが作成されます:

- Virtual Private Cloud（VPC）。
- Amazon Elastic Kubernetes Service（EKS）クラスター。
- Kubernetes向けGitLabエージェントHelmリリース。
- GitLabワークスペースプロキシHelmリリース。
- Ingress NGINX Helmリリース。

素晴らしい！インフラストラクチャが現在デプロイされています。これには時間がかかる場合があります。

## DNSレコードを設定する {#configure-dns-records}

インフラストラクチャがデプロイされたので、新しい環境を指すようにDNSレコードを設定する必要があります。

DNSレコードを設定するには:

1. パイプラインの出力からIngress-NGINXロードバランサーのアドレスを取得します:

   ```shell
   kubectl get services -n ingress-nginx ingress-nginx-controller
   ```

1. ドメインをこのアドレスにポイントするDNSレコードを作成します。例: 
   - `workspaces.example.dev` → ロードバランサーのIPアドレス
   - `*.workspaces.example.dev` → ロードバランサーのIPアドレス

## エージェントを承認する {#authorize-the-agent}

次に、Kubernetes向けGitLabエージェントがGitLabインスタンスに接続することを承認します。

エージェントを承認するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **ワークスペース**を選択します。
1. **グループエージェント**セクションで、**すべてのエージェント**タブを選択します。
1. 利用可能なエージェントのリストから、ステータスが**ブロック済み**のエージェントを見つけて、**許可**を選択します。
1. 確認ダイアログで、**エージェントを許可する**を選択します。

## ワークスペースを作成してセットアップを確認する {#create-a-workspace-and-verify-setup}

最後に、テストワークスペースを作成して、すべてが正常に機能していることを確認しましょう。

ワークスペースのセットアップを確認するには:

1. [ワークスペースを作成する](configuration.md#create-a-workspace)の手順に従って、新しいワークスペースを作成します。
1. プロジェクトから、**コード**を選択します。
1. ワークスペース名を選択します。
1. Web IDEを開く、ターミナルにアクセスする、またはプロジェクトファイルを変更することで、ワークスペースを操作します。

おつかれさまでした。AWS上にGitLabワークスペースインフラストラクチャを正常にセットアップしました。これで、ユーザーは自分のプロジェクト用に開発ワークスペース環境を作成できるようになりました。

イシューが発生した場合は、ログで詳細を確認し、[ワークスペースのトラブルシューティング](workspaces_troubleshooting.md)を参照してガイダンスを得てください。

## 関連トピック {#related-topics}

- [ワークスペース](_index.md)
- [ワークスペースを設定する](configuration.md)
- [ワークスペースの設定](settings.md)
- [チュートリアル: 任意のユーザーIDをサポートするカスタムワークスペースイメージを作成する](create_image.md)
