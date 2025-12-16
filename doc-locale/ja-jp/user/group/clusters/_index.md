---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループレベルのKubernetesクラスター（証明書ベース）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスターをGitLabに接続するには、[Kubernetes向け](../../clusters/agent/_index.md)を使用します。

{{< /alert >}}

[プロジェクトレベル](../../project/clusters/_index.md)および[インスタンスレベル](../../instance/clusters/_index.md)のKubernetesクラスターと同様に、グループレベルのKubernetesクラスターを使用すると、Kubernetesクラスターをグループに接続して、複数のプロジェクトで同じクラスターを使用できます。

グループレベルのKubernetesクラスターを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **操作** > **Kubernetes**を選択します。

## クラスター管理プロジェクト {#cluster-management-project}

Ingressコントローラーなど、インストールに`cluster-admin`権限を必要とする共有リソースを管理するには、[クラスター管理プロジェクト](../../clusters/management_project.md)をクラスターにアタッチします。

## RBACの互換性 {#rbac-compatibility}

Kubernetesクラスターを持つグループのプロジェクトごとに、GitLabはプロジェクトのネームスペースに[`edit`権限](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)を持つ制限付きサービスアカウントを作成します。

## クラスターの優先順位 {#cluster-precedence}

プロジェクトのクラスターが使用可能で無効になっていない場合、GitLabはプロジェクトを含むグループに属するクラスターを使用する前に、プロジェクトのクラスターを使用します。サブグループの場合、GitLabは、クラスターが無効になっていないことを条件に、プロジェクトに最も近い祖先グループのクラスターを使用します。

## 複数のKubernetesクラスター {#multiple-kubernetes-clusters}

複数のKubernetesクラスターをグループに関連付け、開発、ステージング、本番環境など、さまざまな環境に対して異なるクラスターを維持できます。

別のクラスターを追加する場合は、他のクラスターと区別するために、[環境スコープを設定](#environment-scopes)します。

## GitLab管理のクラスター {#gitlab-managed-clusters}

GitLabがクラスターを管理できるように選択できます。GitLabがクラスターを管理する場合、プロジェクトのリソースが自動的に作成されます。GitLabが作成するリソースの詳細については、[アクセスコントロール](../../project/clusters/cluster_access.md)セクションを参照してください。

GitLabで管理されていないクラスターの場合、プロジェクト固有のリソースは自動的に作成されません。GitLabで管理されていないクラスターでデプロイに[Auto DevOps](../../../topics/autodevops/_index.md)を使用している場合は、以下を確認する必要があります:

- プロジェクトのデプロイサービスアカウントには、[`KUBE_NAMESPACE`](../../project/clusters/deploy_to_cluster.md#deployment-variables)へのデプロイ権限があります。
- `KUBECONFIG`は、`KUBE_NAMESPACE`への変更を正しく反映しています（これは[自動ではありません](https://gitlab.com/gitlab-org/gitlab/-/issues/31519)）。`KUBE_NAMESPACE`を直接編集することはお勧めできません。

### クラスターのキャッシュのクリア {#clearing-the-cluster-cache}

GitLabがクラスターを管理できるように選択した場合、GitLabは、プロジェクト用に作成するネームスペースとサービスアカウントのキャッシュされたバージョンを保存します。これらのリソースをクラスターで手動で変更すると、このキャッシュがクラスターと同期しなくなり、デプロイメントジョブが失敗する可能性があります。

キャッシュをクリアするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **操作** > **Kubernetes**を選択します。
1. クラスターを選択します。
1. **Advanced settings**（高度な設定）を展開するします。
1. **クラスターのキャッシュを削除**を選択します。

## ベースドメイン {#base-domain}

クラスターレベルのドメインでは、[複数のKubernetesクラスター](#multiple-kubernetes-clusters)ごとに複数のドメインをサポートできます。ドメインを指定すると、[Auto DevOps](../../../topics/autodevops/_index.md)ステージ中に、これは環境変数（`KUBE_INGRESS_BASE_DOMAIN`）として自動的に設定されます。

ドメインには、Ingress IPアドレスに構成されたワイルドカードDNSが必要です。[詳細](../../project/clusters/gitlab_managed_clusters.md#base-domain)。

## 環境スコープ {#environment-scopes}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数のKubernetesクラスターをプロジェクトに追加する場合は、環境スコープを使用して区別する必要があります。環境スコープは、[環境](../../../ci/environments/_index.md)を[環境固有のCI/CD変数](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)の動作と同様に、クラスターに関連付けます。

クラスターの環境スコープに一致する環境を評価する際に、[クラスターの優先順位](#cluster-precedence)が有効になります。プロジェクトレベルのクラスターが優先され、次に最も近い祖先グループ、次にそのグループの親というようになります。

たとえば、プロジェクトに次のKubernetesクラスターがある場合:

| クラスター:    | 環境スコープ   | 場所     |
| ---------- | ------------------- | ----------|
| プロジェクト    | `*`                 | プロジェクト   |
| ステージング    | `staging/*`         | プロジェクト   |
| 本番環境 | `production/*`      | プロジェクト   |
| Test       | `test`              | グループ     |
| 開発| `*`                 | グループ     |

そして、次の環境が`.gitlab-ci.yml`ファイルに設定されています:

```yaml
stages:
  - test
  - deploy

test:
  stage: test
  script: sh test

deploy to staging:
  stage: deploy
  script: make deploy
  environment:
    name: staging/$CI_COMMIT_REF_NAME
    url: https://staging.example.com/

deploy to production:
  stage: deploy
  script: make deploy
  environment:
    name: production/$CI_COMMIT_REF_NAME
    url: https://example.com/
```

結果は次のとおりです:

- プロジェクトクラスターは`test`ジョブに使用されます。
- ステージングクラスターは、`deploy to staging`ジョブに使用されます。
- 本番環境クラスターは、`deploy to production`ジョブに使用されます。

## クラスター環境 {#cluster-environments}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

どのCI[環境](../../../ci/environments/_index.md)がKubernetesクラスターにデプロイされているかの統合ビューについては、[クラスター環境](../../clusters/environments.md)のドキュメントを参照してください。

## Runnerのセキュリティ {#security-of-runners}

Runnerを安全に構成する方法に関する重要な情報については、プロジェクトレベルのクラスターの[Runnerのセキュリティ](../../project/clusters/cluster_access.md#security-of-runners)に関するドキュメントを参照してください。

## 詳細情報 {#more-information}

GitLabとKubernetesの統合については、[Kubernetesクラスター](../../infrastructure/clusters/_index.md)を参照してください。
