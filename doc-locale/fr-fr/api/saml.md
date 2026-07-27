---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API SAML
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) dans GitLab 15.5.

{{< /history >}}

Utilisez cette API pour interagir avec les fonctionnalités SAML.

## Points de terminaison GitLab.com {#gitlabcom-endpoints}

### Lister toutes les identités SAML d'un groupe {#list-all-saml-identities-for-a-group}

```plaintext
GET /groups/:id/saml/identities
```

Liste toutes les identités SAML d'un groupe.

Attributs pris en charge :

| Attribut         | Type    | Obligatoire | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type   | Description               |
| ------------ | ------ | ------------------------- |
| `extern_uid` | string | UID externe de l'utilisateur |
| `user_id`    | string | Identifiant de l'utilisateur           |

Exemple de requête :

```shell
curl --location --request GET \
  --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/identities"
```

Exemple de réponse :

```json
[
    {
        "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
        "user_id": 48
    }
]
```

### Récupérer une identité SAML unique {#retrieve-a-single-saml-identity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591) dans GitLab 16.1.

{{< /history >}}

Récupère une identité SAML unique.

```plaintext
GET /groups/:id/saml/:uid
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `uid`     | string         | oui      | UID externe de l'utilisateur. |

Exemple de requête :

```shell
curl --location --request GET \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd"
```

Exemple de réponse :

```json
{
    "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
    "user_id": 48
}
```

### Mettre à jour le champ `extern_uid` pour une identité SAML {#update-extern_uid-field-for-a-saml-identity}

Met à jour le champ `extern_uid` pour une identité SAML :

| Attribut du fournisseur d'identité SAML | Champ GitLab |
| ------------------ | ------------ |
| `id/externalId`    | `extern_uid` |

```plaintext
PATCH /groups/:id/saml/:uid
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `uid`     | string | oui      | UID externe de l'utilisateur. |

Exemple de requête :

```shell
curl --request PATCH \
  --location \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
  --form "extern_uid=be20d8dcc028677c931e04f387"
```

### Supprimer une identité SAML unique {#delete-a-single-saml-identity}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/423592) dans GitLab 16.5.

{{< /history >}}

```plaintext
DELETE /groups/:id/saml/:uid
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | entier | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `uid`     | string  | oui      | UID externe de l'utilisateur. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/be20d8dcc028677c931e04f387"
```

Exemple de réponse :

```json
{
    "message" : "204 No Content"
}
```

## Points de terminaison GitLab Self-Managed {#gitlab-self-managed-endpoints}

### Récupérer une identité SAML unique {#retrieve-a-single-saml-identity-1}

Utilise l'API Users pour [obtenir une identité SAML unique](users.md#as-an-administrator).

### Mettre à jour le champ `extern_uid` pour une identité SAML {#update-extern_uid-field-for-a-saml-identity-1}

Utilise l'API Users pour [mettre à jour le champ `extern_uid` d'un utilisateur](users.md#modify-a-user).

### Supprimer une identité SAML unique {#delete-a-single-saml-identity-1}

Utilise l'API Users pour [supprimer une identité unique d'un utilisateur](users.md#delete-authentication-identity-from-a-user).

## Liens de groupe SAML {#saml-group-links}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/290367) dans GitLab 15.3.0.
- Le type `access_level` a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607) de `string` à `integer` dans GitLab 15.3.3.
- Le type `member_role_id` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) dans GitLab 16.7 [avec un indicateur](../administration/feature_flags/_index.md) nommé `custom_roles_for_saml_group_links`. Désactivé par défaut.
- Le type `member_role_id` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) dans GitLab 16.8. L'indicateur de fonctionnalité `custom_roles_for_saml_group_links` a été supprimé.
- Le paramètre `provider` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/548725) dans GitLab 18.2.

{{< /history >}}

