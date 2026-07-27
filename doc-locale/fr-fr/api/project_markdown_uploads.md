---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des téléversements Markdown
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [téléversements Markdown](../security/user_file_uploads.md) pouvant être référencés dans du texte Markdown dans des tickets, des merge requests, des extraits de code ou des pages wiki.

## Créer un téléversement {#create-an-upload}

{{< history >}}

- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112450) dans GitLab 15.10. L'indicateur de fonctionnalité `enforce_max_attachment_size_upload_api` a été supprimé.
- Le modèle d'attribut de réponse `full_path` a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150939) dans GitLab 17.1.
- L'attribut `id` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161160) dans GitLab 17.3.

{{< /history >}}

Téléverse un fichier vers le projet spécifié pour l'utiliser dans un ticket ou la description d'une merge request, ou dans un commentaire.

```plaintext
POST /projects/:id/uploads
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `file`    | string            | Oui      | Fichier à téléverser. |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Pour télécharger un fichier depuis votre système de fichiers, utilisez l'argument `--form`. Cela oblige cURL à envoyer des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`.

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

Exemple de réponse :

```json
{
  "id": 5,
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/-/project/1234/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

Dans la réponse, le/la :

- `full_path` est le chemin absolu vers le fichier.
- `url` peut être utilisé dans les contextes Markdown. Le lien est développé lorsque le format dans `markdown` est utilisé.

## Lister les téléversements {#list-uploads}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Liste tous les téléversements d'un projet triés par `created_at` dans l'ordre décroissant.

Prérequis :

- le rôle Maintainer ou Owner.

```plaintext
GET /projects/:id/uploads
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "size": 1024,
    "filename": "image.png",
    "created_at":"2024-06-20T15:53:03.067Z",
    "uploaded_by": {
      "id": 18,
      "name" : "Alexandra Bashirian",
      "username" : "eileen.lowe"
    }
  },
  {
    "id": 2,
    "size": 512,
    "filename": "other-image.png",
    "created_at":"2024-06-19T15:53:03.067Z",
    "uploaded_by": null
  }
]
```

## Télécharger un fichier téléversé par ID {#download-an-uploaded-file-by-id}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Télécharge un fichier téléversé par ID.

Prérequis :

- le rôle Maintainer ou Owner.

```plaintext
GET /projects/:id/uploads/:upload_id
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `upload_id` | entier           | Oui      | ID du téléversement. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et le fichier téléversé dans le corps de la réponse.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## Télécharger un fichier téléversé par secret et nom de fichier {#download-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) dans GitLab 17.4.

{{< /history >}}

Télécharge un fichier téléversé par secret et nom de fichier.

Prérequis :

- le rôle Planificateur, Guest, Reporter, Developer, Maintainer ou Owner.

```plaintext
GET /projects/:id/uploads/:secret/:filename
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|:-----------|:------------------|:---------|:------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `secret`   | string            | Oui      | Secret de 32 caractères du téléversement. |
| `filename` | string            | Oui      | Nom du fichier téléversé. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et le fichier téléversé dans le corps de la réponse.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

## Supprimer un fichier téléversé par ID {#delete-an-uploaded-file-by-id}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Supprime un fichier téléversé par ID.

Prérequis :

- le rôle Maintainer ou Owner.

```plaintext
DELETE /projects/:id/uploads/:upload_id
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `upload_id` | entier           | Oui      | ID du téléversement. |

En cas de succès, renvoie le code de statut [`204`](rest/troubleshooting.md#status-codes) sans corps de réponse.

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## Supprimer un fichier téléversé par secret et nom de fichier {#delete-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) dans GitLab 17.4.

{{< /history >}}

Supprime un fichier téléversé par secret et nom de fichier.

Prérequis :

- le rôle Maintainer ou Owner.

```plaintext
DELETE /projects/:id/uploads/:secret/:filename
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|:-----------|:------------------|:---------|:------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `secret`   | string            | Oui      | Secret de 32 caractères du téléversement. |
| `filename` | string            | Oui      | Nom du fichier téléversé. |

En cas de succès, renvoie le code de statut [`204`](rest/troubleshooting.md#status-codes) sans corps de réponse.

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```
