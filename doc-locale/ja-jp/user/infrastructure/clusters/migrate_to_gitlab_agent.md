---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes向けGitLabエージェントへの移行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabとKubernetesクラスターを接続するには、以下を使用できます:

- [GitOpsワークフロー](../../clusters/agent/gitops.md)。
- [GitLab CI/CDワークフロー](../../clusters/agent/ci_cd_workflow.md)。
- [証明書ベースのインテグレーション](_index.md)。

証明書ベースのインテグレーションはGitLab 14.5で[**非推奨**](https://about.gitlab.com/blog/deprecating-the-cert-based-kubernetes-integration/)です。サービス終了計画は以下に記載されています:

- [GitLab.comユーザー](../../../update/deprecations.md#gitlabcom-certificate-based-integration-with-kubernetes)向け。
- [GitLab Self-Managedユーザー](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes)向け。

証明書ベースのインテグレーションを使用している場合は、できるだけ早く別のワークフローに移行する必要があります。

一般的なルールとして、GitLab CI/CDに依存するクラスターを移行する移行するには、[CI/CDワークフロー](../../clusters/agent/ci_cd_workflow.md)を使用できます。このワークフローは、エージェントを使用してクラスターに接続します。エージェント:

- インターネットに公開されません。
- GitLabへの完全な[`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)アクセスを必要としません。

> [!note]
> 証明書ベースのインテグレーションは、GitLabマネージドApp、GitLabマネージドクラスター、Auto DevOpsなどの一般的なGitLab機能に使用されていました。

## 証明書ベースのクラスターを検索 {#find-certificate-based-clusters}

GitLabインスタンスまたはグループ内にあるすべての証明書ベースのクラスター（サブグループやプロジェクトを含む）は、[専用のAPI](../../../api/cluster_discovery.md#retrieve-certificate-based-clusters)を使用して検索できます。グループIDでAPIをクエリすると、指定されたグループまたはその下に定義されているすべての証明書ベースのクラスターが返されます。

この場合、親グループに定義されているクラスターは返されません。この動作により、グループオーナーは移行する必要のあるすべてのクラスターを見つけることができます。

誤ってクラスターが残されることを避けるため、無効化されたクラスターも返されます。

> [!note]
> クラスター検出APIは個人ネームスペースでは動作しません。

## 一般的なデプロイを移行する {#migrate-generic-deployments}

一般的なデプロイを移行するには:

1. [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
1. CI/CDワークフローに従って、[エージェントにグループとプロジェクトへのアクセスを許可する](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)か、[代理でアクセスを保護](../../clusters/agent/ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation)します。
1. 左サイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターをオフにします。

## GitLabマネージドクラスターからKubernetesリソースへの移行する {#migrate-from-gitlab-managed-clusters-to-kubernetes-resources}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

GitLabマネージドクラスターを使用すると、GitLabはブランチごとに個別のサービスアカウントとネームスペースを作成し、これらのリソースを使用してデプロイします。

これで、[GitLabマネージドKubernetesリソース](../../clusters/agent/managed_kubernetes_resources.md)を使用して、強化されたセキュリティ制御でリソースをセルフサービスで利用できます。

GitLabマネージドKubernetesリソースを使用すると、以下のことが可能です:

- 手動での介入なしに、安全に環境を設定できます。
- デベロッパーに管理クラスター権限を与えることなく、リソースの作成とアクセスを制御できます。
- 新しいプロジェクトや環境を作成する際に、デベロッパーにセルフサービス機能を提供します。
- デベロッパーが専用または共有のネームスペースにテストおよび開発バージョンをデプロイできるようにします。

前提条件: 

- [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
- [エージェントのアクセスを承認](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)し、関連するプロジェクトまたはグループにアクセスさせます。
- 証明書ベースのクラスターインテグレーションページで、**環境ごとのネームスペース**チェックボックスのステータスを確認します。

GitLabマネージドクラスターからGitLabマネージドKubernetesリソースへ移行するには:

1. 既存の環境を移行する場合は、[Kubernetes用ダッシュボード](../../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard)または[環境API](../../../api/environments.md)のいずれかを使用して、環境用のエージェントを設定します。
1. エージェント設定ファイルでリソース管理を有効にするようにエージェントを設定します:

   ```yaml
   ci_access:
      projects:
        - id: <your_group/your_project>
          access_as:
            ci_job: {}
          resource_management:
            enabled: true
      groups:
        - id: <your_other_group>
          access_as:
            ci_job: {}
          resource_management:
            enabled: true
   ```

1. `.gitlab/agents/<agent-name>/environment_templates/default.yaml`の下に環境テンプレートを作成します。証明書ベースのクラスターインテグレーションページで、**環境ごとのネームスペース**チェックボックスのステータスを確認します。

   **環境ごとのネームスペース**がチェックされていた場合は、以下のテンプレートを使用します:

   ```yaml
   objects:
     - apiVersion: v1
       kind: Namespace
       metadata:
         # the `.legacy_namespace` produces something like:
         # '{{ .project.slug }}-{{ .project.id }}-{{ .environment.slug }}'
         # that is compatible with what the certificate-based cluster integration
         # would have generated.
         name: '{{ .legacy_namespace }}'
     - apiVersion: rbac.authorization.k8s.io/v1
       kind: RoleBinding
       metadata:
         name: 'bind-{{ .agent.id }}-{{ .project.id }}-{{ .environment.slug }}'
         namespace: '{{ .legacy_namespace }}'
       subjects:
         - kind: Group
           apiGroup: rbac.authorization.k8s.io
           name: 'gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}'
       roleRef:
         apiGroup: rbac.authorization.k8s.io
         kind: ClusterRole
         name: admin
   ```

   **環境ごとのネームスペース**がチェックされていなかった場合は、以下のテンプレートを使用します:

   ```yaml
   objects:
     - apiVersion: v1
       kind: Namespace
       metadata:
         name: '{{ .project.slug | slugify }}-{{ .project.id }}'
     - apiVersion: rbac.authorization.k8s.io/v1
       kind: RoleBinding
       metadata:
         name: 'bind-{{ .agent.id }}-{{ .project.id }}-{{ .environment.slug }}'
         namespace: '{{ .project.slug | slugify }}-{{ .project.id }}'
       subjects:
         - kind: Group
           apiGroup: rbac.authorization.k8s.io
           name: 'gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}'
       roleRef:
         apiGroup: rbac.authorization.k8s.io
         kind: ClusterRole
         name: admin
   ```

1. CI/CDの設定で、`environment.kubernetes.agent: <path/to/agent/project:agent-name>`構文を使用してエージェントを使用します。
1. 左サイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターをオフにします。

## Auto DevOpsからの移行する {#migrate-from-auto-devops}

Auto DevOpsプロジェクトで、Kubernetes向けGitLabエージェントを使用してKubernetesクラスターに接続できます。

前提条件

- [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
- [エージェントのアクセスを承認](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)し、関連するプロジェクトまたはグループにアクセスさせます。

Auto DevOpsから移行するには:

1. GitLabで、Auto DevOpsを使用しているプロジェクトに移動します。
1. 3つの変数を追加します。左サイドバーで、**設定** > **CI/CD**を選択し、**変数**を展開するします。
   - アプリケーションデプロイドメインを値として、`KUBE_INGRESS_BASE_DOMAIN`というキーを追加します。
   - `path/to/agent/project:agent-name`のような値を持つ`KUBE_CONTEXT`というキーを追加します。任意の環境スコープを選択します。エージェントのコンテキストがわからない場合は、`.gitlab-ci.yml`ファイルを編集し、利用可能なコンテキストを確認するためのジョブを追加します:

     ```yaml
     deploy:
       image: debian:13-slim
       variables:
         KUBECTL_VERSION: v1.34
         DEBIAN_FRONTEND: noninteractive
       script:
         # Follows https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
         - apt-get update
         - apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg
         - curl --fail --silent --show-error --location "https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/Release.key" | gpg --dearmor --output /etc/apt/keyrings/kubernetes-apt-keyring.gpg
         - chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
         - echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
         - chmod 644 /etc/apt/sources.list.d/kubernetes.list
         - apt-get update
         - apt-get install -y --no-install-recommends kubectl
         - kubectl config get-contexts
      ```

   - ターゲットとするデプロイ用のKubernetesネームスペースの値を、`KUBE_NAMESPACE`というキーに追加します。同じ環境スコープを設定します。
1. **変数を追加**を選択します。
1. 左サイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターを無効にします。
1. `.gitlab-ci.yml`ファイルを編集し、Auto DevOpsテンプレートを使用していることを確認します。例: 

   ```yaml
   include:
     template: Auto-DevOps.gitlab-ci.yml

   variables:
     KUBE_INGRESS_BASE_DOMAIN: 74.220.23.215.nip.io
     KUBE_CONTEXT: "gitlab-examples/ops/gitops-demo/k8s-agents:demo-agent"
     KUBE_NAMESPACE: "demo-agent"
   ```

1. パイプラインをテストするには、左サイドバーで**ビルド** > **パイプライン**、そして**新しいパイプライン**を選択します。

例として、[このプロジェクト](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)をご覧ください。

## GitLabマネージドアプリケーションからの移行する {#migrate-from-gitlab-managed-applications}

GitLabマネージドApp (GMA) はGitLab 14.0で非推奨となり、GitLab 15.0で削除されました。Kubernetes用エージェントはそれらをサポートしていません。GMAからエージェントへ移行するには、以下の手順を実行します:

1. [GitLabマネージドAppからクラスター管理プロジェクトへ移行する](../../clusters/migrating_from_gma_to_project_template.md)。
1. [クラスター管理プロジェクトをエージェントを使用するように移行する](../../clusters/management_project_template.md)。

## クラスター管理プロジェクトを移行する {#migrate-a-cluster-management-project}

[Kubernetes向けGitLabエージェントでクラスター管理プロジェクトを使用する方法](../../clusters/management_project_template.md)をご覧ください。

## クラスターモニタリング機能の移行する {#migrate-cluster-monitoring-features}

KubernetesクラスターをKubernetes用エージェントを使用してGitLabに接続すると、[ユーザーアクセス](../../clusters/agent/user_access.md)を有効にした後、[Kubernetes用ダッシュボード](../../../ci/environments/kubernetes_dashboard.md)を使用できます。
