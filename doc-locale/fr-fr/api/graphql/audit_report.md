---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Créer un rapport d'audit à l'aide de GraphQL"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez créer un rapport d'audit pour un sous-ensemble spécifique d'utilisateurs à l'aide de :

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Utiliser GraphiQL {#use-graphiql}

Vous pouvez utiliser GraphiQL pour interroger des informations sur un sous-ensemble d'utilisateurs.

1. Ouvrez GraphiQL :
   - Pour GitLab.com, utilisez : `https://gitlab.com/-/graphql-explorer`
   - Pour GitLab Self-Managed, utilisez : `https://gitlab.example.com/-/graphql-explorer`
1. Copiez le texte suivant et collez-le dans la fenêtre de gauche. Cette requête recherche un sous-ensemble d'utilisateurs par nom d'utilisateur. Vous pouvez également utiliser leur [ID global](_index.md#global-ids).

   ```graphql
   {
     users(usernames: ["user1", "user2", "user3"]) {
       pageInfo {
         endCursor
         startCursor
         hasNextPage
       }
       nodes {
         id
         ...memberships
       }
     }
   }

   fragment membership on MemberInterface {
     createdAt
     updatedAt
     accessLevel {
       integerValue
       stringValue
     }
     createdBy {
       id
     }
   }

   fragment memberships on User {
     groupMemberships {
       nodes {
         ...membership
         group {
           id
           name
         }
       }
     }

     projectMemberships {
       nodes {
         ...membership
         project {
           id
           name
         }
       }
     }
   }
   ```

1. Sélectionnez **Play**.

> [!note]
> [L'API GraphQL renvoie un GlobalID plutôt qu'un ID standard](getting_started.md#queries-and-mutations). Elle attend également un GlobalID en entrée plutôt qu'un seul entier.

Cette requête renvoie les groupes et les projets dont l'utilisateur a été explicitement désigné comme membre.

- Étant donné que GraphiQL utilise le jeton de session pour autoriser l'accès aux ressources, la sortie est limitée aux projets et aux groupes accessibles à l'utilisateur actuellement authentifié.
- Si vous êtes connecté en tant qu'administrateur d'instance, vous avez accès à toutes les ressources.

## Pagination et nœuds de graphe {#pagination-and-graph-nodes}

La requête comprend :

- [`pageInfo`](#pageinfo)
- [`nodes`](#nodes)

### `pageInfo` {#pageinfo}

Contient les données nécessaires à l'implémentation de la pagination. GitLab utilise la [pagination](getting_started.md#pagination) basée sur les curseurs. Pour plus d'informations, consultez [Pagination](https://graphql.org/learn/pagination/) dans la documentation GraphQL.

### `nodes` {#nodes}

Dans une requête GraphQL, `nodes` représente une collection de [`nodes` sur un graphe](https://en.wikipedia.org/wiki/Vertex_(graph_theory)). Dans ce cas, la collection de nœuds est une collection d'objets `User`. Pour chacun d'eux, la sortie comprend :

- L'`id` de l'utilisateur.
- Le fragment `membership`, qui représente l'appartenance à un projet ou à un groupe pour cet utilisateur. Les fragments sont indiqués par la notation `...memberships`.

## Sujets connexes {#related-topics}

- [Référence de l'API GraphQL](reference/_index.md)
- [Entités spécifiques à GraphQL, telles que les fragments et les interfaces](https://graphql.org/learn/)
