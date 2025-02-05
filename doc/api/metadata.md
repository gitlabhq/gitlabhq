---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Metadata API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357032) in GitLab 15.2.
> - `enterprise` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103969) in GitLab 15.6.
> - `kas.externalK8sProxyUrl` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172373) in GitLab 17.6.

Retrieve metadata information for this GitLab instance.

```plaintext
GET /metadata
```

Response body attributes:

| Attribute                 | Type           | Description                                                                                                                   |
|:--------------------------|:---------------|:------------------------------------------------------------------------------------------------------------------------------|
| `version`                 | string         | Version of the GitLab instance.                                                                                               |
| `revision`                | string         | Revision of the GitLab instance.                                                                                              |
| `kas`                     | object         | Metadata about the GitLab agent server for Kubernetes (KAS).                                                                  |
| `kas.enabled`             | boolean        | Indicates whether KAS is enabled.                                                                                             |
| `kas.externalUrl`         | string or null | URL used by the agents to communicate with KAS. It's `null` if `kas.enabled` is `false`.                                      |
| `kas.externalK8sProxyUrl` | string or null | URL used by the Kubernetes tooling to communicate with the KAS Kubernetes API proxy. It's `null` if `kas.enabled` is `false`. |
| `kas.version`             | string or null | Version of KAS. It's `null` if `kas.enabled` is `false` or when GitLab instance failed to fetch server info from KAS.         |
| `enterprise`              | boolean        | Indicates whether GitLab instance is Enterprise Edition.                                                                      |

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
    "externalK8sProxyUrl": "https://gitlab.example.com:8150/k8s-proxy",
    "version": "15.0.0"
  },
  "enterprise": true
}
```
