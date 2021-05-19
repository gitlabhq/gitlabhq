---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Avatar API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/19121) in GitLab 11.0.

## Get a single avatar URL

Get a single [avatar](../user/profile/index.md#access-your-user-settings) URL for a user with the given email address.

If:

- No user with the given public email address is found, results from external avatar services are
  returned.
- Public visibility is restricted, response is `403 Forbidden` when unauthenticated.

NOTE:
This endpoint can be accessed without authentication.

```plaintext
GET /avatar?email=admin@example.com
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `email`   | string  | yes      | Public email address of the user.                                                                                                       |
| `size`    | integer | no       | Single pixel dimension (because images are squares). Only used for avatar lookups at `Gravatar` or at the configured `Libravatar` server. |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/avatar?email=admin@example.com&size=32"
```

Example response:

```json
{
  "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=64&d=identicon"
}
```
