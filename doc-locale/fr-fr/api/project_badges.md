---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des badges de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [badges](../user/project/badges.md) de projet.

Les badges prennent en charge des espaces réservés qui sont remplacés en temps réel dans l'URL du lien et dans l'URL de l'image. Les espaces réservés suivants sont disponibles :

- `%{project_path}` : Remplacé par le chemin du projet.
- `%{project_title}` : Remplacé par le titre du projet.
- `%{project_name}` : Remplacé par le nom du projet.
- `%{project_id}` : Remplacé par l'ID du projet.
- `%{project_namespace}` : Remplacé par le chemin complet de l'espace de nommage du projet.
- `%{group_name}` : Remplacé par le nom du groupe principal du projet.
- `%{gitlab_server}` : Remplacé par le nom du serveur du projet.
- `%{gitlab_pages_domain}` : Remplacé par le nom de domaine hébergeant GitLab Pages.
- `%{default_branch}` : Remplacé par la branche par défaut du projet.
- `%{commit_sha}` : Remplacé par le SHA du dernier commit du projet.
- `%{latest_tag}` : Remplacé par le dernier tag du projet.

## Lister tous les badges d'un projet {#list-all-badges-of-a-project}

Liste tous les badges d'un projet, y compris les badges de groupe.

```plaintext
GET /projects/:id/badges
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `name`    | string         | non  | Nom des badges à retourner (sensible à la casse). |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges?name=Coverage"
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
    "kind": "project"
  },
  {
    "name": "Pipeline",
    "id": 2,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  }
]
```

## Récupérer un badge d'un projet {#retrieve-a-badge-of-a-project}

Récupère un badge d'un projet.

```plaintext
GET /projects/:id/badges/:badge_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `badge_id` | entier | oui   | L'ID du badge |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
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
  "kind": "project"
}
```

## Créer un badge pour un projet {#create-a-badge-for-a-project}

Crée un badge pour un projet.

```plaintext
POST /projects/:id/badges
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `link_url` | string         | oui | URL du lien du badge |
| `image_url` | string | oui | URL de l'image du badge |
| `name` | string | non | Nom du badge |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/main" \
  --form "image_url=https://shields.io/my/badge1" \
  --form "name=mybadge" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "project"
}
```

## Mettre à jour un badge d'un projet {#update-a-badge-of-a-project}

Met à jour un badge d'un projet.

```plaintext
PUT /projects/:id/badges/:badge_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `badge_id` | entier | oui   | L'ID du badge |
| `link_url` | string         | non | URL du lien du badge |
| `image_url` | string | non | URL de l'image du badge |
| `name` | string | non | Nom du badge |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "project"
}
```

## Supprimer un badge d'un projet {#delete-a-badge-from-a-project}

Supprime un badge d'un projet. Pour supprimer des badges de groupe, utilisez plutôt l'[API des badges de groupe](group_badges.md).

```plaintext
DELETE /projects/:id/badges/:badge_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `badge_id` | entier | oui   | L'ID du badge |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

## Prévisualiser un badge d'un projet {#preview-a-badge-from-a-project}

Retourne les URL finales de `link_url` et `image_url` telles qu'elles seraient après la résolution de l'interpolation des espaces réservés.

```plaintext
GET /projects/:id/badges/render
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `link_url` | string         | oui | URL du lien du badge|
| `image_url` | string | oui | URL de l'image du badge |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
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
