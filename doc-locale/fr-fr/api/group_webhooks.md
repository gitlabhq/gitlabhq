---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des webhooks de groupe
description: "Configurez et gérez des webhooks pour un groupe avec l'API REST."
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [webhooks de groupe](../user/project/integrations/webhooks.md#group-webhooks). Les webhooks de groupe sont différents des [hooks système](system_hooks.md) qui affectent l'ensemble de l'instance, et des [webhooks de projet](project_webhooks.md) limités à un seul projet.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

## Lister tous les hooks de groupe {#list-all-group-hooks}

Liste tous les hooks de groupe pour un groupe spécifié.

```plaintext
GET /groups/:id/hooks
```

Attributs pris en charge :

| Attribut | Type            | Obligatoire | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères  | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "url": "http://example.com/hook",
    "name": "Test group hook",
    "description": "This is a test group hook.",
    "created_at": "2024-09-01T09:10:54.854Z",
    "push_events": true,
    "tag_push_events": false,
    "merge_requests_events": false,
    "repository_update_events": false,
    "enable_ssl_verification": true,
    "alert_status": "executable",
    "disabled_until": null,
    "url_variables": [],
    "push_events_branch_filter": null,
    "branch_filter_strategy": "all_branches",
    "group_id": 99,
    "issues_events": false,
    "confidential_issues_events": false,
    "note_events": false,
    "confidential_note_events": false,
    "pipeline_events": false,
    "wiki_page_events": false,
    "job_events": false,
    "deployment_events": false,
    "feature_flag_events": false,
    "releases_events": false,
    "milestone_events": false,
    "subgroup_events": false,
    "emoji_events": false,
    "resource_access_token_events": false,
    "member_events": false,
    "project_events": false,
    "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
    "custom_headers": [
      {
        "key": "Authorization"
      }
    ],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## Récupérer un hook de groupe {#retrieve-a-group-hook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- Les attributs `token_present` et `signing_token_present` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0.

{{< /history >}}

Récupère un hook de groupe spécifié.

```plaintext
GET /groups/:id/hooks/:hook_id
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `hook_id` | integer        | oui      | L'ID d'un hook de groupe. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
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
  "feature_flag_events": false,
  "releases_events": true,
  "milestone_events": false,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
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

## Lister tous les événements de hook de groupe {#list-all-group-hook-events}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048) dans GitLab 17.3.

{{< /history >}}

Liste tous les événements d'un hook de groupe spécifié au cours des sept derniers jours à partir de la date de début.

```plaintext
GET /groups/:id/hooks/:hook_id/events
```

Attributs pris en charge :

| Attribut  | Type                 | Obligatoire | Description |
|----------- |--------------------- |--------- |------------ |
| `hook_id`  | Entier              | Oui      | L'ID d'un hook de projet. |
| `id`       | Entier ou chaîne    | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `page`     | Entier              | Non       | Page à récupérer. La valeur par défaut est `1`. |
| `per_page` | Entier              | Non       | Nombre d'enregistrements à retourner par page. La valeur par défaut est `20`. |
| `status`   | Entier ou chaîne    | Non       | Le code de statut de réponse des événements, par exemple : `200` ou `500`. Vous pouvez rechercher par catégorie de statut :  `successful` (200-299), `client_failure` (400-499) et `server_failure` (500-599). |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/events"
```

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
      "Idempotency-Key": "a5461c4d-9c7f-4af9-add6-cddebe3c426f",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
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
      "Idempotency-Key": "1f0a54f0-0529-408d-a5b8-a2a98ff5f94a",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com:3000",
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

### Renvoyer un événement de hook de groupe {#resend-group-hook-event}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130) dans GitLab 17.4.

{{< /history >}}

Renvoie un événement de hook spécifique.

Cet endpoint a une limite de débit de cinq requêtes par minute pour chaque hook et utilisateur authentifié. Pour désactiver cette limite sur GitLab Self-Managed et GitLab Dedicated, un administrateur peut [désactiver le feature flag](../administration/feature_flags/_index.md) nommé `web_hook_event_resend_api_endpoint_rate_limit`.

```plaintext
POST /groups/:id/hooks/:hook_id/events/:hook_event_id/resend
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|---------------- |------------------ |--------- |------------ |
| `hook_event_id` | Entier           | Oui      | L'ID d'un événement de hook. |
| `hook_id`       | Entier           | Oui      | L'ID d'un hook de groupe. |
| `id`            | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/events/1/resend"
```

Exemple de réponse :

```json
{
  "response_status": 200
}
```

## Créer un hook de groupe {#create-a-group-hook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- L'attribut `signing_token` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0 [avec un flag](../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.
- Le feature flag `webhook_signing_token` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/596374) dans GitLab 19.1.

