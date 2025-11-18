---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Helm API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with [Helm package clients](../../user/packages/helm_repository/_index.md).

{{< alert type="warning" >}}

This API is used by the Helm-related package clients such as [Helm](https://helm.sh/)
and [`helm-push`](https://github.com/chartmuseum/helm-push/#readme),
and is generally not meant for manual consumption.

{{< /alert >}}

{{< alert type="note" >}}

These endpoints do not adhere to the standard API authentication methods.
See the [Helm registry documentation](../../user/packages/helm_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.

{{< /alert >}}

## Download a chart index

{{< alert type="note" >}}

To ensure consistent chart download URLs, the `contextPath` field in `index.yaml` responses
always uses the numeric project ID, whether you access the API with the project ID or the
full project path.

{{< /alert >}}

Download a chart index:

```plaintext
GET projects/:id/packages/helm/:channel/index.yaml
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The ID or full path of the project. |
| `channel` | string | yes      | Helm repository channel. |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml"
```

Write the output to a file:

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml" \
     --remote-name
```

## Download a chart

Download a chart:

```plaintext
GET projects/:id/packages/helm/:channel/charts/:file_name.tgz
```

| Attribute   | Type   | Required | Description |
| ----------- | ------ | -------- | ----------- |
| `id`        | string | yes      | The ID or full path of the project. |
| `channel`   | string | yes      | Helm repository channel. |
| `file_name` | string | yes      | Chart filename. |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/charts/mychart.tgz" \
     --remote-name
```

## Upload a chart

Upload a chart:

```plaintext
POST projects/:id/packages/helm/api/:channel/charts
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The ID or full path of the project. |
| `channel` | string | yes      | Helm repository channel. |
| `chart`   | file   | yes      | Chart (as `multipart/form-data`). |

```shell
curl --request POST \
     --form 'chart=@mychart.tgz' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts"
```
