# Version API

>**Note:** This feature was introduced in GitLab 8.13

Retrieve version information for this GitLab instance. Responds `200 OK` for
authenticated users.

```
GET /version
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/version
```

Example response:

```json
{
  "version": "8.13.0-pre",
  "revision": "4e963fe"
}
```
