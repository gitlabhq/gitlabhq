---
stage: Deploy
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Model registry API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Download a machine learning model package

Returns the file.

```plaintext
GET /projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

Parameters:

| Attribute          | Type              | Required | Description                                                                            |
|--------------------|-------------------|----------|----------------------------------------------------------------------------------------|
| `id`               | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)    |
| `model_version_id` | integer           | yes      | The model version ID for the file                                                      |
| `path`             | string            | yes      | File directory path                                                                    |
| `filename`         | string            | yes      | Filename                                                                               |

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):filename
```

The response contains the file contents.

For example, the following command returns the file `foo.txt` for the model version with an ID of `2` and project with an ID of `1`.

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/foo.txt
```
