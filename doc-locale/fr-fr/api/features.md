---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des feature flags
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette API permet de gérer les feature flags basés sur Flipper utilisés dans le développement de GitLab.

Toutes les méthodes nécessitent une autorisation administrateur.

Notez que l'API ne prend en charge que les valeurs de gate booléennes et de pourcentage de temps.

## Lister tous les feature flags {#list-all-feature-flags}

Lister tous les feature flags persistants, avec leurs valeurs de gate.

```plaintext
GET /features
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features"
```

Exemple de réponse :

```json
[
  {
    "name": "experimental_feature",
    "state": "off",
    "gates": [
      {
        "key": "boolean",
        "value": false
      }
    ],
    "definition": null
  },
  {
    "name": "my_user_feature",
    "state": "on",
    "gates": [
      {
        "key": "percentage_of_actors",
        "value": 34
      }
    ],
    "definition": {
      "name": "my_user_feature",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
      "group": "group::ci",
      "type": "development",
      "default_enabled": false
    }
  },
  {
    "name": "new_library",
    "state": "on",
    "gates": [
      {
        "key": "boolean",
        "value": true
      }
    ],
    "definition": null
  }
]
```

## Lister toutes les définitions de feature flag {#list-all-feature-flag-definitions}

Lister toutes les définitions de feature flag.

```plaintext
GET /features/definitions
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features/definitions"
```

Exemple de réponse :

```json
[
  {
    "name": "geo_pages_deployment_replication",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68662",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/337676",
    "milestone": "14.3",
    "log_state_changes": null,
    "type": "development",
    "group": "group::geo",
    "default_enabled": true
  }
]
```

## Créer ou mettre à jour un feature flag {#create-or-update-a-feature-flag}

Créer ou mettre à jour la valeur de gate d'un feature flag. Si un feature flag portant ce nom n'existe pas encore, il est créé. La valeur peut être un booléen ou un entier pour indiquer le pourcentage de temps.

> [!warning]
> Avant d'activer une fonctionnalité encore en développement, vous devez comprendre les [risques de sécurité et de stabilité](../administration/feature_flags/_index.md#risks-when-enabling-features-still-in-development).

```plaintext
POST /features/:name
```

| Attribut       | Type           | Obligatoire | Description                                                                                                                                                                                      |
|-----------------|----------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`          | string         | oui      | Nom de la fonctionnalité à créer ou à mettre à jour                                                                                                                                                          |
| `value`         | entier ou chaîne | oui      | `true` ou `false` pour activer/désactiver, ou un entier pour le pourcentage de temps                                                                                                                        |
| `key`           | string         | non       | `percentage_of_actors` ou `percentage_of_time` (par défaut)                                                                                                                                         |
| `feature_group` | string         | non       | Un nom de groupe de fonctionnalités                                                                                                                                                                             |
| `user`          | string         | non       | Un nom d'utilisateur GitLab ou plusieurs noms d'utilisateur séparés par des virgules                                                                                                                                          |
| `group`         | string         | non       | Le chemin d'un groupe GitLab, par exemple `gitlab-org`, ou plusieurs chemins de groupe séparés par des virgules                                                                                                         |
| `namespace`     | string         | non       | Le chemin de l'espace de nommage d'un groupe ou d'un utilisateur GitLab, par exemple `john-doe`, ou plusieurs chemins d'espace de nommage séparés par des virgules. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/353117) dans GitLab 15.0. |
| `project`       | string         | non       | Un chemin de projet, par exemple `gitlab-org/gitlab-foss`, ou plusieurs chemins de projet séparés par des virgules                                                                                                 |
| `repository`    | string         | non       | Un chemin de dépôt, par exemple `gitlab-org/gitlab-test.git`, `gitlab-org/gitlab-test.wiki.git`, `snippets/21.git`, entre autres. Utilisez une virgule pour séparer plusieurs chemins de dépôt              |
| `runner`        | string         | non       | Un ID de runner, ou une liste d'ID de runner séparés par des virgules                                                                                                                                               |
| `force`         | boolean        | non       | Ignorer les vérifications de validation des feature flags, telles qu'une définition YAML                                                                                                                                   |

Vous pouvez activer ou désactiver une fonctionnalité pour un `feature_group`, un `user`, un `group`, un `namespace`, un `project`, un `repository`, et un `runner` en un seul appel API.

```shell
curl --request POST \
  --data "value=30" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features/new_library"
```

Exemple de réponse :

```json
{
  "name": "new_library",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_time",
      "value": 30
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

### Définir le pourcentage de déploiement par acteurs {#set-percentage-of-actors-rollout}

Déploiement vers un pourcentage d'acteurs.

```plaintext
POST https://gitlab.example.com/api/v4/features/my_user_feature?private_token=<your_access_token>
Content-Type: application/x-www-form-urlencoded
value=42&key=percentage_of_actors&
```

Exemple de réponse :

```json
{
  "name": "my_user_feature",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_actors",
      "value": 42
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

Déploie `my_user_feature` vers `42%` des acteurs.

## Supprimer un feature flag {#delete-a-feature}

Supprimer une gate de feature flag. Renvoie la même réponse que le feature flag existe ou non.

```plaintext
DELETE /features/:name
```
