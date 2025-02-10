---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project wikis API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The project [wikis](../user/project/wiki/_index.md) API is available only in APIv4.
An API for [group wikis](group_wikis.md) is also available.

## List wiki pages

Get all wiki pages for a given project.

```plaintext
GET /projects/:id/wikis
```

| Attribute      | Type           | Required | Description |
| -------------- | -------------- | -------- | ----------- |
| `id`           | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `with_content` | boolean        | No       | Include pages' content. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/wikis?with_content=1"
```

Example response:

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

## Get a wiki page

Get a wiki page for a given project.

```plaintext
GET /projects/:id/wikis/:slug
```

| Attribute     | Type           | Required | Description |
| ------------- | -------------- | -------- | ----------- |
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `slug`        | string         | Yes      | URL encoded slug (a unique string) of the wiki page, such as `dir%2Fpage_name`. |
| `render_html` | boolean        | No       | Return the rendered HTML of the wiki page. |
| `version`     | string         | No       | Wiki page version SHA. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/wikis/home"
```

Example response:

```json
{
  "content" : "home page",
  "format" : "markdown",
  "slug" : "home",
  "title" : "home",
  "encoding": "UTF-8"
}
```

## Create a new wiki page

Creates a new wiki page for the given repository with the given title, slug, and content.

```plaintext
POST /projects/:id/wikis
```

| Attribute | Type           | Required | Description |
| ----------| -------------- | -------- | ----------- |
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `content` | string         | Yes      | The content of the wiki page. |
| `title`   | string         | Yes      | The title of the wiki page. |
| `format`  | string         | No       | The format of the wiki page. Available formats are: `markdown` (default), `rdoc`, `asciidoc`, and `org`. |

```shell
curl --data "format=rdoc&title=Hello&content=Hello world" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/wikis"
```

Example response:

```json
{
  "content" : "Hello world",
  "format" : "markdown",
  "slug" : "Hello",
  "title" : "Hello",
  "encoding": "UTF-8"
}
```

## Edit an existing wiki page

Updates an existing wiki page. At least one parameter is required to update the wiki page.

```plaintext
PUT /projects/:id/wikis/:slug
```

| Attribute | Type           | Required                          | Description |
| --------- | -------        | --------------------------------- | ----------- |
| `id`      | integer/string | Yes                               | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `content` | string         | Yes, if `title` is not provided   | The content of the wiki page. |
| `title`   | string         | Yes, if `content` is not provided | The title of the wiki page. |
| `format`  | string         | No                                | The format of the wiki page. Available formats are: `markdown` (default), `rdoc`, `asciidoc`, and `org`. |
| `slug`    | string         | Yes                               | URL-encoded slug (a unique string) of the wiki page, such as `dir%2Fpage_name`. |

```shell
curl --request PUT --data "format=rdoc&content=documentation&title=Docs" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

Example response:

```json
{
  "content" : "documentation",
  "format" : "markdown",
  "slug" : "Docs",
  "title" : "Docs",
  "encoding": "UTF-8"
}
```

## Delete a wiki page

Deletes a wiki page with a given slug.

```plaintext
DELETE /projects/:id/wikis/:slug
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `slug`    | string         | Yes      | URL-encoded slug (a unique string) of the wiki page, such as `dir%2Fpage_name`. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

If successful, a `204 No Content` HTTP response with an empty body is expected.

## Upload an attachment to the wiki repository

Uploads a file to the attachment folder inside the wiki's repository. The
 attachment folder is the `uploads` folder.

```plaintext
POST /projects/:id/wikis/attachments
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `file`    | string         | Yes      | The attachment to be uploaded. |
| `branch`  | string         | No       | The name of the branch. Defaults to the wiki repository default branch. |

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your file system and be preceded
by `@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/1/wikis/attachments"
```

Example response:

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
