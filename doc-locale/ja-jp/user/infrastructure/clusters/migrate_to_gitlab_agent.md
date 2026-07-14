---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes向けGitLabエージェントへ移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabとKubernetesクラスターを接続するには、以下を使用できます:

- [GitOpsワークフロー](../../clusters/agent/gitops.md)。
- [GitLab CI/CDワークフロー](../../clusters/agent/ci_cd_workflow.md)。
- [証明書ベースのインテグレーション](_index.md)。

証明書ベースのインテグレーションはGitLab 14.5で[**非推奨**](https://about.gitlab.com/blog/deprecating-the-cert-based-kubernetes-integration/)になりました。廃止予定計画は次のとおりです:

- [GitLab.comのお客様向け](../../../update/deprecations.md#gitlabcom-certificate-based-integration-with-kubernetes)。
- [GitLab Self-Managedのお客様向け](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes)。

証明書ベースのインテグレーションを使用している場合は、できるだけ早く別のワークフローに移行する必要があります。

原則として、GitLab CI/CDに依存するクラスターを移行するには、[CI/CDワークフロー](../../clusters/agent/ci_cd_workflow.md)を使用できます。このワークフローは、エージェントを使用してクラスターに接続します。エージェントは次のとおりです:

- インターネットに公開されていません。
- フル[`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)アクセスをGitLabに要求しません。

> [!note]
> 証明書ベースのインテグレーションは、GitLabマネージドApp、GitLabマネージドクラスター、およびAuto DevOpsのような人気のあるGitLab機能に使用されていました。

## 証明書ベースのクラスターを検索する {#find-certificate-based-clusters}

サブグループやプロジェクトを含む、GitLabインスタンスまたはグループ内のすべての証明書ベースのクラスターは、[専用のAPI](../../../api/cluster_discovery.md#retrieve-certificate-based-clusters)を使用して検索できます。グループIDでAPIをクエリすると、指定されたグループまたはそれ以下で定義されているすべての証明書ベースのクラスターが返されます。

この場合、親グループで定義されているクラスターは返されません。この動作により、グループオーナーは移行する必要のあるすべてのクラスターを見つけることができます。

無効化されたクラスターも、誤ってクラスターが置き去りにされるのを防ぐために返されます。

> [!note]
> クラスター検出APIは個人のネームスペースでは機能しません。

## 汎用的なデプロイを移行する {#migrate-generic-deployments}

汎用的なデプロイを移行するには:

1. [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
1. CI/CDワークフローに従って、グループとプロジェクトへの[エージェントアクセス](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)を承認するか、[代理でアクセスを保護する](../../clusters/agent/ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation)かします。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターをオフにします。

## GitLabマネージドクラスターからKubernetesリソースへ移行する {#migrate-from-gitlab-managed-clusters-to-kubernetes-resources}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

GitLabマネージドクラスターを使用すると、GitLabはブランチごとに個別のサービスアカウントとネームスペースを作成し、これらのリソースを使用してデプロイします。

これで、[GitLabマネージドKubernetesリソース](../../clusters/agent/managed_kubernetes_resources.md)を使用して、セキュリティ制御が強化されたリソースをセルフサービスできます。

GitLabマネージドKubernetesリソースを使用すると、次のことができます:

- 手動での介入なしに、環境を安全に設定できます。
- デベロッパーに管理者クラスター権限を与えることなく、リソースの作成とアクセスを制御できます。
- 新しいプロジェクトや環境を作成する際に、デベロッパー向けにセルフサービス機能を提供します。
- デベロッパーがテストバージョンと開発バージョンを専用または共有のネームスペースにデプロイできるようにします。

前提条件: 

- [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
- 関連するプロジェクトまたはグループにアクセスするように[エージェントを承認します](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)。
- 証明書ベースのクラスターインテグレーションページで、**環境ごとのネームスペース**チェックボックスのステータスを確認します。

GitLabマネージドクラスターからGitLabマネージドKubernetesリソースへ移行するには:

1. 既存の環境を移行する場合は、[Kubernetes用ダッシュボード](../../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard)または[環境API](../../../api/environments.md)のいずれかを介して、その環境のエージェントを設定します。
1. エージェントの設定ファイルでリソース管理を有効にするようにエージェントを設定します:

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

   **環境ごとのネームスペース**がチェックされている場合は、次のテンプレートを使用します:

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

   **環境ごとのネームスペース**がチェックされていない場合は、次のテンプレートを使用します:

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

1. CI/CD設定で、`environment.kubernetes.agent: <path/to/agent/project:agent-name>`構文を持つエージェントを使用します。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターをオフにします。

## Auto DevOpsから移行する {#migrate-from-auto-devops}

Auto DevOpsプロジェクトで、Kubernetes向けGitLabエージェントを使用してKubernetesクラスターに接続できます。

前提条件

- [Kubernetes向けGitLabエージェント](../../clusters/agent/install/_index.md)をインストールします。
- 関連するプロジェクトまたはグループにアクセスするように[エージェントを承認します](../../clusters/agent/ci_cd_workflow.md#authorize-agent-access)。

Auto DevOpsから移行するには:

1. GitLabで、Auto DevOpsを使用しているプロジェクトに移動します。
1. 3つの変数を追加します。左側のサイドバーで、**設定** > **CI/CD**を選択し、**変数**を展開します。
   - `KUBE_INGRESS_BASE_DOMAIN`というキーに、アプリケーションデプロイドメインを値として追加します。
   - `KUBE_CONTEXT`というキーに`path/to/agent/project:agent-name`のような値を追加します。選択した環境スコープを選択します。エージェントのコンテキストが不明な場合は、`.gitlab-ci.yml`ファイルを編集し、利用可能なコンテキストを確認するためにジョブを追加します:

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

   - `KUBE_NAMESPACE`というキーに、デプロイのターゲットとなるKubernetesネームスペースの値を追加します。同じ環境スコープを設定します。
1. **変数を追加**を選択します。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. 証明書ベースのクラスターセクションから、同じ環境スコープを提供するクラスターを開きます。
1. **詳細**タブを選択し、クラスターを無効にします。
1. ご使用の`.gitlab-ci.yml`ファイルを編集し、Auto DevOpsテンプレートを使用していることを確認します。例: 

   ```yaml
   include:
     template: Auto-DevOps.gitlab-ci.yml

   variables:
     KUBE_INGRESS_BASE_DOMAIN: 74.220.23.215.nip.io
     KUBE_CONTEXT: "gitlab-examples/ops/gitops-demo/k8s-agents:demo-agent"
     KUBE_NAMESPACE: "demo-agent"
   ```

1. ご使用のパイプラインをテストするには、左側のサイドバーで**ビルド** > **パイプライン**を選択し、次に**新しいパイプライン**を選択します。

例については、[このプロジェクトを参照してください](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)。

## GitLabマネージドアプリケーションから移行する {#migrate-from-gitlab-managed-applications}

GitLabマネージドApp (GMA) はGitLab 14.0で非推奨になり、GitLab 15.0で削除されました。エージェントfor Kubernetesはそれらをサポートしていません。GMAからエージェントへ移行するには、次の手順を実行します:

1. [GitLabマネージドAppからクラスター管理プロジェクトへ移行する](../../clusters/migrating_from_gma_to_project_template.md)。
1. [クラスター管理プロジェクトをエージェントを使用するように移行する](../../clusters/management_project_template.md)。

## クラスター管理プロジェクトを移行する {#migrate-a-cluster-management-project}

[クラスター管理プロジェクトをKubernetes向けGitLabエージェントと共に使用する方法](../../clusters/management_project_template.md)を参照してください。

## クラスターモニタリング機能を移行する {#migrate-cluster-monitoring-features}

Kubernetesクラスターをエージェントfor Kubernetesを使用してGitLabに接続すると、[ユーザーアクセス](../../clusters/agent/user_access.md)を有効にした後、[Kubernetes用ダッシュボード](../../../ci/environments/kubernetes_dashboard.md)を使用できます。
