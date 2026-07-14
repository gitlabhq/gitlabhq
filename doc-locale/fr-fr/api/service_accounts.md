---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des comptes de service
description: "L'API des comptes de service GitLab gère les comptes de service au niveau de l'instance ou du groupe, avec des contrôles robustes de gestion des jetons et des comptes."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225913) dans le niveau Free dans GitLab 18.10 [avec un indicateur](../administration/feature_flags/_index.md) nommé `service_accounts_available_on_free_or_unlicensed`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227910) dans le niveau Free dans GitLab 18.11. L'indicateur de fonctionnalité `service_accounts_available_on_free_or_unlicensed` a été supprimé.

{{< /history >}}

Utilisez cette API pour interagir avec les [comptes de service](../user/profile/service_accounts.md).

Le nombre de comptes de service que vous pouvez créer dépend de votre abonnement et de votre offre :

- Sur GitLab Premium et Ultimate, vous pouvez créer un nombre illimité de comptes de service pour toutes les offres.
- Sur GitLab Free, les limites varient selon l'offre :
  - Pour GitLab.com, vous pouvez créer jusqu'à 100 comptes de service pour chaque groupe principal. Cela inclut les comptes de service créés dans des sous-groupes ou des projets.
  - Pour GitLab Self-Managed, vous pouvez créer jusqu'à 100 comptes de service par instance. Cela inclut tous les comptes de service, quelle que soit la façon dont ils sont provisionnés (instance, groupe ou niveau du projet).

Vous pouvez également interagir avec les comptes de service via l'[API des utilisateurs](users.md). Pour gérer les clés SSH des comptes de service, utilisez l'[API des clés SSH et GPG des utilisateurs](user_keys.md).

## Comptes de service d'instance {#instance-service-accounts}

{{< details >}}

- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les comptes de service d'instance sont disponibles pour l'ensemble d'une instance GitLab, mais doivent tout de même être ajoutés aux groupes et aux projets comme un utilisateur humain.

Pour gérer les jetons d'accès personnels des comptes de service d'instance, utilisez l'[API des jetons d'accès personnels](personal_access_tokens.md).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

### Répertorier tous les comptes de service d'instance {#list-all-instance-service-accounts}

{{< history >}}

- Répertorier tous les comptes de service [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) dans GitLab 17.1.

{{< /history >}}

Répertorie tous les comptes de service d'instance.

Utilisez les [paramètres de pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour filtrer les résultats.

```plaintext
GET /service_accounts
```

Attributs pris en charge :

| Attribut  | Type   | Obligatoire | Description |
| ---------- | ------ | -------- | ----------- |
| `order_by` | string | non       | Attribut permettant d'ordonner les résultats. Valeurs possibles : `id` ou `username`. Valeur par défaut : `id`. |
| `sort`     | string | non       | Direction dans laquelle trier les résultats. Valeurs possibles : `desc` ou `asc`. Valeur par défaut : `desc`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/service_accounts"
```

Exemple de réponse :

```json
[
  {
    "id": 114,
    "username": "service_account_33",
    "name": "Service account user"
  },
  {
    "id": 137,
    "username": "service_account_34",
    "name": "john doe"
  }
]
```

### Créer un compte de service d'instance {#create-an-instance-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/406782) dans GitLab 16.1
- Attributs `username` et `name` [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) dans GitLab 16.10.
- Attribut `email` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178689) dans GitLab 17.9.

{{< /history >}}

Crée un compte de service d'instance.

```plaintext
POST /service_accounts
POST /service_accounts?email=custom_email@gitlab.example.com
```

Attributs pris en charge :

| Attribut  | Type   | Obligatoire | Description |
| ---------- | ------ | -------- | ----------- |
| `name`     | string | non       | Nom de l'utilisateur. Si non défini, utilise `Service account user`. |
| `username` | string | non       | Nom d'utilisateur du compte utilisateur. Si non défini, génère un nom préfixé par `service_account_`. |
| `email`    | string | non       | Adresse e-mail du compte utilisateur. Si non définie, génère une adresse e-mail de non-réponse. Les adresses e-mail personnalisées nécessitent une confirmation, sauf si les paramètres de confirmation d'e-mail sont [désactivés](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/service_accounts"
```

Exemple de réponse :

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "service_account_6018816a18e515214e0c34c2b33523fc@noreply.gitlab.example.com"
}
```

Si l'adresse e-mail définie par l'attribut `email` est déjà utilisée par un autre utilisateur, retourne une erreur `400 Bad request`.

### Mettre à jour un compte de service d'instance {#update-an-instance-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309/) dans GitLab 18.2.

{{< /history >}}

Met à jour un compte de service d'instance spécifié.

```plaintext
PATCH /service_accounts/:id
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description                                                                                                                                                                                                               |
|:-----------|:---------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | integer        | oui      | ID du compte de service.  |
| `name`     | string         | non       | Nom de l'utilisateur.  |
| `username` | string         | non       | Nom d'utilisateur du compte utilisateur. |
| `email`    | string         | non       | Adresse e-mail du compte utilisateur. Les adresses e-mail personnalisées nécessitent une confirmation, sauf si les paramètres de confirmation d'e-mail sont [désactivés](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/service_accounts/57" \
  --data "name=Updated Service Account&email=updated_email@example.com"