Listez, récupérez, ajoutez et supprimez des [liens de groupe SAML](../user/group/saml_sso/group_sync.md#configure-saml-group-links) en utilisant l'API REST.

### Lister tous les liens de groupe SAML {#list-all-saml-group-links}

Liste tous les liens de groupe SAML pour un groupe.

```plaintext
GET /groups/:id/saml_group_links
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|:----------|:---------------|:---------|:------------|
| `id`      | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|:--------------------|:--------|:------------|
| `[].name`           | string  | Nom du groupe SAML. |
| `[].access_level`   | entier | Le niveau d'accès par défaut pour les membres du groupe SAML. Valeurs possibles : `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Rapporteur), `25` (Responsable sécurité), `30` (Développeur), `40` (Mainteneur), ou `50` (Propriétaire). |
| `[].member_role_id` | entier | [ID de rôle membre (`member_role_id`)](member_roles.md) pour les membres du groupe SAML. |
| `[].provider`       | string  | [Nom du fournisseur](../integration/saml.md#configure-saml-support-in-gitlab) unique qui doit correspondre pour que ce lien de groupe soit appliqué. |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

Exemple de réponse :

```json
[
  {
    "name": "saml-group-1",
    "access_level": 10,
    "member_role_id": 12,
    "provider": null
  },
  {
    "name": "saml-group-2",
    "access_level": 40,
    "member_role_id": 99,
    "provider": "saml_provider_1"
  }
]
```

### Récupérer un lien de groupe SAML {#retrieve-a-saml-group-link}

Récupère un lien de groupe SAML pour un groupe.

```plaintext
GET /groups/:id/saml_group_links/:saml_group_name
```

Attributs pris en charge :

| Attribut         | Type           | Obligatoire | Description |
|:------------------|:---------------|:---------|:------------|
| `id`              | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `saml_group_name` | string         | oui      | Nom du groupe SAML. |
| `provider`        | string         | non       | [Nom du fournisseur](../integration/saml.md#configure-saml-support-in-gitlab) unique pour lever l'ambiguïté lorsque plusieurs liens existent avec le même nom. Requis lorsque plusieurs liens existent avec le même `saml_group_name`. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut        | Type    | Description |
|:-----------------|:--------|:------------|
| `name`           | string  | Nom du groupe SAML. |
| `access_level`   | entier | Le niveau d'accès par défaut pour les membres du groupe SAML. Valeurs possibles : `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Rapporteur), `25` (Responsable sécurité), `30` (Développeur), `40` (Mainteneur), ou `50` (Propriétaire). |
| `member_role_id` | entier | [ID de rôle membre (`member_role_id`)](member_roles.md) pour les membres du groupe SAML. |
| `provider`       | string  | [Nom du fournisseur](../integration/saml.md#configure-saml-support-in-gitlab) unique qui doit correspondre pour que ce lien de groupe soit appliqué. |

Si plusieurs liens de groupe SAML existent avec le même nom mais des fournisseurs différents, et qu'aucun paramètre `provider` n'est spécifié, renvoie [`422`](rest/troubleshooting.md#status-codes) avec un message d'erreur indiquant que le paramètre `provider` est requis pour lever l'ambiguïté.

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

Exemple de requête avec le paramètre provider :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

Exemple de réponse :

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### Ajouter un lien de groupe SAML {#add-a-saml-group-link}

Ajoute un lien de groupe SAML pour un groupe.

```plaintext
POST /groups/:id/saml_group_links
```

Attributs pris en charge :

| Attribut         | Type              | Obligatoire | Description |
|:------------------|:------------------|:---------|:------------|
| `id`              | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `saml_group_name` | string            | oui      | Nom du groupe SAML. |
| `access_level`    | entier           | oui      | Le niveau d'accès par défaut pour les membres du groupe SAML. Valeurs possibles : `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Rapporteur), `25` (Responsable sécurité), `30` (Développeur), `40` (Mainteneur), ou `50` (Propriétaire). |
| `member_role_id`  | entier           | non       | [ID de rôle membre (`member_role_id`)](member_roles.md) pour les membres du groupe SAML. |
| `provider`        | string            | non       | [Nom du fournisseur](../integration/saml.md#configure-saml-support-in-gitlab) unique qui doit correspondre pour que ce lien de groupe soit appliqué. |

En cas de succès, renvoie [`201`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut        | Type    | Description |
|:-----------------|:--------|:------------|
| `name`           | string  | Nom du groupe SAML. |
| `access_level`   | entier | Le niveau d'accès par défaut pour les membres du groupe SAML. Valeurs possibles : `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Rapporteur), `25` (Responsable sécurité), `30` (Développeur), `40` (Mainteneur), ou `50` (Propriétaire). |
| `member_role_id` | entier | [ID de rôle membre (`member_role_id`)](member_roles.md) pour les membres du groupe SAML. |
| `provider`       | string  | [Nom du fournisseur](../integration/saml.md#configure-saml-support-in-gitlab) unique qui doit correspondre pour que ce lien de groupe soit appliqué. |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{ "saml_group_name": "<your_saml_group_name`>", "access_level": <chosen_access_level>, "member_role_id": <chosen_member_role_id>, "provider": "<your_provider>" }' --url  "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

Exemple de réponse :

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### Supprimer un lien de groupe SAML {#delete-a-saml-group-link}

Supprime un lien de groupe SAML pour un groupe.

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

Attributs pris en charge :

| Attribut         | Type           | Obligatoire | Description |
|:------------------|:---------------|:---------|:------------|
| `id`              | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `saml_group_name` | string         | oui      | Nom du groupe SAML. |
| `provider`        | string         | non       | [Nom du fournisseur](../integration/saml.md#configure-saml-support-in-gitlab) unique pour lever l'ambiguïté lorsque plusieurs liens existent avec le même nom. Requis lorsque plusieurs liens existent avec le même `saml_group_name`. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

Exemple de requête avec le paramètre provider :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

En cas de succès, renvoie le code de statut [`204`](rest/troubleshooting.md#status-codes) sans corps de réponse.

Si plusieurs liens de groupe SAML existent avec le même nom mais des fournisseurs différents, et qu'aucun paramètre `provider` n'est spécifié, renvoie [`422`](rest/troubleshooting.md#status-codes) avec un message d'erreur indiquant que le paramètre `provider` est requis pour lever l'ambiguïté.
