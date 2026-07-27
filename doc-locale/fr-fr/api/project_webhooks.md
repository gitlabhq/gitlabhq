---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des webhooks de projet
description: "Configurez et gérez des webhooks pour un projet avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [webhooks de projet](../user/project/integrations/webhooks.md). Les webhooks de projet sont différents des [hooks système](system_hooks.md) qui impactent l'ensemble de l'instance, et des [webhooks de groupe](group_webhooks.md) qui impactent tous les projets et sous-groupes d'un groupe.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Maintainer ou Owner pour le projet.

## Lister les webhooks d'un projet {#list-webhooks-for-a-project}

Obtenez la liste des webhooks d'un projet.

```plaintext
GET /projects/:id/hooks
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

## Récupérer un webhook de projet {#retrieve-a-project-webhook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- Les attributs `token_present` et `signing_token_present` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0.

{{< /history >}}

Récupère un webhook spécifié pour un projet.

```plaintext
GET /projects/:id/hooks/:hook_id
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID d'un webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de réponse :

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "project_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "releases_events": true,
  "milestone_events": true,
  "feature_flag_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ],
  "token_present": false,
  "signing_token_present": false
}
```

## Lister les événements d'un webhook de projet {#list-project-webhook-events}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048) dans GitLab 17.3.

{{< /history >}}

Répertorie tous les événements d'un webhook de projet spécifié au cours des 7 derniers jours à partir de la date de début.

```plaintext
GET /projects/:id/hooks/:hook_id/events
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|:-----------|:------------------|:---------|:------------|
| `hook_id`  | integer           | Oui      | ID d'un webhook de projet. |
| `id`       | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `status`   | entier ou chaîne de caractères | Non       | Code de statut de réponse des événements, par exemple : `200` ou `500`. Vous pouvez rechercher par catégorie de statut :  `successful` (200-299), `client_failure` (400-499) et `server_failure` (500-599). |
| `page`     | integer           | Non       | Page à récupérer. La valeur par défaut est `1`. |
| `per_page` | integer           | Non       | Nombre d'enregistrements à retourner par page. La valeur par défaut est `20`. |

Exemple de réponse :

```json
[
  {
    "id": 1,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "3a427872-00df-429c-9bc9-a9475de2efe4",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:17 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0906479999999874,
    "response_status": "200"
  },
  {
    "id": 2,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "7c6e0583-49f2-4dc5-a50b-4c0bcf3c1b27",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "842d7c3e-3114-4396-8a95-66c084d53cb1",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:19 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0716120000000728,
    "response_status": "200"
  }
]
```

## Renvoyer un événement de webhook de projet {#resend-a-project-webhook-event}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130) dans GitLab 17.4.

{{< /history >}}

Renvoyez un événement de webhook de projet spécifique.

Cet endpoint a une limite de débit de cinq requêtes par minute pour chaque webhook de projet et utilisateur authentifié. Pour désactiver cette limite sur GitLab Self-Managed et GitLab Dedicated, un administrateur peut [désactiver le feature flag](../administration/feature_flags/_index.md) nommé `web_hook_event_resend_api_endpoint_rate_limit`.

```plaintext
POST /projects/:id/hooks/:hook_id/events/:hook_event_id/resend
```

Attributs pris en charge :

| Attribut       | Type    | Obligatoire | Description |
|:----------------|:--------|:---------|:------------|
| `hook_event_id` | integer | Oui      | ID d'un événement de webhook de projet. |
| `hook_id`       | integer | Oui      | ID d'un webhook de projet. |

Exemple de réponse :

```json
{
  "response_status": 200
}
```

## Ajouter un webhook à un projet {#add-a-webhook-to-a-project}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- L'attribut `signing_token` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0 [avec un flag](../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.
- Le feature flag `webhook_signing_token` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/596374) dans GitLab 19.1.

{{< /history >}}

Ajoutez un webhook à un projet spécifié.

