---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Suggest Changes API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This page describes the API for [suggesting changes](../user/project/merge_requests/reviews/suggestions.md).

Every API call to suggestions must be authenticated.

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

Applies a suggested patch in a merge request. Users must have
at least the Developer role to perform such action.

```plaintext
PUT /suggestions/:id/apply
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a suggestion |
| `commit_message` | string | no | A custom commit message to use instead of the default generated message or the project's default message |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/suggestions/5/apply"
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

```plaintext
PUT /suggestions/batch_apply
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `ids` | integer | yes | The IDs of suggestions |
| `commit_message` | string | no | A custom commit message to use instead of the default generated message or the project's default message |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --header 'Content-Type: application/json' --data '{"ids": [5, 6]}' "https://gitlab.example.com/api/v4/suggestions/batch_apply"
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
  }
  {
    "id": 6,
    "from_line": 19
    "to_line": 19,
    "applicable": true,
    "applied": false,
    "from_content": "This is another example\n",
    "to_content": "This is another example\n"
  }
 ]
```
