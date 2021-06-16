---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Suggest Changes API **(FREE)**

This page describes the API for [suggesting changes](../user/project/merge_requests/reviews/suggestions.md).

Every API call to suggestions must be authenticated.

## Applying suggestions

Applies a suggested patch in a merge request. Users must be
at least [Developer](../user/permissions.md) to perform such action.

```plaintext
PUT /suggestions/:id/apply
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of a suggestion |
| `commit_message` | string | no | A custom commit message to use instead of the default generated message or the project's default message |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/suggestions/5/apply"
```

Example response:

```json
  {
    "id": 36,
    "from_line": 10,
    "to_line": 10,
    "appliable": false,
    "applied": true,
    "from_content": "        \"--talk-name=org.freedesktop.\",\n",
    "to_content": "        \"--talk-name=org.free.\",\n        \"--talk-name=org.desktop.\",\n"
  }
```