```plaintext
POST /projects/:id/hooks
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
|:-------------------------------|:------------------|:---------|:------------|
| `id`                           | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `url`                          | string            | Oui      | URL du webhook de projet. |
| `branch_filter_strategy`       | string            | Non       | Filtrer les événements push par branche. Les valeurs possibles sont `wildcard` (par défaut), `regex` et `all_branches`. |
| `confidential_issues_events`   | boolean           | Non       | Déclenche le webhook de projet sur les événements de ticket confidentiel. |
| `confidential_note_events`     | boolean           | Non       | Déclenche le webhook de projet sur les événements de note confidentielle. |
| `custom_headers`               | array             | Non       | En-têtes personnalisés pour le webhook de projet. |
| `custom_webhook_template`      | string            | Non       | Modèle de webhook personnalisé pour le webhook de projet. |
| `deployment_events`            | boolean           | Non       | Déclenche le webhook de projet sur les événements de déploiement. |
| `description`                  | string            | Non       | Description du webhook. |
| `enable_ssl_verification`      | boolean           | Non       | Effectue la vérification SSL lors du déclenchement du webhook. |
| `feature_flag_events`          | boolean           | Non       | Déclenche le webhook de projet sur les événements de feature flag. |
| `issues_events`                | boolean           | Non       | Déclenche le webhook de projet sur les événements de ticket. |
| `job_events`                   | boolean           | Non       | Déclenche le webhook de projet sur les événements de job. |
| `merge_requests_events`        | boolean           | Non       | Déclenche le webhook de projet sur les événements de merge request. |
| `milestone_events`             | boolean           | Non       | Déclenche le webhook de projet sur les événements de jalon. |
| `name`                         | string            | Non       | Nom du webhook de projet. |
| `note_events`                  | boolean           | Non       | Déclenche le webhook de projet sur les événements de note. |
| `pipeline_events`              | boolean           | Non       | Déclenche le webhook de projet sur les événements de pipeline. |
| `push_events`                  | boolean           | Non       | Déclenche le webhook de projet sur les événements push. |
| `push_events_branch_filter`    | string            | Non       | Déclenche le webhook de projet sur les événements push uniquement pour les branches correspondantes. |
| `releases_events`              | boolean           | Non       | Déclenche le webhook de projet sur les événements de release. |
| `resource_access_token_events` | boolean           | Non       | Déclenche le webhook de projet sur les événements d'expiration du jeton d'accès au projet. |
| `signing_token`                | string            | Non       | Jeton de signature HMAC utilisé pour calculer l'en-tête `webhook-signature`. Doit être au format `whsec_<base64>` encodant une clé de 32 octets. Non retourné dans la réponse. |
| `tag_push_events`              | boolean           | Non       | Déclenche le webhook de projet sur les événements de push de tag. |
| `token`                        | string            | Non       | Jeton secret pour valider les charges utiles reçues. Non retourné dans la réponse. |
| `wiki_page_events`             | boolean           | Non       | Déclenche le webhook de projet sur les événements wiki. |
| `resource_deploy_token_events` | boolean           | Non       | Déclenche le webhook de projet sur les événements d'expiration du jeton de déploiement de projet. |

## Mettre à jour un webhook de projet {#update-a-project-webhook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- L'attribut `signing_token` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0 [avec un flag](../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.
- Le feature flag `webhook_signing_token` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/596374) dans GitLab 19.1.

{{< /history >}}

Met à jour un webhook de projet pour un projet spécifié.

```plaintext
PUT /projects/:id/hooks/:hook_id
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
|:-------------------------------|:------------------|:---------|:------------|
| `hook_id`                      | integer           | Oui      | ID du webhook de projet. |
| `id`                           | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `url`                          | string            | Oui      | URL du webhook de projet. |
| `branch_filter_strategy`       | string            | Non       | Filtrer les événements push par branche. Les valeurs possibles sont `wildcard` (par défaut), `regex` et `all_branches`. |
| `custom_headers`               | array             | Non       | En-têtes personnalisés pour le webhook de projet. |
| `custom_webhook_template`      | string            | Non       | Modèle de webhook personnalisé pour le webhook de projet. |
| `description`                  | string            | Non       | Description du webhook de projet. |
| `confidential_issues_events`   | boolean           | Non       | Déclenche le webhook de projet sur les événements de ticket confidentiel. |
| `confidential_note_events`     | boolean           | Non       | Déclenche le webhook de projet sur les événements de note confidentielle. |
| `deployment_events`            | boolean           | Non       | Déclenche le webhook de projet sur les événements de déploiement. |
| `enable_ssl_verification`      | boolean           | Non       | Effectue la vérification SSL lors du déclenchement du hook. |
| `feature_flag_events`          | boolean           | Non       | Déclenche le webhook de projet sur les événements de feature flag. |
| `issues_events`                | boolean           | Non       | Déclenche le webhook de projet sur les événements de ticket. |
| `job_events`                   | boolean           | Non       | Déclenche le webhook de projet sur les événements de job. |
| `merge_requests_events`        | boolean           | Non       | Déclenche le webhook de projet sur les événements de merge request. |
| `milestone_events`             | boolean           | Non       | Déclenche le webhook de projet sur les événements de jalon. |
| `name`                         | string            | Non       | Nom du webhook de projet. |
| `note_events`                  | boolean           | Non       | Déclenche le webhook de projet sur les événements de note. |
| `pipeline_events`              | boolean           | Non       | Déclenche le webhook de projet sur les événements de pipeline. |
| `push_events`                  | boolean           | Non       | Déclenche le webhook de projet sur les événements push. |
| `push_events_branch_filter`    | string            | Non       | Déclenche le webhook de projet sur les événements push uniquement pour les branches correspondantes. |
| `releases_events`              | boolean           | Non       | Déclenche le webhook de projet sur les événements de release. |
| `resource_access_token_events` | boolean           | Non       | Déclenche le webhook de projet sur les événements d'expiration du jeton d'accès au projet. |
| `signing_token`                | string            | Non       | Jeton de signature HMAC utilisé pour calculer l'en-tête `webhook-signature`. Doit être au format `whsec_<base64>` encodant une clé de 32 octets. Non retourné dans la réponse. |
| `tag_push_events`              | boolean           | Non       | Déclenche le webhook de projet sur les événements de push de tag. |
| `token`                        | string            | Non       | Jeton secret pour valider les charges utiles reçues. Non retourné dans la réponse. Lorsque vous modifiez l'URL du webhook, le jeton secret est réinitialisé et non conservé. |
| `wiki_page_events`             | boolean           | Non       | Déclenche le webhook de projet sur les événements de page wiki. |
| `resource_deploy_token_events` | boolean           | Non       | Déclenche le webhook de projet sur les événements d'expiration du jeton de déploiement de projet. |

