---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes向けダッシュボード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/390769) GitLab 16.1。名前が`environment_settings_to_graphql`、`kas_user_access`、`kas_user_access_project`、`expose_authorized_cluster_agents`の[機能フラグ](../../administration/feature_flags/_index.md)を使用します。この機能は[ベータ版](../../policy/development_stages_support.md#beta)です。
- 機能フラグ`environment_settings_to_graphql`はGitLab 16.2で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124177)されました。
- GitLab 16.2で、`kas_user_access`、`kas_user_access_project`、`expose_authorized_cluster_agents`の[機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835)が削除されました。
- 16.10で環境詳細ページに[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/431746)しました。

{{< /history >}}

Kubernetesのダッシュボードを使用して、直感的なビジュアルインターフェースでクラスターの状態を把握できます。ダッシュボードは、CI/CDまたはGitOpsでデプロイしたかどうかにかかわらず、接続されているすべてのKubernetesクラスターで動作します。

![Kubernetesポッドとサービスの状態を示すダッシュボード。](img/kubernetes_summary_ui_v17_2.png)

## ダッシュボードを設定する {#configure-a-dashboard}

{{< history >}}

- ネームスペースによるリソースのフィルタリングは、GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/403618)されました（`kubernetes_namespace_for_environment`という[フラグ](../../administration/feature_flags/_index.md)を使用）。デフォルトでは無効になっています。
- ネームスペースによるリソースのフィルタリングは、GitLab 16.3で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127043)になりました。機能フラグ`kubernetes_namespace_for_environment`は削除されました。
- 関連するFluxリソースの選択は、`flux_resource_for_environment`という[フラグ](../../administration/feature_flags/_index.md)を使用して、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128857)されました。
- 関連するFluxリソースの選択は、GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130648)されました。機能フラグ`flux_resource_for_environment`は削除されました。

{{< /history >}}

特定の環境で使用するためにダッシュボードを設定します。ダッシュボードは、既存の環境に設定することも、環境の作成時に追加することもできます。

前提要件: 

- Kubernetes向けGitLabエージェントが[インストール](../../user/clusters/agent/install/_index.md)され、[`user_access`](../../user/clusters/agent/user_access.md)が環境のプロジェクトまたはその親グループに対して設定されている必要があります。

{{< tabs >}}

{{< tab title="環境はすでに存在します" >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. Kubernetes向けエージェントに関連付ける環境を選択します。
1. **編集**を選択します。
1. Kubernetes用のGitLab Agentを選択します。
1. オプション。**Kubernetes namespace**（Kubernetesネームスペース）ドロップダウンリストから、ネームスペースを選択します。
1. オプション。**Flux resource**（Fluxリソース）ドロップダウンリストから、Fluxリソースを選択します。
1. **保存**を選択します。

{{< /tab >}}

{{< tab title="環境が存在しません" >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. **新しい環境**を選択します。
1. **名前**フィールドに入力します。
1. Kubernetes用のGitLab Agentを選択します。
1. オプション。**Kubernetes namespace**（Kubernetesネームスペース）ドロップダウンリストから、ネームスペースを選択します。
1. オプション。**Flux resource**（Fluxリソース）ドロップダウンリストから、Fluxリソースを選択します。
1. **保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

### 動的環境のダッシュボードを設定する {#configure-a-dashboard-for-a-dynamic-environment}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)されました。

{{< /history >}}

動的環境のダッシュボードを設定するには:

- `.gitlab-ci.yml`ファイルでエージェントを指定します。エージェント設定プロジェクトへのフルパスの後に、コロンとエージェントの名前を指定する必要があります。

例: 

```yaml
deploy_review_app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
```

詳細については、[CI/CD YAML構文リファレンス](../yaml/_index.md#environmentkubernetes)を参照してください。

## ダッシュボードを表示する {#view-a-dashboard}

{{< history >}}

- Kubernetes Watch APIインテグレーションは、`k8s_watch_api`という[フラグ](../../administration/feature_flags/_index.md)を使用して、GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422945)されました。デフォルトでは無効になっています。
- Kubernetes Watch APIインテグレーションは、GitLab 16.7で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136831)になりました。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/427762)になりました。機能フラグ`k8s_watch_api`は削除されました。

{{< /history >}}

ダッシュボードを表示して、接続されているクラスターの状態を確認します。KubernetesリソースとFlux調整の更新の状態がリアルタイムで表示されます。

設定されたダッシュボードを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. Kubernetes向けエージェントに関連付けられている環境を選択します。
1. **Kubernetesの概要**タブを選択します。

ポッドの一覧が表示されます。ポッドを選択して、詳細を表示します。

### Flux同期状態 {#flux-sync-status}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)されました。
- Fluxリソースの名前のカスタマイズは、`flux_resource_for_environment`という[フラグ](../../administration/feature_flags/_index.md)を使用して、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128857)されました。
- Fluxリソースの名前のカスタマイズは、GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130648)されました。機能フラグ`flux_resource_for_environment`は削除されました。

{{< /history >}}

ダッシュボードからFluxデプロイの同期ステータスをレビューできます。デプロイステータスを表示するには、ダッシュボードが`Kustomization`および`HelmRelease`リソースを取得できる必要があります。そのためには、環境に対してネームスペースを設定する必要があります。

GitLabは、環境設定の**Flux resource**（Fluxリソース）ドロップダウンリストで指定された`Kustomization`および`HelmRelease`リソースを検索します。

ダッシュボードには、次のステータスバッジのいずれかが表示されます:

| ステータス | 説明 |
|---------|-------------|
| **照合済み** | デプロイがその環境と正常に照合されました。 |
| **照合中** | 調整が進行中です。 |
| **停止中** | 調整は、人的介入なしでは解決できないエラーが発生したため、停止しています。 |
| **失敗** | デプロイは、回復不能なエラーが発生したため、照合できませんでした。 |
| **不明** | デプロイの同期ステータスを取得できませんでした。 |
| **利用不可** | `Kustomization`または`HelmRelease`リソースを取得できませんでした。 |

### Flux調整をトリガーする {#trigger-flux-reconciliation}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/434248)されました。

{{< /history >}}

Fluxリソースとのデプロイを照合するには、手動で実行できます。

調整をトリガーするには:

1. ダッシュボードで、Fluxデプロイの同期ステータスバッジを選択します。
1. **アクション**（{{< icon name="ellipsis_v" >}}）> **トリガー調整**（{{< icon name="retry" >}}）を選択します。

### Flux調整を一時停止または再開する {#suspend-or-resume-flux-reconciliation}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/478380)されました。

{{< /history >}}

UIからFlux調整を手動で一時停止または再開できます。

調整を一時停止または再開するには:

1. ダッシュボードで、Fluxデプロイの同期ステータスバッジを選択します。
1. **アクション**（{{< icon name="ellipsis_v" >}}）を選択し、次のいずれかを選択します:
   - **調整を停止**（{{< icon name="stop" >}}）を選択して、Flux調整を一時停止します。
   - **調整を再開**（{{< icon name="play" >}}）を選択して、Flux調整を再開します。

### ポッドログを表示する {#view-pod-logs}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/13793)。

{{< /history >}}

設定されたダッシュボードから、環境全体のイシューを迅速に把握し、問題を解決したい場合は、ポッドログを表示します。ポッド内の各コンテナのログを表示できます。

- **ログの表示**を選択し、ログを表示するコンテナを選択します。

ポッドの詳細からポッドログを表示することもできます。

### ポッドを削除する {#delete-a-pod}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467653)されました。

{{< /history >}}

失敗したポッドを再起動するには、Kubernetesダッシュボードから削除します。

podを削除するには、次のようにします:

1. **Kubernetesの概要**タブで、削除するポッドを見つけます。
1. **アクション**（{{< icon name="ellipsis_v" >}}）> **ポッドの削除**（{{< icon name="remove" >}}）を選択します。

ポッドの詳細からポッドを削除することもできます。

## 詳細なダッシュボード {#detailed-dashboard}

{{< history >}}

- GitLab 16.4で`k8s_dashboard`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/11351)されました。デフォルトでは無効になっています。
- 一部のユーザー向けに、GitLab 16.7で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/424237)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

詳細なダッシュボードには、次のKubernetesリソースに関する情報が表示されます:

- pod
- サービス
- デプロイ
- ReplicaSet
- StatefulSet
- DaemonSet
- ジョブ
- CronJob

各ダッシュボードには、リソースのリストがステータス、ネームスペース、経過時間とともに表示されます。リソースを選択すると、ラベル、YAML形式のステータス、注釈、および仕様など、詳細情報を含むドロワーが開きます。

![接続されたクラスターに関する詳細情報を含むダッシュボード。](img/kubernetes_dashboard_deployments_v16_9.png)

[このイシュー](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/general/-/issues/53#note_1720060812)で説明されているように、フォーカスが変更されたため、詳細なダッシュボードの作業は一時停止されています。

詳細なダッシュボードに関するフィードバックを提供するには、[issue 460279](https://gitlab.com/gitlab-org/gitlab/-/issues/460279)を参照してください。

### 詳細なダッシュボードを表示する {#view-a-detailed-dashboard}

前提要件: 

- Kubernetes向けGitLabエージェントが[構成](../../user/clusters/agent/install/_index.md)され、[`user_access`](../../user/clusters/agent/user_access.md)キーワードを使用して、環境のプロジェクトまたはその親グループと共有されます。

詳細なダッシュボードは、サイドバーナビゲーションからはリンクされていません。詳細なダッシュボードを表示するには:

1. KubernetesエージェントIDを検索します:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **操作** > **Kubernetesクラスター**を選択します。
   1. アクセスするエージェントの数値IDをコピーします。
1. 次のURLのいずれかに移動し、`<agent_id>`エージェントIDに置き換えます:

   | リソースの種類 | URL |
   | --- | --- |
   | pod | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/pods` |
   | サービス | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/services` |
   | デプロイ | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/deployments` |
   | ReplicaSet | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/replicaSets` |
   | StatefulSet | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/statefulSets` |
   | DaemonSet | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/daemonSets` |
   | ジョブ | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/jobs` |
   | CronJob | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/cronJobs` |

## トラブルシューティング {#troubleshooting}

Kubernetesのダッシュボードの操作中に、次のイシューが発生する可能性があります。

### APIグループでリソースを一覧表示できません {#user-cannot-list-resource-in-api-group}

`Error: services is forbidden: User "gitlab:user:<user-name>" cannot list resource "<resource-name>" in API group "" at the cluster scope`というエラーが表示されることがあります。

このエラーは、[Kubernetesロールベースのアクセス制御](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)で指定された操作をユーザーが実行できない場合に発生します。

解決するには、[RBAC設定](../../user/clusters/agent/user_access.md#configure-kubernetes-access)を確認してください。RBACが適切に設定されている場合は、Kubernetes管理者にお問い合わせください。

### GitLabエージェントドロップダウンリストが空です {#gitlab-agent-dropdown-list-is-empty}

新しい環境を設定するときに、Kubernetesクラスターを設定していても、**GitLabエージェント**ドロップダウンリストが空になることがあります。

**GitLabエージェント**ドロップダウンリストに入力された状態にするには、[`user_access`](../../user/clusters/agent/user_access.md)キーワードを使用して、エージェントにKubernetesアクセス権を付与します。
