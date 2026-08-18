---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Users
description: "L'API Users de GitLab permet de créer, modifier, rechercher et supprimer des comptes utilisateur. Elle prend également en charge les opérations d'administration et le provisionnement SCIM."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les comptes utilisateur sur GitLab. Ces points de terminaison peuvent vous aider à gérer [votre compte](../user/profile/_index.md) ou les [comptes d'autres utilisateurs](../administration/administer_users.md).

## Lister tous les utilisateurs {#list-all-users}

Liste tous les utilisateurs.

Utilise les [paramètres de pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour restreindre la liste des utilisateurs.

### En tant qu'utilisateur régulier {#as-a-regular-user}

{{< history >}}

- La pagination par jeu de clés a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419556) dans GitLab 16.5.
- L'attribut `saml_provider_id` a été supprimé dans GitLab 18.2.

{{< /history >}}

```plaintext
GET /users
```

Attributs pris en charge :

| Attribut              | Type     | Obligatoire | Description |
|:-----------------------|:---------|:---------|:------------|
| `username`             | string   | non       | Récupère un seul utilisateur avec un nom d'utilisateur spécifique. |
| `public_email`         | string   | non       | Récupère un seul utilisateur avec une adresse e-mail publique spécifique. |
| `search`               | string   | non       | Recherche des utilisateurs par nom, nom d'utilisateur ou adresse e-mail publique. |
| `active`               | boolean  | non       | Filtre uniquement les utilisateurs actifs. La valeur par défaut est `false`. |
| `external`             | boolean  | non       | Filtre uniquement les utilisateurs externes. La valeur par défaut est `false`. |
| `blocked`              | boolean  | non       | Filtre uniquement les utilisateurs bloqués. La valeur par défaut est `false`. |
| `humans`               | boolean  | non       | Filtre uniquement les utilisateurs réguliers qui ne sont pas des utilisateurs bot ou internes. La valeur par défaut est `false`. |
| `created_after`        | DateTime | non       | Retourne les utilisateurs créés après l'heure spécifiée. |
| `created_before`       | DateTime | non       | Retourne les utilisateurs créés avant l'heure spécifiée. |
| `exclude_active`       | boolean  | non       | Filtre uniquement les utilisateurs non actifs. La valeur par défaut est `false`. |
| `exclude_external`     | boolean  | non       | Filtre uniquement les utilisateurs non externes. La valeur par défaut est `false`. |
| `exclude_humans`       | boolean  | non       | Filtre uniquement les utilisateurs bot ou internes. La valeur par défaut est `false`. |
| `exclude_internal`     | boolean  | non       | Filtre uniquement les utilisateurs non internes. La valeur par défaut est `false`. |
| `without_project_bots` | boolean  | non       | Filtre les utilisateurs sans bots de projet. La valeur par défaut est `false`. |

Exemple de réponse :

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

Ce point de terminaison prend en charge la [pagination par jeu de clés](rest/_index.md#keyset-based-pagination). Dans GitLab 17.0 et versions ultérieures, la pagination par jeu de clés est obligatoire pour les réponses contenant 50 000 entrées et plus.

Vous pouvez également utiliser `?search=` pour rechercher des utilisateurs par nom, nom d'utilisateur ou adresse e-mail publique. Par exemple, `/users?search=John`. Lorsque vous recherchez :

- Une adresse e-mail publique, vous devez utiliser l'adresse e-mail complète pour obtenir une correspondance exacte.
- Un nom ou un nom d'utilisateur, vous n'êtes pas obligé d'obtenir une correspondance exacte car il s'agit d'une recherche approximative.

De plus, vous pouvez rechercher des utilisateurs par nom d'utilisateur :

```plaintext
GET /users?username=:username
```

Par exemple :

```plaintext
GET /users?username=jack_smith
```

> [!note]
> La recherche par nom d'utilisateur est insensible à la casse.

De plus, vous pouvez filtrer les utilisateurs en fonction des états `blocked` et `active`. Cela ne prend pas en charge `active=false` ni `blocked=false`.

```plaintext
GET /users?active=true
```

```plaintext
GET /users?blocked=true
```

De plus, vous pouvez rechercher uniquement les utilisateurs externes avec `external=true`. Cela ne prend pas en charge `external=false`.

```plaintext
GET /users?external=true
```

GitLab prend en charge les utilisateurs bot tels que le [bot d'alerte](../operations/incident_management/integrations.md) ou le [bot de support](../user/project/service_desk/configure.md#support-bot-user). Vous pouvez exclure les types suivants d'[utilisateurs internes](../administration/internal_users.md) de la liste des utilisateurs à l'aide du paramètre `exclude_internal=true` :

- Bot d'alerte
- Bot de support

Cependant, cette action n'exclut pas les [utilisateurs bot pour les projets](../user/project/settings/project_access_tokens.md#bot-users-for-projects) ni les [utilisateurs bot pour les groupes](../user/group/settings/group_access_tokens.md#bot-users-for-groups).

```plaintext
GET /users?exclude_internal=true
```

De plus, pour exclure les utilisateurs externes de la liste des utilisateurs, vous pouvez utiliser le paramètre `exclude_external=true`.

```plaintext
GET /users?exclude_external=true
```

Pour exclure les [utilisateurs bot pour les projets](../user/project/settings/project_access_tokens.md#bot-users-for-projects) et les [utilisateurs bot pour les groupes](../user/group/settings/group_access_tokens.md#bot-users-for-groups), vous pouvez utiliser le paramètre `without_project_bots=true`.

```plaintext
GET /users?without_project_bots=true
```

### En tant qu'administrateur {#as-an-administrator}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le champ `created_by` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092) dans GitLab 15.6.
- Le champ `scim_identities` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/324247) dans GitLab 16.1.
- Le champ `auditors` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418023) dans GitLab 16.2.
- Le champ `email_reset_offered_at` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610) dans GitLab 16.7.
- Le champ `email_reset_offered_at` dans la réponse a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197491) dans GitLab 18.3.

