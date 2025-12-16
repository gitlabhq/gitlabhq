---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インスタンスKubernetesクラスター（証明書ベース）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスターをGitLabに接続するには、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用します。

{{< /alert >}}

[プロジェクト](../../project/clusters/_index.md)および[グループ](../../group/clusters/_index.md)のKubernetesクラスターと同様に、インスタンスKubernetesクラスターを使用すると、KubernetesクラスターをGitLabインスタンスに接続し、複数のプロジェクトで同じクラスターを使用できます。

インスタンスのKubernetesクラスターを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Kubernetes**を選択します。

## クラスターの優先順位 {#cluster-precedence}

GitLabは、次の順序でクラスターを照合しようとします:

- プロジェクトクラスター
- グループクラスター。
- インスタンスクラスター

選択されるには、クラスターが有効になっており、[環境セレクター](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)と一致している必要があります。

## クラスター環境 {#cluster-environments}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

どのCI [環境](../../../ci/environments/_index.md)がKubernetesクラスターにデプロイされているかの統合ビューについては、[クラスター環境](../../clusters/environments.md)のドキュメントを参照してください。

## 詳細情報 {#more-information}

GitLabとKubernetesの統合については、[Kubernetesクラスター](../../infrastructure/clusters/_index.md)を参照してください。
