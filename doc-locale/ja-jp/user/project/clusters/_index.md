---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトレベルのKubernetesクラスタ（証明書ベース）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。GitLabにクラスタを接続するには、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用してください。

{{< /alert >}}

[プロジェクトレベルの](../../infrastructure/clusters/connect/_index.md#cluster-levels-deprecated) Kubernetesクラスタを使用すると、GitLabのプロジェクトにKubernetesクラスタを接続できます。

単一のプロジェクトに[複数のクラスタを接続](multiple_kubernetes_clusters.md)することもできます。

## プロジェクトレベルのクラスタを表示 {#view-your-project-level-clusters}

プロジェクトレベルのKubernetesクラスタを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。
