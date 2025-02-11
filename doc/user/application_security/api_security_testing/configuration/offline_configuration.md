---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Offline configuration
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

For instances in an environment with limited, restricted, or intermittent access to external resources through the internet, some adjustments are required for the API security testing job to successfully run.

Steps:

1. Host the Docker image in a local container registry.
1. Set the `SECURE_ANALYZERS_PREFIX` to the local container registry.

The Docker image for API security testing must be pulled (downloaded) from the public registry and then pushed (imported) into a local registry. The GitLab container registry can be used to locally host the Docker image. This process can be performed using a special template. See [loading Docker images onto your offline host](../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host) for instructions.

Once the Docker image is hosted locally, the `SECURE_ANALYZERS_PREFIX` variable is set with the location of the local registry. The variable must be set such that concatenating `/api-security:2` results in a valid image location.

NOTE:
API security testing and API Fuzzing both use the same underlying Docker image `api-security:2`.

For example, the below line sets a registry for the image `registry.gitlab.com/security-products/api-security:2`:

`SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/security-products"`

NOTE:
Setting `SECURE_ANALYZERS_PREFIX` changes the Docker image registry location for all GitLab Secure templates.

For more information, see [Offline environments](../../offline_deployments/_index.md).
