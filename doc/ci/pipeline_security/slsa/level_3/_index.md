---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SLSA level 3 provenance attestations
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/547865) in GitLab 18.3 [with a flag](../../../../administration/feature_flags/_index.md) named `slsa_provenance_statement`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

GitLab can generate SLSA level 3 compatible provenance attestations.
The key differences between level 2 and 3 provenance attestation are [isolation and "unforgeable" requirements](https://slsa.dev/spec/v1.2/build-requirements#isolated).

For the details of attestations, see the GitLab [SLSA provenance specification](provenance_v1.md).

## Prerequisites

These conditions need to be met for the attestation of any container or artifact:

- The project associated with the build is public. This requirement is enforced to prevent accidental
  disclosure of information to [Rekor](https://docs.sigstore.dev/logging/overview/).
- The build must use the `build` stage.
- The `slsa_provenance_statement` feature flag must be enabled for the project.

## Generate an attestation for artifacts

To generate an attestation for all artifacts produced by a build:

- Set the `ATTEST_BUILD_ARTIFACTS` CI/CD variable is `true`.
- The artifact must not exceed 100 MB.

For example, GitLab generates an attestation for the artifacts in this CI/CD job:

```yaml
build-job:
  stage: build
  variables:
    ATTEST_BUILD_ARTIFACTS: true
  script:
    - echo "Hello, $GITLAB_USER_LOGIN!"
    - echo "Hello, $GITLAB_USER_LOGIN!" > test.txt
  artifacts:
    paths:
      - test.txt
```

## Generate an attestation for a container

To generate an attestation for a container:

- Set the CI/CD variable `ATTEST_CONTAINER_IMAGES` to `true`.
- Set the `IMAGE_DIGEST` variable to a valid SHA256 reference, with this format:

  ```plaintext
  sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  org/project-name@sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  ```

For example, GitLab generates an attestation for the image created in this CI/CD job:

```yaml
build-dockerhub:
  stage: build
  variables:
    ATTEST_CONTAINER_IMAGES: true
    CI_REGISTRY: docker.io
    DOCKER_IMAGE_NAME: sroqueworcel/test-slsa-sbom:stable
  script:
    - echo $DOCKER_REGISTRY_PASSWORD | docker login $CI_REGISTRY -u $DOCKER_REGISTRY_USER --password-stdin
    - docker build -t $DOCKER_IMAGE_NAME .
    - docker push $DOCKER_IMAGE_NAME
    - IMAGE_DIGEST="$(docker inspect --format='{{index .Id}}' "$DOCKER_IMAGE_NAME")"
    - echo "IMAGE_DIGEST=$IMAGE_DIGEST" >> build.env
  artifacts:
    reports:
      dotenv: build.env
```

## View attestations

Successful attestations are stored in the attestations page. To view the attestations:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Attestations**.

If the attestation is not successful, the CI/CD job log shows an error.

You can also fetch successful attestations with the [Attestations API](../../../../api/attestations.md).

## Verifying attestations

You can verify both artifacts and containers by using the `glab` command-line interface.
For example:

- A successful verification:

  ```shell
  % glab attestation verify ~/file-or-container -p org/project-name
  Artifact provenance successfully verified. Signatures confirm file.txt was attested by org/project-name
  ```

- A failed verification:

  ```shell
  % glab attestation verify ~/file.txt -p org/project-name

     ERROR

    Unable to find a provenance statement for 1f9e5808a340916aa5618ee13a893dcf9d4f7e2d42a254be0f7eb06a094ab8ea.
  ```
