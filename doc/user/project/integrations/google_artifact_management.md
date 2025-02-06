---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Artifact Management
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127) in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `google_cloud_support_feature_flag`. This feature is in [beta](../../../policy/development_stages_support.md).
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) in GitLab 17.1. Feature flag `google_cloud_support_feature_flag` removed.

You can use the Google Artifact Management integration to
configure and connect a [Google Artifact Registry](https://cloud.google.com/artifact-registry) repository to your GitLab project.

After you connect the Google Artifact Registry to your project, you can view, push, and pull Docker and [OCI](https://opencontainers.org/) images in a [Google Artifact Registry](https://cloud.google.com/artifact-registry) repository.

## Set up the Google Artifact Registry in a GitLab project

Prerequisites:

- You must have at least the Maintainer role for the GitLab project.
- You must have the [permissions needed](https://cloud.google.com/iam/docs/granting-changing-revoking-access#required-permissions) to manage access to the Google Cloud project with the Artifact Registry repository.
- A [workload identity federation](../../../integration/google_cloud_iam.md) (WLIF) pool and provider must be configured to authenticate to Google Cloud.
- A [Google Artifact Registry repository](https://cloud.google.com/artifact-registry/docs/repositories) with the following configuration:
  - [Docker](https://cloud.google.com/artifact-registry/docs/supported-formats) format.
  - [Standard](https://cloud.google.com/artifact-registry/docs/repositories/create-repos) mode. Other repository formats and modes are not supported.

To connect a Google Artifact Registry repository to a GitLab project:

1. In GitLab, on the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Google Artifact Management**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Complete the fields:
   - **Google Cloud project ID**: The [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects) where the Artifact Registry repository is located.
   - **Repository name**: The name of the Artifact Registry repository.
   - **Repository location**: The [Google Cloud location](https://cloud.google.com/about/locations) of the Artifact Registry repository.
1. Follow the onscreen instructions to set up the Google Cloud Identity and Access Management (IAM) policies. For more information about the types of policies, see [IAM policies](#iam-policies).
1. Select **Save changes**.

You should now see a **Google Artifact Registry** entry in the sidebar under **Deploy**.

## View images stored in the Google Artifact Registry

Prerequisites:

- The Google Artifact Registry must be [configured](google_artifact_management.md#set-up-the-google-artifact-registry-in-a-gitlab-project) in the project.

To view the list of images in the connected Artifact Registry repository in the GitLab UI:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Google Artifact Registry**.
1. To view the image details, select an image.
1. To view the image in the Google Cloud console, select **Open in Google Cloud**. You must have the [required permissions](https://cloud.google.com/artifact-registry/docs/repositories/list-repos#required_roles) to view that Artifact Registry repository.

## CI/CD

### Predefined variables

After the Artifact Registry integration is activated, the following predefined environment variables are available in CI/CD.
You can use these environment variables to interact with the Artifact Registry, like pulling or pushing an image to the connected repository.

| Variable | GitLab | Runner | Description |
|-|-|-|-|
| `GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID` | 16.10 | 16.10 | The Google Cloud project ID where the Artifact Registry repository is located. |
| `GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME` | 16.10  | 16.10 | The name of the connected Artifact Registry repository. |
| `GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION` | 16.10  | 16.10 | The Google Cloud location of the connected Artifact Registry repository. |

### Authenticate with the Google Artifact Registry

You can configure a pipeline to authenticate with the Google Artifact Registry during pipeline
execution. GitLab uses the configured [workload identity pool](../../../integration/google_cloud_iam.md) IAM policies
and populates the `GOOGLE_APPLICATION_CREDENTIALS` and `CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE`
environment credentials. These environment credentials are automatically detected by client tools,
like [gcloud CLI](https://cloud.google.com/sdk/gcloud) and [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md).

To authenticate with the Google Artifact Registry, in the project's `.gitlab-ci.yml` file, use the [`identity`](../../../ci/yaml/_index.md#identity) keyword set to `google_cloud`.

#### IAM policies

Your Google Cloud project must have specific IAM policies to use the Google Artifact Management integration.
When you [set up this integration](#set-up-the-google-artifact-registry-in-a-gitlab-project), on-screen instructions
provide the steps to create the following IAM policies in your Google Cloud project:

- Grant [Artifact Registry Reader](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.reader) role to GitLab project members with [Guest](../../permissions.md#roles) role or above.
- Grant [Artifact Registry Writer](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.writer) role to GitLab project members with [Developer](../../permissions.md#roles) role or above.

To create these IAM policies manually, use the following `gcloud` commands. Replace these values:

- `<your_google_cloud_project_id>` with the [ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects) of the Google Cloud project where the Artifact Registry repository is located.
- `<your_workload_identity_pool_id>` with the ID of the workload identity pool. This is the same value used for the [Google Cloud IAM integration](../../../integration/google_cloud_iam.md).
- `<your_google_cloud_project_number>` with the [number](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects) of the Google Cloud project where the workload identity pool is located. This is the same value used for the [Google Cloud IAM integration](../../../integration/google_cloud_iam.md).

```shell
gcloud projects add-iam-policy-binding '<your_google_cloud_project_id>' \
  --member='principalSet://iam.googleapis.com/projects/<your_google_cloud_project_number>/locations/global/workloadIdentityPools/<your_workload_identity_pool_id>/attribute.guest_access/true' \
  --role='roles/artifactregistry.reader'

gcloud projects add-iam-policy-binding '<your_google_cloud_project_id>' \
  --member='principalSet://iam.googleapis.com/projects/<your_google_cloud_project_number>/locations/global/workloadIdentityPools/<your_workload_identity_pool_id>/attribute.developer_access/true' \
  --role='roles/artifactregistry.writer'
```

For a list of available claims, see [OIDC custom claims](../../../integration/google_cloud_iam.md#oidc-custom-claims).

### Examples

#### Use gcloud CLI to list images

```yaml
list-images:
  image: gcr.io/google.com/cloudsdktool/google-cloud-cli:466.0.0-alpine
  identity: google_cloud
  script:
    - gcloud artifacts docker images list $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app
```

#### Use crane to list images

```yaml
list-images:
  image:
    name: gcr.io/go-containerregistry/crane:debug
    entrypoint: [""]
  identity: google_cloud
  before_script:
    # Temporary workaround for https://github.com/google/go-containerregistry/issues/1886
    - wget -q "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.22/docker-credential-gcr_linux_amd64-2.1.22.tar.gz" -O - | tar xz -C /tmp && chmod +x /tmp/docker-credential-gcr && mv /tmp/docker-credential-gcr /usr/bin/
    - docker-credential-gcr configure-docker --registries=$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - crane ls $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app
```

#### Pull an image with Docker

The following example shows how to set up authentication for Docker with the [standalone Docker credential helper](https://cloud.google.com/artifact-registry/docs/docker/authentication#standalone-helper) provided by Google.

```yaml
pull-image:
  image: docker:24.0.5
  identity: google_cloud
  services:
    - docker:24.0.5-dind
  variables:
    # The following two variables ensure that the DinD service starts in TLS
    # mode and that the Docker CLI is properly configured to communicate with
    # the API. More details about the importance of this can be found at
    # https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-in-docker
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - wget -q "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.22/docker-credential-gcr_linux_amd64-2.1.22.tar.gz" -O - | tar xz -C /tmp && chmod +x /tmp/docker-credential-gcr && mv /tmp/docker-credential-gcr /usr/bin/
    - docker-credential-gcr configure-docker --registries=$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - docker pull $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app:v0.1.0
```

#### Copy an image by using a CI/CD component

Google provides the [`upload-artifact-registry`](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry) CI/CD component, which you can use to copy an image from the GitLab container registry to Artifact Registry.

To use the `upload-artifact-registry` component, add the following to your `.gitlab-ci.yml`:

```yaml
include:
  - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@main
    inputs:
      stage: deploy
      source: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
      target: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA
```

For details, see [the component documentation](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry).

Using the `upload-artifact-registry` component simplifies copying images to Artifact Registry and is the intended method for this integration. If you want to use Docker or Crane, see the following examples.

#### Copy an image by using Docker

In the following example, the `gcloud` CLI is used to set up the Docker authentication, as an alternative to the [standalone Docker credential helper](https://cloud.google.com/artifact-registry/docs/docker/authentication#standalone-helper).

```yaml
copy-image:
  image: gcr.io/google.com/cloudsdktool/google-cloud-cli:466.0.0-alpine
  identity: google_cloud
  services:
    - docker:24.0.5-dind
  variables:
    SOURCE_IMAGE: $CI_REGISTRY_IMAGE:v0.1.0
    TARGET_IMAGE: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app:v0.1.0
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - gcloud auth configure-docker $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - docker push $TARGET_IMAGE
```

#### Copy an image by using Crane

```yaml
copy-image:
  image:
    name: gcr.io/go-containerregistry/crane:debug
    entrypoint: [""]
  identity: google_cloud
  variables:
    SOURCE_IMAGE: $CI_REGISTRY_IMAGE:v0.1.0
    TARGET_IMAGE: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app:v0.1.0
  before_script:
    # Temporary workaround for https://github.com/google/go-containerregistry/issues/1886
    - wget -q "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.22/docker-credential-gcr_linux_amd64-2.1.22.tar.gz" -O - | tar xz -C /tmp && chmod +x /tmp/docker-credential-gcr && mv /tmp/docker-credential-gcr /usr/bin/
    - docker-credential-gcr configure-docker --registries=$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - crane auth login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - crane copy $SOURCE_IMAGE $TARGET_IMAGE
```
