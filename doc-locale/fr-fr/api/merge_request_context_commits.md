---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des commits de contexte de merge request dans GitLab."
title: API des commits de contexte de merge request
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si votre merge request s'appuie sur une merge request précédente, vous devrez peut-être [inclure des commits précédemment fusionnés pour le contexte](../user/project/merge_requests/commits.md#show-commits-from-previous-merge-requests) dans votre merge request. Utilisez cette API REST pour ajouter des commits à une merge request afin d'obtenir plus de contexte.

## Lister les commits de contexte d'une merge request {#list-context-commits-for-a-merge-request}

Liste les commits de contexte d'une seule merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Paramètres :

| Attribut           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | integer | Oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer | Oui | L'ID interne de la merge request. |

```json
[
    {
        "id": "4a24d82dbca5c11c61556f3b35ca472b7463187e",
        "short_id": "4a24d82d",
        "created_at": "2017-04-11T10:08:59.000Z",
        "parent_ids": null,
        "title": "Update README.md to include `Usage in testing and development`",
        "message": "Update README.md to include `Usage in testing and development`",
        "author_name": "Example \"Sample\" User",
        "author_email": "user@example.com",
        "authored_date": "2017-04-11T10:08:59.000Z",
        "committer_name": "Example \"Sample\" User",
        "committer_email": "user@example.com",
        "committed_date": "2017-04-11T10:08:59.000Z"
    }
]
```

## Créer des commits de contexte pour une merge request {#create-context-commits-for-a-merge-request}

Crée des commits de contexte pour une seule merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Paramètres :

| Attribut           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | integer | Oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)  |
| `merge_request_iid` | integer | Oui | L'ID interne de la merge request. |
| `commits`           | string array | Oui | Les SHAs des commits de contexte. |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"commits": ["51856a574ac3302a95f82483d6c7396b1e0783cb"]}' \
  --url "https://gitlab.example.com/api/v4/projects/15/merge_requests/12/context_commits"
```

Exemple de réponse :

```json
[
    {
        "id": "51856a574ac3302a95f82483d6c7396b1e0783cb",
        "short_id": "51856a57",
        "created_at": "2014-02-27T10:05:10.000+02:00",
        "parent_ids": [
            "57a82e2180507c9e12880c0747f0ea65ad489515"
        ],
        "title": "Commit title",
        "message": "Commit message",
        "author_name": "Example User",
        "author_email": "user@example.com",
        "authored_date": "2014-02-27T10:05:10.000+02:00",
        "committer_name": "Example User",
        "committer_email": "user@example.com",
        "committed_date": "2014-02-27T10:05:10.000+02:00",
        "trailers": {},
        "web_url": "https://gitlab.example.com/project/path/-/commit/b782f6c553653ab4e16469ff34bf3a81638ac304"
    }
]
```

## Supprimer des commits de contexte d'une merge request {#delete-context-commits-from-a-merge-request}

Supprime les commits de contexte d'une seule merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Paramètres :

| Attribut           | Type         | Obligatoire | Description  |
|---------------------|--------------|----------|--------------|
| `commits`           | string array | Oui | Le SHA des commits de contexte. |
| `id`                | integer      | Oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer      | Oui | L'ID interne de la merge request. |
