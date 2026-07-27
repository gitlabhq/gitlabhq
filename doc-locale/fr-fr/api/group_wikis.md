---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des wikis de groupe
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [wikis de groupe](../user/project/wiki/group.md). Une API pour les [wikis de projet](wikis.md) est également disponible.

Les commentaires sur une page wiki sont appelés `notes`. Pour interagir avec eux, utilisez l'[API des notes](notes.md#group-wikis).

## Lister les pages wiki {#list-wiki-pages}

Liste toutes les pages wiki pour un groupe spécifié.

```plaintext
GET /groups/:id/wikis
```

| Attribut      | Type           | Obligatoire | Description |
| -------------- | -------------- | -------- | ----------- |
| `id`           | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `with_content` | boolean        | Non       | Inclure le contenu des pages. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/wikis?with_content=1"
```

Exemple de réponse :

```json
[
  {
    "content" : "Here is an instruction how to deploy this project.",
    "format" : "markdown",
    "slug" : "deploy",
    "title" : "deploy",
    "encoding": "UTF-8"
  },
  {
    "content" : "Our development process is described here.",
    "format" : "markdown",
    "slug" : "development",
    "title" : "development",
    "encoding": "UTF-8"
  },{
    "content" : "*  [Deploy](deploy)\n*  [Development](development)",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home",
    "encoding": "UTF-8"
  }
]
```

## Récupérer une page wiki {#retrieve-a-wiki-page}

Récupère une page wiki pour un groupe spécifié.

```plaintext
GET /groups/:id/wikis/:slug
```

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `slug`        | string         | Oui      | Slug encodé en URL (une chaîne unique) de la page wiki, tel que `dir%2Fpage_name`. |
| `render_html` | boolean        | Non       | Retourner le HTML rendu de la page wiki. |
| `version`     | string         | Non       | SHA de la version de la page wiki. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/wikis/home"
```

Exemple de réponse :

```json
{
  "content" : "home page",
  "format" : "markdown",
  "slug" : "home",
  "title" : "home",
  "encoding": "UTF-8"
}
```

## Créer une page wiki {#create-a-wiki-page}

Crée une page wiki pour un projet spécifique avec le titre, le slug et le contenu donnés.

```plaintext
POST /projects/:id/wikis
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `content` | string         | Oui      | Le contenu de la page wiki. |
| `title`   | string         | Oui      | Le titre de la page wiki. |
| `format`  | string         | Non       | Le format de la page wiki. Les formats disponibles sont : `markdown` (par défaut), `rdoc`, `asciidoc` et `org`. |

```shell
curl --request POST \
     --data "format=rdoc&title=Hello&content=Hello world" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/1/wikis"
```

Exemple de réponse :

```json
{
  "content" : "Hello world",
  "format" : "markdown",
  "slug" : "Hello",
  "title" : "Hello",
  "encoding": "UTF-8"
}
```

## Mettre à jour une page wiki {#update-a-wiki-page}

Met à jour une page wiki. Au moins un paramètre est requis pour mettre à jour la page wiki.

```plaintext
PUT /groups/:id/wikis/:slug
```

| Attribut | Type           | Obligatoire                           | Description |
| --------- | -------------- | ---------------------------------- | ----------- |
| `id`      | entier ou chaîne de caractères | Oui                                | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `content` | string         | Oui, si `title` n'est pas fourni   | Le contenu de la page wiki. |
| `title`   | string         | Oui, si `content` n'est pas fourni | Le titre de la page wiki. |
| `format`  | string         | Non                                 | Le format de la page wiki. Les formats disponibles sont `markdown` (par défaut), `rdoc`, `asciidoc` et `org`. |
| `slug`    | string         | Oui                                | Slug encodé en URL (une chaîne unique) de la page wiki. Par exemple : `dir%2Fpage_name`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/wikis/foo" \
  --data "format=rdoc" \
  --data "title=Docs" \
  --data "content=documentation"
```

Exemple de réponse :

```json
{
  "content" : "documentation",
  "format" : "markdown",
  "slug" : "Docs",
  "title" : "Docs",
  "encoding": "UTF-8"
}
```

## Supprimer une page wiki {#delete-a-wiki-page}

Supprime une page wiki d'un projet spécifique avec un slug spécifié.

```plaintext
DELETE /groups/:id/wikis/:slug
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `slug`    | string         | Oui      | Slug encodé en URL (une chaîne unique) de la page wiki, tel que `dir%2Fpage_name`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/wikis/foo"
```

En cas de succès, une réponse HTTP `204 No Content` avec un corps vide est attendue.

## Charger une pièce jointe dans le dépôt wiki {#upload-an-attachment-to-the-wiki-repository}

Charge un fichier dans le dossier des pièces jointes à l'intérieur du dépôt du wiki pour un projet spécifique. Le dossier des pièces jointes est le dossier `uploads`.

```plaintext
POST /groups/:id/wikis/attachments
```

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `file`        | string         | Oui      | La pièce jointe à charger. |
| `branch`      | string         | Non       | Le nom de la branche. Par défaut, la branche par défaut du dépôt wiki. |

Pour charger un fichier depuis votre système de fichiers, utilisez l'argument `--form`. Cela oblige cURL à envoyer des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/wikis/attachments" \
  --form "file=@dk.png"
```

Exemple de réponse :

```json
{
  "file_name" : "dk.png",
  "file_path" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
  "branch" : "main",
  "link" : {
    "url" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
    "markdown" : "![dk](uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png)"
  }
}
```
