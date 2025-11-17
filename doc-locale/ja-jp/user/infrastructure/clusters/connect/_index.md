---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスターをGitLabに接続する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[証明書ベースのGitLabとKubernetesのインテグレーション](../_index.md)は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスターを接続するには、[Kubernetes向けGitLabエージェント](../../../clusters/agent/_index.md)を使用します。

## クラスターレベル（非推奨） {#cluster-levels-deprecated}

{{< history >}}

- GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /history >}}

{{< alert type="warning" >}}

[クラスターレベルの概念は非推奨](../_index.md#cluster-levels)になりました(GitLab 14.5)。

{{< /alert >}}

目的に応じてクラスターのレベルを選択します:

| レベル                                                  | 目的 |
|--------------------------------------------------------|---------|
| [プロジェクトレベル](../../../project/clusters/_index.md)   | 単一のプロジェクトにクラスターを使用します。 |
| [グループレベル](../../../group/clusters/_index.md)       | グループ内の複数のプロジェクトで同じクラスターを使用します。 |
| [インスタンスレベル](../../../instance/clusters/_index.md) | インスタンス内のグループやプロジェクト全体で同じクラスターを使用します。 |

### クラスターを表示する {#view-your-clusters}

プロジェクト、グループ、またはインスタンスに接続されたKubernetesクラスターを表示するには、クラスターのレベルに応じて、クラスターのページを開きます。

**Project-level clusters**（プロジェクトレベルのクラスター）:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。

**Group-level clusters**（グループレベルのクラスター）:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。

**Instance-level clusters**（インスタンスレベルのクラスター）:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Kubernetes**を選択します。

## 証明書で接続されたクラスターのセキュリティに関する注意点 {#security-implications-for-clusters-connected-with-certificates}

{{< history >}}

- クラスター証明書を介してGitLabにクラスターを接続することは、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /history >}}

{{< alert type="warning" >}}

クラスター全体のセキュリティは、[デベロッパー](../../../permissions.md)が信頼されているモデルに基づいているため、**only trusted users should be allowed to control your clusters**（信頼できるユーザーのみがクラスターを制御できるようにする必要があります）。

{{< /alert >}}

クラスター証明書を使用してクラスターを接続すると、コンテナ化されたアプリケーションのビルドとデプロイを正常に行うために必要な幅広い機能にアクセスできるようになります。同じ認証情報が、クラスター上で実行されているすべてのアプリケーションに使用されることに注意してください。
