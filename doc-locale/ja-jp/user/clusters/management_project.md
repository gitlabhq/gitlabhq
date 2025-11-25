---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター管理プロジェクト（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.0で[GitLab Self-Managedで無効](https://gitlab.com/gitlab-org/gitlab/-/issues/353410)になりました。

{{< /history >}}

{{< alert type="warning" >}}

クラスター管理プロジェクトは、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスタアプリケーションを管理するには、[Kubernetes向けGitLabエージェント](agent/_index.md)と[Cluster Management Project Template](management_project_template.md)を使用します。

{{< /alert >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`certificate_based_clusters`という名前の[機能フラグを有効にする](../../administration/feature_flags/_index.md)と、この機能を使用できるようになります。

{{< /alert >}}

プロジェクトは、クラスタのクラスター管理プロジェクトとして指定できます。クラスター管理プロジェクトは、Kubernetes [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)権限でデプロイメントジョブを実行するために使用できます。

これは、以下の場合に役立ちます:

- クラスタ全体のアプリケーションをクラスタにインストールするためのパイプラインの作成。詳細については、[management project template](management_project_template.md)を参照してください。
- `cluster-admin`権限を必要とするジョブ。

## 権限 {#permissions}

クラスター管理プロジェクトのみが`cluster-admin`権限を受け取ります。他のすべてのプロジェクトは、[ネームスペーススコープの`edit`レベルの権限](../project/clusters/cluster_access.md#rbac-cluster-resources)を引き続き受け取ります。

クラスター管理プロジェクトは、以下に制限されています:

- プロジェクトレベルのクラスタの場合、クラスター管理プロジェクトは、クラスタのプロジェクトと同じネームスペース（または子孫）にある必要があります。
- グループレベルのクラスタの場合、クラスター管理プロジェクトは、クラスタのグループと同じグループ（または子孫）にある必要があります。
- インスタンスレベルのクラスタの場合、そのような制限はありません。

## クラスター管理プロジェクトを作成および設定する方法 {#how-to-create-and-configure-a-cluster-management-project}

クラスター管理プロジェクトを使用してクラスタを管理するには、次の手順に従います:

1. クラスタのクラスター管理プロジェクトとして機能する新しいプロジェクトを作成します。
1. [クラスターをクラスター管理プロジェクトに関連付けます](#associate-the-cluster-management-project-with-the-cluster)。
1. [クラスタのパイプラインを設定します](#configuring-your-pipeline)。
1. [環境スコープ](#setting-the-environment-scope)を設定します。

### クラスター管理プロジェクトをクラスタに関連付ける {#associate-the-cluster-management-project-with-the-cluster}

クラスター管理プロジェクトをクラスタに関連付けるには、次の手順に従います:

1. 適切な設定ページに移動します。以下の場合:
   - [プロジェクトレベルのクラスタ](../project/clusters/_index.md)の場合は、プロジェクトの**操作** > **Kubernetesクラスター**ページに移動します。
   - [グループレベルのクラスタ](../group/clusters/_index.md)の場合は、グループの**Kubernetes**ページに移動します。
   - [インスタンスレベルのクラスタ](../instance/clusters/_index.md):
     1. 左側のサイドバーの下部で、**管理者**を選択します。
     1. **Kubernetes**を選択します。
1. **Advanced settings**（高度な設定）を展開します。
1. **クラスター管理プロジェクト**クラスター管理プロジェクトドロップダウンリストから、前の手順で作成したクラスター管理プロジェクトを選択します。

### パイプラインの設定 {#configuring-your-pipeline}

プロジェクトをクラスタのクラスター管理プロジェクトとして指定した後、そのプロジェクトに`.gitlab-ci.yml`ファイルを追加します。例: 

```yaml
configure cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

### 環境スコープの設定 {#setting-the-environment-scope}

[環境スコープ](../project/clusters/multiple_kubernetes_clusters.md#setting-the-environment-scope)は、複数のクラスタを同じクラスター管理プロジェクトに関連付ける場合に使用できます。

各スコープは、クラスター管理プロジェクトの単一のクラスタでのみ使用できます。

たとえば、次のKubernetesクラスタがクラスター管理プロジェクトに関連付けられています:

| クラスター     | 環境スコープ |
| ----------- | ----------------- |
| 開発 | `*`               |
| ステージング     | `staging`         |
| 本番環境  | `production`      |

`.gitlab-ci.yml`ファイルに設定された環境は、Development、ステージング、および本番環境クラスタにデプロイされます。

```yaml
stages:
  - deploy

configure development cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: development

configure staging cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: staging

configure production cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```
