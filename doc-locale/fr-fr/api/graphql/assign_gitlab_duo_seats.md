---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Attribuez des sièges GitLab Duo aux utilisateurs à l'aide de l'API GraphQL. Découvrez les prérequis, les requêtes, les mutations et la manière de gérer efficacement les attributions de sièges d'extensions."
title: "Attribuer des sièges GitLab Duo à l'aide de GraphQL"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146620) dans GitLab 16.11.

{{< /history >}}

Utilisez cette API pour attribuer des [sièges GitLab Duo](../../user/gitlab_duo/_index.md) aux utilisateurs.

## Prérequis {#prerequisites}

- Vous devez disposer du rôle Owner pour le groupe auquel vous souhaitez attribuer des sièges.
- Vous devez disposer d'un jeton d'accès personnel avec la portée `api`.

## Obtenir l'ID d'achat de l'extension {#get-the-add-on-purchase-id}

Pour commencer, récupérez l'ID d'achat pour l'extension GitLab Duo. Pour GitLab.com :

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

Pour GitLab Self-Managed et GitLab Dedicated :

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

## Attribuer un siège GitLab Duo à des utilisateurs spécifiques {#assign-a-gitlab-duo-seat-to-specific-users}

Attribuez ensuite des sièges à des utilisateurs spécifiques :

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

## Utiliser GraphQL {#use-graphql}

Vous pouvez utiliser [GraphQL](https://gitlab.com/-/graphql-explorer) pour attribuer des sièges aux utilisateurs.

1. Copiez l'extrait de code de l'ID d'achat de l'extension.
1. Ouvrez GraphQL.
1. Dans la fenêtre de gauche, saisissez la requête pour [obtenir un ID d'achat d'extension](#get-the-add-on-purchase-id).
1. Sélectionnez **Play**.
1. Répétez l'opération pour attribuer un siège GitLab Duo à des utilisateurs spécifiques.

## Sujets connexes {#related-topics}

- [Ressources de l'API GraphQL](reference/_index.md)
- [Entités spécifiques à GraphQL, telles que les fragments et les interfaces](https://graphql.org/learn/)
