---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター証明書を使用したクラスターの追加（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 14.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/327908)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/327908)になりました。新しいクラスターを作成および管理するには、[Infrastructure as Code](../../infrastructure/iac/_index.md)を使用してください。

{{< /alert >}}

## クラスターを無効にする {#disable-a-cluster}

クラスター証明書を使用して既存のクラスターへの接続に成功すると、GitLabへのクラスター接続が有効になります。無効にするには、次の手順に従います: 

1. 以下に移動します:
   - プロジェクトレベルのクラスターの場合は、プロジェクトの{{< icon name="cloud-gear" >}} **操作** > **Kubernetesクラスター**ページ。
   - グループレベルのクラスターの場合は、グループの{{< icon name="cloud-gear" >}} **Kubernetes**ページ。
   - インスタンスレベルのクラスターの場合は、**管理者**エリアの**Kubernetes**ページ。
1. 無効にするクラスターの名前を選択します。
1. **GitLabインテグレーション**をオフ（グレー表示）に切り替えます。
1. **変更を保存**を選択します。

## クラスターの削除 {#remove-a-cluster}

クラスターのインテグレーションを削除すると、GitLabへのクラスターの関係のみが削除され、クラスター自体は削除されません。クラスター自体を削除するには、クラスターのGKEまたはAmazon EKSのダッシュボードに移動してUIから削除するか、`kubectl`を使用します。

GitLabとのインテグレーションを削除するには、プロジェクトまたはグループに対するメンテナー以上の[権限](../../permissions.md)が必要です。

クラスターのインテグレーションを削除する場合、次の2つのオプションがあります:

- **インテグレーションを消去**: Kubernetesインテグレーションのみを削除します。
- **インテグレーションとリソースを削除**: クラスターのインテグレーションと、ネームスペース、ロール、バインディングなど、GitLabのクラスター関連のリソースをすべて削除します。

Kubernetesクラスターのインテグレーションを削除するには:

1. クラスターの詳細ページに移動します。
1. **高度な設定**タブを選択します。
1. **インテグレーションを消去**または**インテグレーションとリソースを削除**のいずれかを選択します。

### Railsコンソールを使用してクラスターを削除する {#remove-clusters-by-using-the-rails-console}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Railsコンソールセッションを開始します](../../../administration/operations/rails_console.md#starting-a-rails-console-session)。

クラスターを見つけるには:

``` ruby
cluster = Clusters::Cluster.find(1)
cluster = Clusters::Cluster.find_by(name: 'cluster_name')
```

クラスターを削除するには、関連付けられたリソースは削除しません:

```ruby
# Find users who have administrator access
user = User.find_by(username: 'admin_user')

# Find the cluster with the ID
cluster = Clusters::Cluster.find(1)

# Delete the cluster
Clusters::DestroyService.new(user).execute(cluster)
```
