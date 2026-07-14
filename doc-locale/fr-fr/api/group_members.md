---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des membres de groupes
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez ce point de terminaison pour interagir avec les membres du groupe.

Pour des informations sur les membres du projet, consultez l'[API des membres du projet](project_members.md).

## Problèmes connus {#known-issues}

- Les attributs `group_saml_identity` et `group_scim_identity` sont uniquement visibles par les propriétaires du groupe pour les [groupes avec SSO activé](../user/group/saml_sso/_index.md).
- L'attribut `email` est uniquement visible par les propriétaires du groupe pour les [utilisateurs enterprise](../user/enterprise_user/_index.md) du groupe lorsqu'une requête API est envoyée au groupe lui-même, ou aux sous-groupes ou projets de ce groupe.

## Lister tous les membres du groupe {#list-all-group-members}

Répertorie tous les membres directs d'un groupe spécifié. Retourne uniquement les membres directs et non les membres hérités via les groupes ancêtres ou les membres d'un groupe invité.

Cette fonction accepte les paramètres de pagination `page` et `per_page` pour limiter la liste des utilisateurs.

```plaintext
GET /groups/:id/members
```

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `query`          | string            | non       | Filtre les résultats en fonction d'un nom, d'un e-mail ou d'un nom d'utilisateur donné. Utilisez des valeurs partielles pour élargir la portée de la requête. |
| `user_ids`       | tableau d'entiers | non       | Filtre les résultats sur les identifiants d'utilisateurs donnés. |
| `skip_users`     | tableau d'entiers | non       | Exclut les utilisateurs ignorés des résultats. |
| `show_seat_info` | boolean           | non       | Affiche les informations de siège pour les utilisateurs. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null,
    "is_using_seat": true
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  }
]
```

## Lister tous les membres du groupe, y compris les membres hérités et invités {#list-all-group-members-including-inherited-and-invited-members}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) pour retourner les membres du groupe privé invité si l'utilisateur actuel est membre du groupe ou projet partagé dans GitLab 16.10 [avec un flag](../administration/feature_flags/_index.md) nommé `webui_members_inherited_users`. Désactivé par défaut.
- Le feature flag `webui_members_inherited_users` a été [activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) dans GitLab 17.0.
- Le feature flag `webui_members_inherited_users` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) dans GitLab 17.4. Les membres des groupes invités sont affichés par défaut.

{{< /history >}}

Répertorie tous les membres d'un groupe spécifié, y compris les membres hérités, les utilisateurs invités et les autorisations via les groupes ancêtres.

Si un utilisateur est membre de ce groupe et également d'un ou plusieurs groupes ancêtres, seule son appartenance avec le niveau `access_level` le plus élevé est retournée. Cela représente l'autorisation effective de l'utilisateur.

Les membres d'un groupe invité sont retournés si l'une des conditions suivantes est remplie :

- Le groupe invité est public.
- Le demandeur est également membre du groupe invité.
- Le demandeur est membre du groupe partagé.

> [!note]
> Les membres du groupe invité ont une appartenance partagée dans le groupe partagé. Cela signifie que si le demandeur est membre d'un groupe partagé, mais pas membre d'un groupe privé invité, alors en utilisant ce point de terminaison, le demandeur peut obtenir tous les membres du groupe partagé, y compris les membres du groupe privé invité.

Cette fonction accepte les paramètres de pagination `page` et `per_page` pour limiter la liste des utilisateurs.

```plaintext
GET /groups/:id/members/all
```

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `query`          | string            | non       | Filtre les résultats en fonction d'un nom, d'un e-mail ou d'un nom d'utilisateur donné. Utilisez des valeurs partielles pour élargir la portée de la requête. |
| `user_ids`       | tableau d'entiers | non       | Filtre les résultats sur les identifiants d'utilisateurs donnés. |
| `show_seat_info` | boolean           | non       | Affiche les informations de siège pour les utilisateurs. |
| `state`          | string            | non       | Filtre les résultats par état du membre, soit `awaiting` ou `active`. Premium et Ultimate uniquement. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-10-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-11-22",
    "access_level": 30,
    "group_saml_identity": null
  }
]
```

## Récupérer un membre du groupe {#retrieve-a-group-member}

