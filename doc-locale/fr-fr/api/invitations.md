---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des invitations
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les invitations et ajouter des utilisateurs à un [groupe](../user/group/_index.md#add-users-to-a-group) ou à un [projet](../user/project/members/_index.md).

## Ajouter un membre à un groupe ou à un projet {#add-a-member-to-a-group-or-project}

Ajoute un nouveau membre. Vous pouvez spécifier un ID utilisateur ou inviter un utilisateur par e-mail.

Prérequis :

- Pour les groupes, vous devez avoir le rôle Propriétaire pour le groupe.
- Pour les projets :
  - Vous devez avoir le rôle Maintainer ou Owner pour le projet.
  - Le [verrouillage de l'appartenance au groupe](../user/group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group) doit être désactivé.
- Pour les instances GitLab Self-Managed :
  - Si [les nouveaux comptes utilisateurs ne sont pas autorisés](../administration/settings/sign_up_restrictions.md#disable-new-user-account-creation), un administrateur doit ajouter l'utilisateur.
  - Si [les invitations d'utilisateurs ne sont pas autorisées](../administration/settings/visibility_and_access_controls.md#prevent-invitations-to-groups-and-projects), un administrateur doit ajouter l'utilisateur.
  - Si [l'approbation de l'administrateur pour les promotions de rôle est activée](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions), un administrateur doit approuver l'invitation.

```plaintext
POST /groups/:id/invitations
POST /projects/:id/invitations
```

| Attribut        | Type              | Obligatoire                          | Description |
| ---------------- | ----------------- | --------------------------------- | ----------- |
| `id`             | entier ou chaîne de caractères | oui                               | L'ID ou le [chemin encodé par URL du projet ou du groupe](rest/_index.md#namespaced-paths) |
| `email`          | string            | oui (si `user_id` n'est pas fourni) | L'e-mail du nouveau membre ou plusieurs e-mails séparés par des virgules. |
| `user_id`        | entier ou chaîne de caractères | oui (si `email` n'est pas fourni)   | L'ID du nouveau membre ou plusieurs ID séparés par des virgules. |
| `access_level`   | integer           | oui                               | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles : `0` (Aucun accès), `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). Par défaut : `30`. |
| `expires_at`     | string            | non                                | Une chaîne de date au format `YEAR-MONTH-DAY` |
| `invite_source`  | string            | non                                | La source de l'invitation qui lance le processus de création de membre. |
| `member_role_id` | integer           | non                                | Attribue le nouveau membre au rôle personnalisé fourni. ([Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134100)) dans GitLab 16.6. Ultimate uniquement. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/invitations" \
  --data "email=test@example.com&user_id=1&access_level=30"
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/invitations" \
  --data "email=test@example.com&user_id=1&access_level=30"
```

Exemples de réponses :

Lorsque tous les e-mails ont été envoyés avec succès :

```json
{  "status":  "success"  }
```

Lorsque des erreurs se sont produites lors de l'envoi de l'e-mail :

```json
{
  "status": "error",
  "message": {
               "test@example.com": "Invite email has already been taken",
               "test2@example.com": "User already exists in source",
               "test_username": "Access level is not included in the list"
             }
}
```

Pour activer **Manage non-billable promotions**, vous devez d'abord activer le paramètre d'application `enable_member_promotion_management`.

Exemple de réponse :

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## Lister toutes les invitations en attente pour un groupe ou un projet {#list-all-pending-invitations-for-a-group-or-project}

Liste toutes les invitations en attente visibles par l'utilisateur authentifié. Renvoie les invitations aux membres directs uniquement, et non via les groupes d'ancêtres hérités.

Cette fonction utilise les paramètres de pagination `page` et `per_page` pour restreindre la liste des membres.

```plaintext
GET /groups/:id/invitations
GET /projects/:id/invitations
```

| Attribut  | Type           | Obligatoire | Description |
|------------|----------------|----------|-------------|
| `id`       | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé par URL du projet ou du groupe](rest/_index.md#namespaced-paths) |
| `page`     | integer        | non       | Page à récupérer |
| `per_page` | integer        | non       | Nombre d'invitations de membres à retourner par page |
| `query`    | string         | non       | Une chaîne de requête pour rechercher des membres invités par e-mail d'invitation. Le texte de la requête doit correspondre exactement à l'adresse e-mail. Lorsqu'elle est vide, retourne toutes les invitations. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/invitations?query=member@example.org"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/invitations?query=member@example.org"
```

Exemple de réponse :

```json
 [
   {
     "id": 1,
     "invite_email": "member@example.org",
     "created_at": "2020-10-22T14:13:35Z",
     "access_level": 30,
     "expires_at": "2020-11-22T14:13:35Z",
     "user_name": "Raymond Smith",
     "created_by_name": "Administrator"
   },
]
```

## Mettre à jour une invitation à un groupe ou à un projet {#update-an-invitation-to-a-group-or-project}

Met à jour une invitation en attente à un groupe ou à un projet.

```plaintext
PUT /groups/:id/invitations/:email
PUT /projects/:id/invitations/:email
```

| Attribut      | Type              | Obligatoire | Description |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé par URL du projet ou du groupe](rest/_index.md#namespaced-paths). |
| `email`        | string            | oui      | L'adresse e-mail à laquelle l'invitation a été précédemment envoyée. |
| `access_level` | integer           | non       | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles : `0` (Aucun accès), `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). Par défaut : `30`. |
| `expires_at`   | string            | non       | Une chaîne de date au format ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org?access_level=40"
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org?access_level=40"
```

Exemple de réponse :

```json
{
  "expires_at": "2012-10-22T14:13:35Z",
  "access_level": 40,
}
```

## Supprimer une invitation à un groupe ou à un projet {#delete-an-invitation-to-a-group-or-project}

Supprime une invitation en attente à l'adresse e-mail spécifiée.

```plaintext
DELETE /groups/:id/invitations/:email
DELETE /projects/:id/invitations/:email
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé par URL du projet ou du groupe](rest/_index.md#namespaced-paths) |
| `email`   | string         | oui      | L'adresse e-mail à laquelle l'invitation a été précédemment envoyée |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org"
```

- Retourne `204` et aucun contenu en cas de succès.
- Retourne `403` forbidden si non autorisé à supprimer l'invitation.
- Retourne `404` not found si autorisé et qu'aucune invitation n'est trouvée pour cette adresse e-mail.
- Retourne `409` si la requête était valide mais que l'invitation n'a pas pu être supprimée.
