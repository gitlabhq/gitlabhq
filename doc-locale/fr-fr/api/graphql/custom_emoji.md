---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser des emoji personnalisés avec GraphQL
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911) dans GitLab 13.6 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `custom_emoji`. Désactivé par défaut.
- Activé sur GitLab.com dans GitLab 14.0.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138969) dans GitLab 16.7.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/) dans GitLab 16.9. L'indicateur de fonctionnalité `custom_emoji` a été supprimé.

{{< /history >}}

Pour utiliser des [emoji personnalisés](../../user/emoji_reactions.md) dans les commentaires et les descriptions, vous pouvez les ajouter à un groupe principal à l'aide de l'API GraphQL.

## Créer un emoji personnalisé {#create-a-custom-emoji}

```graphql
mutation CreateCustomEmoji($groupPath: ID!) {
  createCustomEmoji(input: {groupPath: $groupPath, name: "party-parrot", url: "https://cultofthepartyparrot.com/parrots/hd/parrot.gif"}) {
    clientMutationId
    customEmoji {
      name
    }
    errors
  }
}
```

Après avoir ajouté un emoji personnalisé au groupe, les membres peuvent l'utiliser de la même manière que les autres emoji dans les commentaires.

### Attributs {#attributes}

La requête accepte ces attributs :

| Attribut    | Type           | Obligatoire               | Description |
| :----------- | :------------- | :--------------------- | :---------- |
| `group_path` | entier ou chaîne | Oui | ID ou [chemin encodé en URL du groupe principal](../rest/_index.md#namespaced-paths). |
| `name`       | string         | Oui | Nom de l'emoji personnalisé. |
| `file`       | string         | Oui | URL de l'image de l'emoji personnalisé. |

## Utiliser GraphiQL {#use-graphiql}

Vous pouvez utiliser GraphiQL pour interroger les emoji d'un groupe.

1. Ouvrez GraphiQL :
   - Pour GitLab.com, utilisez : `https://gitlab.com/-/graphql-explorer`
   - Pour GitLab Self-Managed, utilisez : `https://gitlab.example.com/-/graphql-explorer`
1. Copiez le texte suivant et collez-le dans la fenêtre de gauche. Dans cette requête, `gitlab-org` est le chemin du groupe.

   ```graphql
       query GetCustomEmoji {
         group(fullPath: "gitlab-org") {
           id
           customEmoji {
             nodes {
               name,
               url
             }
           }
         }
       }
   ```

1. Sélectionnez **Play**.

## Sujets connexes {#related-topics}

- [Référence de l'API GraphQL](reference/_index.md)
- [Entités spécifiques à GraphQL, comme les fragments et les interfaces](https://graphql.org/learn/)
