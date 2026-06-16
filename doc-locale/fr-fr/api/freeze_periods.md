---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des périodes de gel
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [périodes de gel du déploiement](../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) de déploiement.

## Lister les périodes de gel du déploiement {#list-freeze-periods}

Liste paginée des périodes de gel du déploiement, triées par `created_at` par ordre croissant.

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

```plaintext
GET /projects/:id/freeze_periods
```

| Attribut     | Type           | Obligatoire | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

Exemple de réponse :

```json
[
   {
      "id":1,
      "freeze_start":"0 23 * * 5",
      "freeze_end":"0 8 * * 1",
      "cron_timezone":"UTC",
      "created_at":"2020-05-15T17:03:35.702Z",
      "updated_at":"2020-05-15T17:06:41.566Z"
   }
]
```

## Récupérer une période de gel du déploiement {#retrieve-a-freeze-period}

Récupère une période de gel du déploiement pour un `freeze_period_id` spécifié.

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| Attribut     | Type           | Obligatoire | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `freeze_period_id`    | entier         | oui      | L'ID de la période de gel du déploiement.                                     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

Exemple de réponse :

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Créer une période de gel du déploiement {#create-a-freeze-period}

Crée une période de gel du déploiement pour un projet spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
POST /projects/:id/freeze_periods
```

| Attribut          | Type            | Obligatoire                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | entier ou chaîne  | oui                         | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                              |
| `freeze_start`     | string          | oui                         | Début de la période de gel du déploiement au format [cron](https://crontab.guru/).                                                              |
| `freeze_end`       | string          | oui                         | Fin de la période de gel du déploiement au format [cron](https://crontab.guru/).                                                                |
| `cron_timezone`    | string          | non                          | Le fuseau horaire pour les champs cron, par défaut UTC si non renseigné.                                                               |

Exemple de requête :

```shell
curl --request POST \
  --header 'Content-Type: application/json' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{ "freeze_start": "0 23 * * 5", "freeze_end": "0 7 * * 1", "cron_timezone": "UTC" }' \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

Exemple de réponse :

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 7 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:03:35.702Z"
}
```

## Mettre à jour une période de gel du déploiement {#update-a-freeze-period}

Met à jour une période de gel du déploiement pour un `freeze_period_id` spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
PUT /projects/:id/freeze_periods/:freeze_period_id
```

| Attribut     | Type            | Obligatoire | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne  | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                         |
| `freeze_period_id`    | entier          | oui      | L'ID de la période de gel du déploiement.                                                              |
| `freeze_start`     | string          | non                         | Début de la période de gel du déploiement au format [cron](https://crontab.guru/).                                                              |
| `freeze_end`       | string          | non                         | Fin de la période de gel du déploiement au format [cron](https://crontab.guru/).                                                                |
| `cron_timezone`    | string          | non                          | Le fuseau horaire pour les champs cron.                                                               |

Exemple de requête :

```shell
curl --request PUT \
  --header 'Content-Type: application/json' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{ "freeze_end": "0 8 * * 1" }' \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

Exemple de réponse :

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Supprimer une période de gel du déploiement {#delete-a-freeze-period}

Supprime une période de gel du déploiement pour un `freeze_period_id` spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| Attribut     | Type           | Obligatoire | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `freeze_period_id`    | entier         | oui      | L'ID de la période de gel du déploiement.                                     |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```
