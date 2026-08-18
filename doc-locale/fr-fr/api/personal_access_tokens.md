---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des jetons d'accès personnels"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

## Lister tous les jetons d'accès personnels {#list-all-personal-access-tokens}

{{< history >}}

- Les filtres `created_after`, `created_before`, `last_used_after`, `last_used_before`, `revoked`, `search` et `state` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/362248) dans GitLab 15.5.

{{< /history >}}

Liste tous les jetons d'accès personnels accessibles par l'utilisateur authentifié. Pour les administrateurs, renvoie tous les jetons d'accès personnels de l'instance. Pour les non-administrateurs, renvoie l'ensemble de leurs jetons d'accès personnels.

```plaintext
GET /personal_access_tokens
GET /personal_access_tokens?created_after=2022-01-01T00:00:00
GET /personal_access_tokens?created_before=2022-01-01T00:00:00
GET /personal_access_tokens?last_used_after=2022-01-01T00:00:00
GET /personal_access_tokens?last_used_before=2022-01-01T00:00:00
GET /personal_access_tokens?revoked=true
GET /personal_access_tokens?search=name
GET /personal_access_tokens?state=inactive
GET /personal_access_tokens?user_id=1
```

Attributs pris en charge :

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `created_after`    | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés après le temps spécifié. |
| `created_before`   | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés avant le temps spécifié. |
| `expires_after`    | date (ISO 8601)     | Non       | Si défini, retourne les jetons qui expirent après le temps spécifié. |
| `expires_before`   | date (ISO 8601)     | Non       | Si défini, retourne les jetons qui expirent avant le temps spécifié. |
| `last_used_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois après le temps spécifié. |
| `last_used_before` | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois avant le temps spécifié. |
| `revoked`          | boolean             | Non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | Non       | Si défini, retourne les jetons dont le nom contient la valeur spécifiée. |
| `sort`             | string              | Non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | string              | Non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |
| `user_id`          | entier ou chaîne de caractères   | Non       | Si défini, renvoie les jetons appartenant à l'utilisateur spécifié. Les non-administrateurs ne peuvent filtrer que leurs propres jetons. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3&created_before=2022-01-01"
```

Exemple de réponse :

```json
[
    {
        "id": 4,
        "name": "Test Token",
        "revoked": false,
        "created_at": "2020-07-23T14:31:47.729Z",
        "description": "Test Token description",
        "scopes": [
            "api"
        ],
        "user_id": 3,
        "last_used_at": "2021-10-06T17:58:37.550Z",
        "active": true,
        "expires_at": null
    }
]
```

En cas de succès, renvoie une liste de jetons.

Autre réponse possible :

- `401: Unauthorized` si un non-administrateur utilise l'attribut `user_id` pour filtrer d'autres utilisateurs.

## Récupérer un jeton d'accès personnel {#retrieve-a-personal-access-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/362239) dans GitLab 15.1.
- Le code de statut HTTP `404` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650) dans GitLab 15.3.

{{< /history >}}

Récupère les détails d'un jeton d'accès personnel spécifié. Les administrateurs peuvent récupérer les détails de n'importe quel jeton. Les non-administrateurs peuvent uniquement récupérer les détails de leurs propres jetons.

```plaintext
GET /personal_access_tokens/:id
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id` | entier ou chaîne de caractères | oui | ID d'un jeton d'accès personnel ou le mot-clé `self`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

En cas de succès, renvoie les détails du jeton.

Autres réponses possibles :

- `401: Unauthorized` si l'une des conditions suivantes est vraie :
  - Le jeton n'existe pas.
  - Vous n'avez pas accès au jeton spécifié.
- `404: Not Found` si l'utilisateur est un administrateur mais que le jeton n'existe pas.

### Auto-information {#self-inform}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/373999) dans GitLab 15.5

{{< /history >}}

