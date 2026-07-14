---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des merge trains dans GitLab."
title: API des merge trains
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [merge trains](../ci/pipelines/merge_trains.md).

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

Tous les endpoints de merge train prennent en charge la [pagination décalée](rest/_index.md#offset-based-pagination) à l'aide des paramètres `page` et `per_page`.

## Lister tous les merge trains d'un projet {#list-all-merge-trains-for-a-project}

Liste tous les merge trains d'un projet spécifié.

```plaintext
GET /projects/:id/merge_trains
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `scope`   | string            | Non       | Renvoie les merge trains filtrés selon la portée donnée. Les portées disponibles sont `active` (à fusionner) et `complete` (déjà fusionnés). |
| `sort`    | string            | Non       | Renvoie les merge trains triés par ordre `asc` ou `desc`. Par défaut : `desc`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Horodatage de la création du merge train. |
| `duration`                  | entier  | Temps passé en secondes sur le merge train, ou `null` si non terminé. |
| `id`                        | entier  | ID du merge train. |
| `merged_at`                 | datetime | Horodatage de la fusion de la merge request, ou `null` si non fusionnée. |
| `merge_request`             | objet   | Détails de la merge request. |
| `merge_request.created_at`  | datetime | Horodatage de la création de la merge request. |
| `merge_request.description` | string   | Description de la merge request. |
| `merge_request.id`          | entier  | ID de la merge request. |
| `merge_request.iid`         | entier  | ID interne de la merge request. |
| `merge_request.project_id`  | entier  | ID du projet contenant la merge request. |
| `merge_request.state`       | string   | État de la merge request. |
| `merge_request.title`       | string   | Titre de la merge request. |
| `merge_request.updated_at`  | datetime | Horodatage de la dernière mise à jour de la merge request. |
| `merge_request.web_url`     | string   | URL web de la merge request. |
| `pipeline`                  | objet   | Détails du pipeline, ou `null` si aucun pipeline n'est associé. |
| `pipeline.created_at`       | datetime | Horodatage de la création du pipeline. |
| `pipeline.id`               | entier  | ID du pipeline. |
| `pipeline.iid`              | entier  | ID interne du pipeline. |
| `pipeline.project_id`       | entier  | ID du projet contenant le pipeline. |
| `pipeline.ref`              | string   | Référence Git du pipeline. |
| `pipeline.sha`              | string   | SHA du commit qui a déclenché le pipeline. |
| `pipeline.source`           | string   | Source du déclencheur du pipeline. |
| `pipeline.status`           | string   | Statut du pipeline. |
| `pipeline.updated_at`       | datetime | Horodatage de la dernière mise à jour du pipeline. |
| `pipeline.web_url`          | string   | URL web du pipeline. |
| `status`                    | string   | Statut de la merge request sur le merge train. Valeurs possibles pour les merge trains actifs : `idle`, `fresh` ou `stale`. Valeurs possibles pour les merge trains terminés : `merging`, `merged` ou `skip_merged`. |
| `target_branch`             | string   | Nom de la branche cible. |
| `updated_at`                | datetime | Horodatage de la dernière mise à jour du merge train. |
| `user`                      | objet   | Utilisateur qui a ajouté la merge request au merge train. |
| `user.avatar_url`           | string   | URL de l'avatar de l'utilisateur. |
| `user.id`                   | entier  | ID de l'utilisateur. |
| `user.name`                 | string   | Nom de l'utilisateur. |
| `user.state`                | string   | État du compte utilisateur. |
| `user.username`             | string   | Nom d'utilisateur. |
| `user.web_url`              | string   | URL web du profil utilisateur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_trains"
```

Exemple de réponse :

```json
[
  {
    "id": 110,
    "merge_request": {
      "id": 126,
      "iid": 59,
      "project_id": 20,
      "title": "Test MR 1580978354",
      "description": "",
      "state": "merged",
      "created_at": "2020-02-06T08:39:14.883Z",
      "updated_at": "2020-02-06T08:40:57.038Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/-/merge_requests/59"
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://local.gitlab.test:8181/root"
    },
    "pipeline": {
      "id": 246,
      "sha": "bcc17a8ffd51be1afe45605e714085df28b80b13",
      "ref": "refs/merge-requests/59/train",
      "status": "success",
      "created_at": "2020-02-06T08:40:42.410Z",
      "updated_at": "2020-02-06T08:40:46.912Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/pipelines/246"
    },
    "created_at": "2020-02-06T08:39:47.217Z",
    "updated_at": "2020-02-06T08:40:57.720Z",
    "target_branch": "feature-1580973432",
    "status": "merged",
    "merged_at": "2020-02-06T08:40:57.719Z",
    "duration": 70
  }
]
```

## Lister toutes les merge requests d'un merge train {#list-all-merge-requests-in-a-merge-train}

Liste toutes les merge requests d'un merge train pour une branche cible.

```plaintext
GET /projects/:id/merge_trains/:target_branch
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
| --------------- | ----------------- | -------- | ----------- |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `target_branch` | string            | Oui      | La branche cible du merge train. |
| `scope`         | string            | Non       | Renvoie les merge trains filtrés selon la portée donnée. Les portées disponibles sont `active` (à fusionner) et `complete` (déjà fusionnés). |
| `sort`          | string            | Non       | Renvoie les merge trains triés par ordre `asc` ou `desc`. Par défaut : `desc`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Horodatage de la création du merge train. |
| `duration`                  | entier  | Temps passé en secondes sur le merge train, ou `null` si non terminé. |
| `id`                        | entier  | ID du merge train. |
| `merged_at`                 | datetime | Horodatage de la fusion de la merge request, ou `null` si non fusionnée. |
| `merge_request`             | objet   | Détails de la merge request. |
| `merge_request.created_at`  | datetime | Horodatage de la création de la merge request. |
| `merge_request.description` | string   | Description de la merge request. |
| `merge_request.id`          | entier  | ID de la merge request. |
| `merge_request.iid`         | entier  | ID interne de la merge request. |
| `merge_request.project_id`  | entier  | ID du projet contenant la merge request. |
| `merge_request.state`       | string   | État de la merge request. |
| `merge_request.title`       | string   | Titre de la merge request. |
| `merge_request.updated_at`  | datetime | Horodatage de la dernière mise à jour de la merge request. |
| `merge_request.web_url`     | string   | URL web de la merge request. |
| `pipeline`                  | objet   | Détails du pipeline, ou `null` si aucun pipeline n'est associé. |
| `pipeline.created_at`       | datetime | Horodatage de la création du pipeline. |
| `pipeline.id`               | entier  | ID du pipeline. |
| `pipeline.iid`              | entier  | ID interne du pipeline. |
| `pipeline.project_id`       | entier  | ID du projet contenant le pipeline. |
| `pipeline.ref`              | string   | Référence Git du pipeline. |
| `pipeline.sha`              | string   | SHA du commit qui a déclenché le pipeline. |
| `pipeline.source`           | string   | Source du déclencheur du pipeline. |
| `pipeline.status`           | string   | Statut du pipeline. |
| `pipeline.updated_at`       | datetime | Horodatage de la dernière mise à jour du pipeline. |
| `pipeline.web_url`          | string   | URL web du pipeline. |
| `status`                    | string   | Statut de la merge request sur le merge train. Valeurs possibles pour les merge trains actifs : `idle`, `fresh` ou `stale`. Valeurs possibles pour les merge trains terminés : `merging`, `merged` ou `skip_merged`. |
| `target_branch`             | string   | Nom de la branche cible. |
| `updated_at`                | datetime | Horodatage de la dernière mise à jour du merge train. |
| `user`                      | objet   | Utilisateur qui a ajouté la merge request au merge train. |
| `user.avatar_url`           | string   | URL de l'avatar de l'utilisateur. |
| `user.id`                   | entier  | ID de l'utilisateur. |
| `user.name`                 | string   | Nom de l'utilisateur. |
| `user.state`                | string   | État du compte utilisateur. |
| `user.username`             | string   | Nom d'utilisateur. |
| `user.web_url`              | string   | URL web du profil utilisateur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/main"
```

Exemple de réponse :

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```

## Récupérer le statut du merge train {#retrieve-merge-train-status}

Récupère le statut du merge train d'une merge request spécifiée.

```plaintext
GET /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne de la merge request. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Horodatage de la création du merge train. |
| `duration`                  | entier  | Temps passé en secondes sur le merge train, ou `null` si non terminé. |
| `id`                        | entier  | ID du merge train. |
| `merged_at`                 | datetime | Horodatage de la fusion de la merge request, ou `null` si non fusionnée. |
| `merge_request`             | objet   | Détails de la merge request. |
| `merge_request.created_at`  | datetime | Horodatage de la création de la merge request. |
| `merge_request.description` | string   | Description de la merge request. |
| `merge_request.id`          | entier  | ID de la merge request. |
| `merge_request.iid`         | entier  | ID interne de la merge request. |
| `merge_request.project_id`  | entier  | ID du projet contenant la merge request. |
| `merge_request.state`       | string   | État de la merge request. |
| `merge_request.title`       | string   | Titre de la merge request. |
| `merge_request.updated_at`  | datetime | Horodatage de la dernière mise à jour de la merge request. |
| `merge_request.web_url`     | string   | URL web de la merge request. |
| `pipeline`                  | objet   | Détails du pipeline, ou `null` si aucun pipeline n'est associé. |
| `pipeline.created_at`       | datetime | Horodatage de la création du pipeline. |
| `pipeline.id`               | entier  | ID du pipeline. |
| `pipeline.iid`              | entier  | ID interne du pipeline. |
| `pipeline.project_id`       | entier  | ID du projet contenant le pipeline. |
| `pipeline.ref`              | string   | Référence Git du pipeline. |
| `pipeline.sha`              | string   | SHA du commit qui a déclenché le pipeline. |
| `pipeline.source`           | string   | Source du déclencheur du pipeline. |
| `pipeline.status`           | string   | Statut du pipeline. |
| `pipeline.updated_at`       | datetime | Horodatage de la dernière mise à jour du pipeline. |
| `pipeline.web_url`          | string   | URL web du pipeline. |
| `status`                    | string   | Statut de la merge request sur le merge train. Valeurs possibles pour les merge trains actifs : `idle`, `fresh` ou `stale`. Valeurs possibles pour les merge trains terminés : `merging`, `merged` ou `skip_merged`. |
| `target_branch`             | string   | Nom de la branche cible. |
| `updated_at`                | datetime | Horodatage de la dernière mise à jour du merge train. |
| `user`                      | objet   | Utilisateur qui a ajouté la merge request au merge train. |
| `user.avatar_url`           | string   | URL de l'avatar de l'utilisateur. |
| `user.id`                   | entier  | ID de l'utilisateur. |
| `user.name`                 | string   | Nom de l'utilisateur. |
| `user.state`                | string   | État du compte utilisateur. |
| `user.username`             | string   | Nom d'utilisateur. |
| `user.web_url`              | string   | URL web du profil utilisateur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

Exemple de réponse :

```json
{
  "id": 267,
  "merge_request": {
    "id": 273,
    "iid": 1,
    "project_id": 597,
    "title": "My title 9",
    "description": null,
    "state": "opened",
    "created_at": "2022-10-31T19:06:05.725Z",
    "updated_at": "2022-10-31T19:06:05.725Z",
    "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
  },
  "user": {
    "id": 933,
    "username": "user12",
    "name": "Sidney Jones31",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
    "web_url": "http://localhost/user12"
  },
  "pipeline": {
    "id": 273,
    "iid": 1,
    "project_id": 598,
    "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
    "ref": "main",
    "status": "pending",
    "source": "push",
    "created_at": "2022-10-31T19:06:06.231Z",
    "updated_at": "2022-10-31T19:06:06.231Z",
    "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
  },
  "created_at": "2022-10-31T19:06:06.237Z",
  "updated_at": "2022-10-31T19:06:06.237Z",
  "target_branch": "main",
  "status": "idle",
  "merged_at": null,
  "duration": null
}
```

## Ajouter une merge request à un merge train {#add-a-merge-request-to-a-merge-train}

Ajoute une merge request spécifiée à un merge train.

```plaintext
POST /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

Attributs pris en charge :

| Attribut                | Type              | Obligatoire | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid`      | entier           | Oui      | L'ID interne de la merge request. |
| `auto_merge`             | boolean           | Non       | Si vrai, la merge request est ajoutée au merge train lorsque les vérifications sont validées. Si faux ou non spécifié, la merge request est ajoutée directement au merge train. |
| `sha`                    | string            | Non       | Si présent, le SHA doit correspondre au `HEAD` de la branche source, sinon la fusion échoue. |
| `squash`                 | boolean           | Non       | Si vrai, les commits sont regroupés en un seul commit lors de la fusion. |
| `when_pipeline_succeeds` | boolean           | Non       | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/521290) dans GitLab 17.11. Utilisez `auto_merge` à la place. |

