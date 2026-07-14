---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des membres de projets
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cet endpoint pour interagir avec les membres d'un projet.

Pour en savoir plus sur les membres d'un groupe, consultez l'[API des membres de groupe](group_members.md).

## Problèmes connus {#known-issues}

- Les attributs `group_saml_identity` et `group_scim_identity` ne sont visibles que par les propriétaires de groupe pour les [groupes avec SSO activé](../user/group/saml_sso/_index.md).
- L'attribut `email` n'est visible que par les propriétaires de groupe pour les [utilisateurs enterprise](../user/enterprise_user/_index.md) du groupe lorsqu'une requête API est envoyée au groupe lui-même, ou aux sous-groupes ou projets de ce groupe.

## Lister tous les membres directs d'un projet {#list-all-direct-members-of-a-project}

Liste tous les membres directs d'un projet spécifié qui sont visibles par l'utilisateur authentifié. Utilisez [Lister tous les membres d'un projet](#list-all-members-of-a-project) pour lister les membres hérités.

Cette fonction utilise les paramètres de pagination `page` et `per_page` pour restreindre la liste des utilisateurs.

```plaintext
GET /projects/:id/members
```

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `query`          | string            | non       | Filtre les résultats en fonction d'un nom, d'un e-mail ou d'un nom d'utilisateur donné. Utilisez des valeurs partielles pour élargir la portée de la requête. |
| `user_ids`       | tableau d'entiers | non       | Filtre les résultats sur les identifiants d'utilisateurs donnés. |
| `skip_users`     | tableau d'entiers | non       | Exclut les utilisateurs ignorés des résultats. |
| `show_seat_info` | boolean           | non       | Affiche les informations de siège pour les utilisateurs. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members"
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

## Lister tous les membres d'un projet {#list-all-members-of-a-project}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) pour retourner les membres du groupe privé invité si l'utilisateur actuel est membre du groupe ou du projet partagé dans GitLab 16.10 [avec un flag](../administration/feature_flags/_index.md) nommé `webui_members_inherited_users`. Désactivé par défaut. Désactivé par défaut.
- Le feature flag `webui_members_inherited_users` a été [activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) dans GitLab 17.0.
- Le feature flag `webui_members_inherited_users` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) dans GitLab 17.4. Les membres des groupes invités sont affichés par défaut.

{{< /history >}}

Liste tous les membres du projet visibles par l'utilisateur authentifié, y compris les membres hérités, les utilisateurs invités et les permissions accordées via les groupes ancêtres.

Si un utilisateur est membre de ce projet et également d'un ou plusieurs groupes ancêtres, seule l'appartenance avec le `access_level` le plus élevé est retournée. Cela représente la permission effective de l'utilisateur.

Les membres d'un groupe invité sont retournés si l'une des conditions suivantes est remplie :

- Le groupe invité est public.
- Le demandeur est également membre du groupe invité.
- Le demandeur est membre du groupe ou du projet partagé.

> [!note]
> Les membres du groupe invité ont une appartenance partagée dans le groupe ou le projet partagé. Cela signifie que si le demandeur est membre d'un groupe ou d'un projet partagé, mais pas membre d'un groupe privé invité, il peut utiliser cet endpoint pour obtenir tous les membres du groupe ou du projet partagé, y compris les membres du groupe privé invité.

Cette fonction utilise les paramètres de pagination `page` et `per_page` pour restreindre la liste des utilisateurs.

```plaintext
GET /projects/:id/members/all
```

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `query`          | string            | non       | Filtre les résultats en fonction d'un nom, d'un e-mail ou d'un nom d'utilisateur donné. Utilisez des valeurs partielles pour élargir la portée de la requête. |
| `user_ids`       | tableau d'entiers | non       | Filtre les résultats sur les identifiants d'utilisateurs donnés. |
| `show_seat_info` | boolean           | non       | Affiche les informations de siège pour les utilisateurs. |
| `state`          | string            | non       | Filtre les résultats par état du membre, `awaiting` ou `active`. Premium et Ultimate uniquement. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all"
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

## Récupérer un membre direct d'un projet {#retrieve-a-direct-member-of-a-project}

Récupère un membre direct spécifié d'un projet. Utilisez [Récupérer un membre d'un projet](#retrieve-a-member-of-a-project) pour récupérer les membres hérités.

```plaintext
GET /projects/:id/members/:user_id
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `user_id` | entier           | oui      | L'identifiant utilisateur du membre. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

Pour mettre à jour ou supprimer un rôle personnalisé d'un membre de groupe, transmettez une valeur `member_role_id` vide :

```shell
# Updates a project membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"
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

## Récupérer un membre d'un projet {#retrieve-a-member-of-a-project}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744) dans GitLab 12.4.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) pour retourner les membres du groupe privé invité si l'utilisateur actuel est membre du groupe ou du projet partagé dans GitLab 16.10 [avec un flag](../administration/feature_flags/_index.md) nommé `webui_members_inherited_users`. Désactivé par défaut. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) dans GitLab 17.0.
- Le feature flag `webui_members_inherited_users` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) dans GitLab 17.4. Les membres des groupes invités sont affichés par défaut.

