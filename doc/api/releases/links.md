---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Release links API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> Support for [GitLab CI/CD job token](../../ci/jobs/ci_job_token.md) authentication [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250819) in GitLab 15.1.

Use this API to manipulate GitLab [Release](../../user/project/releases/_index.md)
links. For manipulating other Release assets, see [Release API](_index.md).

GitLab supports links to `http`, `https`, and `ftp` assets.

## List links of a release

Get assets as links from a release.

```plaintext
GET /projects/:id/releases/:tag_name/assets/links
```

| Attribute     | Type           | Required | Description                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | yes      | The tag associated with the Release. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links"
```

Example response:

```json
[
   {
      "id":2,
      "name":"awesome-v0.2.msi",
      "url":"http://192.168.10.15:3000/msi",
      "link_type":"other"
   },
   {
      "id":1,
      "name":"awesome-v0.2.dmg",
      "url":"http://192.168.10.15:3000",
      "link_type":"other"
   }
]
```

## Get a release link

Get an asset as a link from a release.

```plaintext
GET /projects/:id/releases/:tag_name/assets/links/:link_id
```

| Attribute     | Type           | Required | Description                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | yes      | The tag associated with the Release. |
| `link_id`    | integer         | yes      | The ID of the link. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

Example response:

```json
{
   "id":1,
   "name":"awesome-v0.2.dmg",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```

## Create a release link

Creates an asset as a link from a release.

```plaintext
POST /projects/:id/releases/:tag_name/assets/links
```

| Attribute            | Type           | Required | Description                                                                                                               |
|----------------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `id`                 | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths).                                        |
| `tag_name`           | string         | yes      | The tag associated with the Release.                                                                                      |
| `name`               | string         | yes      | The name of the link. Link names must be unique in the release.                                                           |
| `url`                | string         | yes      | The URL of the link. Link URLs must be unique in the release.                                                             |
| `direct_asset_path`  | string         | no       | Optional path for a [direct asset link](../../user/project/releases/release_fields.md#permanent-links-to-release-assets). |
| `link_type`          | string         | no       | The type of the link: `other`, `runbook`, `image`, `package`. Defaults to `other`.                                        |

Example request:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data name="hellodarwin-amd64" \
    --data url="https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64" \
    --data direct_asset_path="/bin/hellodarwin-amd64" \
    "https://gitlab.example.com/api/v4/projects/20/releases/v1.7.0/assets/links"
```

Example response:

```json
{
   "id":2,
   "name":"hellodarwin-amd64",
   "url":"https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64",
   "direct_asset_url":"https://gitlab.example.com/mynamespace/hello/-/releases/v1.7.0/downloads/bin/hellodarwin-amd64",
   "link_type":"other"
}
```

## Update a release link

Updates an asset as a link from a release.

```plaintext
PUT /projects/:id/releases/:tag_name/assets/links/:link_id
```

| Attribute            | Type           | Required | Description                                                                                                               |
| -------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------- |
| `id`                 | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `tag_name`           | string         | yes      | The tag associated with the Release. |
| `link_id`            | integer        | yes      | The ID of the link. |
| `name`               | string         | no       | The name of the link. |
| `url`                | string         | no       | The URL of the link. |
| `direct_asset_path`  | string         | no       | Optional path for a [direct asset link](../../user/project/releases/release_fields.md#permanent-links-to-release-assets). |
| `link_type`          | string         | no       | The type of the link: `other`, `runbook`, `image`, `package`. Defaults to `other`. |

NOTE:
You have to specify at least one of `name` or `url`

Example request:

```shell
curl --request PUT --data name="new name" --data link_type="runbook" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

Example response:

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"runbook"
}
```

## Delete a release link

Deletes an asset as a link from a release.

```plaintext
DELETE /projects/:id/releases/:tag_name/assets/links/:link_id
```

| Attribute     | Type           | Required | Description                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | yes      | The tag associated with the Release. |
| `link_id`    | integer         | yes      | The ID of the link. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

Example response:

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```
