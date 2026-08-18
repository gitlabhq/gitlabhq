---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des hooks système
description: "Configurez et gérez les hooks système avec l'API REST."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Utilisez cette API pour gérer les [hooks système](../administration/system_hooks.md). Les hooks système sont différents des [webhooks de groupe](group_webhooks.md) qui ont un impact sur tous les projets et sous-groupes d'un groupe, et des [webhooks de projet](project_webhooks.md) qui sont limités à un seul projet.

Prérequis :

- Vous devez être un administrateur.

## Lister tous les hooks système {#list-all-system-hooks}

Liste tous les hooks système.

```plaintext
GET /hooks
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks"
```

Exemple de réponse :

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": [],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## Récupérer un hook système {#retrieve-system-hook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- Les attributs `token_present` et `signing_token_present` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0.

{{< /history >}}

Récupère un hook système par son ID.

```plaintext
GET /hooks/:id
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | entier | Oui      | L'ID du hook. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "url": "https://gitlab.example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "created_at": "2016-10-31T12:32:15.192Z",
  "push_events": true,
  "tag_push_events": false,
  "merge_requests_events": true,
  "repository_update_events": true,
  "enable_ssl_verification": true,
  "url_variables": [],
  "token_present": false,
  "signing_token_present": false
}
```

## Ajouter un nouveau hook système {#add-new-system-hook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- L'attribut `signing_token` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0 [avec un flag](../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut. Activé par défaut.
- Le feature flag `webhook_signing_token` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/596374) dans GitLab 19.1.

{{< /history >}}

Ajoute un nouveau hook système.

```plaintext
POST /hooks
```

| Attribut                   | Type    | Obligatoire | Description |
|-----------------------------|---------|----------|-------------|
| `url`                       | string  | Oui      | L'URL du hook. |
| `branch_filter_strategy`    | string  | Non       | Filtrer les événements push par branche. Les valeurs possibles sont `wildcard` (par défaut), `regex` et `all_branches`. |
| `description`               | string  | Non       | Description du hook. |
| `enable_ssl_verification`   | boolean | Non       | Effectuer la vérification SSL lors du déclenchement du hook. |
| `merge_requests_events`     | boolean | Non       | Déclencher le hook sur les événements de merge request. |
| `name`                      | string  | Non       | Nom du hook. |
| `push_events`               | boolean | Non       | Lorsque la valeur est true, le hook se déclenche sur les événements push. |
| `push_events_branch_filter` | string  | Non       | Déclencher le hook sur les événements push uniquement pour les branches correspondantes. |
| `repository_update_events`  | boolean | Non       | Déclencher le hook sur les événements de mise à jour du dépôt. |
| `signing_token`             | string  | Non       | Token de signature HMAC utilisé pour calculer l'en-tête `webhook-signature`. Doit être au format `whsec_<base64>` encodant une clé de 32 octets. Non retourné dans la réponse. |
| `tag_push_events`           | boolean | Non       | Lorsque la valeur est true, le hook se déclenche lors du push de nouveaux tags. |
| `token`                     | string  | Non       | Token secret pour valider les charges utiles reçues. Non retourné dans la réponse. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks?url=https://gitlab.example.com/hook"
```

Exemple de réponse :

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": [],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## Mettre à jour un hook système {#update-system-hook}

{{< history >}}

- Les attributs `name` et `description` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) dans GitLab 17.1.
- L'attribut `signing_token` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) dans GitLab 19.0 [avec un flag](../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut. Activé par défaut.
- Le feature flag `webhook_signing_token` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/596374) dans GitLab 19.1.

{{< /history >}}

Met à jour un hook système existant.

```plaintext
PUT /hooks/:hook_id
```

| Attribut                   | Type    | Obligatoire | Description |
|-----------------------------|---------|----------|-------------|
| `hook_id`                   | entier | Oui      | L'ID du hook système. |
| `branch_filter_strategy`    | string  | Non       | Filtrer les événements push par branche. Les valeurs possibles sont `wildcard` (par défaut), `regex` et `all_branches`. |
| `description`               | string  | Non       | Description du hook. |
| `enable_ssl_verification`   | boolean | Non       | Effectuer la vérification SSL lors du déclenchement du hook. |
| `merge_requests_events`     | boolean | Non       | Déclencher le hook sur les événements de merge request. |
| `name`                      | string  | Non       | Nom du hook. |
| `push_events`               | boolean | Non       | Lorsque la valeur est true, le hook se déclenche sur les événements push. |
| `push_events_branch_filter` | string  | Non       | Déclencher le hook sur les événements push uniquement pour les branches correspondantes. |
| `repository_update_events`  | boolean | Non       | Déclencher le hook sur les événements de mise à jour du dépôt. |
| `signing_token`             | string  | Non       | Token de signature HMAC utilisé pour calculer l'en-tête `webhook-signature`. Doit être au format `whsec_<base64>` encodant une clé de 32 octets. Non retourné dans la réponse. |
| `tag_push_events`           | boolean | Non       | Lorsque la valeur est true, le hook se déclenche lors du push de nouveaux tags. |
| `token`                     | string  | Non       | Token secret pour valider les charges utiles reçues. Non retourné dans la réponse. |
| `url`                       | string  | Non       | L'URL du hook. |

## Tester un hook système {#test-system-hook}

Exécute le hook système avec des données fictives.

```plaintext
POST /hooks/:id
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | entier | Oui      | L'ID du hook. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

La réponse est toujours les données fictives :

```json
{
   "project_id" : 1,
   "owner_email" : "example@gitlabhq.com",
   "owner_name" : "Someone",
   "name" : "Ruby",
   "path" : "ruby",
   "event_name" : "project_create"
}
```

## Supprimer un hook système {#delete-system-hook}

Supprime un hook système.

```plaintext
DELETE /hooks/:id
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | entier | Oui      | L'ID du hook. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/2"
```

## Définir une variable d'URL {#set-a-url-variable}

```plaintext
PUT /hooks/:hook_id/url_variables/:key
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `hook_id` | entier | Oui      | ID du hook système. |
| `key`     | string  | Oui      | Clé de la variable d'URL. |
| `value`   | string  | Oui      | Valeur de la variable d'URL. |

En cas de succès, cet endpoint retourne le code de réponse `204 No Content`.

## Supprimer une variable d'URL {#delete-a-url-variable}

```plaintext
DELETE /hooks/:hook_id/url_variables/:key
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | entier           | Oui      | ID du hook système. |
| `key`     | string            | Oui      | Clé de la variable d'URL. |

En cas de succès, cet endpoint retourne le code de réponse `204 No Content`.