```

Exemple de réponse :

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

## Comptes de service de groupe {#group-service-accounts}

{{< history >}}

- Les comptes de service de sous-groupe [introduits](https://gitlab.com/gitlab-org/gitlab/-/work_items/585513) dans GitLab 18.10 [avec un feature flag](../administration/feature_flags/_index.md) nommé `allow_subgroups_to_create_service_accounts`. Désactivé par défaut.
- Les comptes de service de sous-groupe [disponibles en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/) dans GitLab 18.11. L'indicateur de fonctionnalité `allow_subgroups_to_create_service_accounts` a été supprimé.

{{< /history >}}

Les comptes de service de groupe appartiennent à un groupe spécifique et peuvent être invités dans le groupe où ils ont été créés ou dans tout sous-groupe ou projet descendant. Ils ne peuvent pas être invités dans des groupes ancêtres.

Prérequis :

- Sur GitLab.com, vous devez disposer du rôle Owner pour le groupe.
- Sur GitLab Self-Managed ou GitLab Dedicated, vous devez soit :
  - Être administrateur de l'instance.
  - Avoir le rôle Owner dans un groupe et être [autorisé à créer des comptes de service](../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

### Répertorier tous les comptes de service de groupe {#list-all-group-service-accounts}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) dans GitLab 17.1.

{{< /history >}}

Répertorie tous les comptes de service dans un groupe spécifié.

Utilisez les [paramètres de pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour filtrer les résultats.

```plaintext
GET /groups/:id/service_accounts
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `order_by` | string         | non       | Trie la liste des utilisateurs par `username` ou `id`. La valeur par défaut est `id`. |
| `sort`     | string         | non       | Spécifie le tri par `asc` ou `desc`. La valeur par défaut est `desc`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts"
```

Exemple de réponse :

```json
[

  {
    "id": 57,
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### Créer un compte de service de groupe {#create-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/407775) dans GitLab 16.1.
- Attributs `username` et `name` [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) dans GitLab 16.10.
- Attribut `email` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181456) dans GitLab 17.9 [avec un indicateur](../administration/feature_flags/_index.md) nommé `group_service_account_custom_email`.
- Attribut `email` [disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186476) dans GitLab 17.11. L'indicateur de fonctionnalité `group_service_account_custom_email` a été supprimé.

{{< /history >}}

Crée un compte de service dans un groupe spécifié.

```plaintext
POST /groups/:id/service_accounts
```

Attributs pris en charge :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `name`     | string         | non       | Nom du compte utilisateur. Si non spécifié, utilise `Service account user`. |
| `username` | string         | non       | Nom d'utilisateur du compte utilisateur. Si non spécifié, génère un nom préfixé par `service_account_group_`. |
| `email`    | string         | non       | Adresse e-mail du compte utilisateur. Si non spécifiée, génère une adresse e-mail préfixée par `service_account_group_`. Les adresses e-mail personnalisées nécessitent une confirmation, sauf si le groupe dispose d'un [domaine vérifié](../user/enterprise_user/_index.md#manage-group-domains) correspondant ou si les paramètres de confirmation d'e-mail sont [désactivés](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts" \
  --data "email=custom_email@example.com"
```

Exemple de réponse :

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

### Mettre à jour un compte de service de groupe {#update-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182607/) dans GitLab 17.10.
- Ajout d'une adresse e-mail personnalisée [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309) dans GitLab 18.2.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/work_items/581050) des limites de nom d'utilisateur pour les comptes de service avec des identités composites dans GitLab 18.9.

{{< /history >}}

Met à jour un compte de service dans un groupe spécifié.

> [!note]
>
> - Vous ne pouvez pas mettre à jour le nom d'utilisateur d'un compte de service associé à une [identité composite](../user/duo_agent_platform/composite_identity.md).

```plaintext
PATCH /groups/:id/service_accounts/:user_id
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `user_id`  | integer        | oui      | L'ID du compte de service. |
| `name`     | string         | non       | Nom de l'utilisateur. |
| `username` | string         | non       | Nom d'utilisateur de l'utilisateur. |
| `email`    | string         | non       | Adresse e-mail du compte utilisateur. Les adresses e-mail personnalisées nécessitent une confirmation, sauf si le groupe dispose d'un [domaine vérifié](../user/enterprise_user/_index.md#manage-group-domains) correspondant ou si les paramètres de confirmation d'e-mail sont [désactivés](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts/57" \
  --data "name=Updated Service Account&email=updated_email@example.com"
```

Exemple de réponse :

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

### Supprimer un compte de service de groupe {#delete-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) dans GitLab 17.1.

{{< /history >}}

Supprime un compte de service d'un groupe spécifié.

```plaintext
DELETE /groups/:id/service_accounts/:user_id
```

Paramètres :

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | integer ou string | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `user_id`     | integer        | oui      | L'ID d'un compte de service. |
| `hard_delete` | boolean        | non       | Si la valeur est true, les contributions qui auraient normalement été [transférées à un utilisateur fantôme](../user/profile/account/delete_account.md#associated-records) sont supprimées, ainsi que les groupes détenus uniquement par ce compte de service. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts/181"
```

### Répertorier tous les jetons d'accès personnels pour un compte de service de groupe {#list-all-personal-access-tokens-for-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/526924) dans GitLab 17.11.

{{< /history >}}

Répertorie tous les jetons d'accès personnels pour un compte de service dans un groupe spécifié.

```plaintext
GET /groups/:id/service_accounts/:user_id/personal_access_tokens
```

Attributs pris en charge :

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | integer ou string      | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `user_id`          | integer             | oui      | ID du compte de service. |
| `created_after`    | datetime (ISO 8601) | non       | Si défini, retourne les jetons créés après l'heure spécifiée. |
| `created_before`   | datetime (ISO 8601) | non       | Si défini, retourne les jetons créés avant l'heure spécifiée. |
| `expires_after`    | date (ISO 8601)     | non       | Si défini, retourne les jetons qui expirent après l'heure spécifiée. |
| `expires_before`   | date (ISO 8601)     | non       | Si défini, retourne les jetons qui expirent avant l'heure spécifiée. |
| `last_used_after`  | datetime (ISO 8601) | non       | Si défini, retourne les jetons utilisés en dernier après l'heure spécifiée. |
| `last_used_before` | datetime (ISO 8601) | non       | Si défini, retourne les jetons utilisés en dernier avant l'heure spécifiée. |
| `revoked`          | boolean             | non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | non       | Si défini, retourne les jetons dont le nom inclut la valeur spécifiée. |
| `sort`             | string              | non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | string              | non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
```

Exemple de réponse :

```json
[
    {
        "id": 187,
        "name": "service_accounts_token2b",
        "revoked": false,
        "created_at": "2025-03-26T14:42:51.084Z",
        "description": null,
        "scopes": [
            "api"
        ],
        "user_id": 195,
        "last_used_at": null,
        "active": true,
        "expires_at": null
    }
]
```

Exemple de réponses d'erreur :

- `401: Unauthorized`
- `404 Group Not Found`

### Créer un jeton d'accès personnel pour un compte de service de groupe {#create-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) dans GitLab 16.1.

{{< /history >}}

Crée un jeton d'accès personnel pour un compte de service existant dans un groupe spécifié.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

Paramètres :

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | integer ou string | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `user_id`     | integer        | oui      | ID du compte de service. |
| `name`        | string         | oui      | Nom du jeton d'accès personnel. |
| `description` | string         | non       | Description du jeton d'accès personnel. |
| `scopes`      | array          | oui      | Tableau des portées approuvées. Pour obtenir la liste des valeurs possibles, consultez les [portées des jetons d'accès personnels](../user/profile/personal_access_tokens.md#personal-access-token-scopes). |
| `expires_at`  | date           | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si non spécifiée, la date est définie sur la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens" \
  --data "scopes[]=api,read_user,read_repository" \
  --data "name=service_accounts_token"
```

Exemple de réponse :

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

### Révoquer un jeton d'accès personnel pour un compte de service de groupe {#revoke-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184287) dans GitLab 17.11

{{< /history >}}

Révoque un jeton d'accès personnel spécifié pour un compte de service existant dans un groupe.

```plaintext
DELETE /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `user_id`  | integer        | oui      | L'ID du compte de service. |
| `token_id` | integer        | oui      | L'ID du jeton. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6"
```

En cas de succès, retourne `204: No Content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas abouti.
- `401: Unauthorized` si la requête n'est pas autorisée.
- `403: Forbidden` si la requête n'est pas autorisée.
- `404: Not Found` si le jeton d'accès n'existe pas.

### Effectuer la rotation d'un jeton d'accès personnel pour un compte de service de groupe {#rotate-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) dans GitLab 16.1.

{{< /history >}}

Effectue la rotation d'un jeton d'accès personnel spécifié pour un compte de service existant dans un groupe spécifié. Cette opération révoque le jeton existant et crée un nouveau jeton avec le même nom, la même description et les mêmes portées.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

Paramètres :

| Attribut    | Type           | Obligatoire | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer ou string | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `user_id`    | integer        | oui      | L'ID du compte de service. |
| `token_id`   | integer        | oui      | L'ID du jeton. |
| `expires_at` | date           | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/505671) dans GitLab 17.9. Si le jeton nécessite une date d'expiration, la valeur par défaut est d'une semaine. Si non requis, la valeur par défaut est la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6/rotate"
```

Exemple de réponse :

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```

## Comptes de service de projet {#project-service-accounts}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/585509) dans GitLab 18.9 [avec un indicateur](../administration/feature_flags/_index.md) nommé `allow_projects_to_create_service_accounts`. Désactivé par défaut.
- Les comptes de service de projet [disponibles en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/) dans GitLab 18.11. L'indicateur de fonctionnalité `allow_projects_to_create_service_accounts` a été supprimé.

{{< /history >}}

Les comptes de service de projet appartiennent à un projet spécifique et ne sont disponibles que pour leur projet associé.

Prérequis :

- Sur GitLab.com, vous devez disposer du rôle Maintainer ou Owner pour le projet.
- Sur GitLab Self-Managed ou GitLab Dedicated, vous devez soit :
  - Être administrateur de l'instance.
  - Avoir le rôle Maintainer ou Owner dans un projet.

### Répertorier tous les comptes de service de projet {#list-all-project-service-accounts}

Répertorie tous les comptes de service dans un projet spécifié.

Utilisez les [paramètres de pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour filtrer les résultats.

```plaintext
GET /projects/:id/service_accounts
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | L'ID ou le [chemin encodé en URL du projet cible](rest/_index.md#namespaced-paths). |
| `order_by` | string         | non       | Trie la liste des utilisateurs par `username` ou `id`. La valeur par défaut est `id`. |
| `sort`     | string         | non       | Spécifie le tri par `asc` ou `desc`. La valeur par défaut est `desc`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts"
```

Exemple de réponse :

```json
[

  {
    "id": 57,
    "username": "service_account_project_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_project_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### Créer un compte de service de projet {#create-a-project-service-account}

Crée un compte de service dans un projet spécifié.

```plaintext
POST /projects/:id/service_accounts
```

Attributs pris en charge :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet |
| `name`     | string         | non       | Nom du compte utilisateur. Si non spécifié, utilise `Service account user`. |
| `username` | string         | non       | Nom d'utilisateur du compte utilisateur. Si non spécifié, génère un nom préfixé par `service_account_project_`. |
| `email`    | string         | non       | Adresse e-mail du compte utilisateur. Si non spécifiée, génère une adresse e-mail préfixée par `service_account_project_`. Les adresses e-mail personnalisées nécessitent une confirmation, sauf si le groupe dispose d'un [domaine vérifié](../user/enterprise_user/_index.md#manage-group-domains) correspondant ou si les paramètres de confirmation d'e-mail sont [désactivés](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts" \
  --data "email=custom_email@example.com"
```

Exemple de réponse :

```json
{
  "id": 57,
  "username": "service_account_project_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

### Mettre à jour un compte de service de projet {#update-a-project-service-account}

Met à jour un compte de service dans un projet spécifié.

```plaintext
PATCH /projects/:id/service_accounts/:user_id
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | L'ID ou le [chemin encodé en URL du projet cible](rest/_index.md#namespaced-paths). |
| `user_id`  | integer        | oui      | L'ID du compte de service. |
| `name`     | string         | non       | Nom de l'utilisateur. |
| `username` | string         | non       | Nom d'utilisateur de l'utilisateur. |
| `email`    | string         | non       | Adresse e-mail du compte utilisateur. Les adresses e-mail personnalisées nécessitent une confirmation, sauf si le groupe dispose d'un [domaine vérifié](../user/enterprise_user/_index.md#manage-group-domains) correspondant ou si les paramètres de confirmation d'e-mail sont [désactivés](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts/57" \
  --data "name=Updated Service Account&email=updated_email@example.com"
```

Exemple de réponse :

```json
{
  "id": 57,
  "username": "service_account_project_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

### Supprimer un compte de service de projet {#delete-a-project-service-account}

Supprime un compte de service d'un projet spécifié.

```plaintext
DELETE /projects/:id/service_accounts/:user_id
```

Paramètres :

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | integer ou string | oui      | L'ID ou le [chemin encodé en URL du projet cible](rest/_index.md#namespaced-paths). |
| `user_id`     | integer        | oui      | L'ID d'un compte de service. |
| `hard_delete` | boolean        | non       | Si la valeur est true, les contributions qui auraient normalement été [transférées à un utilisateur fantôme](../user/profile/account/delete_account.md#associated-records) sont supprimées, ainsi que les groupes détenus uniquement par ce compte de service. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts/181"
```

### Répertorier tous les jetons d'accès personnels pour un compte de service de projet {#list-all-personal-access-tokens-for-a-project-service-account}

Répertorie tous les jetons d'accès personnels pour un compte de service dans un projet.

```plaintext
GET /projects/:id/service_accounts/:user_id/personal_access_tokens
```

Attributs pris en charge :

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | integer ou string      | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `user_id`          | integer             | oui      | ID du compte de service. |
| `created_after`    | datetime (ISO 8601) | non       | Si défini, retourne les jetons créés après l'heure spécifiée. |
| `created_before`   | datetime (ISO 8601) | non       | Si défini, retourne les jetons créés avant l'heure spécifiée. |
| `expires_after`    | date (ISO 8601)     | non       | Si défini, retourne les jetons qui expirent après l'heure spécifiée. |
| `expires_before`   | date (ISO 8601)     | non       | Si défini, retourne les jetons qui expirent avant l'heure spécifiée. |
| `last_used_after`  | datetime (ISO 8601) | non       | Si défini, retourne les jetons utilisés en dernier après l'heure spécifiée. |
| `last_used_before` | datetime (ISO 8601) | non       | Si défini, retourne les jetons utilisés en dernier avant l'heure spécifiée. |
| `revoked`          | boolean             | non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | non       | Si défini, retourne les jetons dont le nom inclut la valeur spécifiée. |
| `sort`             | string              | non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | string              | non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
```

Exemple de réponse :

```json
[
    {
        "id": 187,
        "name": "service_accounts_token2b",
        "revoked": false,
        "created_at": "2025-03-26T14:42:51.084Z",
        "description": null,
        "scopes": [
            "api"
        ],
        "user_id": 195,
        "last_used_at": null,
        "active": true,
        "expires_at": null
    }
]
```

Exemple de réponses d'erreur :

- `401: Unauthorized`
- `404 Project Not Found`

### Créer un jeton d'accès personnel pour un compte de service de projet {#create-a-personal-access-token-for-a-project-service-account}

Crée un jeton d'accès personnel pour un compte de service existant dans un projet spécifié.

```plaintext
POST /projects/:id/service_accounts/:user_id/personal_access_tokens
```

Paramètres :

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | integer ou string | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `user_id`     | integer        | oui      | ID du compte de service. |
| `name`        | string         | oui      | Nom du jeton d'accès personnel. |
| `description` | string         | non       | Description du jeton d'accès personnel. |
| `scopes`      | array          | oui      | Tableau des portées approuvées. Pour obtenir la liste des valeurs possibles, consultez les [portées des jetons d'accès personnels](../user/profile/personal_access_tokens.md#personal-access-token-scopes). |
| `expires_at`  | date           | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). Si non spécifiée, la date est définie sur la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens" \
  --data "scopes[]=api,read_user,read_repository" \
  --data "name=service_accounts_token"
```

Exemple de réponse :

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

### Révoquer un jeton d'accès personnel pour un compte de service de projet {#revoke-a-personal-access-token-for-a-project-service-account}

Révoque un jeton d'accès personnel pour un compte de service existant dans un projet spécifié.

```plaintext
DELETE /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

Paramètres :

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer ou string | oui      | L'ID ou le [chemin encodé en URL du projet cible](rest/_index.md#namespaced-paths). |
| `user_id`  | integer        | oui      | L'ID du compte de service. |
| `token_id` | integer        | oui      | L'ID du jeton. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens/6"
```

En cas de succès, retourne `204: No Content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas abouti.
- `401: Unauthorized` si la requête n'est pas autorisée.
- `403: Forbidden` si la requête n'est pas autorisée.
- `404: Not Found` si le jeton d'accès n'existe pas.

### Effectuer la rotation d'un jeton d'accès personnel pour un compte de service de projet {#rotate-a-personal-access-token-for-a-project-service-account}

Effectue la rotation d'un jeton d'accès personnel pour un compte de service existant dans un projet spécifié. Cette opération crée un nouveau jeton valide pendant une semaine et révoque tous les jetons existants.

```plaintext
POST /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

Paramètres :

| Attribut    | Type           | Obligatoire | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer ou string | oui      | L'ID ou le [chemin encodé en URL du projet cible](rest/_index.md#namespaced-paths). |
| `user_id`    | integer        | oui      | L'ID du compte de service. |
| `token_id`   | integer        | oui      | L'ID du jeton. |
| `expires_at` | date           | non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/505671) dans GitLab 17.9. Si le jeton nécessite une date d'expiration, la valeur par défaut est d'une semaine. Si non requis, la valeur par défaut est la [limite de durée de vie maximale autorisée](../user/profile/personal_access_tokens.md#access-token-expiration). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens/6/rotate"
```

Exemple de réponse :

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```
