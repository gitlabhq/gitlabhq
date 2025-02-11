---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform Module Registry API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This is the API documentation for the [Terraform Module Registry](../../user/packages/terraform_module_registry/_index.md).

WARNING:
This API is used by the [Terraform CLI](https://www.terraform.io/)
and is generally not meant for manual consumption. Undocumented authentication methods might be removed in the future.

For instructions on how to upload and install Terraform modules from the GitLab
Terraform Module Registry, see the [Terraform Module Registry documentation](../../user/packages/terraform_module_registry/_index.md).

## List available versions for a specific module

Get a list of available versions for a specific module.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The top-level group (namespace) to which Terraform module's project or subgroup belongs.|
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/versions"
```

Example response:

```json
{
  "modules": [
    {
      "versions": [
        {
          "version": "1.0.0",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        },
        {
          "version": "0.9.3",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        }
      ],
      "source": "https://gitlab.example.com/group/hello-world"
    }
  ]
}
```

## Latest version for a specific module

Get information about the latest version for a given module.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local"
```

Example response:

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## Get specific version for a specific module

Get information about a specific version for a given module.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/1.0.0
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0"
```

Example response:

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## Get URL for downloading latest module version

Get the download URL for latest module version in `X-Terraform-Get` header

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/download"
```

Example response:

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

Under the hood, this API endpoint redirects to `packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download`

## Get URL for downloading specific module version

Get the download URL for a specific module version in `X-Terraform-Get` header

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |
| `module_version` | string | yes | Specific module version to download. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/download"
```

Example response:

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

## Download module

### From a namespace

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |
| `module_version` | string | yes | Specific module version to download. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file"
```

To write the output to file:

```shell
curl --header "Authorization: Bearer <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file" --output hello-world-local.tgz
```

### From a project

```plaintext
GET /projects/:id/packages/terraform/modules/:module_name/:module_system/:module_version
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or URL-encoded path of the project. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |
| `module_version` | string | no | Specific module version to download. If omitted, the latest version is downloaded. |

```shell
curl --user "<username>:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0"
```

To write the output to file:

```shell
curl --user "<username>:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0" --output hello-world-local.tgz
```

## Upload module

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| Attribute        | Type              | Required | Description |
|------------------|-------------------|----------|-------------|
| `id`             | integer or string | yes      | The ID or URL-encoded path of the project. |
| `module-name`    | string            | yes      | The module name. |
| `module-system`  | string            | yes      | The name of the module system or [provider](https://www.terraform.io/registry/providers). |
| `module-version` | string            | yes      | Specific module version to upload. |

```shell
curl --fail-with-body \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --upload-file path/to/file.tgz \
   --url  "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/my-module/my-system/0.0.1/file"
```

Tokens that can be used to authenticate:

| Header          | Value |
|-----------------|-------|
| `PRIVATE-TOKEN` | A [personal access token](../../user/profile/personal_access_tokens.md) with `api` scope. |
| `DEPLOY-TOKEN`  | A [deploy token](../../user/project/deploy_tokens/_index.md) with `write_package_registry` scope. |
| `JOB-TOKEN`     | A [job token](../../ci/jobs/ci_job_token.md). |

Example response:

```json
{
  "message": "201 Created"
}
```
