---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Version API **(FREE)**

NOTE:
We recommend you use the [Metadata API](metadata.md) instead of the Version API.
It contains additional information and is aligned with the GraphQL metadata endpoint.

Retrieve version information for this GitLab instance. Responds `200 OK` for
authenticated users.

```plaintext
GET /version
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/version"
```

Example response:

```json
{
  "version": "8.13.0-pre",
  "revision": "4e963fe"
}
```
