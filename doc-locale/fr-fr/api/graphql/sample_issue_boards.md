---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Identifier les tableaux des tickets à l'aide de GraphQL"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez identifier les [tableaux des tickets](../../user/project/issue_board.md) d'un projet en utilisant :

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Utiliser GraphiQL {#use-graphiql}

Vous pouvez utiliser GraphiQL pour lister les tableaux des tickets d'un projet.

1. Ouvrez GraphiQL :
   - Pour GitLab.com, utilisez : `https://gitlab.com/-/graphql-explorer`
   - Pour GitLab Self-Managed, utilisez : `https://gitlab.example.com/-/graphql-explorer`
1. Copiez le texte suivant et collez-le dans la fenêtre de gauche. Cette requête récupère les tableaux des tickets pour le dépôt `docs-gitlab-com`.

   ```graphql
   query {
     project(fullPath: "gitlab-org/technical-writing/docs-gitlab-com") {
       name
       forksCount
       statistics {
         wikiSize
       }
       issuesEnabled
       boards {
         nodes {
           id
           name
         }
       }
     }
   }
   ```

1. Sélectionnez **Play**.

Pour afficher l'un de ces tableaux des tickets, copiez un identifiant numérique depuis la sortie. Par exemple, si l'identifiant est `7174622`, utilisez cette URL pour accéder au tableau des tickets :

```http
https:/gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/boards/7174622
```

## Sujets connexes {#related-topics}

- [Référence de l'API GraphQL](reference/_index.md)