{{< /history >}}

Crée un hook de groupe pour un groupe spécifié.

```plaintext
POST /groups/:id/hooks
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
|------------------------------- |------------------ |--------- |------------ |
| `id`                           | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `url`                          | Chaîne            | Oui      | L'URL du hook. |
| `branch_filter_strategy`       | Chaîne            | Non       | Filtrer les événements push par branche. Les valeurs possibles sont `wildcard` (par défaut), `regex` et `all_branches`. |
| `confidential_issues_events`   | Boolean           | Non       | Déclencher le hook sur les événements de ticket confidentiel. |
| `confidential_note_events`     | Boolean           | Non       | Déclencher le hook sur les événements de note confidentielle. |
| `custom_headers`               | Array             | Non       | En-têtes personnalisés pour le hook. |
| `custom_webhook_template`      | Chaîne            | Non       | Modèle de webhook personnalisé pour le hook. |
| `deployment_events`            | Boolean           | Non       | Déclencher le hook sur les événements de déploiement. |
| `description`                  | Chaîne            | Non       | Description du hook ([introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1). |
| `enable_ssl_verification`      | Boolean           | Non       | Effectue la vérification SSL lors du déclenchement du hook. |
| `feature_flag_events`          | Boolean           | Non       | Déclencher le hook sur les événements de feature flag. |
| `issues_events`                | Boolean           | Non       | Déclencher le hook sur les événements de ticket. |
| `job_events`                   | Boolean           | Non       | Déclencher le hook sur les événements de job. |
| `member_events`                | Boolean           | Non       | Déclencher le hook sur les événements de membre. |
| `merge_requests_events`        | Boolean           | Non       | Déclencher le hook sur les événements de merge request. |
| `milestone_events`             | Boolean           | Non       | Déclencher le hook sur les événements de jalon. |
| `name`                         | Chaîne            | Non       | Nom du hook ([introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1). |
| `note_events`                  | Boolean           | Non       | Déclencher le hook sur les événements de note. |
| `pipeline_events`              | Boolean           | Non       | Déclencher le hook sur les événements de pipeline. |
| `project_events`               | Boolean           | Non       | Déclencher le hook sur les événements de projet. |
| `push_events`                  | Boolean           | Non       | Déclencher le hook sur les événements push. |
| `push_events_branch_filter`    | Chaîne            | Non       | Déclencher le hook sur les événements push uniquement pour les branches correspondantes. |
| `releases_events`              | Boolean           | Non       | Déclencher le hook sur les événements de release. |
| `resource_access_token_events` | Boolean           | Non       | Déclencher le hook sur les événements d'expiration de jeton d'accès au projet. |
| `signing_token`                | Chaîne            | Non       | Jeton de signature HMAC utilisé pour calculer l'en-tête `webhook-signature`. Doit être au format `whsec_<base64>` encodant une clé de 32 octets. Non retourné dans la réponse. |
| `subgroup_events`              | Boolean           | Non       | Déclencher le hook sur les événements de sous-groupe. |
| `tag_push_events`              | Boolean           | Non       | Déclencher le hook sur les événements de push de tag. |
| `token`                        | Chaîne            | Non       | Jeton secret pour valider les charges utiles reçues. Non retourné dans la réponse. |
| `wiki_page_events`             | Boolean           | Non       | Déclencher le hook sur les événements de page wiki. |

Exemple de requête :

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks" \
  --data '{"url": "https://example.com/hook", "name": "My Hook", "description": "Hook description"}'
```

Exemple de réponse :

```json
{
  "id": 42,
  "url": "https://example.com/hook",
  "name": "My Hook",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
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
  "feature_flag_events": true,
  "releases_events": true,
  "milestone_events": true,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "token_present": false,
  "signing_token_present": false
}
```

## Mettre à jour un hook de groupe {#update-a-group-hook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- L'attribut `signing_token` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0 [avec un flag](../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.
- Le feature flag `webhook_signing_token` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/596374) dans GitLab 19.1.

