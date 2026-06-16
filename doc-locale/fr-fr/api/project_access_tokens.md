---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des jetons d'accès au projet"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les jetons d'accès au projet. Pour plus d'informations, consultez [Jetons d'accès au projet](../user/project/settings/project_access_tokens.md).

## Lister tous les jetons d'accès au projet {#list-all-project-access-tokens}

{{< history >}}

- L'attribut `state` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) dans GitLab 17.2.

{{< /history >}}

Liste tous les jetons d'accès au projet pour un projet spécifié.

```plaintext
GET projects/:id/access_tokens
GET projects/:id/access_tokens?state=inactive
```

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | entier ou chaîne   | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `created_after`    | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés après l'heure spécifiée. |
| `created_before`   | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés avant l'heure spécifiée. |
| `expires_after`    | date (ISO 8601)     | Non       | Si défini, retourne les jetons qui expirent après l'heure spécifiée. |
| `expires_before`   | date (ISO 8601)     | Non       | Si défini, retourne les jetons qui expirent avant l'heure spécifiée. |
| `last_used_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois après l'heure spécifiée. |
| `last_used_before` | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois avant l'heure spécifiée. |
| `revoked`          | boolean             | Non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | Non       | Si défini, retourne les jetons qui incluent la valeur spécifiée dans le nom. |
| `sort`             | string              | Non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`.|
| `state`            | string              | Non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens"
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
      "last_used_at" : null,
      "revoked" : false,
      "access_level" : 40
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
      "last_used_at" : "2021-02-13T10:34:57.178Z",
      "access_level" : 40
   }
]
```

## Récupérer les détails d'un jeton d'accès au projet {#retrieve-details-on-a-project-access-token}

Récupère les détails d'un jeton d'accès au projet.

```plaintext
GET projects/:id/access_tokens/:token_id
```

| Attribut  | Type              | requis | Description |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `token_id` | entier ou chaîne | oui      | ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
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
   "access_level": 40,
   "last_used_at": "2022-03-15T11:05:42.437Z"
}
```

## Créer un jeton d'accès au projet {#create-a-project-access-token}

{{< history >}}

- La valeur par défaut de l'attribut `expires_at` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) dans GitLab 16.0.

{{< /history >}}

Crée un jeton d'accès au projet pour un projet spécifié. Vous ne pouvez pas créer un jeton avec un niveau d'accès supérieur à celui de votre compte. Par exemple, un utilisateur avec le rôle Maintainer ne peut pas créer un jeton d'accès au projet avec le rôle Owner.

Vous devez utiliser un jeton d'accès personnel avec ce point de terminaison. Vous ne pouvez pas vous authentifier avec un jeton d'accès au projet. Il existe une [demande de fonctionnalité ouverte](https://gitlab.com/gitlab-org/gitlab/-/issues/359953) pour ajouter cette fonctionnalité.

```plaintext
POST projects/:id/access_tokens
```

| Attribut      | Type              | requis | Description |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `name`         | string            | oui      | Nom du jeton. |
| `description`  | string            | non       | Description du jeton d'accès au projet. Maximum : 255 caractères. |
| `scopes`       | `Array[String]`   | oui      | Liste des [portées](../user/project/settings/project_access_tokens.md#project-access-token-scopes) disponibles pour le jeton. |
| `access_level` | entier           | non       | Rôle pour le jeton. Valeurs possibles : `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) et `50` (Owner). Valeur par défaut : `40`. |
| `expires_at`   | date              | oui      | Date d'expiration du jeton au format ISO (`YYYY-MM-DD`). Si non défini, la date est fixée à la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_personal_access_token>" \
  --header "Content-Type:application/json" \
  --data '{ "name":"test_token", "scopes":["api", "read_repository"], "expires_at":"2021-01-31", "access_level":30 }' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens"
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

## Faire pivoter un jeton d'accès au projet {#rotate-a-project-access-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) dans GitLab 16.0
- Attribut `expires_at` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) dans GitLab 16.6.

{{< /history >}}

Fait pivoter un jeton d'accès au projet. Cela révoque immédiatement le jeton précédent et crée un nouveau jeton. En général, ce point de terminaison fait pivoter un jeton d'accès au projet spécifique en s'authentifiant avec un jeton d'accès personnel. Vous pouvez également utiliser un jeton d'accès au projet pour le faire pivoter lui-même. Pour plus d'informations, consultez [Auto-rotation](#self-rotate).

Si vous tentez d'utiliser ce point de terminaison pour faire pivoter un jeton qui a été précédemment révoqué, tous les jetons actifs de la même famille de jetons sont révoqués. Pour plus d'informations, consultez [Détection automatique de réutilisation](personal_access_tokens.md#automatic-reuse-detection).

Prérequis :

- Pour faire pivoter un autre jeton d'accès au projet, vous devez disposer d'un jeton d'accès personnel avec la [portée `api`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
- Pour [faire pivoter automatiquement](#self-rotate) un jeton d'accès au projet, le jeton doit avoir la [portée `api` ou `self_rotate`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).

```plaintext
POST /projects/:id/access_tokens/:token_id/rotate
```

| Attribut    | Type              | requis | Description |
| ------------ | ----------------- | -------- | ----------- |
| `id`         | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `token_id`   | entier ou chaîne | oui      | ID d'un jeton d'accès au projet ou le mot-clé `self`. |
| `expires_at` | date              | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si le jeton nécessite une date d'expiration, la valeur par défaut est 1 semaine. Si non requis, la valeur par défaut est la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>/rotate"
```

Exemple de réponse :

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test project access token",
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
  - Vous utilisez un jeton d'accès au projet pour faire pivoter un autre jeton d'accès au projet. Consultez plutôt [Auto-rotation](#self-rotate).
- `403: Forbidden` si le jeton n'est pas autorisé à effectuer sa propre rotation.
- `404: Not Found` si l'utilisateur est un administrateur mais que le jeton n'existe pas.
- `405: Method Not Allowed` si le jeton n'est pas un jeton d'accès au projet.

### Auto-rotation {#self-rotate}

Au lieu de faire pivoter un jeton d'accès au projet spécifique, vous pouvez faire pivoter le même jeton d'accès au projet que vous avez utilisé pour authentifier la requête. Pour effectuer l'auto-rotation d'un jeton d'accès au projet, vous devez :

- Faire pivoter un jeton d'accès au projet avec la [portée `api` ou `self_rotate`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
- Utiliser le mot-clé `self` dans l'URL de la requête.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_project_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/self/rotate"
```

## Révoquer un jeton d'accès au projet {#revoke-a-project-access-token}

Révoque un jeton d'accès au projet spécifié.

```plaintext
DELETE projects/:id/access_tokens/:token_id
```

| Attribut  | Type              | requis | Description |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `token_id` | entier           | oui      | ID d'un jeton d'accès au projet. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

En cas de succès, retourne `204 No content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas réussi.
- `404: Not Found` si le jeton d'accès n'existe pas.