{{< /history >}}

Récupère un membre spécifié d'un projet, y compris les membres hérités ou invités via les groupes ancêtres. Pour plus d'informations, consultez [Lister tous les membres d'un projet](#list-all-members-of-a-project).

> [!note]
> Les membres du groupe invité ont une appartenance partagée dans le groupe ou le projet partagé. Cela signifie que si le demandeur est membre d'un groupe ou d'un projet partagé, mais pas membre d'un groupe privé invité, il peut utiliser cet endpoint pour obtenir tous les membres du groupe ou du projet partagé, y compris les membres du groupe privé invité.

```plaintext
GET /projects/:id/members/all/:user_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `user_id` | entier | oui   | L'identifiant utilisateur du membre. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all/:user_id"
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

## Ajouter un membre à un projet {#add-a-member-to-a-project}

Ajoute un membre direct à un projet spécifié.

Pour donner à un groupe l'accès à un projet, consultez [partager un projet avec un groupe](projects.md#share-a-project-with-a-group).

```plaintext
POST /projects/:id/members
```

| Attribut        | Type              | Obligatoire                           | Description |
| ---------------- | ----------------- | ---------------------------------- | ----------- |
| `id`             | entier ou chaîne | oui                                | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `user_id`        | entier ou chaîne | oui, si `username` n'est pas fourni | L'identifiant utilisateur du nouveau membre ou plusieurs identifiants séparés par des virgules. |
| `username`       | string            | oui, si `user_id` n'est pas fourni  | Le nom d'utilisateur du nouveau membre ou plusieurs noms d'utilisateur séparés par des virgules. |
| `access_level`   | entier           | oui                                | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles :  `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer), ou `50` (Owner). Par défaut : `30`. |
| `expires_at`     | string            | non                                 | Une chaîne de date au format `YEAR-MONTH-DAY`. |
| `invite_source`  | string            | non                                 | La source de l'invitation qui lance le processus de création du membre. Les membres de l'équipe GitLab peuvent consulter plus d'informations dans ce ticket confidentiel : `https://gitlab.com/gitlab-org/gitlab/-/issues/327120`. |
| `member_role_id` | entier           | non                                 | Ultimate uniquement. L'identifiant d'un rôle personnalisé de membre. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
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
> Si l'[approbation de l'administrateur pour les promotions de rôles](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) est activée, les demandes d'appartenance qui font passer des utilisateurs existants à un rôle facturable nécessitent l'approbation de l'administrateur.

Pour activer **Manage Non-Billable Promotions**, vous devez d'abord activer le paramètre d'application `enable_member_promotion_management`.

Exemple de mise en file d'attente d'un seul utilisateur :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
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
     --data "user_id=1,2&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
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

## Mettre à jour un membre d'un projet {#update-a-member-of-a-project}

Met à jour le membre spécifié d'un projet.

```plaintext
PUT /projects/:id/members/:user_id
```

| Attribut        | Type              | Obligatoire | Description |
| ---------------- | ----------------- | -------- | ----------- |
| `id`             | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `user_id`        | entier           | oui      | L'identifiant utilisateur du membre. |
| `access_level`   | entier           | oui       | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles :  `0` (Aucun accès), `5` (Accès minimum), `10` (Invité), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer), ou `50` (Owner). Par défaut : `30`. |
| `expires_at`     | string            | non       | Une chaîne de date au format `YEAR-MONTH-DAY`. |
| `member_role_id` | entier           | non       | Ultimate uniquement. L'identifiant d'un rôle personnalisé de membre. Si aucune valeur n'est spécifiée, tous les rôles sont supprimés. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40"
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
> Si l'[approbation de l'administrateur pour les promotions de rôles](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) est activée, les demandes d'appartenance qui font passer des utilisateurs existants à un rôle facturable nécessitent l'approbation de l'administrateur.

Pour activer **Manage non-billable promotions**, vous devez d'abord activer le paramètre d'application `enable_member_promotion_management`.

Exemple de réponse :

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

## Supprimer un membre direct d'un projet {#remove-a-direct-member-of-a-project}

Supprime le membre direct spécifié d'un projet.

Par exemple, si l'utilisateur a été ajouté directement à un projet du groupe mais pas à ce groupe explicitement, vous ne pouvez pas utiliser cet endpoint pour le supprimer. Pour plus d'informations, consultez [Supprimer un membre facturable d'un groupe](group_members.md#remove-a-billable-group-member).

```plaintext
DELETE /projects/:id/members/:user_id
```

| Attribut            | Type              | Obligatoire | Description |
|----------------------|-------------------|----------|-------------|
| `id`                 | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `user_id`            | entier           | oui      | L'identifiant utilisateur du membre. |
| `skip_subresources`  | boolean           | false    | Indique si la suppression des appartenances directes du membre supprimé dans les sous-groupes et les projets doit être ignorée. La valeur par défaut est `false`. |
| `unassign_issuables` | boolean           | false    | Indique si le membre supprimé doit être désassigné de tous les tickets ou merge requests dans un projet donné. La valeur par défaut est `false`. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```