{{< /history >}}

Met à jour un hook de groupe pour un groupe spécifié.

```plaintext
PUT /groups/:id/hooks/:hook_id
```

Attributs pris en charge :

| Attribut                                   | Type              | Obligatoire | Description |
|-------------------------------------------- |------------------ |--------- |------------ |
| `hook_id`                                   | Entier           | Oui      | L'ID du hook de groupe. |
| `id`                                        | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `url`                                       | Chaîne            | Oui      | L'URL du hook. |
| `branch_filter_strategy`                    | Chaîne            | Non       | Filtrer les événements push par branche. Les valeurs possibles sont `wildcard` (par défaut), `regex` et `all_branches`. |
| `confidential_issues_events`                | Boolean           | Non       | Déclencher le hook sur les événements de ticket confidentiel. |
| `confidential_note_events`                  | Boolean           | Non       | Déclencher le hook sur les événements de note confidentielle. |
| `custom_headers`                            | Array             | Non       | En-têtes personnalisés pour le hook. |
| `custom_webhook_template`                   | Chaîne            | Non       | Modèle de webhook personnalisé pour le hook. |
| `deployment_events`                         | Boolean           | Non       | Déclencher le hook sur les événements de déploiement. |
| `description`                               | Chaîne            | Non       | Description du hook. |
| `enable_ssl_verification`                   | Boolean           | Non       | Effectue la vérification SSL lors du déclenchement du hook. |
| `feature_flag_events`                       | Boolean           | Non       | Déclencher le hook sur les événements de feature flag. |
| `issues_events`                             | Boolean           | Non       | Déclencher le hook sur les événements de ticket. |
| `job_events`                                | Boolean           | Non       | Déclencher le hook sur les événements de job. |
| `member_events`                             | Boolean           | Non       | Déclencher le hook sur les événements de membre. |
| `merge_requests_events`                     | Boolean           | Non       | Déclencher le hook sur les événements de merge request. |
| `milestone_events`                          | Boolean           | Non       | Déclencher le hook sur les événements de jalon. |
| `name`                                      | Chaîne            | Non       | Nom du hook. |
| `note_events`                               | Boolean           | Non       | Déclencher le hook sur les événements de note. |
| `pipeline_events`                           | Boolean           | Non       | Déclencher le hook sur les événements de pipeline. |
| `project_events`                            | Boolean           | Non       | Déclencher le hook sur les événements de projet. |
| `push_events`                               | Boolean           | Non       | Déclencher le hook sur les événements push. |
| `push_events_branch_filter`                 | Chaîne            | Non       | Déclencher le hook sur les événements push uniquement pour les branches correspondantes. |
| `releases_events`                           | Boolean           | Non       | Déclencher le hook sur les événements de release. |
| `resource_access_token_events`              | Boolean           | Non       | Déclencher le hook sur les événements d'expiration de jeton d'accès au projet. |
| `service_access_tokens_expiration_enforced` | Boolean           | Non       | Exiger que les jetons d'accès des comptes de service aient une date d'expiration. |
| `signing_token`                             | Chaîne            | Non       | Jeton de signature HMAC utilisé pour calculer l'en-tête `webhook-signature`. Doit être au format `whsec_<base64>` encodant une clé de 32 octets. Non retourné dans la réponse. |
| `subgroup_events`                           | Boolean           | Non       | Déclencher le hook sur les événements de sous-groupe. |
| `tag_push_events`                           | Boolean           | Non       | Déclencher le hook sur les événements de push de tag. |
| `token`                                     | Chaîne            | Non       | Jeton secret pour valider les charges utiles reçues. Non retourné dans la réponse. Lorsque vous modifiez l'URL du webhook, le jeton secret est réinitialisé et non conservé. |
| `wiki_page_events`                          | Boolean           | Non       | Déclencher le hook sur les événements de page wiki. |

Exemple de requête :

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1" \
  --data '{"url": "https://example.com/hook", "name": "New hook name", "description": "Changed hook description"}'
