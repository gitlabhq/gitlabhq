---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des badges de groupe
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les badges de groupe. Pour plus d'informations, consultez [les badges de groupe](../user/project/badges.md#group-badges).

Les badges prennent en charge des espaces réservés qui sont remplacés en temps réel dans l'URL du lien et dans l'URL de l'image. Les espaces réservés suivants sont disponibles :

- `%{project_path}` : remplacé par le chemin du projet.
- `%{project_title}` : remplacé par le titre du projet.
- `%{project_name}` : remplacé par le nom du projet.
- `%{project_id}` : remplacé par l'ID du projet.
- `%{project_namespace}` : remplacé par le chemin complet de l'espace de nommage du projet.
- `%{group_name}` : remplacé par le nom du groupe principal du projet.
- `%{gitlab_server}` : remplacé par le nom du serveur du projet.
- `%{gitlab_pages_domain}` : remplacé par le nom de domaine hébergeant GitLab Pages.
- `%{default_branch}` : remplacé par la branche par défaut du projet.
- `%{commit_sha}` : remplacé par le SHA du dernier commit du projet.
- `%{latest_tag}` : remplacé par le dernier tag du projet.

Comme ces endpoints ne sont pas dans le contexte d'un projet, les informations utilisées pour remplacer les espaces réservés proviennent du premier projet du groupe par date de création. Si le groupe n'a pas de projet, l'URL d'origine avec les espaces réservés est retournée.

## Lister tous les badges de groupe {#list-all-group-badges}

Liste les badges d'un groupe spécifié.

```plaintext
GET /groups/:id/badges
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `name`    | string         | non  | Nom des badges à retourner (sensible à la casse). |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges?name=Coverage"
```

Exemple de réponse :

```json
[
  {
    "name": "Coverage",
    "id": 1,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  }
]
```

## Récupérer un badge de groupe {#retrieve-a-group-badge}

Récupère un badge spécifié pour un groupe.

```plaintext
GET /groups/:id/badges/:badge_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `badge_id` | entier | oui   | L'ID du badge |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

Exemple de réponse :

```json
{
  "name": "Coverage",
  "id": 1,
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## Créer un badge de groupe {#create-a-group-badge}

Crée un badge pour un groupe spécifié.

```plaintext
POST /groups/:id/badges
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `link_url` | string         | oui | URL du lien du badge |
| `image_url` | string | oui | URL de l'image du badge |
| `name` | string | non | Nom du badge |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges" \
  --data "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/master&image_url=https://shields.io/my/badge1&name=mybadge&position=0"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "group"
}
```

## Mettre à jour un badge de groupe {#update-a-group-badge}

Met à jour un badge spécifié pour un groupe.

```plaintext
PUT /groups/:id/badges/:badge_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `badge_id` | entier | oui   | L'ID du badge |
| `link_url` | string         | non | URL du lien du badge |
| `image_url` | string | non | URL de l'image du badge |
| `name` | string | non | Nom du badge |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## Supprimer un badge de groupe {#delete-a-group-badge}

Supprime un badge spécifié d'un groupe.

```plaintext
DELETE /groups/:id/badges/:badge_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `badge_id` | entier | oui   | L'ID du badge |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

## Récupérer un aperçu d'un badge de groupe {#retrieve-a-group-badge-preview}

Récupère un aperçu des URLs finales `link_url` et `image_url` pour un groupe spécifié après résolution de l'interpolation des espaces réservés.

```plaintext
GET /groups/:id/badges/render
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `link_url` | string         | oui | URL du lien du badge|
| `image_url` | string | oui | URL de l'image du badge |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
```

Exemple de réponse :

```json
{
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge"
}
```
