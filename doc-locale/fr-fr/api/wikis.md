---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des wikis de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [wikis de projet](../user/project/wiki/_index.md). Une API pour les [wikis de groupe](group_wikis.md) est également disponible.

Les commentaires sur une page wiki sont appelés `notes`. Pour interagir avec eux, utilisez l'[API des notes](notes.md#project-wikis).

## Lister toutes les pages wiki {#list-all-wiki-pages}

Liste toutes les pages wiki d'un projet spécifié.

```plaintext
GET /projects/:id/wikis
```

| Attribut      | Type           | Obligatoire | Description |
| -------------- | -------------- | -------- | ----------- |
| `id`           | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `with_content` | boolean        | Non       | Inclure le contenu des pages. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis?with_content=1"
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
  },
  {
    "content" : "*  [Deploy](deploy)\n*  [Development](development)",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home",
    "encoding": "UTF-8"
  }
]
```

## Récupérer une page wiki {#retrieve-a-wiki-page}

Récupère une page wiki spécifiée pour un projet.

```plaintext
GET /projects/:id/wikis/:slug
```

| Attribut     | Type           | Obligatoire | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `slug`        | string         | Oui      | Slug encodé en URL (une chaîne unique) de la page wiki, tel que `dir%2Fpage_name`. |
| `render_html` | boolean        | Non       | Renvoie le HTML rendu de la page wiki. |
| `version`     | string         | Non       | SHA de version de la page wiki. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/home"
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

Crée une page wiki pour un projet spécifié avec le titre, le slug et le contenu indiqués.

```plaintext
POST /projects/:id/wikis
```

| Attribut | Type           | Obligatoire | Description |
| ----------| -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `content` | string         | Oui      | Le contenu de la page wiki. |
| `title`   | string         | Oui      | Le titre de la page wiki. |
| `format`  | string         | Non       | Le format de la page wiki. Les formats disponibles sont : `markdown` (par défaut), `rdoc`, `asciidoc` et `org`. |

```shell
curl --data "format=rdoc&title=Hello&content=Hello world" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis"
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

Pour le contenu Markdown avec des caractères spéciaux et des diagrammes, utilisez `--data-urlencode` avec une référence de fichier pour gérer l'encodage automatiquement.

Par exemple, créez un fichier nommé `content.md` avec le contenu de votre wiki, puis exécutez :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "title=Page with Complex Content" \
  --data-urlencode "content@content.md" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis"
```

L'option `--data-urlencode "content@content.md"` encode en URL le contenu du fichier Markdown et l'affecte à l'attribut `content`. Cet encodage gère les caractères spéciaux, les sauts de ligne et la syntaxe Markdown complexe qui pourraient autrement provoquer des erreurs.

Exemple de réponse :

```json
{
"content": "<contents of content.md>",
"format": "markdown",
"slug": "Page-with-Complex-Content",
"title": "Page with Complex Content",
"encoding": "UTF-8"
}
```

## Mettre à jour une page wiki {#update-a-wiki-page}

Met à jour une page wiki spécifiée. Au moins un paramètre est requis pour mettre à jour la page wiki.

```plaintext
PUT /projects/:id/wikis/:slug
```

| Attribut | Type           | Obligatoire                          | Description |
| --------- | -------        | --------------------------------- | ----------- |
| `id`      | entier ou chaîne | Oui                               | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `content` | string         | Oui, si `title` n'est pas fourni   | Le contenu de la page wiki. |
| `title`   | string         | Oui, si `content` n'est pas fourni | Le titre de la page wiki. |
| `format`  | string         | Non                                | Le format de la page wiki. Les formats disponibles sont : `markdown` (par défaut), `rdoc`, `asciidoc` et `org`. |
| `slug`    | string         | Oui                               | Slug encodé en URL (une chaîne unique) de la page wiki, tel que `dir%2Fpage_name`. |

```shell
curl --request PUT \
  --data "format=rdoc&content=documentation&title=Docs" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
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

Supprime une page wiki spécifiée.

```plaintext
DELETE /projects/:id/wikis/:slug
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `slug`    | string         | Oui      | Slug encodé en URL (une chaîne unique) de la page wiki, tel que `dir%2Fpage_name`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

En cas de succès, une réponse HTTP `204 No Content` avec un corps vide est attendue.

## Téléverser une pièce jointe dans le dépôt wiki {#upload-an-attachment-to-the-wiki-repository}

Téléverse un fichier dans le dossier des pièces jointes à l'intérieur du dépôt du wiki. Le dossier des pièces jointes est le dossier `uploads`.

```plaintext
POST /projects/:id/wikis/attachments
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `file`    | string         | Oui      | La pièce jointe à téléverser. |
| `branch`  | string         | Non       | Le nom de la branche. Par défaut, la branche par défaut du dépôt wiki. |

Pour télécharger un fichier depuis votre système de fichiers, utilisez l'argument `--form`. Cela amène cURL à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@dk.png" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/attachments"
```

Exemple de réponse :

```json
{
  "file_name" : "dk.png",
  "file_path" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
  "branch" : "main",
  "link" : {
    "url" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
    "markdown" : "![A description of the attachment](uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png)"
  }
}
```
