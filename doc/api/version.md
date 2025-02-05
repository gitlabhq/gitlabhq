---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Version API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

NOTE:
We recommend you use the [Metadata API](metadata.md) instead of the Version API.
It contains additional information and is aligned with the GraphQL metadata endpoint.
As of GitLab 15.5, the Version API is a mirror of the Metadata API.

Retrieves version information for the GitLab instance. Responds with `200 OK` for
authenticated users.

```plaintext
GET /version
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/version"
```

## Example responses

### GitLab 15.5 and later

See [Metadata API](metadata.md) for the response.

### GitLab 15.4 and earlier

```json
{
  "version": "8.13.0-pre",
  "revision": "4e963fe"
}
```