{{< /history >}}

```plaintext
GET /users
```

Vous pouvez utiliser tous les [paramètres disponibles pour tout le monde](#as-a-regular-user), ainsi que ces attributs supplémentaires disponibles uniquement pour les administrateurs.

Attributs pris en charge :

| Attribut          | Type    | Obligatoire | Description |
|:-------------------|:--------|:---------|:------------|
| `search`           | string  | non       | Recherche des utilisateurs par nom, nom d'utilisateur, adresse e-mail publique ou adresse e-mail privée. |
| `extern_uid`       | string  | non       | Récupère un seul utilisateur avec un UID de fournisseur d'authentification externe spécifique. |
| `provider`         | string  | non       | Le fournisseur externe. |
| `order_by`         | string  | non       | Retourne les utilisateurs triés par les champs `id`, `name`, `username`, `created_at` ou `updated_at`. La valeur par défaut est `id` |
| `sort`             | string  | non       | Retourne les utilisateurs triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `two_factor`       | string  | non       | Filtre les utilisateurs par authentification à deux facteurs. Les valeurs de filtre sont `enabled` ou `disabled`. Par défaut, retourne tous les utilisateurs |
| `without_projects` | boolean | non       | Filtre les utilisateurs sans projets. La valeur par défaut est `false`, ce qui signifie que tous les utilisateurs sont retournés, avec et sans projets. |
| `admins`           | boolean | non       | Retourne uniquement les administrateurs. La valeur par défaut est `false` |
| `auditors`         | boolean | non       | Retourne uniquement les utilisateurs auditeurs. La valeur par défaut est `false`. Si non inclus, retourne tous les utilisateurs. Premium et Ultimate uniquement. |
| `skip_ldap`        | boolean | non       | Ignorer les utilisateurs LDAP. Premium et Ultimate uniquement. |

Exemple de réponse :

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2012-05-23T08:00:58Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "linkedin": "",
    "twitter": "",
    "discord": "",
    "github": "",
    "website_url": "",
    "organization": "",
    "job_title": "",
    "last_sign_in_at": "2012-06-01T11:41:01Z",
    "confirmed_at": "2012-05-23T09:05:22Z",
    "theme_id": 1,
    "last_activity_on": "2012-05-23",
    "color_scheme_id": 2,
    "projects_limit": 100,
    "current_sign_in_at": "2012-06-02T06:36:55Z",
    "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "196.165.1.102",
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 1,
    "created_by": null
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/2/index.jpg",
    "web_url": "http://localhost:3000/jack_smith",
    "created_at": "2012-05-23T08:01:01Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "linkedin": "",
    "twitter": "",
    "discord": "",
    "github": "",
    "website_url": "",
    "organization": "",
    "job_title": "",
    "last_sign_in_at": null,
    "confirmed_at": "2012-05-30T16:53:06.148Z",
    "theme_id": 1,
    "last_activity_on": "2012-05-23",
    "color_scheme_id": 3,
    "projects_limit": 100,
    "current_sign_in_at": "2014-03-19T17:54:13Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "10.165.1.102",
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 2,
    "created_by": null
  }
]
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les paramètres `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit`, `is_auditor` et `using_license_seat`.

```json
[
  {
    "id": 1,
    ...
    "shared_runners_minutes_limit": 133,
    "extra_shared_runners_minutes_limit": 133,
    "is_auditor": false,
    "using_license_seat": true
    ...
  }
]
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également l'option de fournisseur `group_saml` et le paramètre `provisioned_by_group_id` :

```json
[
  {
    "id": 1,
    ...
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
      {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
    ],
    "provisioned_by_group_id": 123789
    ...
  }
]
```

Vous pouvez également utiliser `?search=` pour rechercher des utilisateurs par nom, nom d'utilisateur ou adresse e-mail. Par exemple, `/users?search=John`. Lorsque vous recherchez :

- Une adresse e-mail, vous devez utiliser l'adresse e-mail complète pour obtenir une correspondance exacte. En tant qu'administrateur, vous pouvez rechercher des adresses e-mail publiques et privées.
- Un nom ou un nom d'utilisateur, vous n'êtes pas obligé d'obtenir une correspondance exacte car il s'agit d'une recherche approximative.

Vous pouvez rechercher des utilisateurs par UID externe et fournisseur :

```plaintext
GET /users?extern_uid=:extern_uid&provider=:provider
```

Par exemple :

```plaintext
GET /users?extern_uid=1234567&provider=github
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) ont le fournisseur `scim` disponible :

