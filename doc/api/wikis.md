# Wikis API

> [Introduced][ce-13372] in GitLab 10.0.

Available only in APIv4.

## List wiki pages

Get all wiki pages for a given project.

```
GET /projects/:id/wikis
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `with_content`      | boolean    | no      | Include pages' content  |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/wikis?with_content=1
```

Example response:

```json
[
  {
    "content" : "Here is an instruction how to deploy this project.",
    "format" : "markdown",
    "slug" : "deploy",
    "title" : "deploy"
  },
  {
    "content" : "Our development process is described here.",
    "format" : "markdown",
    "slug" : "development",
    "title" : "development"
  },{
    "content" : "*  [Deploy](deploy)\n*  [Development](development)",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home"
  }
]
```

## Get a wiki page

Get a wiki page for a given project.

```
GET /projects/:id/wikis/:slug
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `slug` | string  | yes       | The slug (a unique string) of the wiki page |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/wikis/home
```

Example response:

```json
[
  {
    "content" : "home page",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home"
  }
]
```

## Create a new wiki page

Creates a new wiki page for the given repository with the given title, slug, and content.

```
POST /projects/:id/wikis
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `content`       | string  | yes      | The content of the wiki page |
| `title`        | string  | yes      | The title of the wiki page        |
| `format` | string  | no       | The format of the wiki page. Available formats are: `markdown` (default), `rdoc`, and `asciidoc` |

```bash
curl --data "format=rdoc&title=Hello&content=Hello world" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/wikis"
```

Example response:

```json
{
  "content" : "Hello world",
  "format" : "markdown",
  "slug" : "Hello",
  "title" : "Hello"
}
```

## Edit an existing wiki page

Updates an existing wiki page. At least one parameter is required to update the wiki page.

```
PUT /projects/:id/wikis/:slug
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `content`       | string  | yes if `title` is not provided     | The content of the wiki page |
| `title`        | string  | yes if `content` is not provided      | The title of the wiki page        |
| `format` | string  | no       | The format of the wiki page. Available formats are: `markdown` (default), `rdoc`, and `asciidoc` |
| `slug` | string  | yes       | The slug (a unique string) of the wiki page |


```bash
curl --request PUT --data "format=rdoc&content=documentation&title=Docs" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

Example response:

```json
{
  "content" : "documentation",
  "format" : "markdown",
  "slug" : "Docs",
  "title" : "Docs"
}
```

## Delete a wiki page

Deletes a wiki page with a given slug.

```
DELETE /projects/:id/wikis/:slug
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `slug` | string  | yes       | The slug (a unique string) of the wiki page |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

On success the HTTP status code is `204` and no JSON response is expected.

[ce-13372]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13372

## Upload an attachment to the wiki repository

Uploads a file to the attachment folder inside the wiki's repository. The
 attachment folder is the `uploads` folder.

```
POST /projects/:id/wikis/attachments
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `file` | string | yes | The attachment to be uploaded |
| `branch` | string | no | The name of the branch. Defaults to the wiki repository default branch |

To upload a file from your filesystem, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your filesystem and be preceded
by `@`. For example:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "file=@dk.png" https://gitlab.example.com/api/v4/projects/1/wikis/attachments
```

Example response:

```json
{
  "file_name" : "dk.png",
  "file_path" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
  "branch" : "master",
  "link" : {
    "url" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
    "markdown" : "![dk](uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png)"
  }
}
```
