---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "Writing styles, markup, formatting, and other standards for the GitLab RESTful APIs."
---

# RESTful API

REST API resources are documented in Markdown under
[`/doc/api`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/api). Each
resource has its own Markdown file, which is linked from `api_resources.md`.

When modifying the Markdown, also update the corresponding
[OpenAPI definition](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/api/openapi)
if one exists for the resource. If not, consider creating one. Match the latest
[OpenAPI 3.0.x specification](https://swagger.io/specification/). (For more
information, see the discussion in this
[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/16023#note_370901810).)

In the Markdown doc for a resource (AKA endpoint):

- Every method must have the REST API request. For example:

  ```plaintext
  GET /projects/:id/repository/branches
  ```

- Every method must have a detailed [description of the parameters](#method-description).
- Every method must have a cURL example.
- Every method must have a response body (in JSON format).

## API topic template

Use the following template to help you get started. Be sure to list any
required attributes first in the table.

````markdown
## Descriptive title

> Version history note.

One or two sentence description of what endpoint does.

```plaintext
METHOD /endpoint
```

Supported attributes:

| Attribute   | Type     | Required | Description           |
|:------------|:---------|:---------|:----------------------|
| `attribute` | datatype | **{check-circle}** Yes | Detailed description. |
| `attribute` | datatype | **{dotted-circle}** No | Detailed description. |
| `attribute` | datatype | **{dotted-circle}** No | Detailed description. |
| `attribute` | datatype | **{dotted-circle}** No | Detailed description. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/endpoint?parameters"
```

Example response:

```json
[
  {
  }
]
```
````

Adjust the [version history note accordingly](styleguide/index.md#version-text-in-the-version-history)
to describe the GitLab release that introduced the API call.

## Method description

Use the following table headers to describe the methods. Attributes should
always be in code blocks using backticks (`` ` ``).

```markdown
| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
```

Rendered example:

| Attribute | Type   | Required | Description         |
|:----------|:-------|:---------|:--------------------|
| `user`    | string | yes      | The GitLab username. |

## cURL commands

- Use `https://gitlab.example.com/api/v4/` as an endpoint.
- Wherever needed use this personal access token: `<your_access_token>`.
- Always put the request first. `GET` is the default so you don't have to
  include it.
- Wrap the URL in double quotes (`"`).
- Prefer to use examples using the personal access token and don't pass data of
  username and password.

| Methods                                         | Description                                           |
|:-------------------------------------------     |:------------------------------------------------------|
| `--header "PRIVATE-TOKEN: <your_access_token>"` | Use this method as is, whenever authentication needed. |
| `--request POST`                                | Use this method when creating new objects             |
| `--request PUT`                                 | Use this method when updating existing objects        |
| `--request DELETE`                              | Use this method when removing existing objects        |

## cURL Examples

The following sections include a set of [cURL](https://curl.se/) examples
you can use in the API documentation.

WARNING:
Do not use information for real users, URLs, or tokens. For documentation, refer to our
relevant style guide sections on [Fake user information](styleguide/index.md#fake-user-information),
[Fake URLs](styleguide/index.md#fake-urls), and [Fake tokens](styleguide/index.md#fake-tokens).

### Simple cURL command

Get the details of a group:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/gitlab-org"
```

### cURL example with parameters passed in the URL

Create a new project under the authenticated user's namespace:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?name=foo"
```

### Post data using cURL's `--data`

Instead of using `--request POST` and appending the parameters to the URI, you
can use cURL's `--data` option. The example below will create a new project
`foo` under the authenticated user's namespace.

```shell
curl --data "name=foo" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

### Post data using JSON content

This example creates a new group. Be aware of the use of single (`'`) and double
(`"`) quotes.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"path": "my-group", "name": "My group"}' "https://gitlab.example.com/api/v4/groups"
```

For readability, you can also set up the `--data` by using the following format:

```shell
curl --request POST \
--url "https://gitlab.example.com/api/v4/groups" \
--header "content-type: application/json" \
--header "PRIVATE-TOKEN: <your_access_token>" \
--data '{
  "path": "my-group",
  "name": "My group"
}'
```

### Post data using form-data

Instead of using JSON or URL-encoding data, you can use `multipart/form-data` which
properly handles data encoding:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "title=ssh-key" \
     --form "key=ssh-rsa AAAAB3NzaC1yc2EA..." "https://gitlab.example.com/api/v4/users/25/keys"
```

The above example is run by and administrator and will add an SSH public key
titled `ssh-key` to user's account which has an ID of 25.

### Escape special characters

Spaces or slashes (`/`) may sometimes result to errors, thus it is recommended
to escape them when possible. In the example below we create a new issue which
contains spaces in its title. Observe how spaces are escaped using the `%20`
ASCII code.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/issues?title=Hello%20Dude"
```

Use `%2F` for slashes (`/`).

### Pass arrays to API calls

The GitLab API sometimes accepts arrays of strings or integers. For example, to
exclude specific users when requesting a list of users for a project, you would
do something like this:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "skip_users[]=<user_id>" \
     --data "skip_users[]=<user_id>" "https://gitlab.example.com/api/v4/projects/<project_id>/users"
```
