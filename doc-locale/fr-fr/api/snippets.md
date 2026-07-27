---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Snippets
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [snippets](../user/snippets.md). Des API connexes existent pour les [snippets de projet](project_snippets.md) et le [déplacement de snippets entre stockages](snippet_repository_storage_moves.md).

## Répertorier tous les snippets de l'utilisateur actuel {#list-all-snippets-for-current-user}

Obtenez la liste des snippets de l'utilisateur actuel.

```plaintext
GET /snippets
```

Attributs pris en charge :

| Attribut        | Type     | Obligatoire | Description |
|------------------|----------|----------|-------------|
| `created_after`  | datetime | Non       | Renvoie les snippets créés après l'heure indiquée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime | Non       | Renvoie les snippets créés avant l'heure indiquée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `page`           | integer  | Non       | Page à récupérer. |
| `per_page`       | integer  | Non       | Nombre de snippets à renvoyer par page. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut       | Type    | Description |
|-----------------|---------|-------------|
| `author`        | objet  | Objet utilisateur représentant l'auteur du snippet. |
| `created_at`    | string  | Date et heure de création du snippet. |
| `description`   | string  | Description du snippet. |
| `file_name`     | string  | Nom du fichier du snippet. |
| `id`            | integer | ID du snippet. |
| `imported`      | boolean | Si `true`, le snippet a été importé. |
| `imported_from` | string  | Source de l'import. |
| `project_id`    | integer | ID du projet associé. Pour les snippets personnels, `null`. |
| `raw_url`       | string  | URL vers le contenu brut du snippet. |
| `title`         | string  | Titre du snippet. |
| `updated_at`    | string  | Date et heure de la dernière mise à jour du snippet. |
| `visibility`    | string  | Niveau de visibilité du snippet. |
| `web_url`       | string  | URL vers le snippet dans l'interface GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets"
```

Exemple de réponse :

```json
[
    {
        "id": 42,
        "title": "Voluptatem iure ut qui aut et consequatur quaerat.",
        "file_name": "mclaughlin.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.383Z",
        "created_at": "2018-09-18T01:12:26.383Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/42",
        "raw_url": "http://example.com/snippets/42/raw"
    },
    {
        "id": 41,
        "title": "Ut praesentium non et atque.",
        "file_name": "ondrickaemard.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.360Z",
        "created_at": "2018-09-18T01:12:26.360Z",
        "project_id": 1,
        "web_url": "http://example.com/gitlab-org/gitlab-test/snippets/41",
        "raw_url": "http://example.com/gitlab-org/gitlab-test/snippets/41/raw"
    }
]
```

## Récupérer un snippet {#retrieve-a-snippet}

Récupère un snippet spécifié.

```plaintext
GET /snippets/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                |
|-----------|---------|----------|----------------------------|
| `id`      | integer | Oui      | ID du snippet à récupérer. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut          | Type    | Description |
|--------------------|---------|-------------|
| `author`           | objet  | Objet utilisateur représentant l'auteur du snippet. |
| `created_at`       | string  | Date et heure de création du snippet. |
| `description`      | string  | Description du snippet. |
| `expires_at`       | string  | Date et heure d'expiration du snippet. |
| `file_name`        | string  | Nom du fichier du snippet. |
| `http_url_to_repo` | string  | URL HTTP vers le dépôt du snippet. |
| `id`               | integer | ID du snippet. |
| `imported`         | boolean | Si `true`, le snippet a été importé. |
| `imported_from`    | string  | Source de l'import. |
| `project_id`       | integer | ID du projet associé. Pour les snippets personnels, `null`. |
| `raw_url`          | string  | URL vers le contenu brut du snippet. |
| `ssh_url_to_repo`  | string  | URL SSH vers le dépôt du snippet. |
| `title`            | string  | Titre du snippet. |
| `updated_at`       | string  | Date et heure de la dernière mise à jour du snippet. |
| `visibility`       | string  | Niveau de visibilité du snippet. |
| `web_url`          | string  | URL vers le snippet dans l'interface GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "visibility": "private",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw"
}
```

## Contenu d'un snippet unique {#single-snippet-contents}

Obtenez le contenu brut d'un snippet unique.

```plaintext
GET /snippets/:id/raw
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                |
|-----------|---------|----------|----------------------------|
| `id`      | integer | Oui      | ID du snippet à récupérer. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et le contenu brut du snippet.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/raw"
```

Exemple de réponse :

```plaintext
Hello World snippet
```

## Contenu du fichier du dépôt du snippet {#snippet-repository-file-content}

Renvoie le contenu brut du fichier sous forme de texte brut.

```plaintext
GET /snippets/:id/files/:ref/:file_path/raw
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description |
|-------------|---------|----------|-------------|
| `file_path` | string  | Oui      | Chemin encodé en URL vers le fichier. |
| `id`        | integer | Oui      | ID du snippet à récupérer. |
| `ref`       | string  | Oui      | Référence à un tag, une branche ou un commit. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et le contenu brut du fichier.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/files/main/snippet%2Erb/raw"
```

Exemple de réponse :

```plaintext
Hello World snippet
```

## Créer un snippet {#create-a-snippet}

Crée un nouveau snippet.

> [!note]
> L'utilisateur doit avoir la permission de créer de nouveaux snippets.

```plaintext
POST /snippets
```

Attributs pris en charge :

| Attribut         | Type            | Obligatoire | Description |
| ----------------- | --------------- | -------- | ----------- |
| `files:content`   | string          | Oui      | Contenu du fichier du snippet. |
| `files:file_path` | string          | Oui      | Chemin de fichier du snippet. |
| `title`           | string          | Oui      | Titre d'un snippet. |
| `content`         | string          | Non       | Déprécié : Utilisez plutôt `files`. Contenu d'un snippet. |
| `description`     | string          | Non       | Description d'un snippet. |
| `file_name`       | string          | Non       | Déprécié : Utilisez plutôt `files`. Nom d'un fichier de snippet. |
| `files`           | array of hashes | Non       | Un tableau de fichiers de snippet. |
| `visibility`      | string          | Non       | Niveau de visibilité du snippet. Valeurs possibles : `public`, `private` et `internal`. Sur GitLab.com, la valeur `internal` n'est pas disponible. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut          | Type    | Description |
|--------------------|---------|-------------|
| `author`           | objet  | Objet utilisateur représentant l'auteur du snippet. |
| `created_at`       | string  | Date et heure de création du snippet. |
| `description`      | string  | Description du snippet. |
| `expires_at`       | string  | Date et heure d'expiration du snippet. |
| `file_name`        | string  | Nom du fichier du snippet. |
| `files`            | array   | Tableau de fichiers de snippet. |
| `http_url_to_repo` | string  | URL HTTP vers le dépôt du snippet. |
| `id`               | integer | ID du snippet. |
| `imported`         | boolean | Si `true`, le snippet a été importé. |
| `imported_from`    | string  | Source de l'import. |
| `project_id`       | integer | ID du projet associé. Pour les snippets personnels, `null`. |
| `raw_url`          | string  | URL vers le contenu brut du snippet. |
| `ssh_url_to_repo`  | string  | URL SSH vers le dépôt du snippet. |
| `title`            | string  | Titre du snippet. |
| `updated_at`       | string  | Date et heure de la dernière mise à jour du snippet. |
| `visibility`       | string  | Niveau de visibilité du snippet. |
| `web_url`          | string  | URL vers le snippet dans l'interface GitLab. |

Exemple de requête :

```shell
curl --request POST "https://gitlab.example.com/api/v4/snippets" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json` utilisé dans l'exemple de requête précédent :

```json
{
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "files": [
    {
      "content": "Hello world",
      "file_path": "test.txt"
    }
  ]
}
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "test.txt",
  "files": [
    {
      "path": "text.txt",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## Mettre à jour un snippet {#update-snippet}

Met à jour un snippet existant.

> [!note]
> L'utilisateur doit avoir la permission de modifier un snippet existant.

```plaintext
PUT /snippets/:id
```

Attributs pris en charge :

| Attribut             | Type            | Obligatoire      | Description |
| --------------------- | --------------- | ------------- | ----------- |
| `id`                  | integer         | Oui           | ID du snippet à mettre à jour. |
| `files:action`        | string          | Oui           | Type d'action à effectuer sur le fichier, parmi : `create`, `update`, `delete`, `move`. |
| `content`             | string          | Non            | Déprécié : Utilisez plutôt `files`. Contenu d'un snippet. |
| `description`         | string          | Non            | Description d'un snippet. |
| `file_name`           | string          | Non            | Déprécié : Utilisez plutôt `files`. Nom d'un fichier de snippet. |
| `files`               | array of hashes | Conditionnellement | Un tableau de fichiers de snippet. Obligatoire lors de la mise à jour de snippets avec plusieurs fichiers. |
| `files:content`       | string          | Non            | Contenu du fichier du snippet. |
| `files:file_path`     | string          | Non            | Chemin de fichier du snippet. |
| `files:previous_path` | string          | Non            | Chemin précédent du fichier du snippet. |
| `title`               | string          | Non            | Titre d'un snippet. |
| `visibility`          | string          | Non            | Niveau de visibilité du snippet. Valeurs possibles : `public`, `private` et `internal`. Sur GitLab.com, la valeur `internal` n'est pas disponible. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut          | Type    | Description |
|--------------------|---------|-------------|
| `author`           | objet  | Objet utilisateur représentant l'auteur du snippet. |
| `created_at`       | string  | Date et heure de création du snippet. |
| `description`      | string  | Description du snippet. |
| `expires_at`       | string  | Date et heure d'expiration du snippet. |
| `file_name`        | string  | Nom du fichier du snippet. |
| `files`            | array   | Tableau de fichiers de snippet. |
| `http_url_to_repo` | string  | URL HTTP vers le dépôt du snippet. |
| `id`               | integer | ID du snippet. |
| `imported`         | boolean | Si `true`, le snippet a été importé. |
| `imported_from`    | string  | Source de l'import. |
| `project_id`       | integer | ID du projet associé. Pour les snippets personnels, `null`. |
| `raw_url`          | string  | URL vers le contenu brut du snippet. |
| `ssh_url_to_repo`  | string  | URL SSH vers le dépôt du snippet. |
| `title`            | string  | Titre du snippet. |
| `updated_at`       | string  | Date et heure de la dernière mise à jour du snippet. |
| `visibility`       | string  | Niveau de visibilité du snippet. |
| `web_url`          | string  | URL vers le snippet dans l'interface GitLab. |

Exemple de requête :

```shell
curl --request PUT "https://gitlab.example.com/api/v4/snippets/1" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json` utilisé dans l'exemple de requête précédent :

```json
{
  "title": "foo",
  "files": [
    {
      "action": "move",
      "previous_path": "test.txt",
      "file_path": "renamed.md"
    }
  ]
}
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "test",
  "description": "description of snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "renamed.md",
  "files": [
    {
      "path": "renamed.md",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## Supprimer un snippet {#delete-snippet}

Supprime un snippet existant.

```plaintext
DELETE /snippets/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description              |
|-----------|---------|----------|--------------------------|
| `id`      | integer | Oui      | ID du snippet à supprimer. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

Les codes de retour possibles sont les suivants :

| Code  | Description |
|-------|-------------|
| `204` | La suppression a réussi. Aucune donnée n'est renvoyée. |
| `404` | Le snippet est introuvable. |

## Répertorier tous les snippets publics {#list-all-public-snippets}

Répertorie tous les snippets publics.

```plaintext
GET /snippets/public
```

Attributs pris en charge :

| Attribut        | Type     | Obligatoire | Description |
|------------------|----------|----------|-------------|
| `created_after`  | datetime | Non       | Renvoie les snippets créés après l'heure indiquée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime | Non       | Renvoie les snippets créés avant l'heure indiquée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `page`           | integer  | Non       | Page à récupérer. |
| `per_page`       | integer  | Non       | Nombre de snippets à renvoyer par page. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut     | Type    | Description |
|---------------|---------|-------------|
| `author`      | objet  | Objet utilisateur représentant l'auteur du snippet. |
| `created_at`  | string  | Date et heure de création du snippet. |
| `description` | string  | Description du snippet. |
| `file_name`   | string  | Nom du fichier du snippet. |
| `id`          | integer | ID du snippet. |
| `project_id`  | integer | ID du projet associé. Pour les snippets personnels, `null`. |
| `raw_url`     | string  | URL vers le contenu brut du snippet. |
| `title`       | string  | Titre du snippet. |
| `updated_at`  | string  | Date et heure de la dernière mise à jour du snippet. |
| `visibility`  | string  | Niveau de visibilité du snippet. |
| `web_url`     | string  | URL vers le snippet dans l'interface GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/public?per_page=2&page=1"
```

Exemple de réponse :

```json
[
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
            "id": 12,
            "name": "Libby Rolfson",
            "state": "active",
            "username": "elton_wehner",
            "web_url": "http://example.com/elton_wehner"
        },
        "created_at": "2016-11-25T16:53:34.504Z",
        "file_name": "oconnerrice.rb",
        "id": 49,
        "title": "Ratione cupiditate et laborum temporibus.",
        "updated_at": "2016-11-25T16:53:34.504Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/49",
        "raw_url": "http://example.com/snippets/49/raw"
    },
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/36583b28626de71061e6e5a77972c3bd?s=80&d=identicon",
            "id": 16,
            "name": "Llewellyn Flatley",
            "state": "active",
            "username": "adaline",
            "web_url": "http://example.com/adaline"
        },
        "created_at": "2016-11-25T16:53:34.479Z",
        "file_name": "muellershields.rb",
        "id": 48,
        "title": "Minus similique nesciunt vel fugiat qui ullam sunt.",
        "updated_at": "2016-11-25T16:53:34.479Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/48",
        "raw_url": "http://example.com/snippets/49/raw",
        "visibility": "public"
    }
]
```

## Répertorier tous les snippets {#list-all-snippets}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419640) dans GitLab 16.3.

{{< /history >}}

Répertorie tous les snippets auxquels l'utilisateur actuel a accès. Les utilisateurs avec les niveaux d'accès Administrateur ou Auditeur peuvent voir tous les snippets (personnels et de projet).

```plaintext
GET /snippets/all
```

Attributs pris en charge :

| Attribut            | Type     | Obligatoire | Description |
|----------------------|----------|----------|-------------|
| `created_after`      | datetime | Non       | Renvoie les snippets créés après l'heure indiquée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`     | datetime | Non       | Renvoie les snippets créés avant l'heure indiquée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `page`               | integer  | Non       | Page à récupérer. |
| `per_page`           | integer  | Non       | Nombre de snippets à renvoyer par page. |
| `repository_storage` | string   | Non       | Filtrer par stockage de dépôt utilisé par le snippet _(administrateurs uniquement)_. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419640) dans GitLab 16.3. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut            | Type    | Description |
|----------------------|---------|-------------|
| `author`             | objet  | Objet utilisateur représentant l'auteur du snippet. |
| `created_at`         | string  | Date et heure de création du snippet. |
| `description`        | string  | Description du snippet. |
| `file_name`          | string  | Nom du fichier du snippet. |
| `files`              | array   | Tableau de fichiers de snippet. |
| `id`                 | integer | ID du snippet. |
| `imported`           | boolean | Si `true`, le snippet a été importé. |
| `imported_from`      | string  | Source de l'import. |
| `project_id`         | integer | ID du projet associé. Pour les snippets personnels, `null`. |
| `raw_url`            | string  | URL vers le contenu brut du snippet. |
| `repository_storage` | string  | Stockage de dépôt utilisé par le snippet. |
| `title`              | string  | Titre du snippet. |
| `updated_at`         | string  | Date et heure de la dernière mise à jour du snippet. |
| `visibility`         | string  | Niveau de visibilité du snippet. |
| `web_url`            | string  | URL vers le snippet dans l'interface GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/all?per_page=2&page=1"
```

Exemple de réponse :

```json
[
  {
    "id": 113,
    "title": "Internal Project Snippet",
    "description": null,
    "visibility": "internal",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:02.480Z",
    "updated_at": "2023-08-03T10:21:02.480Z",
    "project_id": 35,
    "web_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113",
    "raw_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 112,
    "title": "Private Personal Snippet",
    "description": null,
    "visibility": "private",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "created_at": "2023-08-03T10:20:59.994Z",
    "updated_at": "2023-08-03T10:20:59.994Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/112",
    "raw_url": "http://example.com/-/snippets/112/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 111,
    "title": "Public Personal Snippet",
    "description": null,
    "visibility": "public",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:01.312Z",
    "updated_at": "2023-08-03T10:21:01.312Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/111",
    "raw_url": "http://example.com/-/snippets/111/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  }
]
```

## Obtenir les détails de l'agent utilisateur {#get-user-agent-details}

> [!note]
> Disponible uniquement pour les administrateurs.

```plaintext
GET /snippets/:id/user_agent_detail
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description    |
|-----------|---------|----------|----------------|
| `id`      | integer | Oui      | ID du snippet. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `akismet_submitted` | boolean | Si `true`, les détails ont été soumis à Akismet. |
| `ip_address`        | string  | Adresse IP utilisée pour créer le snippet. |
| `user_agent`        | string  | Chaîne d'agent utilisateur utilisée pour créer le snippet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/user_agent_detail"
```

Exemple de réponse :

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```
