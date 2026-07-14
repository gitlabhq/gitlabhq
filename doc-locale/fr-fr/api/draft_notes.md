---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des notes brouillon (commentaires non publiés) dans GitLab."
title: API des notes brouillon
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API REST pour gérer les notes brouillon. Ces notes sont des commentaires en attente, non publiés, sur les merge requests. Les notes brouillon peuvent démarrer une discussion ou continuer une discussion existante en tant que réponse.

Avant publication, les notes brouillon ne sont visibles que par l'auteur.

## Lister toutes les notes brouillon d'une merge request {#list-all-merge-request-draft-notes}

Liste toutes les notes brouillon d'une merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet |

```json
[
  {
    "id": 5,
    "author_id": 23,
    "merge_request_id": 11,
    "resolve_discussion": false,
    "discussion_id": null,
    "note": "Example title",
    "commit_id": null,
    "line_code": null,
    "position": {
      "base_sha": null,
      "start_sha": null,
      "head_sha": null,
      "old_path": null,
      "new_path": null,
      "position_type": "text",
      "old_line": null,
      "new_line": null,
      "line_range": null
    }
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes"
```

## Récupérer une note brouillon {#retrieve-a-draft-note}

Récupère une note brouillon pour une merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `draft_note_id`     | entier           | oui      | L'ID d'une note brouillon. |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet. |

```json
[
  {
    "id": 5,
    "author_id": 23,
    "merge_request_id": 11,
    "resolve_discussion": false,
    "discussion_id": null,
    "note": "Example title",
    "commit_id": null,
    "line_code": null,
    "position": {
      "base_sha": null,
      "start_sha": null,
      "head_sha": null,
      "old_path": null,
      "new_path": null,
      "position_type": "text",
      "old_line": null,
      "new_line": null,
      "line_range": null
    }
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## Créer une note brouillon {#create-a-draft-note}

Crée une note brouillon pour une merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| Attribut                   | Type              | Obligatoire    | Description           |
| ----------------------------| ----------------- | ----------- | --------------------- |
| `id`                        | entier ou chaîne | oui         | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid`         | entier           | oui         | L'IID d'une merge request de projet. |
| `note`                      | string            | oui         | Le contenu d'une note. |
| `commit_id`                 | string            | non          | Le SHA d'un commit à associer à la note brouillon. |
| `in_reply_to_discussion_id` | string            | non          | L'ID d'une discussion à laquelle la note brouillon répond. |
| `resolve_discussion`        | boolean           | non          | La discussion associée doit être résolue. |
| `position`                  | hash              | non          | Position lors de la création d'une note de diff. Si omis, crée une note de discussion ordinaire. |
| `position[base_sha]`        | string            | oui (si `position` est fourni) | SHA du commit de base dans la branche source. |
| `position[head_sha]`        | string            | oui (si `position` est fourni) | SHA référençant le HEAD de cette merge request. |
| `position[start_sha]`       | string            | oui (si `position` est fourni) | SHA référençant le commit dans la branche cible. |
| `position[new_path]`        | string            | oui (si le type de position est `text`) | Chemin du fichier après la modification. |
| `position[old_path]`        | string            | oui (si le type de position est `text`) | Chemin du fichier avant la modification. |
| `position[position_type]`   | string            | oui (si `position` est fourni) | Type de la référence de position. Valeurs autorisées : `text`, `image`, ou `file`. `file` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423046) dans GitLab 16.4. |
| `position[new_line]`        | entier           | non          | Pour les notes de diff `text`, le numéro de ligne après la modification. |
| `position[old_line]`        | entier           | non          | Pour les notes de diff `text`, le numéro de ligne avant la modification. |
| `position[line_range]`      | hash              | non          | Plage de lignes pour une note de diff multiligne. |
| `position[width]`           | entier           | non          | Pour les notes de diff `image`, la largeur de l'image. |
| `position[height]`          | entier           | non          | Pour les notes de diff `image`, la hauteur de l'image. |
| `position[x]`               | float             | non          | Pour les notes de diff `image`, la coordonnée X. |
| `position[y]`               | float             | non          | Pour les notes de diff `image`, la coordonnée Y. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes?note=note"
```

## Mettre à jour une note brouillon {#update-a-draft-note}

Met à jour une note brouillon pour une merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| Attribut                 | Type              | Obligatoire | Description |
| ------------------------- | ----------------- | -------- | ----------- |
| `id`                      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `draft_note_id`           | entier           | oui      | L'ID d'une note brouillon. |
| `merge_request_iid`       | entier           | oui      | L'IID d'une merge request de projet. |
| `note`                    | string            | non       | Le contenu d'une note. |
| `position`                | hash              | non       | Position lors de la création d'une note de diff. |
| `position[base_sha]`      | string            | oui (si `position` est fourni) | SHA du commit de base dans la branche source. |
| `position[head_sha]`      | string            | oui (si `position` est fourni) | SHA référençant le HEAD de cette merge request. |
| `position[start_sha]`     | string            | oui (si `position` est fourni) | SHA référençant le commit dans la branche cible. |
| `position[new_path]`      | string            | oui (si le type de position est `text`) | Chemin du fichier après la modification. |
| `position[old_path]`      | string            | oui (si le type de position est `text`) | Chemin du fichier avant la modification. |
| `position[position_type]` | string            | oui (si `position` est fourni) | Type de la référence de position. Valeurs autorisées : `text`, `image` ou `file`. `file` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423046) dans GitLab 16.4. |
| `position[new_line]`      | entier           | non       | Pour les notes de diff `text`, le numéro de ligne après la modification. |
| `position[old_line]`      | entier           | non       | Pour les notes de diff `text`, le numéro de ligne avant la modification. |
| `position[line_range]`    | hash              | non       | Plage de lignes pour une note de diff multiligne. |
| `position[width]`         | entier           | non       | Pour les notes de diff `image`, la largeur de l'image. |
| `position[height]`        | entier           | non       | Pour les notes de diff `image`, la hauteur de l'image. |
| `position[x]`             | float             | non       | Pour les notes de diff `image`, la coordonnée X. |
| `position[y]`             | float             | non       | Pour les notes de diff `image`, la coordonnée Y. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## Supprimer une note brouillon {#delete-a-draft-note}

Supprime une note brouillon pour une merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `draft_note_id`     | entier           | oui      | L'ID d'une note brouillon. |
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## Publier une note brouillon {#publish-a-draft-note}

Publie une note brouillon pour une merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id/publish
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `draft_note_id`     | entier           | oui      | L'ID d'une note brouillon. |
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5/publish"
```

## Publier toutes les notes brouillon en attente {#publish-all-pending-draft-notes}

Publie toutes les notes brouillon en attente pour une merge request appartenant à l'utilisateur.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes/bulk_publish
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/bulk_publish"
```