Récupère un membre spécifié d'un groupe. Retourne uniquement les membres directs et non les membres hérités via les groupes ancêtres.

```plaintext
GET /groups/:id/members/:user_id
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
```

Pour mettre à jour ou supprimer un rôle personnalisé d'un membre du groupe, transmettez une valeur vide pour `member_role_id` :

```shell
# Updates a group membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "email": "john@example.com",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": null,
  "group_saml_identity": null
}
```

## Récupérer un membre du groupe, y compris les membres hérités et invités {#retrieve-a-group-member-including-inherited-and-invited-members}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744) dans GitLab 12.4.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) pour retourner les membres du groupe privé invité si l'utilisateur actuel est membre du groupe ou projet partagé dans GitLab 16.10 [avec un flag](../administration/feature_flags/_index.md) nommé `webui_members_inherited_users`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) dans GitLab 17.0.
- Le feature flag `webui_members_inherited_users` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) dans GitLab 17.4. Les membres des groupes invités sont affichés par défaut.

{{< /history >}}

Récupère un membre spécifié d'un groupe, y compris les membres hérités ou invités via les groupes ancêtres. Pour plus d'informations, consultez [Lister tous les membres hérités](#list-all-group-members-including-inherited-and-invited-members).

> [!note]
> Les membres du groupe invité ont une appartenance partagée dans le groupe partagé. Cela signifie que si le demandeur est membre d'un groupe partagé, mais pas membre d'un groupe privé invité, alors en utilisant ce point de terminaison, le demandeur peut obtenir tous les membres du groupe partagé, y compris les membres du groupe privé invité.

```plaintext
GET /groups/:id/members/all/:user_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `user_id` | entier | oui   | L'identifiant utilisateur du membre. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all/:user_id"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "email": "john@example.com",
  "expires_at": null,
  "group_saml_identity": null
}
```

## Lister tous les membres facturables du groupe {#list-all-billable-group-members}

Répertorie tous les membres facturables d'un groupe spécifié. La liste inclut les membres des sous-groupes et des projets.

Prérequis :

- Vous devez disposer du rôle Propriétaire pour accéder au point de terminaison API pour les autorisations de facturation, comme indiqué dans [les autorisations de facturation](../user/free_user_limit.md).
- Ce point de terminaison API fonctionne uniquement sur les groupes principaux. Il ne fonctionne pas sur les sous-groupes.

Cette fonction accepte les paramètres de [pagination](rest/_index.md#pagination) `page` et `per_page` pour limiter la liste des utilisateurs.

Utilisez le paramètre `search` pour rechercher des membres facturables du groupe par nom, et `sort` pour trier les résultats.

```plaintext
GET /groups/:id/billable_members
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `search`  | string            | non       | Une chaîne de requête pour rechercher des membres du groupe par nom, nom d'utilisateur ou e-mail public. |
| `sort`    | string            | non       | Une chaîne de requête contenant des paramètres qui spécifient l'attribut de tri et l'ordre. Voir les valeurs prises en charge ci-dessous. |

Les valeurs prises en charge pour l'attribut `sort` sont :

| Valeur                   | Description                  |
| ----------------------- | ---------------------------- |
| `access_level_asc`      | Niveau d'accès, croissant      |
| `access_level_desc`     | Niveau d'accès, décroissant     |
| `last_joined`           | Dernière adhésion                  |
| `name_asc`              | Nom, croissant              |
| `name_desc`             | Nom, décroissant             |
| `oldest_joined`         | Adhésion la plus ancienne                |
| `oldest_sign_in`        | Connexion la plus ancienne               |
| `recent_sign_in`        | Connexion récente               |
| `last_activity_on_asc`  | Date de dernière activité, croissant  |
| `last_activity_on_desc` | Date de dernière activité, décroissant |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "last_activity_on": "2021-01-27",
    "membership_type": "group_member",
    "removable": true,
    "created_at": "2021-01-03T12:16:02.000Z",
    "last_login_at": "2022-10-09T01:33:06.000Z"
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "email": "john@example.com",
    "last_activity_on": "2021-01-25",
    "membership_type": "group_member",
    "removable": true,
    "created_at": "2021-01-04T18:46:42.000Z",
    "last_login_at": "2022-09-29T22:18:46.000Z"
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "last_activity_on": "2021-01-20",
    "membership_type": "group_invite",
    "removable": false,
    "created_at": "2021-01-09T07:12:31.000Z",
    "last_login_at": "2022-10-10T07:28:56.000Z"
  }
]
```

## Lister toutes les appartenances d'un membre facturable du groupe {#list-all-memberships-for-a-billable-group-member}

Répertorie toutes les appartenances d'un membre facturable spécifié d'un groupe.

Prérequis :

- La réponse représente uniquement les appartenances directes. Les appartenances héritées ne sont pas incluses.
- Ce point de terminaison API fonctionne uniquement sur les groupes principaux. Il ne fonctionne pas sur les sous-groupes.
- Ce point de terminaison API requiert l'autorisation d'administrer les appartenances pour le groupe.

Répertorie tous les projets et groupes dont un utilisateur est membre. Seuls les projets et groupes dans la hiérarchie du groupe sont inclus. Par exemple, si le groupe demandé est `Top-Level Group`, et que l'utilisateur demandé est membre direct de `Top-Level Group / Subgroup One` et de `Other Group / Subgroup Two`, seul `Top-Level Group / Subgroup One` est retourné, car `Other Group / Subgroup Two` n'est pas dans la hiérarchie de `Top-Level Group`.

Ce point de terminaison API accepte les paramètres de [pagination](rest/_index.md#pagination) `page` et `per_page` pour limiter la liste des appartenances.

```plaintext
GET /groups/:id/billable_members/:user_id/memberships
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre facturable. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/memberships"
```

Exemple de réponse :

```json
[
  {
    "id": 168,
    "source_id": 131,
    "source_full_name": "Top-Level Group / Subgroup One",
    "source_members_url": "https://gitlab.example.com/groups/root-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  },
  {
    "id": 169,
    "source_id": 63,
    "source_full_name": "Top-Level Group / Subgroup One / My Project",
    "source_members_url": "https://gitlab.example.com/root-group/sub-group-one/my-project/-/project_members",
    "created_at": "2021-03-31T17:29:14.934Z",
    "expires_at": null,
    "access_level": {
      "string_value": "Maintainer",
      "integer_value": 40
    }
  }
]
```

## Lister toutes les appartenances indirectes d'un membre facturable du groupe {#list-all-indirect-memberships-for-a-billable-group-member}

{{< details >}}

- Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/386583) dans GitLab 16.11.

{{< /history >}}

Obtient la liste des appartenances indirectes d'un membre facturable d'un groupe.

Prérequis :

- Ce point de terminaison API fonctionne uniquement sur les groupes principaux. Il ne fonctionne pas sur les sous-groupes.
- Ce point de terminaison API requiert l'autorisation d'administrer les appartenances pour le groupe.

Répertorie tous les projets et groupes dont un utilisateur est membre, qui ont été invités dans le groupe principal demandé. Par exemple, si le groupe demandé est `Top-Level Group`, et que l'utilisateur demandé est membre direct de `Other Group / Subgroup Two`, qui a été invité dans `Top-Level Group`, seul `Other Group / Subgroup Two` est retourné.

La réponse répertorie uniquement les appartenances indirectes. Les appartenances directes ne sont pas incluses.

Ce point de terminaison API accepte les paramètres de [pagination](rest/_index.md#pagination) `page` et `per_page` pour limiter la liste des appartenances.

```plaintext
GET /groups/:id/billable_members/:user_id/indirect
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre facturable. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/indirect"
```

Exemple de réponse :

```json
[
  {
    "id": 168,
    "source_id": 132,
    "source_full_name": "Invited Group / Subgroup One",
    "source_members_url": "https://gitlab.example.com/groups/invited-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  }
]
```

## Supprimer un membre facturable du groupe {#remove-a-billable-group-member}

Supprime un membre facturable spécifié d'un groupe ainsi que de ses sous-groupes et projets.

L'utilisateur n'a pas besoin d'être membre du groupe pour être éligible à la suppression. Par exemple, si l'utilisateur a été ajouté directement à un projet du groupe, vous pouvez tout de même utiliser ce point de terminaison API pour le supprimer.

> [!note]
> La suppression des membres est gérée de manière asynchrone ; les modifications prennent donc quelques minutes pour être appliquées.

```plaintext
DELETE /groups/:id/billable_members/:user_id
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id"
```

## Modifier l'état d'appartenance au groupe pour un utilisateur {#change-group-membership-state-for-a-user}

Modifie l'état d'appartenance d'un utilisateur spécifié dans un groupe.

Lorsqu'un utilisateur dépasse [la limite d'utilisateurs gratuits](../user/free_user_limit.md), le fait de modifier son état d'appartenance pour un groupe ou un projet en `awaiting` ou `active` peut lui permettre d'accéder à ce groupe ou projet. La modification est appliquée à tous les sous-groupes et projets.

```plaintext
PUT /groups/:id/members/:user_id/state
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre. |
| `state`   | string            | oui      | Le nouvel état pour l'utilisateur. L'état est soit `awaiting` soit `active`. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/state?state=active"
```

Exemple de réponse :

```json
{
  "success":true
}
```

## Ajouter un membre au groupe {#add-a-group-member}

Ajoute un membre à un groupe spécifié.

```plaintext
POST /groups/:id/members
```

| Attribut        | Type              | Obligatoire                           | Description |
| ---------------- | ----------------- | ---------------------------------- | ----------- |
| `id`             | entier ou chaîne | oui                                | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `user_id`        | entier ou chaîne | oui, si `username` n'est pas fourni | L'identifiant utilisateur du nouveau membre ou plusieurs identifiants séparés par des virgules. |
| `username`       | string            | oui, si `user_id` n'est pas fourni  | Le nom d'utilisateur du nouveau membre ou plusieurs noms d'utilisateur séparés par des virgules. |
| `access_level`   | entier           | oui                                | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles :  `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Développeur), `40` (Mainteneur), `50` (Propriétaire). Par défaut : `30`. |
| `expires_at`     | string            | non                                 | Une chaîne de date au format `YEAR-MONTH-DAY`. |
| `invite_source`  | string            | non                                 | La source de l'invitation qui lance le processus de création du membre. Les membres de l'équipe GitLab peuvent consulter plus d'informations dans ce ticket confidentiel : `https://gitlab.com/gitlab-org/gitlab/-/issues/327120>`. |
| `member_role_id` | entier           | non                                 | Ultimate uniquement. L'identifiant d'un rôle personnalisé de membre. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 30,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> Si l'[approbation administrateur pour les promotions de rôles](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) est activée, les demandes d'appartenance qui font passer des utilisateurs existants à un rôle facturable requièrent l'approbation de l'administrateur.

Pour activer **Manage Non-Billable Promotions**, vous devez d'abord activer le paramètre d'application `enable_member_promotion_management`.

Exemple de mise en file d'attente d'un seul utilisateur :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
```

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

Exemple de mise en file d'attente de plusieurs utilisateurs :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval.",
    "username_2": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## Mettre à jour un membre du groupe {#update-a-group-member}

Met à jour un membre spécifié d'un groupe.

```plaintext
PUT /groups/:id/members/:user_id
```

| Attribut        | Type              | Obligatoire | Description |
| ---------------- | ----------------- | -------- | ----------- |
| `id`             | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `user_id`        | entier           | oui      | L'identifiant utilisateur du membre. |
| `access_level`   | entier           | oui       | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles :  `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Développeur), `40` (Mainteneur), `50` (Propriétaire), `60` (Admin). Par défaut : `30`. |
| `expires_at`     | string            | non       | Une chaîne de date au format `YEAR-MONTH-DAY`. |
| `member_role_id` | entier           | non       | Ultimate uniquement. L'identifiant d'un rôle personnalisé de membre. Si aucune valeur n'est spécifiée, tous les rôles sont supprimés. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id?access_level=40"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> Si l'[approbation administrateur pour les promotions de rôles](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) est activée, les demandes d'appartenance qui font passer des utilisateurs existants à un rôle facturable requièrent l'approbation de l'administrateur.

Pour activer **Manage non-billable promotions**, vous devez d'abord activer le paramètre d'application `enable_member_promotion_management`.

Exemple de réponse :

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

### Définir l'indicateur de substitution pour un membre du groupe {#set-override-flag-for-a-member-of-a-group}

Par défaut, le niveau d'accès des membres du groupe LDAP est défini sur la valeur spécifiée par LDAP via Group Sync. Vous pouvez autoriser les substitutions de niveau d'accès en appelant ce point de terminaison.

```plaintext
POST /groups/:id/members/:user_id/override
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "override": true
}
```

### Supprimer la substitution pour un membre du groupe {#remove-override-for-a-member-of-a-group}

Définit l'indicateur de substitution sur false et permet à LDAP Group Sync de réinitialiser le niveau d'accès à la valeur prescrite par LDAP.

```plaintext
DELETE /groups/:id/members/:user_id/override
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "override": false
}
```

## Supprimer un membre du groupe {#remove-a-group-member}

Supprime un utilisateur spécifié d'un groupe où l'utilisateur s'est vu explicitement attribuer un rôle.

L'utilisateur doit être membre du groupe pour être éligible à la suppression. Par exemple, si l'utilisateur a été ajouté directement à un projet du groupe mais pas à ce groupe explicitement, vous ne pouvez pas utiliser ce point de terminaison API pour le supprimer. Consultez [Supprimer un membre facturable d'un groupe](#remove-a-billable-group-member) pour une autre approche.

```plaintext
DELETE /groups/:id/members/:user_id
```

| Attribut            | Type              | Obligatoire | Description |
|----------------------|-------------------|----------|-------------|
| `id`                 | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe](rest/_index.md#namespaced-paths). |
| `user_id`            | entier           | oui      | L'identifiant utilisateur du membre. |
| `skip_subresources`  | boolean           | false    | Indique si la suppression des appartenances directes du membre supprimé dans les sous-groupes et les projets doit être ignorée. La valeur par défaut est `false`. |
| `unassign_issuables` | boolean           | false    | Indique si le membre supprimé doit être désassigné de tout ticket ou merge request au sein d'un groupe ou projet donné. La valeur par défaut est `false`. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## Approuver un membre du groupe {#approve-a-group-member}

Approuve un utilisateur en attente spécifié pour un groupe ainsi que ses sous-groupes et projets.

```plaintext
PUT /groups/:id/members/:member_id/approve
```

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe principal](rest/_index.md#namespaced-paths). |
| `member_id` | entier           | oui      | L'identifiant du membre. |

Exemple de requête :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:member_id/approve"
```

## Approuver tous les membres du groupe en attente {#approve-all-pending-group-members}

Approuve tous les utilisateurs en attente pour un groupe spécifié ainsi que ses sous-groupes et projets.

```plaintext
POST /groups/:id/members/approve_all
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du groupe principal](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/approve_all"
```

## Lister tous les membres du groupe en attente dans un groupe et ses sous-groupes et projets {#list-all-pending-group-members-in-a-group-and-its-subgroups-and-projects}

Répertorie tous les membres dans un état `awaiting` et ceux qui sont invités mais ne possèdent pas de compte GitLab pour un groupe spécifié et ses sous-groupes et projets.

Prérequis :

- Ce point de terminaison API fonctionne uniquement sur les groupes principaux. Il ne fonctionne pas sur les sous-groupes.
- Ce point de terminaison API requiert l'autorisation d'administrer les membres pour le groupe.

Cette requête retourne tous les membres correspondants de groupes et de projets de tous les groupes et projets dans la hiérarchie du groupe principal.

Lorsque le membre est un utilisateur invité qui ne s'est pas encore inscrit à un compte GitLab, l'adresse e-mail invitée est retournée.

Ce point de terminaison API accepte les paramètres de [pagination](rest/_index.md#pagination) `page` et `per_page` pour limiter la liste des membres.

```plaintext
GET /groups/:id/pending_members
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/pending_members"
```

Exemple de réponse :

```json
[
  {
    "id": 168,
    "name": "Alex Garcia",
    "username": "alex_garcia",
    "email": "alex@example.com",
    "avatar_url": "http://example.com/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://example.com/alex_garcia",
    "approved": false,
    "invited": false
  },
  {
    "id": 169,
    "email": "sidney@example.com",
    "avatar_url": "http://gravatar.com/../e346561cd8.jpeg",
    "approved": false,
    "invited": true
  },
  {
    "id": 170,
    "email": "zhang@example.com",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "approved": true,
    "invited": true
  }
]
```
