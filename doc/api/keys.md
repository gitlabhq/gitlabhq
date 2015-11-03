# Keys

## Get SSH key with user by ID of an SSH key

Get the public SSH key with its user information by providing the ID of an SSH
key.

**Note**: This API call can be made only by administrators.

```
GET /keys/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of an SSH key |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/keys/1
```

Example response:

```json
{
   "created_at" : "2015-09-15T18:29:11.737Z",
   "id" : 1,
   "title" : "Sample key 25",
   "user" : {
      "username" : "user5",
      "web_url" : "https://gitlab.example.com/u/user5",
      "current_sign_in_at" : null,
      "projects_limit" : 10,
      "email" : "user5@example.com",
      "name" : "User 5",
      "identities" : [],
      "theme_id" : 2,
      "created_at" : "2015-09-15T18:28:19.510Z",
      "can_create_project" : true,
      "avatar_url" : null,
      "can_create_group" : true,
      "id" : 25,
      "linkedin" : "",
      "skype" : "",
      "is_admin" : false,
      "bio" : null,
      "state" : "active",
      "website_url" : "",
      "color_scheme_id" : 1,
      "twitter" : "",
      "two_factor_enabled" : false
   },
   "key" : "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1256k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK
2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
}
```
