---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Annotate container images with build provenance data'
---

Annotations provide valuable metadata about the build process. This information is used for auditing and traceability. In a security incident, having detailed provenance data can significantly speed up the investigation and remediation process.

This tutorial describes how to set up a GitLab pipeline to automate the process of building, signing, and annotating container images by using Cosign.
You can configure your `.gitlab-ci.yml` file to build, push, and sign a Docker image, and push it to the GitLab container registry.

To annotate container images:

1. [Set an image and service image](#set-image-and-service-image).
1. [Define CI/CD variables](#define-cicd-variables).
1. [Prepare the OIDC token](#prepare-oidc-token).
1. [Prepare the container](#prepare-the-container).
1. [Build and push the image](#build-and-push-the-image).
1. [Sign the image with Cosign](#sign-the-image-with-cosign).
1. [Verify the signature and annotations](#verify-the-signature-and-annotations).

When you put it all together, your `.gitlab-ci.yml` should look similar to the [sample configuration](#example-gitlab-ciyml-configuration) provided at the end of this tutorial.

## Before you begin

You must have:

- Cosign v2.0 or later installed.
- For GitLab Self-Managed, the GitLab container registry [configured with a metadata database](../../../administration/packages/container_registry_metadata_database.md)
  to display signatures.

## Set image and service image

In the `.gitlab-ci.yml` file, use the `docker:latest` image and enable Docker-in-Docker service to allow Docker commands to run in the CI/CD job.

```yaml
build_and_sign:
  stage: build
  image: docker:latest
  services:
    - docker:dind  # Enable Docker-in-Docker service to allow Docker commands inside the container
```

## Define CI/CD variables

Define variables for the image tag and URI using GitLab CI/CD predefined variables.

```yaml
variables:
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA  # Use the commit short SHA as the image tag
  IMAGE_URI: $CI_REGISTRY_IMAGE:$IMAGE_TAG  # Construct the full image URI with the registry, project path, and tag
  COSIGN_YES: "true"  # Automatically confirm actions in Cosign without user interaction
  FF_SCRIPT_SECTIONS: "true"  # Enables GitLab's CI script sections for better multi-line script output
```

## Prepare OIDC token

Set up an OIDC token for keyless signing with Cosign.

```yaml
id_tokens:
  SIGSTORE_ID_TOKEN:
    aud: sigstore  # Provide an OIDC token for keyless signing with Cosign
```

## Prepare the container

In the `before_script` section of the `.gitlab-ci.yml` file:

- Install Cosign and jq (for JSON processing): `apk add --no-cache cosign jq`
- Enable GitLab container registry login using a CI/CD job token: `docker login -u "gitlab-ci-token" -p "$CI_JOB_TOKEN" "$CI_REGISTRY"`

The pipeline starts by setting up the necessary environment.

## Build and push the image

In the `script` section of the `.gitlab-ci.yml` file, enter the following commands to build the Docker image and push it to the GitLab container registry.

```yaml
- docker build --pull -t "$IMAGE_URI" .
- docker push "$IMAGE_URI"
```

This command creates the image using the current directory's Dockerfile and pushes it to the registry.

## Sign the image with Cosign

After building and pushing the image to the GitLab container registry, use Cosign to sign it.

In the `script` section of the `.gitlab-ci.yml` file, enter the following commands:

```yaml
- IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_URI")
- |
  cosign sign "$IMAGE_DIGEST" \
    --annotations "com.gitlab.ci.user.name=$GITLAB_USER_NAME" \
    --annotations "com.gitlab.ci.pipeline.id=$CI_PIPELINE_ID" \
    # ... (other annotations) ...
    --annotations "tag=$IMAGE_TAG"
```

This step retrieves the image digest. It then uses Cosign to sign the image, and adds several annotations.

## Verify the signature and annotations

After signing the image, it's crucial to verify the signature and the annotations added.

In the `.gitlab-ci.yml` file, include a verification step using the `cosign verify` command:

```yaml
- |
  cosign verify \
    --annotations "tag=$IMAGE_TAG" \
    --certificate-identity "$CI_PROJECT_URL//.gitlab-ci.yml@refs/heads/$CI_COMMIT_REF_NAME" \
    --certificate-oidc-issuer "$CI_SERVER_URL" \
    "$IMAGE_URI" | jq .
```

The verification step ensures that the provenance data attached to the image is correct, and was not tampered with.
The `cosign verify` command verifies the signature and checks the annotations. The output shows all the annotations
you've added to the image during the signing process.

In the output, you can see all annotations added earlier, including:

- GitLab user name
- Pipeline ID and URL
- Job ID and URL
- Commit SHA and reference name
- Project path
- Image source and revision

By verifying these annotations, you can ensure that the image's provenance data is intact
and matches what you expect based on your build process.

## Example `.gitlab-ci.yml` configuration

When you follow all the steps mentioned above, your `.gitlab-ci.yml` should look similar to this:

```yaml
stages:
  - build

build_and_sign:
  stage: build
  image: docker:latest
  services:
    - docker:dind  # Enable Docker-in-Docker service to allow Docker commands inside the container
  variables:
    IMAGE_TAG: $CI_COMMIT_SHORT_SHA  # Use the commit short SHA as the image tag
    IMAGE_URI: $CI_REGISTRY_IMAGE:$IMAGE_TAG  # Construct the full image URI with the registry, project path, and tag
    COSIGN_YES: "true"  # Automatically confirm actions in Cosign without user interaction
    FF_SCRIPT_SECTIONS: "true"  # Enables GitLab's CI script sections for better multi-line script output
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore  # Provide an OIDC token for keyless signing with Cosign
  before_script:
    - apk add --no-cache cosign jq  # Install Cosign (mandatory) and jq (optional)
    - docker login -u "gitlab-ci-token" -p "$CI_JOB_TOKEN" "$CI_REGISTRY"  # Log in to the Docker registry using GitLab CI token
  script:
    # Build the Docker image using the specified tag and push it to the registry
    - docker build --pull -t "$IMAGE_URI" .
    - docker push "$IMAGE_URI"

    # Retrieve the digest of the pushed image to use in the signing step
    - IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_URI")

    # Sign the image using Cosign with annotations that provide metadata about the build and tag annotation to allow verifying
    # the tag->digest mapping (https://github.com/sigstore/cosign?tab=readme-ov-file#tag-signing)
    - |
      cosign sign "$IMAGE_DIGEST" \
        --annotations "com.gitlab.ci.user.name=$GITLAB_USER_NAME" \
        --annotations "com.gitlab.ci.pipeline.id=$CI_PIPELINE_ID" \
        --annotations "com.gitlab.ci.pipeline.url=$CI_PIPELINE_URL" \
        --annotations "com.gitlab.ci.job.id=$CI_JOB_ID" \
        --annotations "com.gitlab.ci.job.url=$CI_JOB_URL" \
        --annotations "com.gitlab.ci.commit.sha=$CI_COMMIT_SHA" \
        --annotations "com.gitlab.ci.commit.ref.name=$CI_COMMIT_REF_NAME" \
        --annotations "com.gitlab.ci.project.path=$CI_PROJECT_PATH" \
        --annotations "org.opencontainers.image.source=$CI_PROJECT_URL" \
        --annotations "org.opencontainers.image.revision=$CI_COMMIT_SHA" \
        --annotations "tag=$IMAGE_TAG"

    # Verify the image signature using Cosign to ensure it matches the expected annotations and certificate identity
    - |
      cosign verify \
        --annotations "tag=$IMAGE_TAG" \
        --certificate-identity "$CI_PROJECT_URL//.gitlab-ci.yml@refs/heads/$CI_COMMIT_REF_NAME" \
        --certificate-oidc-issuer "$CI_SERVER_URL" \
        "$IMAGE_URI" | jq .  # Use jq to format the verification output for easier readability
```
