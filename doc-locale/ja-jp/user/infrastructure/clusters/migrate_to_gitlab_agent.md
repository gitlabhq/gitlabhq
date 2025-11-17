---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes用GitLabエージェントに移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

KubernetesクラスターをGitLabに接続するには、次の方法があります:

- [GitOps](../../clusters/agent/gitops.md)ワークフロー
- [GitLab CI/CD](../../clusters/agent/ci_cd_workflow.md)ワークフロー
- [証明書ベースのインテグレーション](_index.md)。

証明書ベースのインテグレーションは、GitLabバージョン14.5で[**非推奨**](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)になりました。段階的廃止の計画は次のとおりです:

- [GitLab.comをご利用のお客様](../../../update/deprecations.md#gitlabcom-certificate-based-integration-with-kubernetes)向け。
- [GitLabセルフマネージドをご利用のお客様](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes)向け。

証明書ベースのインテグレーションを使用している場合は、できるだけ早く別のワークフローに移行してください。

一般的なルールとして、GitLab CI/CDに依存するクラスターを移行するには、[CI/CDワークフロー](../../clusters/agent/ci_cd_workflow.md)を使用できます。このワークフローでは、クラスターへの接続にエージェントを使用します。エージェント:

- インターネットに公開されていません。
- GitLabへの完全な[`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)アクセスを必要としません。

{{< alert type="note" >}}

証明書ベースのインテグレーションは、GitLab管理アプリケーション、GitLab管理クラスター、Auto DevOpsなどの一般的なGitLab機能に使用されていました。

{{< /alert >}}

## 証明書ベースのクラスターを検索 {#find-certificate-based-clusters}

サブグループやプロジェクトを含む、GitLabインスタンスまたはグループ内のすべての証明書ベースのクラスターを検索するには、[専用のAPI](../../../api/cluster_discovery.md#discover-certificate-based-clusters)を使用します。グループIDを使用してAPIをクエリすると、指定されたグループ以下で定義されているすべての証明書ベースのクラスターが返されます。

この場合、親グループで定義されたクラスターは返されません。この動作は、グループのオーナーが移行に必要なすべてのクラスターを見つけるのに役立ちます。

無効になっているクラスターも、誤ってクラスターを置き去りにしないように、同様に返されます。

{{< alert type="note" >}}

クラスター検出APIは、個人のネームスペースでは機能しません。

{{< /alert >}}

## 一般的なデプロイを移行する {#migrate-generic-deployments}

一般的なデプロイを移行するには:

1. [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
1. CI/CDワークフローに従って、[エージェントがアクセスを承認](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)するようにグループとプロジェクトを設定するか、[代理でアクセスを保護](../../clusters/agent/ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation)します。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターをオフにします。

## GitLab管理クラスターからKubernetesリソースへの移行 {#migrate-from-gitlab-managed-clusters-to-kubernetes-resources}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

GitLab管理クラスターを使用すると、GitLabはすべてのブランチとデプロイに対して個別のサービスアカウントとネームスペースを作成し、これらのリソースを使用してデプロイします。

[GitLab管理のKubernetesリソース](../../clusters/agent/managed_kubernetes_resources.md)を使用すると、強化されたセキュリティ制御でリソースをセルフサービスできます。

GitLab管理のKubernetesリソースを使用すると、次のことができます:

- 手動で介入することなく、環境を安全にセットアップします。
- デベロッパーに管理クラスターの権限を付与せずに、リソースの作成とアクセスを制御します。
- デベロッパーが新しいプロジェクトまたは環境を作成するときに、セルフサービス機能を提供します。
- デベロッパーが専用または共有ネームスペースでテストバージョンと開発バージョンをデプロイできるようにします。

前提要件:

- [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
- 関連するプロジェクトまたはグループへのアクセスを[エージェントに承認](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)します。
- 証明書ベースのクラスターインテグレーションページの**環境ごとのネームスペース**チェックボックスの状態を確認します。

GitLab管理クラスターからGitLab管理のKubernetesリソースに移行するには:

1. 既存の環境を移行する場合は、[Kubernetesのダッシュボード](../../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard)または[環境API](../../../api/environments.md)のいずれかを介して、環境のエージェントを設定します。
1. エージェントの設定ファイルでリソース管理をオンにするようにエージェントを設定します:

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

1. `.gitlab/agents/<agent-name>/environment_templates/default.yaml`の下に環境テンプレートを作成します。証明書ベースのクラスターインテグレーションページの**環境ごとのネームスペース**チェックボックスの状態を確認します。

   **環境ごとのネームスペース**がオンになっている場合は、次のテンプレートを使用します:

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

   **環境ごとのネームスペース**がオフになっている場合は、次のテンプレートを使用します:

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

1. CI/CD設定では、`environment.kubernetes.agent: <path/to/agent/project:agent-name>`構文でエージェントを使用します。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターをオフにします。

## Auto DevOpsから移行 {#migrate-from-auto-devops}

Auto DevOpsプロジェクトでは、Kubernetes向けGitLabエージェントを使用してKubernetesクラスターに接続できます。

前提要件

- [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
- 関連するプロジェクトまたはグループへのアクセスを[エージェントに承認](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)します。

Auto DevOpsから移行するには:

1. GitLabで、Auto DevOpsを使用するプロジェクトに移動します。
1. 3つの変数を追加します。左側のサイドバーで、**設定** > **CI/CD**を選択し、**変数**を展開します。
   - アプリケーションデプロイドメインを値として、`KUBE_INGRESS_BASE_DOMAIN`というキーを追加します。
   - `path/to/agent/project:agent-name`のような値を持つ`KUBE_CONTEXT`というキーを追加します。任意の環境スコープを選択します。エージェントのコンテキストが不明な場合は、`.gitlab-ci.yml`ファイルを編集し、ジョブを追加して、使用可能なコンテキストを確認します:

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

   - デプロイのターゲットとするKubernetesネームスペースの値を指定して、`KUBE_NAMESPACE`というキーを追加します。同じ環境スコープを設定します。
1. **変数を追加する**を選択します。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターを無効にします。
1. `.gitlab-ci.yml`ファイルを編集し、Auto DevOpsテンプレートを使用していることを確認します。次に例を示します: 

   ```yaml
   include:
     template: Auto-DevOps.gitlab-ci.yml

   variables:
     KUBE_INGRESS_BASE_DOMAIN: 74.220.23.215.nip.io
     KUBE_CONTEXT: "gitlab-examples/ops/gitops-demo/k8s-agents:demo-agent"
     KUBE_NAMESPACE: "demo-agent"
   ```

1. パイプラインをテストするには、左側のサイドバーで**ビルド** > **パイプライン**、**パイプラインを新規作成**の順に選択します。

例については、[このプロジェクトを表示](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)してください。

## GitLab管理アプリケーションから移行 {#migrate-from-gitlab-managed-applications}

GitLab管理アプリケーション（GMA）はGitLab 14.0で非推奨となり、GitLab 15.0で削除されました。Kubernetes向けエージェントはそれらをサポートしていません。GMAからエージェントに移行するには、次の手順を実行します:

1. [GitLab管理アプリケーションからクラスター管理プロジェクトに移行します](../../clusters/migrating_from_gma_to_project_template.md)。
1. [クラスター管理プロジェクトを移行してエージェントを使用します](../../clusters/management_project_template.md)。

## クラスター管理プロジェクトを移行する {#migrate-a-cluster-management-project}

[Kubernetes向けGitLabエージェントでクラスター管理プロジェクトを使用する方法](../../clusters/management_project_template.md)を参照してください。

## クラスターモニタリング機能を移行する {#migrate-cluster-monitoring-features}

KubernetesクラスターをKubernetes向けGitLabエージェントを使用してGitLabに接続すると、[Kubernetesのダッシュボード](../../../ci/environments/kubernetes_dashboard.md)を有効にした後、[ユーザーアクセス](../../clusters/agent/user_access.md)を使用できます。
