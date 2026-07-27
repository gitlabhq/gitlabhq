---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des chargements Markdown de groupe
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [chargements Markdown](../security/user_file_uploads.md) qui peuvent être référencés dans du texte Markdown dans des epics ou des pages wiki.

## Charger un fichier vers un groupe {#upload-a-file-to-a-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230537) dans GitLab 19.0.

{{< /history >}}

Charge un fichier vers le groupe spécifié. Renvoie un lien formaté en Markdown vers le fichier.

Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
POST /groups/:id/uploads
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `file`    | file              | Oui      | Le fichier à charger. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@/path/to/image.png" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads"
```

Exemple de réponse :

```json
{
  "id": 3,
  "alt": "image",
  "url": "/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png",
  "full_path": "/-/group/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png",
  "markdown": "![image](/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png)"
}
```

## Lister tous les chargements d'un groupe {#list-all-uploads-for-a-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Liste tous les chargements d'un groupe spécifié, triés par `created_at` dans l'ordre décroissant.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /groups/:id/uploads
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads"
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

## Télécharger un fichier chargé par ID {#download-an-uploaded-file-by-id}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Télécharge un fichier chargé avec l'ID spécifié. Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /groups/:id/uploads/:upload_id
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `upload_id` | integer           | Oui      | L'ID du chargement. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et le fichier chargé dans le corps de la réponse.

## Télécharger un fichier chargé par secret et nom de fichier {#download-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) dans GitLab 17.4.

{{< /history >}}

Télécharge un fichier chargé avec le secret et le nom de fichier spécifiés. Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /groups/:id/uploads/:secret/:filename
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `secret`    | string            | Oui      | Le secret à 32 caractères du chargement. |
| `filename`  | string            | Oui      | Le nom de fichier du chargement. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et le fichier chargé dans le corps de la réponse.

## Supprimer un fichier chargé par ID {#delete-an-uploaded-file-by-id}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Supprime un fichier chargé avec l'ID spécifié. Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
DELETE /groups/:id/uploads/:upload_id
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `upload_id` | integer           | Oui      | L'ID du chargement. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

En cas de succès, renvoie le code de statut [`204`](rest/troubleshooting.md#status-codes) sans corps de réponse.

## Supprimer un fichier chargé par secret et nom de fichier {#delete-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) dans GitLab 17.4.

{{< /history >}}

Supprime un fichier chargé avec le secret et le nom de fichier spécifiés. Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
DELETE /groups/:id/uploads/:secret/:filename
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `secret`    | string            | Oui      | Le secret à 32 caractères du chargement. |
| `filename`  | string            | Oui      | Le nom de fichier du chargement. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

En cas de succès, renvoie le code de statut [`204`](rest/troubleshooting.md#status-codes) sans corps de réponse.
