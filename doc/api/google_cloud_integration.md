---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Cloud integration API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com
**Status:** Experiment

Use this API to interact with the Google Cloud integration. For more information, see [GitLab and Google Cloud integration](../ci/gitlab_google_cloud_integration/_index.md).

## Project-level Google Cloud integration scripts

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870) in GitLab 16.10. This feature is an [experiment](../policy/development_stages_support.md).

### Workload identity federation creation script

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870) in GitLab 16.10.

Users with at least the Maintainer role for the project can use the following endpoint to
query a shell script that creates and configures the workload identity
federation in Google Cloud:

```plaintext
GET /projects/:id/google_cloud/setup/wlif.sh
```

Supported attributes:

| Attribute                                         | Type             | Required | Description                                                                                                      |
|---------------------------------------------------|------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                                              | integer          | Yes      | The ID a project.                                                                                                |
| `google_cloud_project_id`                         | string           | Yes      | Google Cloud Project ID for the workload identity federation.                                                    |
| `google_cloud_workload_identity_pool_id`          | string           | No       | ID of the Google Cloud workload identity pool to create. Defaults to `gitlab-wlif`.                              |
| `google_cloud_workload_identity_pool_display_name`| string           | No       | Display name of the Google Cloud workload identity pool to create. Defaults to `WLIF for GitLab integration`.   |
| `google_cloud_workload_identity_pool_provider_id` | string           | No       | ID of the Google Cloud workload identity pool provider to create. Defaults to `gitlab-wlif-oidc-provider`.       |
| `google_cloud_workload_identity_pool_provider_display_name`| string  | No       | Display name of the Google Cloud workload identity pool provider to created. Defaults to `GitLab OIDC provider`. |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/wlif.sh"
```

### Script to set up a Google Cloud integration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144787) in GitLab 16.10.

Users with at least the Maintainer role for the project can use the following endpoint to
query a shell script to set up a Google Cloud integration:

```plaintext
GET /projects/:id/google_cloud/setup/integrations.sh
```

Only the [Google Artifact Management integration](../user/project/integrations/google_artifact_management.md)
is supported.
The script creates IAM policies to access Google Artifact Registry:

- [Artifact Registry Reader](https://cloud.google.com/artifact-registry/docs/access-control#roles)
  role is granted to members with at least Reporter role
- [Artifact Registry Writer](https://cloud.google.com/artifact-registry/docs/access-control#roles)
  role is granted to members with at least Developer role

Supported attributes:

| Attribute                                   | Type    | Required | Description                                                                 |
|---------------------------------------------|---------|----------|-----------------------------------------------------------------------------|
| `id`                                        | integer | Yes      | The ID of a GitLab project.                                                           |
| `enable_google_cloud_artifact_registry`     | boolean | Yes      | Flag to indicate if Google Artifact Management integration should be enabled. |
| `google_cloud_artifact_registry_project_id` | string  | Yes      | Google Cloud Project ID for the Artifact Registry.                          |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/integrations.sh"
```

### Script to configure a Google Cloud project for runner provisioning

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145525) in GitLab 16.10.

Users with at least the Maintainer role for the project can use the following endpoint to
query a shell script to configure a Google Cloud project for runner provisioning and execution:

```plaintext
GET /projects/:id/google_cloud/setup/runner_deployment_project.sh
```

The script performs preparatory configuration steps in the specified Google Cloud project,
namely enabling required services and creating a `GRITProvisioner` role and a `grit-provisioner` service account.

Supported attributes:

| Attribute                 | Type    | Required | Description                            |
|---------------------------|---------|----------|----------------------------------------|
| `id`                      | integer | Yes      | The ID of a GitLab project.            |
| `google_cloud_project_id` | string  | Yes      | The ID of the Google Cloud project.    |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/runner_deployment_project.sh?google_cloud_project_id=<your_google_cloud_project_id>"
```
