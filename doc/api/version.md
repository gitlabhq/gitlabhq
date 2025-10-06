---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Version API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

We recommend you use the [Metadata API](metadata.md) instead of the Version API.
It contains additional information and is aligned with the GraphQL metadata endpoint.
The Version API is a mirror of the Metadata API.

{{< /alert >}}

Retrieves version information for the GitLab instance. Responds with `200 OK` for
authenticated users.

```plaintext
GET /version
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/version"

```

## Example responses

See [Metadata API](metadata.md) for the response.
