---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Snippets de projet
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [snippets de projet](../user/snippets.md). Des API associées existent pour les [snippets personnels](snippets.md) et le [déplacement de snippets entre les stockages](snippet_repository_storage_moves.md).

## Répertorier tous les snippets d'un projet {#list-all-snippets-for-a-project}

Répertorie tous les snippets d'un projet spécifié.

```plaintext
GET /projects/:id/snippets
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date et heure auxquelles le compte de l'auteur a été créé. |
| `author.email`      | string  | Adresse e-mail de l'auteur du snippet. |
| `author.id`         | entier | ID de l'auteur du snippet. |
| `author.name`       | string  | Nom d'affichage de l'auteur du snippet. |
| `author.state`      | string  | État du compte de l'auteur. |
| `author.username`   | string  | Nom d'utilisateur de l'auteur du snippet. |
| `created_at`        | string  | Date et heure auxquelles le snippet a été créé au format ISO 8601. |
| `description`       | string  | Description du snippet. |
| `file_name`         | string  | Nom du fichier snippet. |
| `id`                | entier | ID du snippet. |
| `imported`          | boolean | Si `true`, le snippet a été importé. |
| `imported_from`     | string  | Source de l'importation si le snippet a été importé. |
| `project_id`        | entier | ID du projet contenant le snippet. |
| `raw_url`           | string  | URL directe vers le contenu brut du snippet. |
| `title`             | string  | Titre du snippet. |
| `updated_at`        | string  | Date et heure auxquelles le snippet a été mis à jour pour la dernière fois au format ISO 8601. |
| `web_url`           | string  | URL pour afficher le snippet dans l'interface web de GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "title": "test",
    "file_name": "add.rb",
    "description": "Ruby test snippet",
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "state": "active",
      "created_at": "2012-05-23T08:00:58Z"
    },
    "updated_at": "2012-06-28T10:52:04Z",
    "created_at": "2012-06-28T10:52:04Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/1",
    "raw_url": "http://example.com/example/example/snippets/1/raw"
  },
  {
    "id": 3,
    "title": "Configuration helper",
    "file_name": "config.yml",
    "description": "YAML configuration snippet",
    "author": {
      "id": 2,
      "username": "jane_doe",
      "email": "jane@example.com",
      "name": "Jane Doe",
      "state": "active",
      "created_at": "2013-02-15T10:30:20Z"
    },
    "updated_at": "2013-03-10T14:15:30Z",
    "created_at": "2013-03-01T09:45:12Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/3",
    "raw_url": "http://example.com/example/example/snippets/3/raw"
  }
]
```

## Récupérer un snippet {#retrieve-a-snippet}

Récupère un snippet de projet spécifié.

```plaintext
GET /projects/:id/snippets/:snippet_id
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id` | entier           | Oui      | ID du snippet d'un projet. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date et heure auxquelles le compte de l'auteur a été créé. |
| `author.email`      | string  | Adresse e-mail de l'auteur du snippet. |
| `author.id`         | entier | ID de l'auteur du snippet. |
| `author.name`       | string  | Nom d'affichage de l'auteur du snippet. |
| `author.state`      | string  | État du compte de l'auteur. |
| `author.username`   | string  | Nom d'utilisateur de l'auteur du snippet. |
| `created_at`        | string  | Date et heure auxquelles le snippet a été créé au format ISO 8601. |
| `description`       | string  | Description du snippet. |
| `file_name`         | string  | Nom du fichier snippet. |
| `id`                | entier | ID du snippet. |
| `imported`          | boolean | Si `true`, le snippet a été importé. |
| `imported_from`     | string  | Source de l'importation si le snippet a été importé. |
| `project_id`        | entier | ID du projet contenant le snippet. |
| `raw_url`           | string  | URL directe vers le contenu brut du snippet. |
| `title`             | string  | Titre du snippet. |
| `updated_at`        | string  | Date et heure auxquelles le snippet a été mis à jour pour la dernière fois au format ISO 8601. |
| `web_url`           | string  | URL pour afficher le snippet dans l'interface web de GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## Créer un snippet {#create-a-snippet}

Crée un snippet de projet. L'utilisateur doit avoir la permission de créer des snippets.

```plaintext
POST /projects/:id/snippets
```

Attributs pris en charge :

