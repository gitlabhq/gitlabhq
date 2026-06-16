---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des feature flags
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/9566) dans GitLab Premium 12.5.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) vers GitLab Free dans la version 13.5.

{{< /history >}}

Utilisez cette API pour interagir avec les [feature flags](../operations/feature_flags.md) GitLab.

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

## Lister les feature flags d'un projet {#list-feature-flags-for-a-project}

Récupère tous les feature flags du projet demandé.

```plaintext
GET /projects/:id/feature_flags
```

Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

| Attribut           | Type             | Obligatoire   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                            |
| `scope`             | string           | non         | La condition des feature flags, parmi : `enabled`, `disabled`.                                                              |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags"
```

Exemple de réponse :

```json
[
   {
      "name":"merge_train",
      "description":"This feature is about merge train",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:51.423Z",
      "updated_at":"2019-11-04T08:13:51.423Z",
      "scopes":[],
      "strategies": [
        {
          "id": 1,
          "name": "userWithId",
          "parameters": {
            "userIds": "user1"
          },
          "scopes": [
            {
              "id": 1,
              "environment_scope": "production"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"new_live_trace",
      "description":"This is a new live trace feature",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "default",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"user_list",
      "description":"This feature is about user list",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "gitlabUserList",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": {
            "id": 1,
            "iid": 1,
            "name": "My user list",
            "user_xids": "user1,user2,user3"
          }
        }
      ]
   }
]
```

## Récupérer un feature flag {#retrieve-a-feature-flag}

Récupère un feature flag spécifié.

```plaintext
GET /projects/:id/feature_flags/:feature_flag_name
```

Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |
| `feature_flag_name` | string           | oui        | Le nom du feature flag.                                                          |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```

Exemple de réponse :

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ],
      "user_list": null
    }
  ]
}
```

## Créer un feature flag {#create-a-feature-flag}

Crée un feature flag pour un projet spécifié.

```plaintext
POST /projects/:id/feature_flags
```

| Attribut           | Type             | Obligatoire   | Description                                                                                                                                                                                                                                                                              |
| ------------------- | ---------------- | ---------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                                                                                                                                                                                     |
| `name`              | string           | oui        | Le nom du feature flag.                                                                                                                                                                                                                                                            |
| `version`           | string           | oui        | **Déprécié** La version du feature flag. Doit être `new_version_flag`. Omettre pour créer un feature flag Legacy.                                                                                                                                                                        |
| `description`       | string           | non         | La description du feature flag.                                                                                                                                                                                                                                                     |
| `active`            | boolean          | non         | L'état actif du flag. La valeur par défaut est true.                                                                                                                                                                                                                                          |
| `strategies`        | tableau d'objets JSON de stratégie | non         | Les [stratégies](../operations/feature_flags.md#feature-flag-strategies) du feature flag.                                                                                                                                                                                     |
| `strategies:name`   | JSON             | non         | Le nom de la stratégie. Peut être `default`, `gradualRolloutUserId`, `userWithId` ou `gitlabUserList`. Dans [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/36380) et les versions ultérieures, peut être [`flexibleRollout`](https://docs.getunleash.io/user_guide/activation_strategy/#gradual-rollout). |
| `strategies:parameters` | JSON         | non         | Les paramètres de la stratégie.                                                                                                                                                                                                                                                                 |
| `strategies:scopes` | JSON             | non         | Les portées de la stratégie.                                                                                                                                                                                                                                                             |
| `strategies:scopes:environment_scope` | string | non | La portée d'environnement de la portée.                                                                                                                                                                                                                                                      |
| `strategies:user_list_id` | entier ou chaîne | non     | L'ID de la liste d'utilisateurs du feature flag. Si la stratégie est `gitlabUserList`.                                                                                                                                                                                                                   |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "name": "awesome_feature",
  "version": "new_version_flag",
  "strategies": [{ "name": "default", "parameters": {}, "scopes": [{ "environment_scope": "production" }] }]
}
EOF
```

Exemple de réponse :

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## Mettre à jour un feature flag {#update-a-feature-flag}

Met à jour un feature flag spécifié.

```plaintext
PUT /projects/:id/feature_flags/:feature_flag_name
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).   |
| `feature_flag_name` | string           | oui        | Le nom actuel du feature flag.                                                  |
| `description`       | string           | non         | La description du feature flag.                                                   |
| `active`            | boolean          | non         | L'état actif du flag.                                                          |
| `name`              | string           | non         | Le nouveau nom du feature flag.                                                      |
| `strategies`        | tableau d'objets JSON de stratégie | non         | Les [stratégies](../operations/feature_flags.md#feature-flag-strategies) du feature flag. |
| `strategies:id`     | JSON             | non         | L'ID de la stratégie du feature flag.                                                          |
| `strategies:name`   | JSON             | non         | Le nom de la stratégie.                                                                     |
| `strategies:_destroy` | boolean         | non         | Supprimer la stratégie si la valeur est true.                                                        |
| `strategies:parameters` | JSON         | non         | Les paramètres de la stratégie.                                                               |
| `strategies:scopes` | JSON             | non         | Les portées de la stratégie.                                                           |
| `strategies:scopes:id` | JSON          | non         | L'ID de la portée d'environnement.                                                              |
| `strategies:scopes:environment_scope` | string | non | La portée d'environnement de la portée.                                                    |
| `strategies:scopes:_destroy` | boolean | non | Supprimer la portée si la valeur est true.                                                                    |
| `strategies:user_list_id` | entier ou chaîne | non     | L'ID de la liste d'utilisateurs du feature flag. Si la stratégie est `gitlabUserList`.                 |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "strategies": [{ "name": "gradualRolloutUserId", "parameters": { "groupId": "default", "percentage": "25" }, "scopes": [{ "environment_scope": "staging" }] }]
}
EOF
```

Exemple de réponse :

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T20:10:32.891Z",
  "updated_at": "2020-05-13T20:10:32.891Z",
  "scopes": [],
  "strategies": [
    {
      "id": 38,
      "name": "gradualRolloutUserId",
      "parameters": {
        "groupId": "default",
        "percentage": "25"
      },
      "scopes": [
        {
          "id": 40,
          "environment_scope": "staging"
        }
      ]
    },
    {
      "id": 37,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 39,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## Supprimer un feature flag {#delete-a-feature-flag}

Supprime un feature flag spécifié.

```plaintext
DELETE /projects/:id/feature_flags/:feature_flag_name
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |
| `feature_flag_name` | string           | oui        | Le nom du feature flag.                                                          |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```
