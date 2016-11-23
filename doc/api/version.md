# Version API

>**Note:**
The `https://gitlab.example.com` URL that is presented in the examples of the
API docs is fictional. Replace it with the URL of your GitLab instance,
or in case of GitLab.com, use `https://gitlab.com`.

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
