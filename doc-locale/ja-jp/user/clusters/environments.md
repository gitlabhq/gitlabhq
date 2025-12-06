---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター環境（非推奨）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410)のGitLab 15.0で無効になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`certificate_based_clusters`という名前の[機能フラグを有効にする](../../administration/feature_flags/_index.md)と、この機能を使用できるようになります。

{{< /alert >}}

クラスター環境は、どのCI [環境](../../ci/environments/_index.md)がKubernetesクラスターにデプロイされているかの統合ビューを提供し、以下の機能を提供します:

- プロジェクトとデプロイに関連する関連環境を表示します。
- その環境のポッドのステータスを表示します。

クラスター環境を使用すると、以下についてインサイトを得ることができます:

- どのプロジェクトがクラスターにデプロイされているか。
- 各プロジェクトの環境で、いくつのポッドが使用されているか。
- その環境へのデプロイに使用されたCIジョブ。

![クラスター環境ページ](img/cluster_environments_table_v12_3.png)

クラスター環境へのアクセスは、[グループメンテナーとオーナー](../permissions.md#group-members-permissions)に制限されています

## 使用方法 {#usage}

以下を行うには:

- クラスターの環境を追跡するには、[Kubernetesクラスターにデプロイする](../project/clusters/deploy_to_cluster.md)必要があります。
- ポッドの使用状況を正しく表示するには、[デプロイボードを有効にする](../project/deploy_boards.md#enabling-deploy-boards)必要があります。

グループレベルまたはインスタンスレベルのクラスターへのデプロイに成功したら:

1. グループの**Kubernetes**ページに移動します。
1. **環境**タブを選択します。

このページには、クラスターへの成功したデプロイのみが含まれています。非クラスター環境は含まれていません。
