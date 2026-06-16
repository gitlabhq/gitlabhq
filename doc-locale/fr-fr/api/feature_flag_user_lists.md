---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des listes d'utilisateurs des feature flags"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/205409) dans [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) vers GitLab Free dans la version 13.5.

{{< /history >}}

Utilisez cette API pour interagir avec les feature flags GitLab pour les [listes d'utilisateurs](../operations/feature_flags.md#user-list).

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

> [!note]
> Pour interagir avec les feature flags pour tous les utilisateurs, consultez l'[API des feature flags](feature_flags.md).

## Répertorier toutes les listes d'utilisateurs des feature flags pour un projet {#list-all-feature-flag-user-lists-for-a-project}

Répertorie toutes les listes d'utilisateurs des feature flags pour un projet spécifié.

```plaintext
GET /projects/:id/feature_flags_user_lists
```

Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

| Attribut | Type           | Obligatoire | Description                                                                      |
| --------- | -------------- | -------- | -------------------------------------------------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `search`  | string         | non       | Renvoyer les listes d'utilisateurs correspondant aux critères de recherche.                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists"
```

Exemple de réponse :

```json
[
   {
      "name": "user_list",
      "user_xids": "user1,user2",
      "id": 1,
      "iid": 1,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:51.423Z",
      "updated_at": "2020-02-04T08:13:51.423Z"
   },
   {
      "name": "test_users",
      "user_xids": "user3,user4,user5",
      "id": 2,
      "iid": 2,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:10.507Z",
      "updated_at": "2020-02-04T08:13:10.507Z"
   }
]
```

## Créer une liste d'utilisateurs de feature flag {#create-a-feature-flag-user-list}

Crée une liste d'utilisateurs de feature flag dans un projet spécifié.

```plaintext
POST /projects/:id/feature_flags_user_lists
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |
| `name`              | string           | oui        | Le nom de la liste. |
| `user_xids`         | string           | oui        | Une liste d'ID d'utilisateurs externes séparés par des virgules. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists" \
  --data @- << EOF
{
    "name": "my_user_list",
    "user_xids": "user1,user2,user3"
}
EOF
```

Exemple de réponse :

```json
{
   "name": "my_user_list",
   "user_xids": "user1,user2,user3",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-04T08:32:27.288Z"
}
```

## Récupérer une liste d'utilisateurs de feature flag {#retrieve-a-feature-flag-user-list}

Récupère la liste d'utilisateurs de feature flag spécifiée.

```plaintext
GET /projects/:id/feature_flags_user_lists/:iid
```

Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |
| `iid`               | entier ou chaîne   | oui        | L'ID interne de la liste d'utilisateurs de feature flag du projet.                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```

Exemple de réponse :

```json
{
   "name": "my_user_list",
   "user_xids": "123,456",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:13:10.507Z",
   "updated_at": "2020-02-04T08:13:10.507Z"
}
```

## Mettre à jour une liste d'utilisateurs de feature flag {#update-a-feature-flag-user-list}

Met à jour une liste d'utilisateurs de feature flag spécifiée.

```plaintext
PUT /projects/:id/feature_flags_user_lists/:iid
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |
| `iid`               | entier ou chaîne   | oui        | L'ID interne de la liste d'utilisateurs de feature flag du projet.                               |
| `name`              | string           | non         | Le nom de la liste.                                                          |
| `user_xids`         | string           | non         | Une liste d'ID d'utilisateurs externes séparés par des virgules.                                                    |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1" \
  --data @- << EOF
{
    "user_xids": "user2,user3,user4"
}
EOF
```

Exemple de réponse :

```json
{
   "name": "my_user_list",
   "user_xids": "user2,user3,user4",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-05T09:33:17.179Z"
}
```

## Supprimer une liste d'utilisateurs de feature flag {#delete-feature-flag-user-list}

Supprime une liste d'utilisateurs de feature flag spécifiée.

```plaintext
DELETE /projects/:id/feature_flags_user_lists/:iid
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |
| `iid`               | entier ou chaîne   | oui        | L'ID interne de la liste d'utilisateurs de feature flag du projet                                |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```
