---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency list export API
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Every call to this endpoint requires authentication.

## Create a pipeline-level dependency list export

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333463) in GitLab 16.4 [with a flag](../administration/feature_flags.md) named `merge_sbom_api`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/425312) in GitLab 16.7. Feature flag `merge_sbom_api` removed.

Create a new CycloneDX JSON export for all the project dependencies detected in a pipeline.

If an authenticated user does not have permission to [read_dependency](../user/custom_roles.md#available-permissions),
this request returns a `403 Forbidden` status code.

SBOM exports can be only accessed by the export's author.

```plaintext
POST /pipelines/:id/dependency_list_exports
```

| Attribute           | Type              | Required   | Description                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer           | yes        | The ID of the pipeline which the authenticated user has access to. |
| `export_type`       | string            | yes        | This must be set to `sbom`. |
| `send_email`        | boolean           | no         | When set to `true`, sends an email notification to the user who requested the export when the export completes. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <private_token>" "https://gitlab.example.com/api/v4/pipelines/1/dependency_list_exports" --data "export_type=sbom"
```

The created dependency list export is automatically deleted after 1 hour.

Example response:

```json
{
  "id": 2,
  "has_finished": false,
  "export_type": "sbom",
  "send_email": false,
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/2",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/2/download"
}
```

## Get single dependency list export

Get a single dependency list export.

```plaintext
GET /dependency_list_exports/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the dependency list export. |

```shell
curl --header "PRIVATE-TOKEN: <private_token>" "https://gitlab.example.com/api/v4/dependency_list_exports/2"
```

The status code is `202 Accepted` when the dependency list export is being generated, and `200 OK` when it's ready.

Example response:

```json
{
  "id": 4,
  "has_finished": true,
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/4",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/4/download"
}
```

## Download dependency list export

Download a single dependency list export.

```plaintext
GET /dependency_list_exports/:id/download
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the dependency list export. |

```shell
curl --header "PRIVATE-TOKEN: <private_token>" "https://gitlab.example.com/api/v4/dependency_list_exports/2/download"
```

The response is `404 Not Found` if the dependency list export is not finished yet or was not found.

Example response:

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:aec33827-20ae-40d0-ae83-18ee846364d2",
  "version": 1,
  "metadata": {
    "tools": [
      {
        "vendor": "Gitlab",
        "name": "Gemnasium",
        "version": "2.34.0"
      }
    ],
    "authors": [
      {
        "name": "Gitlab",
        "email": "support@gitlab.com"
      }
    ],
    "properties": [
      {
        "name": "gitlab:dependency_scanning:input_file",
        "value": "package-lock.json"
      }
    ]
  },
  "components": [
    {
      "name": "com.fasterxml.jackson.core/jackson-core",
      "purl": "pkg:maven/com.fasterxml.jackson.core/jackson-core@2.9.2",
      "version": "2.9.2",
      "type": "library",
      "licenses": [
        {
          "license": {
            "id": "MIT",
            "url": "https://spdx.org/licenses/MIT.html"
          }
        },
        {
          "license": {
            "id": "BSD-3-Clause",
            "url": "https://spdx.org/licenses/BSD-3-Clause.html"
          }
        }
      ]
    }
  ]
}

```
