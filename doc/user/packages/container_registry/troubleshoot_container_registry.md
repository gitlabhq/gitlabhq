---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting the GitLab container registry
---

You must sign in to GitLab with administrator rights to troubleshoot most issues with the GitLab container registry.

You can find [additional troubleshooting information](../../../administration/packages/container_registry_troubleshooting.md) in the GitLab container registry administration documentation.

## Migrating OCI container images to GitLab container registry

Migrating container images to the GitLab registry is not supported, but [epic](https://gitlab.com/groups/gitlab-org/-/epics/5210) proposes to change this behavior.

You can use third-party tools to migrate container images. For example, [skopeo](https://github.com/containers/skopeo), can [copy container images](https://github.com/containers/skopeo#copying-images) between various storage mechanisms. You can use skopeo to copy from container registries, container storage backends, local directories, and local OCI-layout directories to the GitLab container registry.

## Docker connection error

A Docker connection error can occur when there are special characters in either the group,
project, or branch name. Special characters include:

- A leading underscore.
- A trailing hyphen or dash.

To resolve this error, you can change the [group path](../../group/manage.md#change-a-groups-path),
the [project path](../../project/working_with_projects.md#rename-a-repository) or the branch name.

You may get a `404 Not Found` or `Unknown Manifest` error message if you use
Docker Engine 17.11 or earlier. Current versions of Docker Engine use
the [v2 API](https://distribution.github.io/distribution/spec/manifest-v2-2/).

The images in your GitLab container registry must use the Docker v2 API.
For information on how to update version 1 images to version 2, see the [Docker documentation](https://distribution.github.io/distribution/spec/deprecated-schema-v1/).

## `Blob unknown to registry` error when pushing a manifest list

When [pushing a Docker manifest list](https://docs.docker.com/reference/cli/docker/manifest/#create-and-push-a-manifest-list)
to the GitLab container registry, you may receive the error
`manifest blob unknown: blob unknown to registry`. This error is likely caused by having multiple images
with different architectures spread out over several repositories instead of the same repository.

For example, you may have two images, each representing an architecture:

- The `amd64` platform.
- The `arm64v8` platform.

To build a multi-arch image with these images, you must push them to the same repository as the
multi-arch image.

To address the `Blob unknown to registry` error, include the architecture in the tag name of
individual images. For example, use `mygroup/myapp:1.0.0-amd64` and `mygroup/myapp:1.0.0-arm64v8`.
You can then tag the manifest list with `mygroup/myapp:1.0.0`.

## Unable to change project path or transfer a project

If you try to change a project path or transfer a project to a new namespace,
you may receive one of the following errors:

- Project cannot be transferred because tags are present in its container registry.
- Namespace cannot be moved because at least one project has tags in the container registry.

This error occurs when the project has images in the container registry.
You must delete or move these images before you change the path or transfer
the project.

The following procedure uses these sample project names:

- For the current project: `gitlab.example.com/org/build/sample_project/cr:v2.9.1`.
- For the new project: `gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1`.

1. Download the Docker images on your computer:

   ```shell
   docker login gitlab.example.com
   docker pull gitlab.example.com/org/build/sample_project/cr:v2.9.1
   ```

   NOTE:
   Use either a [personal access token](../../profile/personal_access_tokens.md) or a
   [deploy token](../../project/deploy_tokens/_index.md) to authenticate your user account.

1. Rename the images to match the new project name:

   ```shell
   docker tag gitlab.example.com/org/build/sample_project/cr:v2.9.1 gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1
   ```

1. Delete the images in the old project by using the [UI](delete_container_registry_images.md) or [API](../../../api/packages.md#delete-a-project-package).
   There may be a delay while the images are queued and deleted.
1. Change the path or transfer the project:

   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Settings > General**.
   1. Expand the **Advanced** section.
   1. In the **Change path** text box, edit the path.
   1. Select **Change path**.

1. Restore the images:

   ```shell
   docker push gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1
   ```

See this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18383) for details.

## `Failed to pull image` messages

You might receive a [`Failed to pull image'](../../../ci/debugging.md#failed-to-pull-image-messages)
error message when a CI/CD job is unable to pull a container image from a project with a limited
[CI/CD job token scope](../../../ci/jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects).

## Slow uploads when using `kaniko` to push large images

When you push large images with `kaniko`, you might experience uncharacteristically long delays.

This is typically a result of [a performance issue with `kaniko` and HTTP/2](https://github.com/GoogleContainerTools/kaniko/issues/2751).
The current workaround is to use HTTP/1.1 when pushing with `kaniko`.

To use HTTP/1.1, set the `GODEBUG` environment variable to `"http2client=0"`.

## `OCI manifest found, but accept header does not support OCI manifests` error

If you are unable to pull an image, the registry logs could have an error similar to:

```plaintext
manifest unknown: OCI manifest found, but accept header does not support OCI manifests
```

This error happens when a client does not submit the correct `Accept: application/vnd.oci.image.manifest.v1+json`
header. Make sure your Docker client version is up to date. If you are using a third party tool,
make sure it can handle OCI manifests.
