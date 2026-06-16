---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Interroger des utilisateurs avec GraphQL
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez interroger un sous-ensemble d'utilisateurs dans une instance GitLab en utilisant :

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Utiliser GraphiQL {#use-graphiql}

1. Ouvrez GraphiQL :
   - Pour GitLab.com, utilisez : `https://gitlab.com/-/graphql-explorer`
   - Pour GitLab Self-Managed, utilisez : `https://gitlab.example.com/-/graphql-explorer`
1. Copiez le texte suivant et collez-le dans la fenêtre de gauche. Cette requête recherche un sous-ensemble d'utilisateurs dans une instance GitLab par nom d'utilisateur. Vous pouvez également utiliser leurs [ID globaux](_index.md#global-ids).

   ```graphql
    {
      users(usernames: ["user1", "user3", "user4"]) {
        pageInfo {
          endCursor
          startCursor
          hasNextPage
        }
        nodes {
          id
          username,
          publicEmail
          location
          webUrl
          userPermissions {
            createSnippet
          }
        }
      }
    }
   ```

1. Sélectionnez **Play**.

> [!note]
> [L'API GraphQL renvoie un GlobalID plutôt qu'un ID standard](getting_started.md#queries-and-mutations). Elle attend également un GlobalID en entrée plutôt qu'un simple entier.

Cette requête renvoie les informations spécifiées pour les trois utilisateurs avec le nom d'utilisateur indiqué.

- Étant donné que GraphiQL utilise le jeton de session pour autoriser l'accès aux ressources, la sortie est limitée aux projets et groupes accessibles à l'utilisateur actuellement authentifié.
- Si vous êtes connecté en tant qu'administrateur d'instance, vous avez accès à toutes les ressources.

### Afficher uniquement les administrateurs {#show-administrators-only}

Si vous êtes connecté en tant qu'administrateur, vous pouvez afficher les administrateurs correspondants sur l'instance en ajoutant le paramètre `admins: true` à la requête. Remplacez la deuxième ligne par :

```graphql
  users(usernames: ["user1", "user3", "user4"], admins: true) {
    ...
  }
```

Ou vous pouvez obtenir tous les administrateurs :

```graphql
  users(admins: true) {
    ...
  }
```

## Pagination et nœuds de graphe {#pagination-and-graph-nodes}

La requête comprend :

- [`pageInfo`](#pageinfo)
- [`nodes`](#nodes)

### `pageInfo` {#pageinfo}

Ceci contient les données nécessaires à la mise en œuvre de la pagination. GitLab utilise la [pagination](getting_started.md#pagination) basée sur les curseurs. Pour plus d'informations, consultez [Pagination](https://graphql.org/learn/pagination/) dans la documentation GraphQL.

### `nodes` {#nodes}

Dans une requête GraphQL, `nodes` représente une collection de [`nodes` sur un graphe](https://en.wikipedia.org/wiki/Vertex_(graph_theory)). Dans ce cas, la collection de nœuds est une collection d'objets `User`. Pour chacun d'eux, la sortie comprend :

- L'`id` de l'utilisateur.
- Le fragment `membership`, qui représente l'appartenance à un projet ou à un groupe pour cet utilisateur. Les fragments sont indiqués par la notation `...memberships`.

## Sujets connexes {#related-topics}

- [Référence de l'API GraphQL](reference/_index.md)
- [Entités spécifiques à GraphQL, comme les fragments et les interfaces](https://graphql.org/learn/)
