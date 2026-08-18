---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Réalisations
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113156) dans GitLab 15.10 [avec le feature flag](../../administration/feature_flags/_index.md) `achievements`. Désactivés par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200774) dans GitLab 19.2.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Les réalisations sont un moyen de récompenser les utilisateurs pour leur activité sur GitLab. En tant que mainteneur ou propriétaire d'un espace de nommage, vous pouvez créer des réalisations personnalisées pour des contributions spécifiques. Vous pouvez attribuer ces réalisations aux utilisateurs ou les révoquer en fonction de critères définis.

En tant qu'utilisateur, vous pouvez collecter des réalisations pour mettre en valeur vos contributions à différents projets ou groupes sur votre profil. Une réalisation se compose d'un nom, d'une description et d'un avatar.

![Réalisations sur la page de profil utilisateur](img/user_profile_achievements_v15_11.png)

Les réalisations sont considérées comme appartenant à l'utilisateur. Elles sont visibles indépendamment du paramètre de visibilité de l'espace de nommage qui a créé la réalisation.

Pour plus d'informations sur les travaux planifiés, consultez l'[epic 9429](https://gitlab.com/groups/gitlab-org/-/epics/9429). Faites-nous part de vos cas d'usage en laissant des commentaires dans l'epic.

## Types de réalisation {#types-of-achievement}

Par programmation, il n'existe qu'une seule façon de créer, attribuer, révoquer ou supprimer des réalisations.

En pratique, vous pouvez faire la distinction entre les réalisations attribuées :

- Une seule fois et irrévocable. Par exemple, une réalisation « Première contribution fusionnée ».
- Une seule fois et révocable. Par exemple, une réalisation « Membre de l'équipe principale ».
- Plusieurs fois. Par exemple, une réalisation « Contributeur du mois ».

## Afficher les réalisations d'un groupe {#view-group-achievements}

Pour afficher toutes les réalisations disponibles et attribuées pour un groupe :

- Accédez à `https://gitlab.com/groups/<group-path>/-/achievements`.

La page affiche une liste de réalisations et les membres qui ont reçu la réalisation.

## Afficher les réalisations d'un utilisateur {#view-a-users-achievements}

Vous pouvez consulter les réalisations d'un utilisateur sur sa page de profil.

Prérequis :

- Le profil de l'utilisateur doit être public.

Pour afficher les réalisations d'un utilisateur :

1. Accédez à la page de profil de l'utilisateur.
1. Sous l'avatar de l'utilisateur, consultez ses réalisations.
1. Pour afficher les détails d'une réalisation, passez le curseur dessus. Les informations suivantes s'affichent :

   - Nom de la réalisation
   - Description de la réalisation
   - Date à laquelle la réalisation a été attribuée à l'utilisateur
   - L'espace de nommage qui a attribué la réalisation si l'utilisateur est membre de l'espace de nommage ou si l'espace de nommage est public

Pour récupérer la liste des réalisations d'un utilisateur, interrogez le [type GraphQL `user`](../../api/graphql/reference/_index.md#user).

Le champ `User.userAchievements` accepte un paramètre facultatif `includeHidden`. Lorsqu'il est défini sur `true`, la réponse inclut les réalisations masquées du profil. Les réalisations masquées ne sont incluses que dans les cas suivants :

- L'utilisateur demandant est le même que l'utilisateur demandé.
- L'utilisateur demandant dispose du rôle Maintainer ou Owner dans le groupe auquel appartient la réalisation.

```graphql
query {
  user(username: "<username>") {
    userAchievements(includeHidden: true) {
      nodes {
        achievement {
          name
          description
          avatarUrl
          namespace {
            fullPath
            name
          }
        }
      }
    }
  }
}
```

## Créer une réalisation {#create-an-achievement}

Vous pouvez créer des réalisations personnalisées à attribuer pour des contributions spécifiques.

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner pour l'espace de nommage.

Pour créer une réalisation :

- Dans l'interface utilisateur :
  1. Sur la [page Réalisations](#view-group-achievements), sélectionnez **Nouvelle réalisation**.
  1. Saisissez un nom pour la réalisation.
  1. Facultatif. Saisissez une description et importez un avatar pour la réalisation.
  1. Sélectionnez **Enregistrer les modifications**.

- Avec l'API GraphQL, appelez la [mutation GraphQL `achievementsCreate`](../../api/graphql/reference/_index.md#mutationachievementscreate) :

  ```graphql
  mutation achievementsCreate($file: Upload!) {
    achievementsCreate(
      input: {
        namespaceId: "gid://gitlab/Namespace/<namespace id>",
        name: "<name>",
        description: "<description>",
        avatar: $file}
    ) {
      errors
      achievement {
        id
        name
        description
        avatarUrl
      }
    }
  }
  ```

  Pour fournir le fichier avatar, appelez la mutation en utilisant `curl` :

  ```shell
  curl "https://gitlab.com/api/graphql" \
    -H "Authorization: Bearer <your-pat-token>" \
    -H "Content-Type: multipart/form-data" \
    -F operations='{ "query": "mutation ($file: Upload!) { achievementsCreate(input: { namespaceId: \"gid://gitlab/Namespace/<namespace-id>\", name: \"<name>\", description: \"<description>\", avatar: $file }) { achievement { id name description avatarUrl } } }", "variables": { "file": null } }' \
    -F map='{ "0": ["variables.file"] }' \
    -F 0='@/path/to/your/file.jpg'
  ```

  En cas de succès, la réponse retourne l'ID de la réalisation :

  ```shell
  {"data":{"achievementsCreate":{"achievement":{"id":"gid://gitlab/Achievements::Achievement/1","name":"<name>","description":"<description>","avatarUrl":"https://gitlab.com/uploads/-/system/achievements/achievement/avatar/1/file.jpg"}}}}
  ```

## Mettre à jour une réalisation {#update-an-achievement}

Vous pouvez modifier le nom, la description et l'avatar d'une réalisation à tout moment.

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner pour l'espace de nommage.

Pour mettre à jour une réalisation, appelez la [mutation GraphQL `achievementsUpdate`](../../api/graphql/reference/_index.md#mutationachievementsupdate).

```graphql
mutation achievementsUpdate($file: Upload!) {
  achievementsUpdate(
    input: {
      achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>",
      name: "<new name>",
      description: "<new description>",
      avatar: $file}
  ) {
    errors
    achievement {
      id
      name
      description
      avatarUrl
    }
  }
}
```

## Attribuer une réalisation {#award-an-achievement}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227918) de l'approbation du destinataire dans GitLab 19.0.

{{< /history >}}

Vous pouvez attribuer des réalisations aux utilisateurs pour reconnaître leurs contributions. Après l'attribution, l'utilisateur reçoit une notification par e-mail avec un lien pour accepter la réalisation. Les réalisations ne sont pas visibles sur un profil tant que l'utilisateur ne les a pas acceptées.

Le lien d'acceptation reste valide pendant 30 jours. Passé ce délai, appelez la [mutation GraphQL `userAchievementsUpdate`](#change-visibility-of-specific-achievements) pour accepter la réalisation.

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner pour l'espace de nommage.

Pour attribuer une réalisation à un utilisateur, appelez la [mutation GraphQL `achievementsAward`](../../api/graphql/reference/_index.md#mutationachievementsaward).

```graphql
mutation {
  achievementsAward(input: {
    achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>",
    userId: "gid://gitlab/User/<user id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
    }
    errors
  }
}
```

## Révoquer une réalisation {#revoke-an-achievement}

Vous pouvez révoquer la réalisation d'un utilisateur si vous estimez que celui-ci ne remplit plus les critères d'attribution.

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner pour l'espace de nommage.

Pour révoquer une réalisation, appelez la [mutation GraphQL `achievementsRevoke`](../../api/graphql/reference/_index.md#mutationachievementsrevoke).

```graphql
mutation {
  achievementsRevoke(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
      revokedAt
    }
    errors
  }
}
```

## Supprimer une réalisation attribuée {#delete-an-awarded-achievement}

Si vous avez attribué une réalisation à un utilisateur par erreur, vous pouvez la supprimer.

Prérequis :

- Vous devez disposer du rôle Owner pour l'espace de nommage.

Pour supprimer une réalisation attribuée, appelez la [mutation GraphQL `userAchievementsDelete`](../../api/graphql/reference/_index.md#mutationuserachievementsdelete).

```graphql
mutation {
  userAchievementsDelete(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
    }
    errors
  }
}
```

## Supprimer une réalisation {#delete-an-achievement}

Si vous estimez que vous n'avez plus besoin d'une réalisation, vous pouvez la supprimer. Cela supprime toutes les instances attribuées et révoquées associées à la réalisation.

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner pour l'espace de nommage.

Pour supprimer une réalisation, appelez la [mutation GraphQL `achievementsDelete`](../../api/graphql/reference/_index.md#mutationachievementsdelete).

```graphql
mutation {
  achievementsDelete(input: {
    achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>" }) {
    achievement {
      id
      name
    }
    errors
  }
}
```

## Masquer les réalisations {#hide-achievements}

Si vous ne souhaitez pas afficher les réalisations sur votre profil, vous pouvez vous désabonner. Pour cela :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la section **Paramètres principaux**, décochez la case **Afficher les réalisations sur votre profil**.
1. Sélectionnez **Mettre à jour les paramètres du profil**.

## Modifier la visibilité de réalisations spécifiques {#change-visibility-of-specific-achievements}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161225) dans GitLab 17.3.

{{< /history >}}

Si vous ne souhaitez pas afficher toutes vos réalisations sur votre profil, vous pouvez modifier la visibilité de réalisations spécifiques.

Pour masquer l'une de vos réalisations, appelez la [mutation GraphQL `userAchievementsUpdate`](../../api/graphql/reference/_index.md#mutationuserachievementsupdate).

```graphql
mutation {
  userAchievementsUpdate(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>"
    showOnProfile: false
  }) {
    userAchievement {
      id
      showOnProfile
    }
    errors
  }
}
```

Pour afficher à nouveau l'une de vos réalisations, appelez la même mutation avec la valeur `true` pour l'argument `showOnProfile`.

## Réorganiser les réalisations {#reorder-achievements}

Par défaut, les réalisations sur votre profil sont affichées par ordre croissant selon la date d'attribution.

Pour modifier l'ordre de vos réalisations, appelez la [mutation GraphQL `userAchievementPrioritiesUpdate`](../../api/graphql/reference/_index.md#mutationuserachievementprioritiesupdate) avec une liste ordonnée de toutes les réalisations prioritaires.

```graphql
mutation {
  userAchievementPrioritiesUpdate(input: {
    userAchievementIds: ["gid://gitlab/Achievements::UserAchievement/<first user achievement id>", "gid://gitlab/Achievements::UserAchievement/<second user achievement id>"],
    }) {
    userAchievements {
      id
      priority
    }
    errors
  }
}
```