| Attribut         | Type              | Obligatoire | Description |
|-------------------|-------------------|----------|-------------|
| `files`           | tableau de hachages   | Oui      | Un tableau de fichiers snippet. |
| `files:content`   | string            | Oui      | Contenu du fichier snippet. |
| `files:file_path` | string            | Oui      | Chemin du fichier snippet. |
| `id`              | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `title`           | string            | Oui      | Titre d'un snippet. |
| `content`         | string            | Non       | Obsolète : Utilisez `files` à la place. Contenu d'un snippet. |
| `description`     | string            | Non       | Description d'un snippet. |
| `file_name`       | string            | Non       | Obsolète : Utilisez `files` à la place. Nom d'un fichier snippet. |
| `visibility`      | string            | Non       | Niveau de visibilité du snippet. Valeurs possibles : `public`, `private` et `internal`. Sur GitLab.com, la valeur `internal` n'est pas disponible. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date et heure auxquelles le compte de l'auteur a été créé. |
| `author.email`      | string  | Adresse e-mail de l'auteur du snippet. |
| `author.id`         | entier | ID de l'auteur du snippet. |
| `author.name`       | string  | Nom d'affichage de l'auteur du snippet. |
| `author.state`      | string  | État du compte de l'auteur. |
| `author.username`   | string  | Nom d'utilisateur de l'auteur du snippet. |
| `created_at`        | string  | Date et heure auxquelles le snippet a été créé au format ISO 8601. |
| `description`       | string  | Description du snippet. |
| `file_name`         | string  | Nom du fichier snippet. |
| `id`                | entier | ID du snippet. |
| `imported`          | boolean | Si `true`, le snippet a été importé. |
| `imported_from`     | string  | Source de l'importation si le snippet a été importé. |
| `project_id`        | entier | ID du projet contenant le snippet. |
| `raw_url`           | string  | URL directe vers le contenu brut du snippet. |
| `title`             | string  | Titre du snippet. |
| `updated_at`        | string  | Date et heure auxquelles le snippet a été mis à jour pour la dernière fois au format ISO 8601. |
| `web_url`           | string  | URL pour afficher le snippet dans l'interface web de GitLab. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Example Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"file_path": "example.txt", "content": "source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Example Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/1",
  "raw_url": "http://example.com/example/example/snippets/1/raw"
}
```

## Mettre à jour un snippet {#update-a-snippet}

Met à jour un snippet de projet spécifié. L'utilisateur doit avoir la permission de modifier les snippets existants.

Les mises à jour de snippets comportant plusieurs fichiers doivent utiliser l'attribut `files`.

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

Attributs pris en charge :

| Attribut             | Type              | Obligatoire      | Description |
| --------------------- | ----------------- | ------------- | ----------- |
| `id`                  | entier ou chaîne | Oui           | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id`          | entier           | Oui           | ID du snippet d'un projet. |
| `files:action`        | string            | Conditionnellement | Type d'action à effectuer sur le fichier. L'une des valeurs suivantes : `create`, `update`, `delete`, `move`. Requis lors de l'utilisation de l'attribut `files`. |
| `content`             | string            | Non            | Obsolète : Utilisez `files` à la place. Contenu d'un snippet. |
| `description`         | string            | Non            | Description d'un snippet. |
| `file_name`           | string            | Non            | Obsolète : Utilisez `files` à la place. Nom d'un fichier snippet. |
| `files`               | tableau de hachages   | Non            | Un tableau de fichiers snippet. |
| `files:content`       | string            | Non            | Contenu du fichier snippet. |
| `files:file_path`     | string            | Non            | Chemin du fichier snippet. |
| `files:previous_path` | string            | Non            | Chemin précédent du fichier snippet. |
| `title`               | string            | Non            | Titre d'un snippet. |
| `visibility`      | string            | Non       | Niveau de visibilité du snippet. Valeurs possibles : `public`, `private` et `internal`. Sur GitLab.com, la valeur `internal` n'est pas disponible. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date et heure auxquelles le compte de l'auteur a été créé. |
| `author.email`      | string  | Adresse e-mail de l'auteur du snippet. |
| `author.id`         | entier | ID de l'auteur du snippet. |
| `author.name`       | string  | Nom d'affichage de l'auteur du snippet. |
| `author.state`      | string  | État du compte de l'auteur. |
| `author.username`   | string  | Nom d'utilisateur de l'auteur du snippet. |
| `created_at`        | string  | Date et heure auxquelles le snippet a été créé au format ISO 8601. |
| `description`       | string  | Description du snippet. |
| `file_name`         | string  | Nom du fichier snippet. |
| `id`                | entier | ID du snippet. |
| `imported`          | boolean | Si `true`, le snippet a été importé. |
| `imported_from`     | string  | Source de l'importation si le snippet a été importé. |
| `project_id`        | entier | ID du projet contenant le snippet. |
| `raw_url`           | string  | URL directe vers le contenu brut du snippet. |
| `title`             | string  | Titre du snippet. |
| `updated_at`        | string  | Date et heure auxquelles le snippet a été mis à jour pour la dernière fois au format ISO 8601. |
| `web_url`           | string  | URL pour afficher le snippet dans l'interface web de GitLab. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Updated Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"action": "update", "file_path": "example.txt", "content": "updated source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "Updated Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## Supprimer un snippet {#delete-a-snippet}

Supprime un snippet de projet spécifié. Renvoie un code de statut `204 No Content` si l'opération a réussi ou `404` si la ressource est introuvable.

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id` | entier           | Oui      | ID du snippet d'un projet. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

## Récupérer le contenu d'un snippet {#retrieve-snippet-content}

Récupère le snippet de projet brut sous forme de texte brut.

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id` | entier           | Oui      | ID du snippet d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/raw"
```

## Récupérer le contenu d'un fichier du dépôt de snippet {#retrieve-snippet-repository-file-content}

Récupère le contenu brut du fichier sous forme de texte brut.

```plaintext
GET /projects/:id/snippets/:snippet_id/files/:ref/:file_path/raw
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `file_path`  | string            | Oui      | Chemin encodé URL du fichier, par exemple `snippet%2Erb`. |
| `ref`        | string            | Oui      | Nom d'une branche, d'un tag ou d'un commit, par exemple `main`. |
| `snippet_id` | entier           | Oui      | ID du snippet d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/files/master/snippet%2Erb/raw"
```

## Récupérer les détails de l'agent utilisateur {#retrieve-user-agent-details}

Récupère les détails de l'agent utilisateur pour un snippet spécifié. Disponible uniquement pour les utilisateurs disposant d'un accès administrateur.

```plaintext
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id` | entier           | Oui      | ID d'un snippet. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `akismet_submitted` | boolean | Si `true`, le snippet a été soumis à Akismet pour la détection de spam. |
| `ip_address`        | string  | Adresse IP de l'utilisateur qui a créé le snippet. |
| `user_agent`        | string  | Chaîne d'agent utilisateur du navigateur utilisé pour créer le snippet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail"
```

Exemple de réponse :

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```
