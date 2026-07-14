---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des jetons utilisateur
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les jetons d'accès personnels et les jetons d'emprunt d'identité. Pour plus d'informations, voir [les jetons d'accès personnels](../user/profile/personal_access_tokens.md) et [les jetons d'emprunt d'identité](rest/authentication.md#impersonation-tokens).

## Créer un jeton d'accès personnel pour un utilisateur {#create-a-personal-access-token-for-a-user}

{{< history >}}

- La valeur par défaut de l'attribut `expires_at` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) dans GitLab 16.0.

{{< /history >}}

Crée un jeton d'accès personnel pour un utilisateur spécifié.

Les valeurs des jetons sont incluses dans la réponse, mais ne peuvent pas être récupérées ultérieurement.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:user_id/personal_access_tokens
```

Attributs pris en charge :

| Attribut    | Type    | Obligatoire | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | oui      | ID du compte utilisateur. |
| `name`       | string  | oui      | Nom du jeton d'accès personnel. |
| `description`| string  | non       | Description du jeton d'accès personnel. Maximum :  255 caractères. |
| `expires_at` | date    | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si elle n'est pas définie, la date est fixée à la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |
| `scopes`     | array   | oui      | Tableau des portées approuvées. Pour obtenir la liste des valeurs possibles, voir [Portées des jetons d'accès personnels](../user/profile/personal_access_tokens.md#personal-access-token-scopes). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/personal_access_tokens"
```

Exemple de réponse :

```json
{
    "id": 3,
    "name": "mytoken",
    "revoked": false,
    "created_at": "2020-10-14T11:58:53.526Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 42,
    "active": true,
    "expires_at": "2020-12-31",
    "token": "<your_new_access_token>"
}
```

## Créer un jeton d'accès personnel {#create-a-personal-access-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131923) dans GitLab 16.5.

{{< /history >}}

Crée un jeton d'accès personnel pour votre compte. Pour des raisons de sécurité, le jeton :

- Est limité à la [`k8s_proxy` et `self_rotate` portée](../user/profile/personal_access_tokens.md#personal-access-token-scopes).

Les valeurs des jetons sont incluses dans la réponse, mais ne peuvent pas être récupérées ultérieurement.

Prérequis :

- Vous devez être authentifié.

```plaintext
POST /user/personal_access_tokens
```

Attributs pris en charge :

| Attribut    | Type   | Obligatoire | Description |
|:-------------|:-------|:---------|:------------|
| `name`       | string | oui      | Nom du jeton d'accès personnel. |
| `description`| string | non       | Description du jeton d'accès personnel. Maximum :  255 caractères. |
| `scopes`     | array  | oui      | Tableau des portées approuvées. Accepte uniquement `k8s_proxy` et `self_rotate`. |
| `expires_at` | date  | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si elle n'est pas définie, la date est fixée à la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "scopes[]=k8s_proxy" \
  --url "https://gitlab.example.com/api/v4/user/personal_access_tokens"
```

Exemple de réponse :

```json
{
    "id": 3,
    "name": "mytoken",
    "revoked": false,
    "created_at": "2020-10-14T11:58:53.526Z",
    "description": "Test Token description",
    "scopes": [
        "k8s_proxy"
    ],
    "user_id": 42,
    "active": true,
    "expires_at": "2020-10-15",
    "token": "<your_new_access_token>"
}
```

## Lister tous les jetons d'emprunt d'identité d'un utilisateur {#list-all-impersonation-tokens-for-a-user}

Liste tous les jetons d'emprunt d'identité d'un utilisateur spécifié.

Utilisez les `page` et `per_page` [paramètres de pagination](rest/_index.md#offset-based-pagination) pour filtrer les résultats.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
GET /users/:user_id/impersonation_tokens
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `user_id` | integer | oui      | ID du compte utilisateur |
| `state`   | string  | non       | Filtre les jetons selon leur état. Valeurs possibles : `all`, `active` ou `inactive`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

Exemple de réponse :

```json
[
   {
      "active" : true,
      "user_id" : 2,
      "scopes" : [
         "api"
      ],
      "revoked" : false,
      "name" : "mytoken",
      "description": "Test Token description",
      "id" : 2,
      "created_at" : "2017-03-17T17:18:09.283Z",
      "impersonation" : true,
      "expires_at" : "2017-04-04",
      "last_used_at": "2017-03-24T09:44:21.722Z"
   },
   {
      "active" : false,
      "user_id" : 2,
      "scopes" : [
         "read_user"
      ],
      "revoked" : true,
      "name" : "mytoken2",
      "description": "Test Token description",
      "created_at" : "2017-03-17T17:19:28.697Z",
      "id" : 3,
      "impersonation" : true,
      "expires_at" : "2017-04-14",
      "last_used_at": "2017-03-24T09:44:21.722Z"
   }
]
```

## Récupérer un jeton d'emprunt d'identité pour un utilisateur {#retrieve-an-impersonation-token-for-a-user}

Récupère un jeton d'emprunt d'identité pour un utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Attributs pris en charge :

| Attribut                | Type    | Obligatoire | Description |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | integer | oui      | ID du compte utilisateur |
| `impersonation_token_id` | integer | oui      | ID du jeton d'emprunt d'identité |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2"
```

Exemple de réponse :

```json
{
   "active" : true,
   "user_id" : 2,
   "scopes" : [
      "api"
   ],
   "revoked" : false,
   "name" : "mytoken",
   "description": "Test Token description",
   "id" : 2,
   "created_at" : "2017-03-17T17:18:09.283Z",
   "impersonation" : true,
   "expires_at" : "2017-04-04"
}
```

## Créer un jeton d'emprunt d'identité {#create-an-impersonation-token}

Crée un jeton d'emprunt d'identité pour un utilisateur spécifié. Ces jetons sont utilisés pour agir au nom d'un utilisateur et peuvent effectuer des appels API ainsi que des actions Git en lecture et en écriture. Ces jetons ne sont pas visibles pour l'utilisateur associé sur la page des paramètres de son profil.

Les valeurs des jetons sont incluses dans la réponse, mais ne peuvent pas être récupérées ultérieurement.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:user_id/impersonation_tokens
```

Attributs pris en charge :

| Attribut    | Type    | Obligatoire | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | oui      | ID du compte utilisateur |
| `name`       | string  | oui      | Nom du jeton d'emprunt d'identité |
| `description`| string  | non       | Description du jeton d'emprunt d'identité |
| `expires_at` | date    | oui      | Date d'expiration du jeton d'emprunt d'identité au format ISO (`YYYY-MM-DD`). Si elle n'est pas définie, la date est fixée à la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |
| `scopes`     | array   | oui      | Tableau des portées approuvées. Pour obtenir la liste des valeurs possibles, voir [Portées des jetons d'accès personnels](../user/profile/personal_access_tokens.md#personal-access-token-scopes).  |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

Exemple de réponse :

```json
{
   "id" : 2,
   "revoked" : false,
   "user_id" : 2,
   "scopes" : [
      "api"
   ],
   "token" : "<impersonation_token>",
   "active" : true,
   "impersonation" : true,
   "name" : "mytoken",
   "description": "Test Token description",
   "created_at" : "2017-03-17T17:18:09.283Z",
   "expires_at" : "2017-04-04"
}
```

## Révoquer un jeton d'emprunt d'identité {#revoke-an-impersonation-token}

Révoque un jeton d'emprunt d'identité pour un utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Attributs pris en charge :

| Attribut                | Type    | Obligatoire | Description |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | integer | oui      | ID du compte utilisateur |
| `impersonation_token_id` | integer | oui      | ID du jeton d'emprunt d'identité |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1"
```