```plaintext
GET /users?extern_uid=1234567&provider=scim
```

Vous pouvez rechercher des utilisateurs par plage de dates de création avec :

```plaintext
GET /users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060
```

Vous pouvez rechercher des utilisateurs sans projets avec : `/users?without_projects=true`

Vous pouvez filtrer par [attributs personnalisés](custom_attributes.md) avec :

```plaintext
GET /users?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

Vous pouvez inclure les [attributs personnalisés](custom_attributes.md) des utilisateurs dans la réponse avec :

```plaintext
GET /users?with_custom_attributes=true
```

Vous pouvez utiliser le paramètre `created_by` pour vérifier si un compte utilisateur a été créé :

- [Manuellement par un administrateur](../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area).
- En tant qu'[utilisateur bot de projet](../user/project/settings/project_access_tokens.md#bot-users-for-projects).

Si la valeur retournée est `null`, le compte a été créé par un utilisateur qui s'est lui-même inscrit.

## Récupérer un seul utilisateur {#retrieve-a-single-user}

Récupère un seul utilisateur.

### Récupérer un seul utilisateur en tant qu'utilisateur régulier {#retrieve-a-single-user-as-a-regular-user}

Récupère un seul utilisateur en tant qu'utilisateur régulier.

Prérequis :

- Vous devez être connecté pour utiliser ce point de terminaison.

```plaintext
GET /users/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID d'un utilisateur |

Exemple de réponse :

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "bot": false,
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "is_followed": false
}
```

### En tant qu'administrateur {#as-an-administrator-1}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le champ `created_by` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092) dans GitLab 15.6.
- Le champ `email_reset_offered_at` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610) dans GitLab 16.7.
- Le champ `email_reset_offered_at` dans la réponse a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197491) dans GitLab 18.3.

{{< /history >}}

Récupère un seul utilisateur en tant qu'administrateur.

```plaintext
GET /users/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID d'un utilisateur |

Exemple de réponse :

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "plan": "gold",
  "trial": true,
  "sign_in_count": 1337,
  "namespace_id": 1,
  "created_by": null
}
```

> [!note]
> Les paramètres `plan` et `trial` sont uniquement disponibles sur GitLab Enterprise Edition.

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les paramètres `shared_runners_minutes_limit`, `is_auditor` et `extra_shared_runners_minutes_limit`.

```json
{
  "id": 1,
  "username": "john_smith",
  "is_auditor": false,
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  ...
}
```

Les utilisateurs de [GitLab.com Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également l'option `group_saml` et le paramètre `provisioned_by_group_id` :

```json
{
  "id": 1,
  "username": "john_smith",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
    {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
  ],
  "provisioned_by_group_id": 123789
  ...
}
```

Les utilisateurs de [GitLab.com Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également le paramètre `scim_identities` :

```json
{
  ...
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
      {"extern_uid": "2435223452345", "group_id": "3", "active": true},
      {"extern_uid": "john.smith", "group_id": "42", "active": false}
    ]
  ...
}
```

Les administrateurs peuvent utiliser le paramètre `created_by` pour vérifier si un compte utilisateur a été créé :

- [Manuellement par un administrateur](../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area).
- En tant qu'[utilisateur bot de projet](../user/project/settings/project_access_tokens.md#bot-users-for-projects).

Si la valeur retournée est `null`, le compte a été créé par un utilisateur qui s'est lui-même inscrit.

Vous pouvez inclure les [attributs personnalisés](custom_attributes.md) de l'utilisateur dans la réponse avec :

```plaintext
GET /users/:id?with_custom_attributes=true
```

## Récupérer l'utilisateur actuel {#retrieve-the-current-user}

Récupère l'utilisateur actuel.

### En tant qu'utilisateur régulier {#as-a-regular-user-1}

Récupère vos informations d'utilisateur.

```plaintext
GET /user
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "pronouns": "he/him",
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "admin@example.com",
  "preferred_language": "en",
}
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les paramètres `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit`.

### En tant qu'administrateur {#as-an-administrator-2}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le champ `created_by` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092) dans GitLab 15.6.
- Le champ `email_reset_offered_at` dans la réponse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610) dans GitLab 16.7.
- Le champ `email_reset_offered_at` dans la réponse a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197491) dans GitLab 18.3.

{{< /history >}}

Récupère vos informations d'utilisateur ou les informations d'un autre utilisateur.

