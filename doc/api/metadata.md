---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Metadata API **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357032) in GitLab 15.2.
> - `enterprise` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103969) in GitLab 15.6.

Retrieve metadata information for this GitLab instance.

```plaintext
GET /metadata
```

Response body attributes:

| Attribute         | Type           | Description                                                                              |
|:------------------|:---------------|:-----------------------------------------------------------------------------------------|
| `version`         | string         | Version of the GitLab instance.                                                          |
| `revision`        | string         | Revision of the GitLab instance.                                                         |
| `kas`             | object         | Metadata about the GitLab agent server for Kubernetes (KAS).                             |
| `kas.enabled`     | boolean        | Indicates whether KAS is enabled.                                                        |
| `kas.externalUrl` | string or null | URL used by the agents to communicate with KAS. It's `null` if `kas.enabled` is `false`. |
| `kas.version`     | string or null | Version of KAS. It's `null` if `kas.enabled` is `false`.                                 |
| `enterprise`      | boolean        | Indicates whether GitLab instance is Enterprise Edition.                                 |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/metadata"
```

Example response:

```json
{
  "version": "15.2-pre",
  "revision": "c401a659d0c",
  "kas": {
    "enabled": true,
    "externalUrl": "grpc://gitlab.example.com:8150",
    "version": "15.0.0"
  },
  "enterprise": true
}
```