Au lieu d'obtenir les détails d'un jeton d'accès personnel spécifique, vous pouvez également renvoyer les détails du jeton d'accès personnel que vous avez utilisé pour authentifier la requête. Pour renvoyer ces détails, vous devez utiliser le mot-clé `self` dans l'URL de la requête.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## Créer un jeton d'accès personnel {#create-a-personal-access-token}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez créer des jetons d'accès personnels avec l'API des jetons utilisateur. Pour plus d'informations, consultez les endpoints suivants :

- [Créer un jeton d'accès personnel](user_tokens.md#create-a-personal-access-token)
- [Créer un jeton d'accès personnel pour un utilisateur](user_tokens.md#create-a-personal-access-token-for-a-user)

## Faire pivoter un jeton d'accès personnel {#rotate-a-personal-access-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) dans GitLab 16.0
- L'attribut `expires_at` a été [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) dans GitLab 16.6.

{{< /history >}}

Fait pivoter un jeton d'accès personnel spécifié. Cela révoque le jeton précédent et crée un nouveau jeton qui expire après une semaine. Les administrateurs peuvent révoquer les jetons de n'importe quel utilisateur. Les non-administrateurs peuvent uniquement révoquer leurs propres jetons.

```plaintext
POST /personal_access_tokens/:id/rotate
```

| Attribut | Type      | Obligatoire | Description         |
|-----------|-----------|----------|---------------------|
| `id` | entier ou chaîne de caractères | oui      | ID d'un jeton d'accès personnel ou le mot-clé `self`. |
| `expires_at` | date   | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si le jeton nécessite une date d'expiration, la valeur par défaut est 1 semaine. Si non requis, la valeur par défaut est la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>/rotate"
```

Exemple de réponse :

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
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
- `403: Forbidden` si le jeton n'est pas autorisé à pivoter lui-même.
- `404: Not Found` si l'utilisateur est un administrateur mais que le jeton n'existe pas.
- `405: Method Not Allowed` si le jeton n'est pas un jeton d'accès personnel.

### Auto-rotation {#self-rotate}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/426779) dans GitLab 16.10

{{< /history >}}

Au lieu de faire pivoter un jeton d'accès personnel spécifique, vous pouvez également faire pivoter le même jeton d'accès personnel que vous avez utilisé pour authentifier la requête. Pour effectuer l'auto-rotation d'un jeton d'accès personnel, vous devez :

- Faire pivoter un jeton d'accès personnel avec la [portée `api` ou `self_rotate`](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
- Utiliser le mot-clé `self` dans l'URL de la requête.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/rotate"
```

### Détection automatique de réutilisation {#automatic-reuse-detection}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/395352) dans GitLab 16.3

{{< /history >}}

Lorsque vous faites pivoter ou révoquez un jeton, GitLab suit automatiquement la relation entre les anciens et les nouveaux jetons. Chaque fois qu'un nouveau jeton est généré, une connexion est établie avec le jeton précédent. Ces jetons connectés forment une famille de jetons.

Si vous tentez d'utiliser l'API pour faire pivoter un jeton d'accès déjà révoqué, tous les jetons actifs de la même famille de jetons sont révoqués.

Cette fonctionnalité contribue à sécuriser GitLab si un ancien jeton venait à être divulgué ou volé. En suivant les relations entre les jetons et en révoquant automatiquement les accès lorsque d'anciens jetons sont utilisés, les attaquants ne peuvent pas exploiter les jetons compromis.

## Révoquer un jeton d'accès personnel {#revoke-a-personal-access-token}

Révoque un jeton d'accès personnel spécifié. Les administrateurs peuvent révoquer les jetons de n'importe quel utilisateur. Les non-administrateurs peuvent uniquement révoquer leurs propres jetons.

```plaintext
DELETE /personal_access_tokens/:id
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id` | entier ou chaîne de caractères | oui | ID d'un jeton d'accès personnel ou le mot-clé `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>"
```

En cas de succès, retourne `204: No Content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas réussi.
- `401: Unauthorized` si la requête n'est pas autorisée.
- `403: Forbidden` si la requête n'est pas permise.

### Auto-révocation {#self-revoke}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/350240) dans GitLab 15.0. Limité aux jetons avec la portée `api`.
- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/369103) dans GitLab 15.4, n'importe quel jeton peut utiliser cet endpoint.

{{< /history >}}

Au lieu de révoquer un jeton d'accès personnel spécifique, vous pouvez également révoquer le même jeton d'accès personnel que vous avez utilisé pour authentifier la requête. Pour effectuer l'auto-révocation d'un jeton d'accès personnel, vous devez utiliser le mot-clé `self` dans l'URL de la requête.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## Lister toutes les associations de jetons {#list-all-token-associations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/466046) dans GitLab 17.4.

{{< /history >}}

Liste tous les groupes et projets accessibles par le jeton d'accès personnel utilisé pour authentifier la requête. En général, cela inclut tous les groupes ou projets dont l'utilisateur est membre.

```plaintext
GET /personal_access_tokens/self/associations
GET /personal_access_tokens/self/associations?page=2
GET /personal_access_tokens/self/associations?min_access_level=40
```

Attributs pris en charge :

| Attribut           | Type     | Obligatoire | Description                                                              |
|---------------------|----------|----------|--------------------------------------------------------------------------|
| `min_access_level`  | integer  | Non       | Limiter aux groupes et projets où le jeton dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `page`              | integer  | Non       | Page à récupérer. La valeur par défaut est `1`.                                       |
| `per_page`          | integer  | Non       | Nombre d'enregistrements à retourner par page. La valeur par défaut est `20`.                  |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/associations"
```

Exemple de réponse :

```json
{
    "groups": [
        {
        "id": 1,
        "web_url": "http://gitlab.example.com/groups/test",
        "name": "Test",
        "parent_id": null,
        "organization_id": 1,
        "access_levels": 20,
        "visibility": "public"
        },
        {
        "id": 3,
        "web_url": "http://gitlab.example.com/groups/test/test_private",
        "name": "Test Private",
        "parent_id": 1,
        "organization_id": 1,
        "access_levels": 50,
        "visibility": "test_private"
        }
    ],
    "projects": [
        {
            "id": 1337,
            "description": "Leet.",
            "name": "Test Project",
            "name_with_namespace": "Test / Test Project",
            "path": "test-project",
            "path_with_namespace": "Test/test-project",
            "created_at": "2024-07-02T13:37:00.123Z",
            "access_levels": {
                "project_access_level": null,
                "group_access_level": 20
            },
            "visibility": "private",
            "web_url": "http://gitlab.example.com/test/test_project",
            "namespace": {
                "id": 1,
                "name": "Test",
                "path": "Test",
                "kind": "group",
                "full_path": "Test",
                "parent_id": null,
                "avatar_url": null,
                "web_url": "http://gitlab.example.com/groups/test"
            }
        }
    ]
}
```

## Sujets connexes {#related-topics}

- [Dépannage des jetons](../security/tokens/token_troubleshooting.md)