```plaintext
GET /user
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `sudo`    | entier | non       | ID d'un utilisateur pour effectuer l'appel à sa place |

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": true,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "namespace_id": 1,
  "created_by": null,
  "note": null
}
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également ces paramètres :

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `is_auditor`
- `provisioned_by_group_id`
- `using_license_seat`

## Créer un utilisateur {#create-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La possibilité de créer un utilisateur auditeur a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) dans GitLab 15.3.

{{< /history >}}

Crée un utilisateur.

Prérequis :

- Vous devez être un administrateur.

> [!note]
> `private_profile` prend par défaut la valeur du paramètre [Définir les profils des nouveaux utilisateurs comme privés par défaut](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default). `bio` prend par défaut la valeur `""` au lieu de `null`.

```plaintext
POST /users
```

Attributs pris en charge :

| Attribut                            | Obligatoire | Description |
|:-------------------------------------|:---------|:------------|
| `username`                           | Oui      | Le nom d'utilisateur de l'utilisateur    |
| `name`                               | Oui      | Le nom de l'utilisateur        |
| `email`                              | Oui      | L'adresse e-mail de l'utilisateur       |
| `password`                           | Sous condition | Le mot de passe de l'utilisateur. Obligatoire si `force_random_password` ou `reset_password` ne sont pas définis. Si `force_random_password` ou `reset_password` sont définis, ces paramètres sont prioritaires. |
| `admin`                              | Non       | L'utilisateur est un administrateur. Les valeurs valides sont `true` ou `false`. La valeur par défaut est false. |
| `auditor`                            | Non       | L'utilisateur est un auditeur. Les valeurs valides sont `true` ou `false`. La valeur par défaut est false. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) dans GitLab 15.3. Premium et Ultimate uniquement. |
| `avatar`                             | Non       | Fichier image pour l'avatar de l'utilisateur |
| `bio`                                | Non       | Biographie de l'utilisateur |
| `can_create_group`                   | Non       | L'utilisateur peut créer des groupes principaux - true ou false |
| `color_scheme_id`                    | Non       | Le thème de couleurs de l'utilisateur pour le visualiseur de fichiers (pour plus d'informations, voir la [documentation des préférences utilisateur](../user/profile/preferences.md#change-the-syntax-highlighting-theme)) |
| `commit_email`                       | Non       | Adresse e-mail de commit de l'utilisateur |
| `extern_uid`                         | Non       | UID externe |
| `external`                           | Non       | Marque l'utilisateur comme externe - true ou false (par défaut) |
| `extra_shared_runners_minutes_limit` | Non       | Peut être défini uniquement par les administrateurs. Minutes de calcul supplémentaires pour cet utilisateur. Premium et Ultimate uniquement. |
| `force_random_password`              | Non       | Si `true`, définit le mot de passe de l'utilisateur sur une valeur aléatoire. Peut être utilisé avec `reset_password`. Est prioritaire sur `password`. |
| `group_id_for_saml`                  | Non       | ID du groupe dans lequel SAML a été configuré |
| `linkedin`                           | Non       | LinkedIn    |
| `location`                           | Non       | Emplacement de l'utilisateur |
| `note`                               | Non       | Notes de l'administrateur pour cet utilisateur |
| `organization`                       | Non       | Nom de l'organisation |
| `private_profile`                    | Non       | Le profil de l'utilisateur est privé - true ou false. La valeur par défaut est déterminée par [un paramètre](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default). |
| `projects_limit`                     | Non       | Nombre de projets que l'utilisateur peut créer |
| `pronouns`                           | Non       | Pronoms de l'utilisateur |
| `provider`                           | Non       | Nom du fournisseur externe |
| `public_email`                       | Non       | Adresse e-mail publique de l'utilisateur |
| `reset_password`                     | Non       | Si `true`, envoie à l'utilisateur un lien pour réinitialiser son mot de passe. Peut être utilisé avec `force_random_password`. Est prioritaire sur `password`. |
| `shared_runners_minutes_limit`       | Non       | Peut être défini uniquement par les administrateurs. Nombre maximum de minutes de calcul mensuelles pour cet utilisateur. Peut être `nil` (par défaut ; hériter la valeur par défaut du système), `0` (illimité) ou `> 0`. Premium et Ultimate uniquement. |
| `skip_confirmation`                  | Non       | Ignorer la confirmation - true ou false (par défaut) |
| `theme_id`                           | Non       | Thème GitLab pour l'utilisateur (pour plus d'informations, voir la [documentation des préférences utilisateur](../user/profile/preferences.md#change-the-navigation-theme)) |
| `twitter`                            | Non       | Compte X (anciennement Twitter) |
| `discord`                            | Non       | Compte Discord |
| `github`                             | Non       | Nom d'utilisateur GitHub |
| `view_diffs_file_by_file`            | Non       | Indicateur signalant que l'utilisateur ne voit qu'une seule différence de fichier par page |
| `website_url`                        | Non       | URL du site Web |

## Modifier un utilisateur {#modify-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La possibilité de modifier un utilisateur auditeur a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) dans GitLab 15.3.

{{< /history >}}

Modifier un utilisateur existant.

Prérequis :

- Vous devez être un administrateur.

Le champ `email` est l'adresse e-mail principale de l'utilisateur. Vous ne pouvez changer ce champ que pour une adresse e-mail secondaire déjà ajoutée pour cet utilisateur. Pour ajouter d'autres adresses e-mail au même utilisateur, utilisez le [point de terminaison d'ajout d'adresse e-mail](user_email_addresses.md#add-an-email-address).

```plaintext
PUT /users/:id
```

Attributs pris en charge :

| Attribut                            | Obligatoire | Description |
|:-------------------------------------|:---------|:------------|
| `admin`                              | Non       | L'utilisateur est un administrateur. Les valeurs valides sont `true` ou `false`. La valeur par défaut est false. |
| `auditor`                            | Non       | L'utilisateur est un auditeur. Les valeurs valides sont `true` ou `false`. La valeur par défaut est false. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) dans GitLab 15.3.(par défaut) Premium et Ultimate uniquement. |
| `avatar`                             | Non       | Fichier image pour l'avatar de l'utilisateur |
| `bio`                                | Non       | Biographie de l'utilisateur |
| `can_create_group`                   | Non       | L'utilisateur peut créer des groupes - true ou false |
| `color_scheme_id`                    | Non       | Le thème de couleurs de l'utilisateur pour le visualiseur de fichiers (pour plus d'informations, voir la [documentation des préférences utilisateur](../user/profile/preferences.md#change-the-syntax-highlighting-theme)) |
| `commit_email`                       | Non       | E-mail de commit de l'utilisateur. Définir sur `_private` pour utiliser l'adresse e-mail de commit privée. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375148) dans GitLab 15.5. |
| `email`                              | Non       | L'adresse e-mail de l'utilisateur |
| `extern_uid`                         | Non       | UID externe |
| `external`                           | Non       | Marque l'utilisateur comme externe - true ou false (par défaut) |
| `extra_shared_runners_minutes_limit` | Non       | Peut être défini uniquement par les administrateurs. Minutes de calcul supplémentaires pour cet utilisateur. Premium et Ultimate uniquement. |
| `group_id_for_saml`                  | Non       | ID du groupe dans lequel SAML a été configuré |
| `id`                                 | Oui      | ID de l'utilisateur |
| `linkedin`                           | Non       | LinkedIn    |
| `location`                           | Non       | Emplacement de l'utilisateur |
| `name`                               | Non       | Le nom de l'utilisateur |
| `note`                               | Non       | Notes d'administration pour cet utilisateur |
| `organization`                       | Non       | Nom de l'organisation |
| `password`                           | Non       | Le mot de passe de l'utilisateur |
| `private_profile`                    | Non       | Le profil de l'utilisateur est privé - true ou false. |
| `projects_limit`                     | Non       | Limiter le nombre de projets que chaque utilisateur peut créer |
| `pronouns`                           | Non       | Pronoms    |
| `provider`                           | Non       | Nom du fournisseur externe |
| `public_email`                       | Non       | Adresse e-mail publique de l'utilisateur (doit être déjà vérifiée) |
| `shared_runners_minutes_limit`       | Non       | Peut être défini uniquement par les administrateurs. Nombre maximum de minutes de calcul mensuelles pour cet utilisateur. Peut être `nil` (par défaut ; hériter la valeur par défaut du système), `0` (illimité) ou `> 0`. Premium et Ultimate uniquement. |
| `skip_reconfirmation`                | Non       | Ignorer la reconfirmation - true ou false (par défaut) |
| `theme_id`                           | Non       | Thème GitLab pour l'utilisateur (pour plus d'informations, voir la [documentation des préférences utilisateur](../user/profile/preferences.md#change-the-navigation-theme)) |
| `twitter`                            | Non       | Compte X (anciennement Twitter) |
| `discord`                            | Non       | Compte Discord |
| `github`                             | Non       | Nom d'utilisateur GitHub |
| `username`                           | Non       | Le nom d'utilisateur de l'utilisateur |
| `view_diffs_file_by_file`            | Non       | Indicateur signalant que l'utilisateur ne voit qu'une seule différence de fichier par page |
| `website_url`                        | Non       | URL du site Web |

Si vous mettez à jour le mot de passe d'un utilisateur, celui-ci est contraint de le modifier lors de sa prochaine connexion.

Retourne une erreur `404`, même dans les cas où une erreur `409` (Conflit) serait plus appropriée. Par exemple, lors du changement de nom de l'adresse e-mail vers une adresse déjà existante.

## Supprimer un utilisateur {#delete-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Supprime un utilisateur.

Prérequis :

- Vous devez être un administrateur.

Retourne :

- Le code de statut `204 No Content` si l'opération a réussi.
- `404` si la ressource est introuvable.
- `409` si l'utilisateur ne peut pas être supprimé de manière réversible.

```plaintext
DELETE /users/:id
```

Attributs pris en charge :

| Attribut     | Type    | Obligatoire | Description |
|:--------------|:--------|:---------|:------------|
| `id`          | entier | oui      | ID d'un utilisateur |
| `hard_delete` | boolean | non       | Si true, les contributions qui seraient normalement [transférées à l'utilisateur fantôme](../user/profile/account/delete_account.md#associated-records) sont supprimées à la place, ainsi que les groupes détenus uniquement par cet utilisateur. |

## Récupérer votre statut d'utilisateur {#retrieve-your-user-status}

Récupère votre statut d'utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/status
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/status"
```