```

Exemple de réponse :

```json
{
  "id": 1,
  "url": "https://example.com/hook",
  "name": "New hook name",
  "description": "Changed hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
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
  "feature_flag_events": true,
  "releases_events": true,
  "milestone_events": true,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
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

## Supprimer un hook de groupe {#delete-a-group-hook}

Supprime un hook de groupe spécifié. Il s'agit d'une méthode idempotente pouvant être appelée plusieurs fois. Le hook est disponible ou non.

```plaintext
DELETE /groups/:id/hooks/:hook_id
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `hook_id` | Entier           | Oui      | L'ID du hook de groupe. |
| `id`      | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

En cas de succès, aucun message n'est retourné.

## Déclencher un hook de groupe test {#trigger-a-test-group-hook}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/455589) dans GitLab 17.1.
- Limite de débit spéciale [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486) dans GitLab 17.1 [avec un flag](../administration/feature_flags/_index.md) nommé `web_hook_test_api_endpoint_rate_limit`. Activé par défaut.

{{< /history >}}

Déclenche un hook test pour un groupe spécifié.

Cet endpoint a une limite de débit de cinq requêtes par minute pour chaque groupe et utilisateur authentifié. Pour désactiver cette limite sur GitLab Self-Managed et GitLab Dedicated, un administrateur peut [désactiver le feature flag](../administration/feature_flags/_index.md) nommé `web_hook_test_api_endpoint_rate_limit`.

```plaintext
POST /groups/:id/hooks/:hook_id/test/:trigger
```

| Attribut | Type              | Obligatoire | Description |
|---------- |------------------ |--------- |------------ |
| `hook_id` | Entier           | Oui      | L'ID du hook de groupe. |
| `id`      | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `trigger` | Chaîne            | Oui      | L'une des valeurs suivantes : `push_events`, `tag_push_events`, `issues_events`, `confidential_issues_events`, `note_events`, `merge_requests_events`, `job_events`, `pipeline_events`, `wiki_page_events`, `releases_events`, `milestone_events`, `emoji_events` ou `resource_access_token_events`. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/test/push_events"
```

Exemple de réponse :

```json
{"message":"201 Created"}
```

## Mettre à jour un en-tête personnalisé {#update-a-custom-header}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) dans GitLab 17.1.

{{< /history >}}

Met à jour un en-tête personnalisé pour un hook de groupe spécifié.

```plaintext
PUT /groups/:id/hooks/:hook_id/custom_headers/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|---------- |------------------ |--------- |------------ |
| `hook_id` | Entier           | Oui      | L'ID du hook de groupe. |
| `id`      | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`     | Chaîne            | Oui      | La clé de l'en-tête personnalisé. |
| `value`   | Chaîne            | Oui      | La valeur de l'en-tête personnalisé. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key?value='header_value'"
```

En cas de succès, aucun message n'est retourné.

## Supprimer un en-tête personnalisé {#delete-a-custom-header}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) dans GitLab 17.1.

{{< /history >}}

Supprime un en-tête personnalisé.

```plaintext
DELETE /groups/:id/hooks/:hook_id/custom_headers/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|---------- |------------------ |--------- |------------ |
| `hook_id` | Entier           | Oui      | L'ID du hook de groupe. |
| `id`      | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`     | Chaîne            | Oui      | La clé de l'en-tête personnalisé. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key"
```

En cas de succès, aucun message n'est retourné.

## Mettre à jour une variable d'URL {#update-a-url-variable}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310) dans GitLab 15.2.

{{< /history >}}

Met à jour une variable d'URL pour un hook de groupe spécifié.

```plaintext
PUT /groups/:id/hooks/:hook_id/url_variables/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|---------- |------------------ |--------- |------------ |
| `hook_id` | Entier           | Oui      | L'ID du hook de groupe. |
| `id`      | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`     | Chaîne            | Oui      | La clé de la variable d'URL. |
| `value`   | Chaîne            | Oui      | La valeur de la variable d'URL. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key?value='my_key_value'"
```

En cas de succès, aucun message n'est retourné.

## Supprimer une variable d'URL {#delete-a-url-variable}

Supprime une variable d'URL pour un hook de groupe spécifié.

```plaintext
DELETE /groups/:id/hooks/:hook_id/url_variables/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|---------- |------------------ |--------- |------------ |
| `hook_id` | Entier           | Oui      | L'ID du hook de groupe. |
| `id`      | Entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`     | Chaîne            | Oui      | La clé de la variable d'URL. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key"
```

En cas de succès, aucun message n'est retourné.
