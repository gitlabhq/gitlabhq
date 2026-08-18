---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API SCIM
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98354) dans GitLab 15.5.

{{< /history >}}

Utilisez cette API pour gérer les identités SCIM dans les groupes.

Prérequis :

- Vous devez activer [Group SSO](../user/group/saml_sso/_index.md).
- Vous devez activer [SCIM for Group SSO](../user/group/saml_sso/scim_setup.md).
- Vous devez vous authentifier avec un [Personal Access Token](../user/profile/personal_access_tokens.md) ou un [Group Access Token](../user/group/settings/group_access_tokens.md) disposant de la portée appropriée.

Cette API diffère de l'[API SCIM de groupe interne](../development/internal_api/_index.md#group-scim-api) et de l'[API SCIM d'instance interne](../development/internal_api/_index.md#instance-scim-api), qui nécessitent toutes deux un jeton SCIM.

- Cette API :
  - N'implémente pas le [protocole RFC7644](https://www.rfc-editor.org/rfc/rfc7644).
  - Récupère, vérifie, met à jour et supprime les identités SCIM au sein des groupes.
- Les API SCIM de groupe et d'instance internes :
  - Sont destinées à l'utilisation système pour l'intégration des fournisseurs SCIM.
  - Implémentent le [protocole RFC7644](https://www.rfc-editor.org/rfc/rfc7644).
  - Récupèrent une liste d'utilisateurs provisionnés par SCIM pour le groupe ou l'instance.
  - Créent, suppriment et mettent à jour les utilisateurs provisionnés par SCIM pour le groupe ou l'instance.

## Récupérer les identités SCIM pour un groupe {#retrieve-scim-identities-for-a-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) dans GitLab 15.5.

{{< /history >}}

Récupère les identités SCIM pour un groupe.

```plaintext
GET /groups/:id/scim/identities
```

Attributs pris en charge :

| Attribut         | Type    | Obligatoire | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type    | Description               |
| ------------ | ------- | ------------------------- |
| `extern_uid` | string  | UID externe de l'utilisateur |
| `user_id`    | entier | Identifiant de l'utilisateur           |
| `active`     | boolean | Statut de l'identité    |

Exemple de réponse :

```json
[
    {
        "extern_uid": "be20d8dcc028677c931e04f387",
        "user_id": 48,
        "active": true
    }
]
```

Exemple de requête :

```shell
curl --location --request GET \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/identities" \
  --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>"
```

## Récupérer une identité SCIM unique {#retrieve-a-single-scim-identity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591) dans GitLab 16.1.

{{< /history >}}

Récupère une identité SCIM unique.

```plaintext
GET /groups/:id/scim/:uid
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | entier | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `uid`     | string  | oui      | UID externe de l'utilisateur. |

Exemple de requête :

```shell
curl --location --request GET \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>"
```

Exemple de réponse :

```json
{
    "extern_uid": "be20d8dcc028677c931e04f387",
    "user_id": 48,
    "active": true
}
```

## Mettre à jour le champ `extern_uid` pour une identité SCIM {#update-extern_uid-field-for-a-scim-identity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) dans GitLab 15.5.

{{< /history >}}

Met à jour le champ `extern_uid` pour une identité SCIM.

Les champs pouvant être mis à jour sont :

| Champ SCIM/IdP  | Champ GitLab |
| --------------- | ------------ |
| `id/externalId` | `extern_uid` |

```plaintext
PATCH /groups/:groups_id/scim/:uid
```

Paramètres :

| Attribut | Type   | Obligatoire | Description               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `uid`     | string | oui      | UID externe de l'utilisateur. |

Exemple de requête :

```shell
curl --location --request PATCH \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --form "extern_uid=yrnZW46BrtBFqM7xDzE7dddd"
```

## Supprimer une identité SCIM unique {#delete-a-single-scim-identity}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/423592) dans GitLab 16.5.

{{< /history >}}

Supprime une identité SCIM unique.

```plaintext
DELETE /groups/:id/scim/:uid
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | entier | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `uid`     | string  | oui      | UID externe de l'utilisateur. |

Exemple de requête :

```shell
curl --location --request DELETE \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/yrnZW46BrtBFqM7xDzE7dddd" \
  --header "PRIVATE-TOKEN: <your_access_token>"
```

Exemple de réponse :

```json
{
    "message" : "204 No Content"
}
```
