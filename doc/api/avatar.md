# Avatar API

> [Introduced][ce-19121] in GitLab 11.0

## Get a single avatar URL

Get a single avatar URL for a given email addres. If user with matching public
email address is not found, results from external avatar services are returned.
This endpoint can be accessed without authentication. In case public visibility
is restricted, response will be `403 Forbidden` when unauthenticated.

```
GET /avatar?email=admin@example.com
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `email`   | string  | yes      | Public email address of the user |
| `size`    | integer | no       | Single pixel dimension (since images are squares). Only used for avatar lookups at `Gravatar` or at the configured `Libravatar` server |

```bash
curl https://gitlab.example.com/api/v4/avatar?email=admin@example.com
```

Example response:

```json
{
  "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon"
}
```

[ce-19121]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/19121
