---
stage: Package
group: Container Registry
description: 'Backend changes for Google Artifact Registry Integration'
---

# Backend changes for Google Artifact Registry Integration

## Client SDK

To interact with GAR we will make use of the official GAR [Ruby client SDK](https://cloud.google.com/ruby/docs/reference/google-cloud-artifact_registry/latest).
By default, this client will use the [RPC](https://cloud.google.com/artifact-registry/docs/reference/rpc) version of the Artifact Registry API.

To build the client, we will need the [service account key](index.md#authentication).

### Interesting functions

For the scope of this blueprint, we will need to use the following functions from the Ruby client:

- [`#get_repository`](https://github.com/googleapis/google-cloud-ruby/blob/d0ce758a03335b60285a3d2783e4cca7089ee2ea/google-cloud-artifact_registry-v1/lib/google/cloud/artifact_registry/v1/artifact_registry/client.rb#L1244). [API documentation](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#getrepositoryrequest). This will return a single [`Repository`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#repository).
- [`#list_docker_images`](https://github.com/googleapis/google-cloud-ruby/blob/d0ce758a03335b60285a3d2783e4cca7089ee2ea/google-cloud-artifact_registry-v1/lib/google/cloud/artifact_registry/v1/artifact_registry/client.rb#L243). [API documentation](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#listdockerimagesrequest). This will return a list of [`DockerImage`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#dockerimage).
- [`#get_docker_image`](https://github.com/googleapis/google-cloud-ruby/blob/d0ce758a03335b60285a3d2783e4cca7089ee2ea/google-cloud-artifact_registry-v1/lib/google/cloud/artifact_registry/v1/artifact_registry/client.rb#L329). [API documentation](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#getdockerimagerequest). This will return a single [`DockerImage`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#dockerimage).

### Limitations

Filtering is not available in `#list_docker_images`. In other words, we can't filter the returned list (for example on a specific name). However, ordering on some columns is available.

In addition, we can't point directly to a specific page. For example, directly accessing page 3 of the list of Docker images without going first through page 1 and 2.
We can't build this feature on the GitLab side because this will require to walk through all pages and we could hit a situation where we need to go through a very large amount of pages.

### Exposing the client

It would be better to centralize the access to the official Ruby client. This way, it's very easy to check for permissions.

We suggest having a custom client class located in `GoogleCloudPlatform::ArtifactRegistry::Client`. That class will need to require a `User` and a `Integrations::GoogleCloudPlatform::ArtifactRegistry` (see [Project Integration](#project-integration)).

The client will then need to expose three functions: `#repository`, `#docker_images` and `#docker_image` that will be mapped to the similarly name functions of the official client.

Before calling the official client, this class will need to check the user permissions. The given `User` should have `read_gcp_artifact_registry_repository` on the `Project` related with the `Integrations::GoogleCloudPlatform::ArtifactRegistry`.

Lastly, to set up the official client, we will need to properly set:

- the [timeout](https://github.com/googleapis/google-cloud-ruby/blob/a64ed1de61a6f1b5752e7c8e01d6a79365e6de67/google-cloud-artifact_registry-v1/lib/google/cloud/artifact_registry/v1/artifact_registry/operations.rb#L646).
- the [retry_policy](https://github.com/googleapis/google-cloud-ruby/blob/a64ed1de61a6f1b5752e7c8e01d6a79365e6de67/google-cloud-artifact_registry-v1/lib/google/cloud/artifact_registry/v1/artifact_registry/operations.rb#L652).

For these, we can simply either use the default values if they are ok or use fixed values.

## New permission

We will need a new permission on the [Project policy](https://gitlab.com/gitlab-org/gitlab/-/blob/1411076f1c8ec80dd32f5da7518f795014ea5a2b/app/policies/project_policy.rb):

- `read_gcp_artifact_registry_repository` granted to at least reporter users.

## Project Integration

We will need to build a new [project integration](../../../development/integrations/index.md) with the following properties:

- `google_project_id` - the Google project ID. A simple string.
- `google_location` - the Google location. A simple string.
- `repositories` - an array of repository names (see below).
- `json_key` - the service account JSON. A string but displayed as a text area.
- `json_key_base64` - the service account JSON, encoded with base64. Value set from `json_key`.

We will also have derived properties:

- `repository`- the repository name. Derived from `repositories`.

`repositories` is used as a way to store the repository name in an array. This is to help with a future follow up where multiple repositories will need to be supported. As such, we store the repository name into an array and we create a `repository` property that is the first entry of the array. By having a `repository` single property, we can use the [frontend helpers](../../../development/integrations/index.md#customize-the-frontend-form) as array values are not supported in project integrations.

We also need the base64 version of the `json_key`. This is required for the [`CI/CD variables`](#cicd-variables).

Regarding the class name, we suggest using `Integrations::GoogleCloudPlatform::ArtifactRegistry`. The `Integrations::GoogleCloudPlatform` namespace allows us to have possible future other integrations for the other services of the Google Cloud Platform.

Regarding the [configuration test](../../../development/integrations/index.md#define-configuration-test), we need to get the repository info on the official API (method `#get_repository`). The test is successful if and only if, the call is successful and the returned repository has the format `DOCKER`.

## GraphQL APIs

The [UI](ui_ux.md) will basically have two pages: listing Docker images out of the repository configured in the project integration and show details of a given Docker image.

In order to support the other repository formats in follow ups, we choose to not map the official client function names in GraphQL fields or methods but rather have a more re-usable approach.

All GraphQL changes should be marked as [`alpha`](../../../development/api_graphql_styleguide.md#mark-schema-items-as-alpha).

First, on the [`ProjectType`](../../../api/graphql/reference/index.md#project), we will need a new field `google_cloud_platform_artifact_registry_repository_artifacts`. This will return a list of an [abstract](../../../api/graphql/reference/index.md#abstract-types) new type: `GoogleCloudPlatform::ArtifactRegistry::ArtifactType`. This list will have pagination support. Ordering options will be available.

We will have `GoogleCloudPlatform::ArtifactRegistry::DockerImage` as a concrete type of `GoogleCloudPlatform::ArtifactRegistry::ArtifactType` with the following fields:

- `name`. A string.
- `uri`. A string.
- `image_size_bytes`. A integer.
- `upload_time`. A timestamp.

Then, we will need a new query `Query.google_cloud_platform_registry_registry_artifact_details` that given a name of a `GoogleCloudPlatform::ArtifactRegistry::DockerImage` will return a single `GoogleCloudPlatform::ArtifactRegistry::ArtifacDetailsType` with the following fields:

- all fields of `GoogleCloudPlatform::ArtifactRegistry::ArtifactType`.
- `tags`. An array of strings.
- `media_type`. A string.
- `build_time`. A timestamp.
- `updated_time`. A timestamp.

All GraphQL changes will require users to have the [`read_gcp_artifact_registry_repository` permission](#new-permission).

## CI/CD variables

Similar to the [Harbor](../../../user/project/integrations/harbor.md#configure-gitlab) integration, once users activates the GAR integration, additional CI/CD variables will be automatically available if the integration is enabled. These will be set according to the requirements described in the [documentation](https://cloud.google.com/artifact-registry/docs/docker/authentication#json-key):

- `GCP_ARTIFACT_REGISTRY_URL`: This will be set to `https://LOCATION-docker.pkg.dev`, where `LOCATION` is the GCP project location configured for the integration.
- `GCP_ARTIFACT_REGISTRY_PROJECT_URI`: This will be set to `LOCATION-docker.pkg.dev/PROJECT-ID`. `PROJECT-ID` is the GCP project ID of the GAR repository configured for the integration.
- `GCP_ARTIFACT_REGISTRY_PASSWORD`: This will be set to the base64-encode version of the service account JSON key file configured for the integration.
- `GCP_ARTIFACT_REGISTRY_USER`: This will be set to `_json_key_base64`.

These can then be used to log in using `docker login`:

```shell
docker login -u $GCP_ARTIFACT_REGISTRY_USER -p $GCP_ARTIFACT_REGISTRY_PASSWORD $GCP_ARTIFACT_REGISTRY_URL
```

Similarly, these can be used to download images from the repository with `docker pull`:

```shell
docker pull $GCP_ARTIFACT_REGISTRY_PROJECT_URI/REPOSITORY/myapp:latest
```

Finally, provided that the configured service account has the `Artifact Registry Writer` role, one can also push images to GAR:

```shell
docker build -t $GCP_ARTIFACT_REGISTRY_REPOSITORY_URI/myapp:latest .
docker push $GCP_ARTIFACT_REGISTRY_REPOSITORY_URI/myapp:latest
```

For forward compatibility reasons, the repository name (`REPOSITORY` in the command above) must be appended to `GCP_ARTIFACT_REGISTRY_PROJECT_URI` by the user. In the first iteration we will only support a single GAR repository, and therefore we could technically provide a variable like `GCP_ARTIFACT_REGISTRY_REPOSITORY_URI` with the repository name already included. However, once we add support for multiple repositories, there is no way we can tell what repository a user will want to target for a specific instruction.
