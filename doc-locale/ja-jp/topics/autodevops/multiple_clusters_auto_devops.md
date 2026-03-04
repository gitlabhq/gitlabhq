---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Auto DevOpsの複数のKubernetesクラスター
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Auto DevOpsを使用すると、異なる環境を異なるKubernetesクラスターにデプロイできます。

Auto DevOpsで使用される[Deploy Job template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)は、3つの環境名を定義します:

- `review/` （`review/`で始まるすべての環境）
- `staging`
- `production`

これらの環境は[自動デプロイ](stages.md#auto-deploy)を使用してジョブに関連付けられているため、異なるデプロイドメインが必要です。3つの環境それぞれに対して、個別の[`KUBE_CONTEXT`](../../user/clusters/agent/ci_cd_workflow.md#environments-that-use-auto-devops)変数と[`KUBE_INGRESS_BASE_DOMAIN`](requirements.md#auto-devops-base-domain)変数を定義する必要があります。

## 異なるクラスターへのデプロイ {#deploy-to-different-clusters}

環境を異なるKubernetesクラスターにデプロイするには、次の手順を実行します:

1. [OpenTofuとGitLabでKubernetesクラスターを作成](../../user/infrastructure/iac/_index.md)。
1. プロジェクトにクラスターを関連付けます:
   1. [各クラスターにKubernetes向けGitLabエージェントをインストール](../../user/clusters/agent/_index.md)。
   1. [各エージェントがプロジェクトにアクセスするように設定](../../user/clusters/agent/work_with_agent.md#configure-your-agent)。
1. 各クラスターに[NGINX Ingressコントローラーをインストール](cloud_deployments/auto_devops_with_gke.md#install-ingress)。次の手順のために、IPアドレスとKubernetesネームスペースを保存します。
1. [Auto DevOps CI/CDパイプライン変数を設定する](cicd_variables.md#build-and-deployment-variables)
   - `KUBE_CONTEXT`変数を[環境ごとに](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)設定します。値は、関連するクラスターのエージェントを指している必要があります。
   - `KUBE_INGRESS_BASE_DOMAIN`を設定します。関連するクラスターのIngressを指すように、環境ごとに[ベースドメインを設定](requirements.md#auto-devops-base-domain)する必要があります。
   - デプロイのターゲットとするKubernetesネームスペースの値を持つ`KUBE_NAMESPACE`変数を追加します。変数のスコープを複数の環境に設定できます。

[非推奨の証明書ベースのクラスター](../../user/infrastructure/clusters/_index.md#certificate-based-kubernetes-integration-deprecated)の場合:

1. プロジェクトに移動し、左側のサイドバーから**操作** > **Kubernetesクラスター**を選択します。
1. [各クラスターの環境スコープを設定](../../user/project/clusters/multiple_kubernetes_clusters.md#setting-the-environment-scope)。
1. 各クラスターについて、[Ingress IPアドレスに基づいてドメインを追加](../../user/project/clusters/gitlab_managed_clusters.md#base-domain)。

> [!note] 
> [アクティブなKubernetesクラスターをチェックする際に、クラスター環境スコープは考慮されません](https://gitlab.com/gitlab-org/gitlab/-/issues/20351)。マルチクラスター構成をAuto DevOpsで使用するには、**Cluster environment scope**を`*`に設定してフォールバッククラスターを作成する必要があります。既に追加したクラスターをフォールバッククラスターとして設定できます。

### 設定例 {#example-configurations}

| クラスター名 | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN`の値 | `KUBE CONTEXT`の値               | Variable environment scope | 備考 |
|:-------------|:--------------------------|:---------------------------------|:-----------------------------------|:---------------------------|:------|
| レビュー       | `review/*`                | `review.example.com`             | `path/to/project:review-agent`     | `review/*`                 | すべての[レビューアプリ](../../ci/review_apps/_index.md)を実行するレビュークラスター。 |
| ステージング      | `staging`                 | `staging.example.com`            | `path/to/project:staging-agent`    | `staging`                  | オプション。ステージング環境のデプロイを実行するステージングクラスター。[最初に有効にする](cicd_variables.md#deploy-policy-for-staging-and-production-environments)必要があります。 |
| 本番環境   | `production`              | `example.com`                    | `path/to/project:production-agent` | `production`               | 本番環境環境デプロイを実行する本番環境クラスター。[段階的なロールアウト](cicd_variables.md#incremental-rollout-to-production)を使用できます。 |

## 設定をテストする {#test-your-configuration}

構成が完了したら、マージリクエストを作成してセットアップをテストします。アプリケーションが`review/*`環境スコープを持つKubernetesクラスターのレビューアプリとしてデプロイされているかどうかを確認します。同様に、他の環境も確認します。
