---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des jetons d'accès de groupe"
description: "API permettant de lister, obtenir, créer, faire pivoter, faire pivoter soi-même et révoquer des jetons d'accès de groupe."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les jetons d'accès de groupe. Pour plus d'informations, voir [Jetons d'accès de groupe](../user/group/settings/group_access_tokens.md).

## Lister tous les jetons d'accès de groupe {#list-all-group-access-tokens}

{{< history >}}

- L'attribut `state` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) dans GitLab 17.2.

{{< /history >}}

Liste tous les jetons d'accès de groupe pour le groupe spécifié.

```plaintext
GET /groups/:id/access_tokens
GET /groups/:id/access_tokens?state=inactive
```

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | entier ou chaîne de caractères   | oui      | ID ou [chemin encodé URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `created_after`    | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés après le temps spécifié. |
| `created_before`   | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés avant le temps spécifié. |
| `expires_after`    | date (ISO 8601)     | Non       | Si défini, retourne les jetons qui expirent après le temps spécifié. |
| `expires_before`   | date (ISO 8601)     | Non       | Si défini, retourne les jetons qui expirent avant le temps spécifié. |
| `last_used_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois après le temps spécifié. |
| `last_used_before` | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois avant le temps spécifié. |
| `revoked`          | boolean             | Non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | Non       | Si défini, retourne les jetons dont le nom contient la valeur spécifiée. |
| `sort`             | string              | Non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`.|
| `state`            | string              | Non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens"
```

```json
[
   {
      "user_id" : 141,
      "scopes" : [
         "api"
      ],
      "name" : "token",
      "expires_at" : "2021-01-31",
      "id" : 42,
      "active" : true,
      "created_at" : "2021-01-20T22:11:48.151Z",
      "description": "Test Token description",
      "revoked" : false,
      "last_used_at": null,
      "access_level": 40
   },
   {
      "user_id" : 141,
      "scopes" : [
         "read_api"
      ],
      "name" : "token-2",
      "expires_at" : "2021-01-31",
      "id" : 43,
      "active" : false,
      "created_at" : "2021-01-21T12:12:38.123Z",
      "description": "Test Token description",
      "revoked" : true,
      "last_used_at": "2021-02-13T10:34:57.178Z",
      "access_level": 40
   }
]
```

## Récupérer les détails d'un jeton d'accès de groupe {#retrieve-details-on-a-group-access-token}

Récupère les détails d'un jeton d'accès de groupe spécifié.

```plaintext
GET /groups/:id/access_tokens/:token_id
```

| Attribut  | Type              | requis | Description |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | entier ou chaîne de caractères | oui      | ID ou [chemin encodé URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `token_id` | entier ou chaîne de caractères | oui      | ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>"
```

```json
{
   "user_id" : 141,
   "scopes" : [
      "api"
   ],
   "name" : "token",
   "expires_at" : "2021-01-31",
   "id" : 42,
   "active" : true,
   "created_at" : "2021-01-20T22:11:48.151Z",
   "description": "Test Token description",
   "revoked" : false,
   "access_level": 40
}
```

## Créer un jeton d'accès de groupe {#create-a-group-access-token}

{{< history >}}

- La valeur par défaut de l'attribut `expires_at` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) dans GitLab 16.0.

{{< /history >}}

Crée un jeton d'accès de groupe pour un groupe spécifié.

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

```plaintext
POST /groups/:id/access_tokens
```

| Attribut      | Type              | requis | Description |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | entier ou chaîne de caractères | oui      | ID ou [chemin encodé URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `name`         | Chaîne            | oui      | Nom du jeton. |
| `description`  | string            | non       | Description du jeton d'accès de groupe. Maximum : 255 caractères. |
| `scopes`       | `Array[String]`   | oui      | Liste des [portées](../user/group/settings/group_access_tokens.md#group-access-token-scopes) disponibles pour le jeton. |
| `access_level` | Entier           | non       | Rôle du jeton. Valeurs possibles : `10` (Invité), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) et `50` (Owner). Valeur par défaut : `40`. |
| `expires_at`   | date              | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si non définie, la date est fixée à la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{ "name":"test_token", "scopes":["api", "read_repository"], "expires_at":"2021-01-31", "access_level": 30 }' \
  --url "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens"
```

```json
{
   "scopes" : [
      "api",
      "read_repository"
   ],
   "active" : true,
   "name" : "test",
   "revoked" : false,
   "created_at" : "2021-01-21T19:35:37.921Z",
   "description": "Test Token description",
   "user_id" : 166,
   "id" : 58,
   "expires_at" : "2021-01-31",
   "token" : "D4y...Wzr",
   "access_level": 30
}
```

## Faire pivoter un jeton d'accès de groupe {#rotate-a-group-access-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) dans GitLab 16.0
- L'attribut `expires_at` a été [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) dans GitLab 16.6.

{{< /history >}}

Fait pivoter un jeton d'accès de groupe spécifié. Cela révoque immédiatement le jeton précédent et crée un nouveau jeton. En général, ce point de terminaison fait pivoter un jeton d'accès de groupe spécifique en s'authentifiant avec un jeton d'accès personnel. Vous pouvez également utiliser un jeton d'accès de groupe pour le faire pivoter lui-même. Pour plus d'informations, voir [Self-rotate](#self-rotate).

Si vous tentez d'utiliser ce point de terminaison pour faire pivoter un jeton précédemment révoqué, tous les jetons actifs de la même famille de jetons sont révoqués. Pour plus d'informations, voir [la détection automatique de réutilisation](personal_access_tokens.md#automatic-reuse-detection).

Prérequis :

- Pour faire pivoter un autre jeton d'accès de groupe, vous devez disposer d'un jeton d'accès personnel avec la [`api`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
- Pour [faire pivoter soi-même](#self-rotate) un jeton d'accès de groupe, le jeton doit avoir la [portée `api` ou `self_rotate`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).

```plaintext
POST /groups/:id/access_tokens/:token_id/rotate
```

| Attribut    | Type              | requis | Description |
| ------------ | ----------------- | -------- | ----------- |
| `id`         | entier ou chaîne de caractères | oui      | ID ou [chemin encodé URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `token_id`   | entier ou chaîne de caractères | oui      | ID d'un jeton d'accès de groupe ou le mot-clé `self`. |
| `expires_at` | date              | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si le jeton nécessite une date d'expiration, la valeur par défaut est 1 semaine. Si non requis, la valeur par défaut est la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>/rotate"
```

Exemple de réponse :

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test group access token",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "access_level": 30,
    "token": "s3cr3t"
}
```

En cas de succès, retourne `200: OK`.

Autres réponses possibles :

- `400: Bad Request` si la rotation n'a pas réussi.
- `401: Unauthorized` si l'une des conditions suivantes est vraie :
  - Le jeton n'existe pas.
  - Le jeton a expiré.
  - Le jeton a été révoqué.
  - Vous n'avez pas accès au jeton spécifié.
  - Vous utilisez un jeton d'accès de groupe pour faire pivoter un autre jeton d'accès de groupe. Voir [Auto-rotation](#self-rotate) à la place.
- `403: Forbidden` si le jeton n'est pas autorisé à pivoter lui-même.
- `404: Not Found` si l'utilisateur est un administrateur mais que le jeton n'existe pas.
- `405: Method Not Allowed` si le jeton n'est pas un jeton d'accès.

### Auto-rotation {#self-rotate}

Au lieu de faire pivoter un jeton d'accès de groupe spécifique, vous pouvez faire pivoter le même jeton d'accès de groupe que celui utilisé pour authentifier la requête. Pour faire pivoter soi-même un jeton d'accès de groupe, vous devez :

- Faire pivoter un jeton d'accès de groupe avec la [portée `api` ou `self_rotate`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
- Utiliser le mot-clé `self` dans l'URL de la requête.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_group_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/self/rotate"
```

## Révoquer un jeton d'accès de groupe {#revoke-a-group-access-token}

Révoque un jeton d'accès de groupe spécifié.

```plaintext
DELETE /groups/:id/access_tokens/:token_id
```

| Attribut  | Type              | requis | Description |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | entier ou chaîne de caractères | oui      | ID ou [chemin encodé URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `token_id` | integer           | oui      | ID d'un jeton d'accès de groupe. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>"
```

En cas de succès, retourne `204 No content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas réussi.
- `404: Not Found` si le jeton d'accès n'existe pas.