Exemple de réponse :

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## Récupérer le statut d'un utilisateur {#retrieve-the-status-of-a-user}

Récupère le statut d'un utilisateur. Vous pouvez accéder à ce point de terminaison sans authentification.

```plaintext
GET /users/:id_or_username/status
```

Attributs pris en charge :

| Attribut        | Type   | Obligatoire | Description |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | string | oui      | ID ou nom d'utilisateur de l'utilisateur dont vous souhaitez obtenir le statut |

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/users/<username>/status"
```

Exemple de réponse :

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## Définir votre statut d'utilisateur {#set-your-user-status}

Définit votre statut d'utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
PUT /user/status
PATCH /user/status
```

Attributs pris en charge :

| Attribut            | Type   | Obligatoire | Description |
|:---------------------|:-------|:---------|:------------|
| `emoji`              | string | non       | Nom de l'emoji à utiliser comme statut. Si omis, `speech_balloon` est utilisé. Le nom de l'emoji peut être l'un des noms spécifiés dans l'[index Gemojione](https://github.com/bonusly/gemojione/blob/master/config/index.json). |
| `message`            | string | non       | Message à définir comme statut. Il peut également contenir des codes emoji. Ne peut pas dépasser 100 caractères. |
| `availability`       | string | non       | La disponibilité de l'utilisateur. Valeurs possibles : `busy` et `not_set`. |
| `clear_status_after` | string | non       | Nettoie automatiquement le statut après un intervalle de temps donné, valeurs autorisées : `30_minutes`, `3_hours`, `8_hours`, `1_day`, `3_days`, `7_days`, `30_days` |

Différence entre `PUT` et `PATCH` :

- Lors de l'utilisation de `PUT`, les paramètres qui ne sont pas transmis sont définis sur `null` et donc effacés.
- Lors de l'utilisation de `PATCH`, les paramètres qui ne sont pas transmis sont ignorés. Transmettez explicitement `null` pour effacer un champ.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/status" \
  --data "clear_status_after=1_day" \
  --data "emoji=coffee" \
  --data "message=I crave coffee" \
  --data "availability=busy"
```

Exemple de réponse :

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee",
  "message_html": "I crave coffee",
  "clear_status_at":"2021-02-15T10:49:01.311Z"
}
```

## Récupérer vos préférences utilisateur {#retrieve-your-user-preferences}

Récupère vos préférences utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/preferences
```

Exemple de réponse :

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

## Mettre à jour vos préférences utilisateur {#update-your-user-preferences}

Met à jour vos préférences utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
PUT /user/preferences
```

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

Attributs pris en charge :

| Attribut                        | Obligatoire | Description |
|:---------------------------------|:---------|:------------|
| `view_diffs_file_by_file`        | Oui      | Indicateur signalant que l'utilisateur ne voit qu'une seule différence de fichier par page. |
| `show_whitespace_in_diffs`       | Oui      | Indicateur signalant que l'utilisateur voit les modifications d'espaces dans les différences. |
| `pass_user_identities_to_ci_jwt` | Oui      | Indicateur signalant que l'utilisateur transmet ses identités externes comme informations CI. Cet attribut ne contient pas suffisamment d'informations pour identifier ou autoriser l'utilisateur dans un système externe. L'attribut est interne à GitLab et ne doit pas être transmis à des services tiers. Pour plus d'informations et d'exemples, voir [Token Payload](../ci/secrets/id_token_authentication.md#token-payload). |

## Téléverser un avatar pour vous-même {#upload-an-avatar-for-yourself}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148130) dans GitLab 17.0.

{{< /history >}}

Téléverse un avatar pour vous-même.

Prérequis :

- Vous devez être authentifié.
- Votre fichier doit faire 200 Ko ou moins. La taille d'image idéale est de 192 x 192 pixels.
- L'image doit être de l'un des types de fichiers suivants :
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

```plaintext
PUT /user/avatar
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description |
|:----------|:-------|:---------|:------------|
| `avatar`  | string | Oui      | Le fichier à téléverser. |

Pour téléverser un avatar depuis votre système de fichiers, utilisez l'argument `--form`. Cela amène cURL à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `avatar=` doit pointer vers un fichier image sur votre système de fichiers et être précédé de `@`.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/avatar" \
  --form "avatar=@/path/to/your/avatar.png"
```

Exemple de réponse :

```json
{
  "avatar_url": "http://gitlab.example.com/uploads/-/system/user/avatar/76/avatar.png",
}
```

Retourne :

- `200` en cas de succès.
- `400 Bad Request` pour les fichiers de taille supérieure à 200 Kio.

## Récupérer le nombre de vos tickets, merge requests et révisions assignés {#retrieve-a-count-of-your-assigned-issues-merge-requests-and-reviews}

Récupère le nombre de vos tickets, merge requests et révisions assignés.

Prérequis :

- Vous devez être authentifié.

Attributs pris en charge :

| Attribut                         | Type   | Description |
|:----------------------------------|:-------|:------------|
| `assigned_issues`                 | number | Nombre de tickets ouverts et assignés à l'utilisateur actuel. |
| `assigned_merge_requests`         | number | Nombre de merge requests actives et assignées à l'utilisateur actuel. |
| `merge_requests`                  | number | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50026) dans GitLab 13.8. Équivalent à et remplacé par `assigned_merge_requests`. |
| `review_requested_merge_requests` | number | Nombre de merge requests pour lesquelles l'utilisateur actuel a été invité à effectuer une révision. |
| `todos`                           | number | Nombre d'éléments de la liste de tâches en attente pour l'utilisateur actuel. |

```plaintext
GET /user_counts
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user_counts"
```

Exemple de réponse :

```json
{
  "merge_requests": 4,
  "assigned_issues": 15,
  "assigned_merge_requests": 11,
  "review_requested_merge_requests": 0,
  "todos": 1
}
```

## Récupérer le nombre de projets, groupes, tickets et merge requests d'un utilisateur {#retrieve-a-count-of-a-users-projects-groups-issues-and-merge-requests}

Récupère la liste du nombre d'éléments d'un utilisateur :

- Projets.
- Groupes.
- Tickets
- Merge requests

Les administrateurs peuvent interroger n'importe quel utilisateur, mais les non-administrateurs ne peuvent interroger qu'eux-mêmes.

```plaintext
GET /users/:id/associations_count
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID d'un utilisateur |

Exemple de réponse :

```json
{
  "groups_count": 2,
  "projects_count": 3,
  "issues_count": 8,
  "merge_requests_count": 5
}
```

## Lister l'activité d'un utilisateur {#list-a-users-activity}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez être un administrateur pour consulter l'activité des utilisateurs avec des profils privés.

Obtenez la date de dernière activité des utilisateurs avec des profils publics, triée du plus ancien au plus récent.

Les activités qui mettent à jour les horodatages des événements utilisateur (`last_activity_on` et `current_sign_in_at`) sont :

- Activités Git HTTP/SSH (telles que clone, push)
- Connexion de l'utilisateur à GitLab
- Visite de pages liées aux tableaux de bord, projets, tickets et merge requests par l'utilisateur
- Utilisation de l'API par l'utilisateur
- Utilisation de l'API GraphQL par l'utilisateur

Par défaut, affiche l'activité des utilisateurs avec des profils publics au cours des 6 derniers mois, mais cela peut être modifié en utilisant le paramètre `from`.

```plaintext
GET /user/activities
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description |
|:----------|:-------|:---------|:------------|
| `from`    | string | non       | Chaîne de date au format `YEAR-MM-DD`. Par exemple, `2016-03-11`. La valeur par défaut est il y a 6 mois. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/activities"
```

Exemple de réponse :

```json
[
  {
    "username": "user1",
    "last_activity_on": "2015-12-14",
    "last_activity_at": "2015-12-14"
  },
  {
    "username": "user2",
    "last_activity_on": "2015-12-15",
    "last_activity_at": "2015-12-15"
  },
  {
    "username": "user3",
    "last_activity_on": "2015-12-16",
    "last_activity_at": "2015-12-16"
  }
]
```

`last_activity_at` est obsolète. Utilisez plutôt `last_activity_on`.

## Lister les projets et groupes dont un utilisateur est membre {#list-projects-and-groups-that-a-user-is-a-member-of}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez être un administrateur.

Liste tous les projets et groupes dont un utilisateur est membre.

Retourne les champs `source_id`, `source_name`, `source_type` et `access_level` d'une adhésion. La source peut être de type `Namespace` (représentant un groupe) ou `Project`. La réponse représente uniquement les adhésions directes. Les adhésions héritées, par exemple dans les sous-groupes, ne sont pas incluses. Les niveaux d'accès sont représentés par une valeur entière :

- `0` :  Aucun accès
- `5` :  Accès minimum
- `10` :  Invité
- `15` :  Planificateur
- `20` :  Reporter
- `30` :  Développeur
- `40` :  Mainteneur
- `50` :  Propriétaire

```plaintext
GET /users/:id/memberships
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID d'un utilisateur spécifié |
| `type`    | string  | non       | Filtre les adhésions par type. Peut être `Project` ou `Namespace` |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/:user_id/memberships"
```

Exemple de réponse :

```json
[
  {
    "source_id": 1,
    "source_name": "Project one",
    "source_type": "Project",
    "access_level": "20"
  },
  {
    "source_id": 3,
    "source_name": "Group three",
    "source_type": "Namespace",
    "access_level": "20"
  }
]
```

Retourne :

- `200 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` si la demande n'est pas effectuée par un administrateur.
- `400 Bad Request` si le type demandé n'est pas pris en charge.

## Désactiver l'authentification à deux facteurs pour un utilisateur {#disable-two-factor-authentication-for-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/295260) dans GitLab 15.2.

{{< /history >}}

Prérequis :

- Vous devez être un administrateur.

Désactive l'authentification à deux facteurs (2FA) pour l'utilisateur spécifié.

Les administrateurs ne peuvent pas désactiver la 2FA pour leur propre compte utilisateur ni pour d'autres administrateurs via l'API. À la place, ils peuvent désactiver la 2FA d'un administrateur [en utilisant la console Rails](../security/two_factor_authentication.md#for-a-single-user).

```plaintext
PATCH /users/:id/disable_two_factor
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID de l'utilisateur |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/disable_two_factor"
```

Retourne :

- `204 No content` en cas de succès.
- `400 Bad request` si l'authentification à deux facteurs n'est pas activée pour l'utilisateur spécifié.
- `403 Forbidden` si non authentifié en tant qu'administrateur.
- `404 User Not Found` si l'utilisateur est introuvable.

## Créer un runner lié à un utilisateur {#create-a-runner-linked-to-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Crée un runner lié à l'utilisateur actuel. L'utilisateur est répertorié comme propriétaire à des fins d'audit, mais la disponibilité du runner est basée sur `runner_type`. Pour plus d'informations, voir [Gérer les runners](../ci/runners/runners_scope.md).

Prérequis :

- Vous devez être un administrateur ou avoir le rôle Propriétaire pour l'espace de nommage ou le projet cible.
- Pour `instance_type`, vous devez être un administrateur de l'instance GitLab.
- Pour `group_type` ou `project_type` avec un rôle Propriétaire, l'[enregistrement du runner](../administration/settings/continuous_integration.md#control-runner-registration) doit être autorisé.
- Un jeton d'accès avec la portée `create_runner`.

Assurez-vous de copier ou d'enregistrer le `token` dans la réponse, car la valeur ne peut pas être récupérée ultérieurement.

```plaintext
POST /user/runners
```

Attributs pris en charge :

| Attribut          | Type         | Obligatoire | Description |
|:-------------------|:-------------|:---------|:------------|
| `runner_type`      | string       | oui      | Spécifie la portée du runner ; `instance_type`, `group_type` ou `project_type`. |
| `group_id`         | entier      | non       | L'ID du groupe dans lequel le runner est créé. Obligatoire si `runner_type` est `group_type`. |
| `project_id`       | entier      | non       | L'ID du projet dans lequel le runner est créé. Obligatoire si `runner_type` est `project_type`. |
| `description`      | string       | non       | Description du runner. |
| `paused`           | boolean      | non       | Indique si le runner doit ignorer les nouveaux jobs. |
| `locked`           | boolean      | non       | Indique si le runner doit être verrouillé pour le projet actuel. |
| `run_untagged`     | boolean      | non       | Indique si le runner doit gérer les jobs sans étiquette. |
| `tag_list`         | string | non       | Liste de tags du runner séparés par des virgules. |
| `access_level`     | string       | non       | Le niveau d'accès du runner ; `not_protected` ou `ref_protected`. |
| `maximum_timeout`  | entier      | non       | Délai d'expiration maximal qui limite la durée (en secondes) pendant laquelle les runners peuvent exécuter des jobs. |
| `maintenance_note` | string       | non       | Notes de maintenance en texte libre pour le runner (1024 caractères). |
| `token_expires_at` | datetime     | non       | L'heure d'expiration du token d'authentification du runner au format ISO 8601. Doit être compris entre 5 minutes et 15 jours dans le futur. Ne peut pas dépasser les limites au niveau de l'instance, du groupe ou du projet si elles sont configurées. S'applique uniquement au token initial. Les tokens pivotés utilisent l'expiration calculée à partir des paramètres. **(PREMIUM ALL)** |
| `token_rotation_deadline` | datetime | non | La date limite après laquelle les demandes de rotation de token sont rejetées. Nécessite `token_expires_at`. Doit être inférieur ou égal à `token_expires_at`. Définir les deux sur la même valeur désactive la rotation du token. Effacé lors d'une rotation réussie. **(PREMIUM ALL)** |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/runners" \
  --data "runner_type=instance_type"
```

Exemple de réponse :

```json
{
    "id": 9171,
    "token": "<access-token>",
    "token_expires_at": null
}
```

## Supprimer une identité d'authentification d'un utilisateur {#delete-authentication-identity-from-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Supprime l'identité d'authentification d'un utilisateur en utilisant le nom du fournisseur associé à cette identité.

Prérequis :

- Vous devez être un administrateur.

```plaintext
DELETE /users/:id/identities/:provider
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description |
|:-----------|:--------|:---------|:------------|
| `id`       | entier | oui      | ID d'un utilisateur |
| `provider` | string  | oui      | Nom du fournisseur externe |

## Créer un code PIN d'assistance {#create-a-support-pin}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040) dans GitLab 17.8.

{{< /history >}}

Crée un code PIN d'assistance pour votre compte utilisateur. Le code PIN expire sept jours après sa création. L'assistance GitLab peut vous demander ce code PIN pour valider votre identité.

Prérequis :

- Vous devez être authentifié.

```plaintext
POST /user/support_pin
```

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/support_pin"
```

Exemple de réponse :

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

## Obtenir les détails d'un code PIN d'assistance {#get-details-on-a-support-pin}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040) dans GitLab 17.8.

{{< /history >}}

Obtient les détails du code PIN d'assistance pour votre compte. L'assistance GitLab peut vous demander ce code PIN pour valider votre identité.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/support_pin
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/support_pin"
```

Exemple de réponse :

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

## Obtenir un code PIN d'assistance pour un utilisateur {#get-a-support-pin-for-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040) dans GitLab 17.8.

{{< /history >}}

Obtient les détails d'un code PIN d'assistance pour l'utilisateur spécifié. L'assistance GitLab peut vous demander ce code PIN pour valider votre identité.

Prérequis :

- Vous devez être un administrateur.

```plaintext
GET /users/:id/support_pin
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1234/support_pin"
```

Exemple de réponse :

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |

## Révoquer un code PIN d'assistance pour un utilisateur {#revoke-a-support-pin-for-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187657) dans GitLab 17.11.

{{< /history >}}

Révoque un code PIN d'assistance pour l'utilisateur spécifié avant son expiration naturelle. Cela expire et supprime immédiatement le code PIN.

Prérequis :

- Vous devez être un administrateur.

```plaintext
POST /users/:id/support_pin/revoke
```

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1234/support_pin/revoke"
```

Exemple de réponse :

En cas de succès, retourne `202 Accepted`.

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID d'un utilisateur |
