---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Suggest Changes API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [code suggestions](../user/project/merge_requests/reviews/suggestions.md).

Suggestions provide a way to propose specific changes that can be directly applied to the code.
You can programmatically create and apply code suggestions in merge request discussions with
this API. Every API call to suggestions must be authenticated.

## Create a suggestion

To create a suggestion through the API, use the Discussions API to
[create a new thread in the merge request diff](discussions.md#create-new-merge-request-thread).
The format for suggestions is:

````markdown
```suggestion:-3+0
example text
```
````

## Apply a suggestion

Applies a suggested patch in a merge request.

Prerequisites:

- Users must have at least the Developer role.

```plaintext
PUT /suggestions/:id/apply
```

Supported attributes:

| Attribute        | Type    | Required | Description |
|------------------|---------|----------|-------------|
| `id`             | integer | Yes      | ID of a suggestion. |
| `commit_message` | string  | No       | Custom commit message to use instead of the default generated message or the project's default message. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute      | Type    | Description |
|----------------|---------|-------------|
| `applicable`   | boolean | If `true`, suggestion can be applied. |
| `applied`      | boolean | If `true`, suggestion has been applied. |
| `from_content` | string  | Original content before the suggestion. |
| `from_line`    | integer | Starting line number of the suggestion. |
| `id`           | integer | ID of the suggestion. |
| `to_content`   | string  | Suggested content to replace the original. |
| `to_line`      | integer | Ending line number of the suggestion. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/suggestions/5/apply"
```

Example response:

```json
{
  "id": 5,
  "from_line": 10,
  "to_line": 10,
  "applicable": true,
  "applied": false,
  "from_content": "This is an example\n",
  "to_content": "This is an example\n"
}
```

## Apply multiple suggestions

Applies multiple suggested patches in a merge request.

Prerequisites:

- Users must have at least the Developer role.

```plaintext
PUT /suggestions/batch_apply
```

Supported attributes:

| Attribute        | Type          | Required | Description |
|------------------|---------------|----------|-------------|
| `ids`            | integer array | Yes      | IDs of suggestions to apply. |
| `commit_message` | string        | No       | Custom commit message to use instead of the default generated message or the project's default message. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and an array of suggestion objects with the following
response attributes:

| Attribute      | Type    | Description |
|----------------|---------|-------------|
| `applicable`   | boolean | If `true`, suggestion can be applied. |
| `applied`      | boolean | If `true`, suggestion has been applied. |
| `from_content` | string  | Original content before the suggestion. |
| `from_line`    | integer | Starting line number of the suggestion. |
| `id`           | integer | ID of the suggestion. |
| `to_content`   | string  | Suggested content to replace the original. |
| `to_line`      | integer | Ending line number of the suggestion. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"ids": [5, 6]}' \
  --url "https://gitlab.example.com/api/v4/suggestions/batch_apply"
```

Example response:

```json
[
  {
    "id": 5,
    "from_line": 10,
    "to_line": 10,
    "applicable": true,
    "applied": false,
    "from_content": "This is an example\n",
    "to_content": "This is an example\n"
  },
  {
    "id": 6,
    "from_line": 19,
    "to_line": 19,
    "applicable": true,
    "applied": false,
    "from_content": "This is another example\n",
    "to_content": "This is another example\n"
  }
]
```
