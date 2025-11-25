---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: オンデマンドのクラウドベースの開発環境向けにGitLabワークスペースをサポートするために必要なインフラストラクチャを作成します。
title: 'チュートリアル: AWSでワークスペースのインフラストラクチャをセットアップする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、[OpenTofu](https://opentofu.org/)、つまりInfrastructure as Code (IaC) を介したTerraformのオープンソースフォークを使用して、AWS上にGitLabワークスペースのインフラストラクチャをセットアップする方法を説明します。

## はじめる前 {#before-you-begin}

このチュートリアルを実行するには、以下が必要です:

- Amazon Web Services (AWS) のアカウント。
- ワークスペース環境のドメイン名。

GitLabワークスペースのインフラストラクチャをセットアップするには:

1. [リポジトリをフォークする](#fork-the-repository)
1. [AWS認証情報を設定する](#set-up-aws-credentials)
1. [ドメインと証明書を準備する](#prepare-domain-and-certificates)
1. [必要なキーを作成する](#create-required-keys)
1. [Kubernetes向けGitLabエージェント](#create-a-gitlab-agent-for-kubernetes-token)のトークンを作成します
1. [GitLab OAuth](#configure-gitlab-oauth)を設定する
1. [CI/CD変数を設定する](#configure-cicd-variables)
1. [Kubernetes向けGitLabエージェント](#update-the-gitlab-agent-for-kubernetes-configuration)の設定を更新する
1. [パイプライン](#run-the-pipeline)を実行します
1. [DNSレコードを設定する](#configure-dns-records)
1. [エージェントを承認する](#authorize-the-agent)
1. [ワークスペースを作成して設定を確認する](#create-a-workspace-and-verify-setup)

## フォークのリポジトリ {#fork-the-repository}

まず、インフラストラクチャ設定リポジトリの独自のコピーを作成して、自分の環境に合わせて設定できるようにする必要があります。

{{< alert type="note" >}}

個人のネームスペースにあるプロジェクトからワークスペースを作成することはできません。代わりに、リポジトリをトップレベルグループまたはサブグループにフォークします。

{{< /alert >}}

リポジトリをフォークするには:

1. [ワークスペースインフラストラクチャ設定AWS](https://gitlab.com/gitlab-org/workspaces/examples/workspaces-infrastructure-setup-aws)リポジトリに移動します。
1. リポジトリのフォークを作成します。詳細については、[フォーク](../project/repository/forking_workflow.md#create-a-fork)を参照してください

## AWS認証情報を設定する {#set-up-aws-credentials}

次に、インフラストラクチャを適切にプロビジョニングできるように、AWSで必要な権限を設定します。

AWS認証情報を設定するには:

1. [IAMユーザー](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)または[IAMロール](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)を作成します。
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

1. ユーザーまたはロールの[アクセスキーを作成する](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)。
1. アクセスキーのIDとシークレットアクセスキーを保存しますこれらは、後でCI/CD変数を設定するときに必要になります。

## ドメインと証明書を準備する {#prepare-domain-and-certificates}

ワークスペースにアクセスできるようにするには、接続を保護するためのドメインとTLS証明書が必要です。

ドメインと証明書を準備するには:

1. ドメインを購入するか、ワークスペース環境の既存のドメインを使用します。
1. TLS証明書を作成する:
   - GitLabワークスペースプロキシドメイン。たとえば`workspaces.example.dev`などです。
   - GitLabワークスペースプロキシワイルドカードドメイン。たとえば`*.workspaces.example.dev`などです。

詳細については、[TLS証明書を生成する](set_up_gitlab_agent_and_proxies.md#generate-tls-certificates)を参照してください。

## 必要なキーを作成する {#create-required-keys}

次に、認証およびSSH接続用のセキュリティキーを作成する必要があります。

必要なキーを作成するには:

1. ランダムな文字、数字、および特殊文字で構成される署名キーを生成します。例えば、次を実行します:

   ```shell
   openssl rand -base64 32
   ```

1. SSHホストキーを生成する:

   ```shell
   ssh-keygen -f ssh-host-key -N '' -t rsa
   ```

## Kubernetes向けGitLabエージェントのトークンを作成します {#create-a-gitlab-agent-for-kubernetes-token}

Kubernetes向けGitLabエージェントサーバーは、AWS KubernetesクラスタリングをGitLabに接続します。

エージェントのトークンを作成するには:

1. グループに移動します。
1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します
1. **クラスターに接続**を選択します
1. エージェントの名前を入力し、後で使用できるように保存します。たとえば`gitlab-workspaces-agentk-eks`などです。
1. **作成して登録**を選択します。
1. トークンとKASアドレスを保存して、後で使用できるようにします。
1. **次に進む**を選択します。

## GitLab OAuthを設定する {#configure-gitlab-oauth}

次に、OAuth認証を設定して、ワークスペースに安全にアクセスします。

GitLab OAuthを設定するには:

1. **ユーザー設定**に移動します:
   1. プロファイル画像を選択し、**設定**を選択します。
1. 左側のサイドバーで、**アプリケーション**を選択します。
1. **OAuth applications**（OAuthアプリケーション）までスクロールダウンします。
1. **新しいアプリケーションを追加**を選択します。
1. 次の設定を更新します:

   - 名前: GitLabワークスペースプロキシ
   - リダイレクト: たとえば`https://workspaces.example.dev/auth/callback`などです。ユーザー定義ドメインに置き換えます。
   - **非公開**チェックボックスを選択します。
   - スコープ: `api`、`read_user`、`openid`、および`profile`。

1. **アプリケーションを保存**を選択します。
1. CI/CD変数の**アプリケーションID**と**シークレット**を保存します。
1. **次に進む**を選択します。

## CI/CD変数を設定する {#configure-cicd-variables}

次に、インフラストラクチャパイプラインを実行できるように、必要な変数をCI/CD設定に追加する必要があります。

CI/CD変数を設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **プロジェクト変数**セクションで、次の必須変数を追加します:

   | 変数                                       | 値 |
   |------------------------------------------------|-------|
   | `AWS_ACCESS_KEY_ID`                            | AWSアクセスキーのID |
   | `AWS_SECRET_ACCESS_KEY`                        | AWSシークレットアクセスキー |
   | `TF_VAR_agent_token`                           | Kubernetes向けGitLabエージェントのトークン |
   | `TF_VAR_kas_address`                           | GitLab Kubernetesエージェントサーバーのアドレス。GitLab Self-Managedインスタンスを使用している場合は必須です。たとえば`wss://kas.gitlab.com`などです。 |
   | `TF_VAR_workspaces_proxy_auth_client_id`       | OAuthアプリケーションクライアントID。 |
   | `TF_VAR_workspaces_proxy_auth_client_secret`   | OAuthアプリケーションシークレット |
   | `TF_VAR_workspaces_proxy_auth_redirect_uri`    | OAuthコールバックURL。たとえば`https://workspaces.example.dev/auth/callback`などです。 |
   | `TF_VAR_workspaces_proxy_auth_signing_key`     | 生成された署名キー。 |
   | `TF_VAR_workspaces_proxy_domain`               | ワークスペースプロキシのドメイン。 |
   | `TF_VAR_workspaces_proxy_domain_cert`          | プロキシドメインのTLS証明書。 |
   | `TF_VAR_workspaces_proxy_domain_key`           | プロキシドメインのTLSキー。 |
   | `TF_VAR_workspaces_proxy_ssh_host_key`         | 生成されたSSHホストキー。 |
   | `TF_VAR_workspaces_proxy_wildcard_domain`      | ワークスペースのワイルドカードドメイン。 |
   | `TF_VAR_workspaces_proxy_wildcard_domain_cert` | ワイルドカードドメインのTLS証明書。 |
   | `TF_VAR_workspaces_proxy_wildcard_domain_key`  | ワイルドカードドメインのTLSキー。 |

1. オプション。これらの変数を追加して、デプロイをカスタマイズします:

   | 変数                                     | 値 |
   |----------------------------------------------|-------|
   | `TF_VAR_region`                              | AWSリージョン。 |
   | `TF_VAR_zones`                               | AWSアベイラビリティーゾーン |
   | `TF_VAR_name`                                | リソースの名前プレフィックス。 |
   | `TF_VAR_cluster_endpoint_public_access`      | クラスタリングエンドポイントへのパブリックアクセス。 |
   | `TF_VAR_cluster_node_instance_type`          | KubernetesノードのEC2インスタンスタイプ。 |
   | `TF_VAR_cluster_node_count_min`              | ワーカーノードの最小数。 |
   | `TF_VAR_cluster_node_count_max`              | ワーカーノードの最大数 |
   | `TF_VAR_cluster_node_count`                  | ワーカーノードの数。 |
   | `TF_VAR_cluster_node_labels`                 | クラスタリングノードに適用するラベルのマップ。 |
   | `TF_VAR_agent_namespace`                     | エージェントのKubernetesネームスペース。 |
   | `TF_VAR_workspaces_proxy_namespace`          | ワークスペースプロキシのKubernetesネームスペース。 |
   | `TF_VAR_workspaces_proxy_ingress_class_name` | Ingressクラス名。 |
   | `TF_VAR_ingress_nginx_namespace`             | Ingress-NGINXのKubernetesネームスペース。 |

すばらしい出来栄えです。インフラストラクチャデプロイに必要なすべての変数を構成しました。

## Kubernetes向けGitLabエージェントの設定を更新する {#update-the-gitlab-agent-for-kubernetes-configuration}

次に、ワークスペースをサポートするように、Kubernetes向けGitLabエージェントを設定する必要があります。

エージェントの設定を更新するには:

1. フォークリポジトリで、`.gitlab/agents/gitlab-workspaces-agentk-eks/config.yaml`ファイルを開きます。

   {{< alert type="note" >}}

   `config.yaml`ファイルを含むディレクトリは、[Kubernetesトークン用GitLabエージェントの作成](#create-a-gitlab-agent-for-kubernetes-token)ステップで作成したエージェント名と一致する必要があります。

   {{< /alert >}}

1. 次の必須フィールドを使用してファイルを更新します:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "workspaces.example.dev"  # Replace with your domain
   ```

   構成オプションの詳細については、[ワークスペース設定](settings.md)を参照してください。

1. これらの変更をコミットしてリポジトリにプッシュします。

## パイプラインを実行します {#run-the-pipeline}

インフラストラクチャをデプロイする時間です。CI/CDパイプラインを実行して、AWSで必要なすべてのリソースを作成します。

パイプラインを実行するには:

1. GitLabプロジェクトで新しいパイプラインを作成します:
   1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します
   1. **パイプラインを新規作成**を選択し、もう一度**パイプラインを新規作成**を選択して確定します。
1. `plan`ジョブが成功したことを確認し、`apply`ジョブを手動でトリガーします。

OpenTofuコードを実行すると、AWSに次のリソースが作成されます:

- Virtual Private Cloud (VPC)。
- Amazon Elastic Kubernetes Service（Amazon EKS）クラスター
- Kubernetes Helmリリース用GitLabエージェント。
- GitLabワークスペースプロキシHelmリリース。
- Ingress NGINX Helmリリース。

素晴らしい。インフラストラクチャが今、デプロイされています。完了までに時間がかかる場合があります。

## DNSレコードを設定する {#configure-dns-records}

インフラストラクチャがデプロイされたので、新しい環境を指すようにDNSレコードを設定する必要があります。

DNSレコードを設定するには:

1. Ingress-NGINXロードバランサーのアドレスをパイプライン出力から取得します:

   ```shell
   kubectl get services -n ingress-nginx ingress-nginx-controller
   ```

1. ドメインがこのアドレスを指すようにDNSレコードを作成します。例: 
   - `workspaces.example.dev` → ロードバランサーのIPアドレス
   - `*.workspaces.example.dev` → ロードバランサーのIPアドレス

## エージェントを承認する {#authorize-the-agent}

次に、Kubernetes用GitLabエージェントがGitLabインスタンスに接続することを承認します。

エージェントを承認するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **ワークスペース**を選択します。
1. **グループエージェント**セクションで、**すべてのエージェント**タブを選択します。
1. 利用可能なエージェントのリストから、ステータスが**ブロック済み**のエージェントを見つけ、**許可**を選択します。
1. 確認ダイアログで、**エージェントを許可する**を選択します

## ワークスペースを作成して設定を確認する {#create-a-workspace-and-verify-setup}

最後に、テストワークスペースを作成して、すべてが正常に動作していることを確認しましょう。

ワークスペース設定を確認するには:

1. [ワークスペースを作成する](configuration.md#create-a-workspace)の手順に従って、新しいワークスペースを作成します。
1. プロジェクトから**コード**を選択します。
1. ワークスペース名を選択します。
1. Web IDEを開いたり、ターミナルにアクセスしたり、プロジェクトファイルを変更したりして、ワークスペースを操作します。

おつかれさまでした。AWS上にGitLabワークスペースのインフラストラクチャが正常にセットアップされました。これで、ユーザーは自分のプロジェクトの開発ワークスペース環境を作成できます。

問題が発生した場合は、ログで詳細を確認し、ガイダンスについては[トラブルシューティングワークスペース](workspaces_troubleshooting.md)を参照してください。

## 関連トピック {#related-topics}

- [ワークスペース](_index.md)
- [ワークスペースを設定する](configuration.md)
- [ワークスペースの設定](settings.md)
- [チュートリアル: 任意のユーザーIDをサポートするカスタムワークスペースイメージを作成する](create_image.md)
