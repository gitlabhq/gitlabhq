---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des demandes d'accès aux groupes et projets"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les demandes d'accès aux groupes et projets.

## Lister toutes les demandes d'accès pour un groupe ou un projet {#list-all-access-requests-for-a-group-or-project}

Liste toutes les demandes d'accès pour un groupe ou un projet spécifié qui sont visibles par l'utilisateur authentifié.

```plaintext
GET /groups/:id/access_requests
GET /projects/:id/access_requests
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

Exemple de réponse :

```json
[
 {
   "id": 1,
   "username": "raymond_smith",
   "name": "Raymond Smith",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/1/avatar.png",
   "web_url": "https://gitlab.com/raymond_smith",
   "requested_at": "2024-10-22T14:13:35Z"
 },
 {
   "id": 2,
   "username": "john_doe",
   "name": "John Doe",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/2/avatar.png",
   "web_url": "https://gitlab.com/john_doe",
   "requested_at": "2024-10-22T14:13:35Z"
 }
]
```

## Demander l'accès à un groupe ou un projet {#request-access-to-a-group-or-project}

Demande l'accès pour l'utilisateur authentifié à un groupe ou un projet spécifié.

```plaintext
POST /groups/:id/access_requests
POST /projects/:id/access_requests
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe ou du projet](rest/_index.md#namespaced-paths) |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "requested_at": "2012-10-22T14:13:35Z"
}
```

## Approuver une demande d'accès {#approve-an-access-request}

Approuve une demande d'accès pour un utilisateur spécifié dans un groupe ou un projet spécifié.

```plaintext
PUT /groups/:id/access_requests/:user_id/approve
PUT /projects/:id/access_requests/:user_id/approve
```

| Attribut      | Type           | Obligatoire | Description |
|----------------|----------------|----------|-------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `user_id`      | entier        | oui      | L'ID utilisateur du demandeur d'accès |
| `access_level` | entier        | non       | Un [niveau d'accès](../user/permissions.md#default-roles) valide. Valeurs possibles : `0` (Aucun accès), `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer), `50` (Owner). Par défaut : `30`. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id/approve?access_level=20"
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id/approve?access_level=20"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "access_level": 20
}
```

## Refuser une demande d'accès {#deny-an-access-request}

Refuse une demande d'accès pour un utilisateur spécifié dans un groupe ou un projet spécifié.

```plaintext
DELETE /groups/:id/access_requests/:user_id
DELETE /projects/:id/access_requests/:user_id
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `user_id` | entier        | oui      | L'ID utilisateur du demandeur d'accès |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id"
```
