---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Assign GitLab Duo seats by using GraphQL
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

Use the GraphQL API to assign GitLab Duo seats to users.

## Prerequisites

- You must have the Owner role for the group you want to assign seats to.
- You must have a personal access token with the `api` scope.

## Get the add-on purchase ID

To start, retrieve the purchase ID for the GitLab Duo add-on:

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

## Assign a GitLab Duo seat to specific users

Then assign seats to specific users:

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

## Use GraphiQL

You can use [GraphiQL](https://gitlab.com/-/graphql-explorer) to assign seats to users.

1. Copy the add-on purchase ID code excerpt.
1. Open GraphiQL.
1. In the left window, enter the query:

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

1. Select **Play**.
1. Repeat to assign a GitLab Duo seat to specific users.

## Related topics

- [GraphQL API Resources](reference/_index.md)
- [GraphQL specific entities, like fragments and interfaces](https://graphql.org/learn/)
