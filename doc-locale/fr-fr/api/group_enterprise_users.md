---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des utilisateurs d'entreprise de groupe"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com

{{< /details >}}

Utilisez ces points de terminaison d'API pour interagir avec les utilisateurs d'entreprise. Pour plus d'informations, consultez [les utilisateurs d'entreprise](../user/enterprise_user/_index.md).

Ces points de terminaison d'API fonctionnent uniquement pour les groupes principaux. Les utilisateurs n'ont pas à être membres du groupe.

Prérequis :

- Vous devez disposer du rôle Owner dans le groupe principal.

## Lister tous les utilisateurs d'entreprise {#list-all-enterprise-users}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438366) dans GitLab 17.7.

{{< /history >}}

Liste tous les utilisateurs d'entreprise pour un groupe principal spécifié.

Utilisez les `page` et `per_page` [paramètres de pagination](rest/_index.md#offset-based-pagination) pour filtrer les résultats.

```plaintext
GET /groups/:id/enterprise_users
```

Attributs pris en charge :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe principal. |
| `username`       | string         | non       | Renvoie un utilisateur avec un nom d'utilisateur donné. |
| `search`         | string         | non       | Renvoie les utilisateurs dont le nom, l'e-mail ou le nom d'utilisateur correspond. Utilisez des valeurs partielles pour augmenter les résultats. |
| `active`         | boolean        | non       | Renvoie uniquement les utilisateurs actifs. |
| `blocked`        | boolean        | non       | Renvoie uniquement les utilisateurs bloqués. |
| `created_after`  | datetime       | non       | Renvoie les utilisateurs créés après l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_before` | datetime       | non       | Renvoie les utilisateurs créés avant l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `two_factor`     | string         | non       | Renvoie les utilisateurs en fonction de leur statut d'inscription à l'authentification à deux facteurs (2FA). Valeurs possibles : `enabled`, `disabled`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users"
```

Exemple de réponse :

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

## Récupérer un utilisateur d'entreprise {#retrieve-an-enterprise-user}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176328) dans GitLab 17.9.

{{< /history >}}

Récupère un utilisateur d'entreprise spécifié.

```plaintext
GET /groups/:id/enterprise_users/:user_id
```

Attributs pris en charge :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe principal. |
| `user_id`        | entier        | oui      | ID du compte utilisateur. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

Exemple de réponse :

```json
{
  "id": 66,
  "username": "user22",
  "name": "Sidney Jones22",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
  "web_url": "http://my.gitlab.com/user22",
  "created_at": "2021-09-10T12:48:22.381Z",
  "bio": "",
  "location": null,
  "public_email": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": null,
  "job_title": "",
  "pronouns": null,
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": null,
  "last_sign_in_at": null,
  "confirmed_at": "2021-09-10T12:48:22.330Z",
  "last_activity_on": null,
  "email": "user22@example.org",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 100000,
  "current_sign_in_at": null,
  "identities": [
    {
      "provider": "group_saml",
      "extern_uid": "2435223452345",
      "saml_provider_id": 1
    }
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "external": false,
  "private_profile": false,
  "commit_email": "user22@example.org",
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
    {
      "extern_uid": "2435223452345",
      "group_id": 1,
      "active": true
    }
  ]
}
```

## Mettre à jour un utilisateur d'entreprise {#update-an-enterprise-user}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199248) dans GitLab 18.6.

{{< /history >}}

Met à jour un utilisateur d'entreprise spécifié.

```plaintext
PATCH /groups/:id/enterprise_users/:user_id
```

Attributs pris en charge :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe principal. |
| `user_id`        | entier        | oui      | ID du compte utilisateur. |
| `name`           | string         | non       | Nom du compte utilisateur. |
| `email`          | string         | non       | Adresse e-mail du compte utilisateur. Doit provenir d'un [domaine de groupe](../user/enterprise_user/_index.md#manage-group-domains) vérifié. |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "email=new-email@example.com" \
  --data "name=New name" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

En cas de succès, retourne `200 OK`.

Exemple de réponse en cas de succès :

```json
{
  "id": 66,
  "username": "user22",
  "name": "New name",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
  "web_url": "http://my.gitlab.com/user22",
  "created_at": "2021-09-10T12:48:22.381Z",
  "bio": "",
  "location": null,
  "public_email": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": null,
  "job_title": "",
  "pronouns": null,
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": null,
  "last_sign_in_at": null,
  "confirmed_at": "2021-09-10T12:48:22.330Z",
  "last_activity_on": null,
  "email": "new-email@example.com",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 100000,
  "current_sign_in_at": null,
  "identities": [
    {
      "provider": "group_saml",
      "extern_uid": "2435223452345",
      "saml_provider_id": 1
    }
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "external": false,
  "private_profile": false,
  "commit_email": "user22@example.org",
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
    {
      "extern_uid": "2435223452345",
      "group_id": 1,
      "active": true
    }
  ]
}
```

Autres réponses possibles :

- `400 Bad Request` : Erreurs de validation.
- `403 Forbidden` : L'utilisateur authentifié n'est pas un Owner.
- `404 Not found` : L'utilisateur est introuvable.

## Supprimer un utilisateur d'entreprise {#delete-an-enterprise-user}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199646) dans GitLab 18.3.

{{< /history >}}

Supprime un utilisateur d'entreprise spécifié.

```plaintext
DELETE /groups/:id/enterprise_users/:user_id
```

Attributs pris en charge :

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                                                                                                                              |
|:--------------|:---------------|:---------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe principal.                                                                                                                                                                                                          |
| `user_id`     | entier        | oui      | ID du compte utilisateur.                                                                                                                                                                                                                                                                      |
| `hard_delete` | boolean        | non       | Si `false`, supprime l'utilisateur et déplace ses contributions [vers un utilisateur fantôme](../user/profile/account/delete_account.md#associated-records). Si `true`, supprime l'utilisateur, ses contributions associées et tous les groupes détenus uniquement par l'utilisateur. Valeur par défaut : `false`.  |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

En cas de succès, retourne `204 No content`.

Autres réponses possibles :

- `403 Forbidden` : L'utilisateur authentifié n'est pas un Owner.
- `404 Not found` : L'utilisateur est introuvable.
- `409 Conflict` : Impossible de supprimer un utilisateur qui est le seul Owner d'un groupe.

## Désactiver l'authentification à deux facteurs pour un utilisateur d'entreprise {#disable-two-factor-authentication-for-an-enterprise-user}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177943) dans GitLab 17.9.

{{< /history >}}

Désactive l'authentification à deux facteurs (2FA) pour un utilisateur d'entreprise spécifié.

```plaintext
PATCH /groups/:id/enterprise_users/:user_id/disable_two_factor
```

Attributs pris en charge :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe principal. |
| `user_id`        | entier        | oui      | ID du compte utilisateur. |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id/disable_two_factor"
```

En cas de succès, retourne `204 No content`.

Autres réponses possibles :

- `400 Bad request` : La 2FA n'est pas activée pour l'utilisateur spécifié.
- `403 Forbidden` : L'utilisateur authentifié n'est pas un Owner.
- `404 Not found` : L'utilisateur est introuvable.
