---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Helm API

This is the API documentation for [Helm](../../user/packages/helm_repository/index.md).

WARNING:
This API is used by the Helm-related package clients such as [Helm](https://helm.sh/)
and [`helm-push`](https://github.com/chartmuseum/helm-push/#readme),
and is generally not meant for manual consumption.

For instructions on how to upload and install Helm packages from the GitLab
Package Registry, see the [Helm registry documentation](../../user/packages/helm_repository/index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [Helm registry documentation](../../user/packages/helm_repository/index.md)
for details on which headers and token types are supported.

## Download a chart index

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62757) in GitLab 14.1.

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
     https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml
```

Write the output to a file:

```shell
curl --user <username>:<personal_access_token> \
     https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml \
     --remote-name
```

## Download a chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61014) in GitLab 14.0.

Download a chart:

```plaintext
GET projects/:id/packages/helm/:channel/charts/:file_name.tgz
```

| Attribute   | Type   | Required | Description |
| ----------- | ------ | -------- | ----------- |
| `id`        | string | yes      | The ID or full path of the project. |
| `channel`   | string | yes      | Helm repository channel. |
| `file_name` | string | yes      | Chart file name. |

```shell
curl --user <username>:<personal_access_token> \
     https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/charts/mychart.tgz \
     --remote-name
```

## Upload a chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64814) in GitLab 14.1.

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
     https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts
```