En cas de succès, renvoie :

- [`201 Created`](rest/troubleshooting.md#status-codes) si la merge request est immédiatement ajoutée au merge train.
- [`202 Accepted`](rest/troubleshooting.md#status-codes) si la merge request est planifiée pour être ajoutée au merge train.

Les attributs de réponse suivants sont renvoyés :

| Attribut                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Horodatage de la création du merge train. |
| `duration`                  | entier  | Temps passé en secondes sur le merge train, ou `null` si non terminé. |
| `id`                        | entier  | ID du merge train. |
| `merged_at`                 | datetime | Horodatage de la fusion de la merge request, ou `null` si non fusionnée. |
| `merge_request`             | objet   | Détails de la merge request. |
| `merge_request.created_at`  | datetime | Horodatage de la création de la merge request. |
| `merge_request.description` | string   | Description de la merge request. |
| `merge_request.id`          | entier  | ID de la merge request. |
| `merge_request.iid`         | entier  | ID interne de la merge request. |
| `merge_request.project_id`  | entier  | ID du projet contenant la merge request. |
| `merge_request.state`       | string   | État de la merge request. |
| `merge_request.title`       | string   | Titre de la merge request. |
| `merge_request.updated_at`  | datetime | Horodatage de la dernière mise à jour de la merge request. |
| `merge_request.web_url`     | string   | URL web de la merge request. |
| `pipeline`                  | objet   | Détails du pipeline, ou `null` si aucun pipeline n'est associé. |
| `pipeline.created_at`       | datetime | Horodatage de la création du pipeline. |
| `pipeline.id`               | entier  | ID du pipeline. |
| `pipeline.iid`              | entier  | ID interne du pipeline. |
| `pipeline.project_id`       | entier  | ID du projet contenant le pipeline. |
| `pipeline.ref`              | string   | Référence Git du pipeline. |
| `pipeline.sha`              | string   | SHA du commit qui a déclenché le pipeline. |
| `pipeline.source`           | string   | Source du déclencheur du pipeline. |
| `pipeline.status`           | string   | Statut du pipeline. |
| `pipeline.updated_at`       | datetime | Horodatage de la dernière mise à jour du pipeline. |
| `pipeline.web_url`          | string   | URL web du pipeline. |
| `status`                    | string   | Statut de la merge request sur le merge train. Valeurs possibles pour les merge trains actifs : `idle`, `fresh` ou `stale`. Valeurs possibles pour les merge trains terminés : `merging`, `merged` ou `skip_merged`. |
| `target_branch`             | string   | Nom de la branche cible. |
| `updated_at`                | datetime | Horodatage de la dernière mise à jour du merge train. |
| `user`                      | objet   | Utilisateur qui a ajouté la merge request au merge train. |
| `user.avatar_url`           | string   | URL de l'avatar de l'utilisateur. |
| `user.id`                   | entier  | ID de l'utilisateur. |
| `user.name`                 | string   | Nom de l'utilisateur. |
| `user.state`                | string   | État du compte utilisateur. |
| `user.username`             | string   | Nom d'utilisateur. |
| `user.web_url`              | string   | URL web du profil utilisateur. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

Exemple de réponse :

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```
