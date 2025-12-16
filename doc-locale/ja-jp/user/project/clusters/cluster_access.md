---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスタ証明書によるアクセス制御（RBACまたはABAC）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスタをGitLabに接続するには、代わりに[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用してください。

{{< /alert >}}

GitLabでクラスタを作成する際に、以下のいずれかを作成するかどうかを確認するメッセージが表示されます:

- [ロールベースのアクセス制御（RBAC）](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)クラスタ。これはGitLabのデフォルトであり、推奨されるオプションです。
- [属性ベースのアクセス制御（ABAC）](https://kubernetes.io/docs/reference/access-authn-authz/abac/)クラスタ。

GitLabがクラスタを作成すると、`gitlab`サービスアカウント（`cluster-admin`権限を持つ）が`default`ネームスペースに作成され、新しく作成されたクラスタを管理します。

Helmは、インストールされている各アプリケーションに対して、追加のサービスアカウントやその他のリソースも作成します。詳細については、アプリケーションごとのHelmチャートのドキュメントを参照してください。

[既存のKubernetesクラスタを追加](add_existing_cluster.md)する場合は、アカウントのトークンにクラスタの管理者権限があることを確認してください。

GitLabによって作成されるリソースは、クラスタのタイプによって異なります。

## 重要な注意点 {#important-notes}

アクセス制御に関する以下の点に注意してください:

- 環境固有のリソースは、クラスタが[GitLabによって管理](gitlab_managed_clusters.md)されている場合にのみ作成されます。
- クラスタがGitLab 12.2より前に作成された場合、すべてのプロジェクト環境に対して単一のネームスペースを使用します。

## RBACクラスタのリソース {#rbac-cluster-resources}

GitLabは、RBACクラスタに対して以下のリソースを作成します。

| 名前                  | 型                 | 詳細                                                                                                    | 作成タイミング           |
|:----------------------|:---------------------|:-----------------------------------------------------------------------------------------------------------|:-----------------------|
| `gitlab`              | `ServiceAccount`     | `default`ネームスペース                                                                                        | 新規クラスタの作成 |
| `gitlab-admin`        | `ClusterRoleBinding` | [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)ロール    | 新規クラスタの作成 |
| `gitlab-token`        | `Secret`             | `gitlab`サービスアカウントのトークン                                                                          | 新規クラスタの作成 |
| 環境ネームスペース | `Namespace`          | すべての環境固有のリソースが含まれています                                                                | クラスタへのデプロイ |
| 環境ネームスペース | `ServiceAccount`     | 環境のネームスペースを使用                                                                              | クラスタへのデプロイ |
| 環境ネームスペース | `Secret`             | 環境サービスアカウントのトークン                                                                       | クラスタへのデプロイ |
| 環境ネームスペース | `RoleBinding`        | [`admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)ロール            | クラスタへのデプロイ |

## ABACクラスタのリソース {#abac-cluster-resources}

GitLabは、ABACクラスタに対して以下のリソースを作成します。

| 名前                  | 型                 | 詳細                              | 作成タイミング               |
|:----------------------|:---------------------|:-------------------------------------|:---------------------------|
| `gitlab`              | `ServiceAccount`     | `default`ネームスペース                         | 新規クラスタの作成 |
| `gitlab-token`        | `Secret`             | `gitlab`サービスアカウントのトークン           | 新規クラスタの作成 |
| 環境ネームスペース | `Namespace`          | すべての環境固有のリソースが含まれています | クラスタへのデプロイ |
| 環境ネームスペース | `ServiceAccount`     | 環境のネームスペースを使用               | クラスタへのデプロイ |
| 環境ネームスペース | `Secret`             | 環境サービスアカウントのトークン        | クラスタへのデプロイ |

## Runnerのセキュリティ {#security-of-runners}

Runnerは、[特権モード](https://docs.gitlab.com/runner/executors/docker.html#the-privileged-mode)がデフォルトで有効になっており、特別なコマンドを実行したり、DockerでDockerを実行したりできます。この機能は、一部の[Auto DevOps](../../../topics/autodevops/_index.md)ジョブを実行するために必要です。これは、コンテナが特権モードで実行されていることを意味し、したがって、いくつかの重要な詳細に注意する必要があります。

特権フラグは、実行中のコンテナにすべての機能を提供し、ホストができるほとんどすべてのことを実行できます。`docker run`操作を任意のイメージに対して実行することに伴う固有のセキュリティリスクに注意してください。これらは事実上、rootアクセス権を持っています。

特権モードでRunnerを使用したくない場合は、次のいずれかを行います:

- GitLab.comでインスタンスRunnerを使用します。これらには、このセキュリティ上の問題はありません。
- [`docker+machine`](https://docs.gitlab.com/runner/executors/docker_machine.html)を使用する独自のRunnerをセットアップします。
