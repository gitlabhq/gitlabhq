---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GraphQL APIを使用して、GitLab Duoシートをユーザーに割り当てます。クエリ、ミューテーション、およびアドオンのシート割り当てを効率的に管理する方法について説明します。
title: GraphQLを使用してGitLab Duoシートを割り当てる
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146620)されました。

{{< /history >}}

GraphQL APIを使用して、GitLab Duoシートをユーザーに割り当てます。

## 前提要件 {#prerequisites}

- シートを割り当てるグループのオーナーロールが必要です。
- `api`スコープを持つパーソナルアクセストークンが必要です。

## アドオン購入IDを取得する {#get-the-add-on-purchase-id}

まず、GitLab Duoアドオンの購入IDを取得する。GitLab.comの場合:

```graphql
query {
 addOnPurchases (namespaceId: "gid://gitlab/Group/YOUR_NAMESPACE_ID")
 {
  name
  purchasedQuantity
  assignedQuantity
  id
 }
}
```

GitLab Self-ManagedおよびGitLab Dedicatedの場合:

```graphql
query {
 addOnPurchases
 {
  name
  purchasedQuantity
  assignedQuantity
  id
 }
}
```

## 特定のユーザーにGitLab Duoシートを割り当てる {#assign-a-gitlab-duo-seat-to-specific-users}

次に、特定のユーザーにシートを割り当てます:

```graphql
mutation {
  userAddOnAssignmentBulkCreate(input: {
    addOnPurchaseId: "gid://gitlab/GitlabSubscriptions::AddOnPurchase/YOUR_ADDON_PURCHASE_ID",
    userIds: [
      "gid://gitlab/User/USER_ID_1",
      "gid://gitlab/User/USER_ID_2",
      "gid://gitlab/User/USER_ID_3"
    ]
  }) {
    addOnPurchase {
      id
      name
      assignedQuantity
      purchasedQuantity
    }
    users {
      nodes {
        id
        username
        }
      }
    errors
  }
}
```

## GraphQLを使用 {#use-graphql}

[GraphQL](https://gitlab.com/-/graphql-explorer)を使用して、ユーザーに割り当てられたシートを割り当てることができます。

1. アドオン購入IDコードの抜粋をコピーします。
1. GraphQLを開きます。
1. 左側のウィンドウで、[アドオン購入IDを取得する](#get-the-add-on-purchase-id)のクエリを入力します。
1. **再生**を選択します。
1. GitLab Duoシートを特定のユーザーに割り当てるために繰り返します。

## 関連トピック {#related-topics}

- [GraphQL APIリソース](reference/_index.md)
- [フラグメントやインターフェースなど、GraphQL固有のエンティティ](https://graphql.org/learn/)
