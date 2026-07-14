---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GraphQL API를 사용하여 사용자에게 GitLab Duo 사용자를 할당합니다. 필수 조건, 쿼리, 뮤테이션 및 추가 기능 사용자 할당을 효율적으로 관리하는 방법에 대해 알아봅니다."
title: GraphQL을 사용하여 GitLab Duo 사용자 할당
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146620)되었습니다.

{{< /history >}}

이 API를 사용하여 [GitLab Duo 사용자](../../user/gitlab_duo/_index.md)를 사용자에게 할당합니다.

## 전제 조건 {#prerequisites}

- 사용자를 할당하려는 그룹의 소유자 역할이 있어야 합니다.
- 개인 액세스 토큰과 `api` 범위가 있어야 합니다.

## 추가 기능 구매 ID 가져오기 {#get-the-add-on-purchase-id}

먼저 GitLab Duo 추가 기능의 구매 ID를 검색합니다. GitLab.com의 경우:

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

GitLab Self-Managed 및 GitLab Dedicated:

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

## 특정 사용자에게 GitLab Duo 사용자 할당 {#assign-a-gitlab-duo-seat-to-specific-users}

특정 사용자에게 사용자를 할당합니다:

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

## GraphQL 사용 {#use-graphql}

[GraphQL](https://gitlab.com/-/graphql-explorer)을 사용하여 사용자에게 사용자를 할당할 수 있습니다.

1. 추가 기능 구매 ID 코드 발췌본을 복사합니다.
1. GraphQL을 엽니다.
1. 왼쪽 창에서 [추가 기능 구매 ID 가져오기](#get-the-add-on-purchase-id)에 대한 쿼리를 입력합니다.
1. **Play**을 선택합니다.
1. 특정 사용자에게 GitLab Duo 사용자를 할당하도록 반복합니다.

## 관련 항목 {#related-topics}

- [GraphQL API 리소스](reference/_index.md)
- [GraphQL 특정 엔터티(예: 조각 및 인터페이스)](https://graphql.org/learn/)