## Supprimer un webhook de projet {#delete-project-webhook}

Supprimez un webhook d'un projet. Cette méthode est idempotente et peut être appelée plusieurs fois. Le webhook de projet est soit disponible, soit absent.

```plaintext
DELETE /projects/:id/hooks/:hook_id
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID du webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Notez que la réponse JSON diffère selon que le webhook de projet est disponible ou non. Si le hook de projet est disponible avant d'être retourné dans la réponse JSON, ou une réponse vide est retournée.

## Déclencher un webhook de projet de test {#trigger-a-test-project-webhook}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656) dans GitLab 16.11.
- Limite de débit spéciale [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150066) dans GitLab 17.0 [avec un flag](../administration/feature_flags/_index.md) nommé `web_hook_test_api_endpoint_rate_limit`. Activé par défaut.

{{< /history >}}

Déclenchez un webhook de projet de test pour un projet spécifié.

Dans GitLab 17.0 et versions ultérieures, cet endpoint a une limite de débit spéciale :

- Dans GitLab 17.0, le débit était de trois requêtes par minute pour chaque webhook de projet.
- Dans GitLab 17.1, ce débit a été modifié à cinq requêtes par minute pour chaque projet et utilisateur authentifié.

Pour désactiver cette limite sur GitLab Self-Managed et GitLab Dedicated, un administrateur peut [désactiver le feature flag](../administration/feature_flags/_index.md) nommé `web_hook_test_api_endpoint_rate_limit`.

```plaintext
POST /projects/:id/hooks/:hook_id/test/:trigger
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID du webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `trigger` | string            | Oui      | L'un des suivants : `push_events`, `tag_push_events`, `issues_events`, `confidential_issues_events`, `note_events`, `merge_requests_events`, `job_events`, `pipeline_events`, `wiki_page_events`, `releases_events`, `milestone_events`, `emoji_events`,`resource_access_token_events` ou `resource_deploy_token_events`. |

Exemple de réponse :

```json
{"message":"201 Created"}
```

## Définir un en-tête personnalisé {#set-a-custom-header}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) dans GitLab 17.1.

{{< /history >}}

```plaintext
PUT /projects/:id/hooks/:hook_id/custom_headers/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID du webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `key`     | string            | Oui      | Clé de l'en-tête personnalisé. |
| `value`   | string            | Oui      | Valeur de l'en-tête personnalisé. |

En cas de succès, cet endpoint retourne le code de réponse `204 No Content`.

## Supprimer un en-tête personnalisé {#delete-a-custom-header}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) dans GitLab 17.1.

{{< /history >}}

```plaintext
DELETE /projects/:id/hooks/:hook_id/custom_headers/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID du webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `key`     | string            | Oui      | Clé de l'en-tête personnalisé. |

En cas de succès, cet endpoint retourne le code de réponse `204 No Content`.

## Définir une variable d'URL {#set-a-url-variable}

```plaintext
PUT /projects/:id/hooks/:hook_id/url_variables/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID du webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `key`     | string            | Oui      | Clé de la variable d'URL. |
| `value`   | string            | Oui      | Valeur de la variable d'URL. |

En cas de succès, cet endpoint retourne le code de réponse `204 No Content`.

## Supprimer une variable d'URL {#delete-a-url-variable}

```plaintext
DELETE /projects/:id/hooks/:hook_id/url_variables/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Oui      | ID du webhook de projet. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `key`     | string            | Oui      | Clé de la variable d'URL. |

En cas de succès, cet endpoint retourne le code de réponse `204 No Content`.
