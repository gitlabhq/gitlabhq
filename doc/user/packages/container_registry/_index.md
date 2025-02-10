---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab container registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use the integrated container registry to store container images for each GitLab project.

To enable the container registry for your GitLab instance, see the [administrator documentation](../../../administration/packages/container_registry.md).

NOTE:
If you pull container images from Docker Hub, you can use the
[GitLab Dependency Proxy](../dependency_proxy/_index.md#use-the-dependency-proxy-for-docker-images) to avoid
rate limits and speed up your pipelines.

## View the container registry

You can view the container registry for a project or group.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Deploy > Container Registry**.

You can search, sort, filter, and [delete](delete_container_registry_images.md#use-the-gitlab-ui)
your container images. You can share a filtered view by copying the URL from your browser.

### View the tags of a specific container image in the container registry

You can use the container registry **Tag Details** page to view a list of tags associated with a given container image:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Deploy > Container Registry**.
1. Select your container image.

You can view details about each tag, such as when it was published, how much storage it consumes,
and the manifest and configuration digests.

You can search, sort (by tag name), and [delete](delete_container_registry_images.md#use-the-gitlab-ui)
tags on this page. You can share a filtered view by copying the URL from your browser.

## Use container images from the container registry

To download and run a container image hosted in the container registry:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Deploy > Container Registry**.
1. Find the container image you want to work with and select **Copy image path** （**{copy-to-clipboard}**）.

1. Use `docker run` with the copied link:

   ```shell
   docker run [options] registry.example.com/group/project/image [arguments]
   ```

NOTE:
You must [authenticate with the container registry](authenticate_with_container_registry.md) to download
container images from a private repository.

For more information on running container images, see the [Docker documentation](https://docs.docker.com/get-started/).

## Naming convention for your container images

Your container images must follow this naming convention:

```plaintext
<registry server>/<namespace>/<project>[/<optional path>]
```

For example, if your project is `gitlab.example.com/mynamespace/myproject`,
then your container image must be named `gitlab.example.com/mynamespace/myproject`.

You can append additional names to the end of a container image name, up to two levels deep.

For example, these are all valid names for container images in the project named `myproject`:

```plaintext
registry.example.com/mynamespace/myproject:some-tag
```

```plaintext
registry.example.com/mynamespace/myproject/image:latest
```

```plaintext
registry.example.com/mynamespace/myproject/my/image:rc1
```

## Move or rename container registry repositories

The path of a container repository always matches the related project's repository path,
so renaming or moving only the container registry is not possible. Instead, you can
[rename](../../project/working_with_projects.md#rename-a-repository) or [move](../../project/settings/migrate_projects.md)
the entire project.

Renaming projects with populated container repositories is only supported on GitLab.com.

On a self-managed instance, you can delete all container images before moving or renaming
a group or project. Alternatively, [issue 18383](https://gitlab.com/gitlab-org/gitlab/-/issues/18383#possible-workaround)
contains community suggestions to work around this limitation. [Epic 9459](https://gitlab.com/groups/gitlab-org/-/epics/9459)
proposes adding support for moving projects and groups with container repositories
to GitLab Self-Managed.

## Disable the container registry for a project

The container registry is enabled by default.

You can, however, remove the container registry for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section
   and disable **Container registry**.
1. Select **Save changes**.

The **Deploy > Container Registry** entry is removed from the project's sidebar.

## Change visibility of the container registry

By default, the container registry is visible to everyone with access to the project.
You can, however, change the visibility of the container registry for a project.

For more information about the permissions that this setting grants to users,
see [Container registry visibility permissions](#container-registry-visibility-permissions).

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand the section **Visibility, project features, permissions**.
1. Under **Container registry**, select an option from the dropdown list:

   - **Everyone With Access** (Default): The container registry is visible to everyone with access
     to the project. If the project is public, the container registry is also public. If the project
     is internal or private, the container registry is also internal or private.

   - **Only Project Members**: The container registry is visible only to project members with
     at least the Reporter role. This visibility is similar to the behavior of a private project with Container
     Registry visibility set to **Everyone With Access**.

1. Select **Save changes**.

## Container registry visibility permissions

The ability to view the container registry and pull container images is controlled by the container registry's
visibility permissions. You can change the visibility through the [visibility setting on the UI](#change-visibility-of-the-container-registry)
or the [API](../../../api/container_registry.md#change-the-visibility-of-the-container-registry).
[Other permissions](../../permissions.md) such as updating the container registry and pushing or deleting container images are not affected by
this setting. However, disabling the container registry disables all container registry operations.

|                                                                                                                   |                                               | Anonymous<br/>(Everyone on internet) | Guest | Reporter, Developer, Maintainer, Owner |
|-------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|--------------------------------------|-------|----------------------------------------|
| Public project with container registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API)   | View container registry <br/> and pull images | Yes                                  | Yes   | Yes                                    |
| Public project with container registry visibility <br/> set to **Only Project Members** (UI) or `private` (API)   | View container registry <br/> and pull images | No                                   | No    | Yes                                    |
| Internal project with container registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API) | View container registry <br/> and pull images | No                                   | Yes   | Yes                                    |
| Internal project with container registry visibility <br/> set to **Only Project Members** (UI) or `private` (API) | View container registry <br/> and pull images | No                                   | No    | Yes                                    |
| Private project with container registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API)  | View container registry <br/> and pull images | No                                   | No    | Yes                                    |
| Private project with container registry visibility <br/> set to **Only Project Members** (UI) or `private` (API)  | View container registry <br/> and pull images | No                                   | No    | Yes                                    |
| Any project with container registry `disabled`                                                                    | All operations on container registry          | No                                   | No    | No                                     |

## Supported image types

> - OCI conformance [introduced](https://gitlab.com/groups/gitlab-org/-/epics/10345) in GitLab 16.6.

The container registry supports the [Docker V2](https://distribution.github.io/distribution/spec/manifest-v2-2/)
and [Open Container Initiative (OCI)](https://github.com/opencontainers/image-spec/blob/main/spec.md)
image formats. Additionally, the container registry [conforms to the OCI distribution specification](https://conformance.opencontainers.org/#gitlab-container-registry).

OCI support means that you can host OCI-based image formats in the registry, such as [Helm 3+ chart packages](https://helm.sh/docs/topics/registries/). There is no distinction between image formats in the GitLab [API](../../../api/container_registry.md) and the UI. [Issue 38047](https://gitlab.com/gitlab-org/gitlab/-/issues/38047) addresses this distinction, starting with Helm.

## Container image signatures

> - Container image signature display [introduced](https://gitlab.com/groups/gitlab-org/-/epics/7856) in GitLab 17.1.

In the GitLab container registry, you can use the [OCI 1.1 manifest `subject` field](https://github.com/opencontainers/image-spec/blob/v1.1.0/manifest.md)
to associate container images with [Cosign signatures](../../../ci/yaml/signing_examples.md).
You can then view signature information alongside its associated container image without having to
search for that signature's tag.

When [viewing a container image's tags](#view-the-tags-of-a-specific-container-image-in-the-container-registry), you see an icon displayed
next to each tag that has an associated signature. To see the details of the signature, select the icon.

Prerequisites:

- To sign container images, Cosign v2.0 or later.
- For GitLab Self-Managed, you need a
  [GitLab container registry configured with a metadata database](../../../administration/packages/container_registry_metadata_database.md)
  to display signatures.

### Sign container images with OCI referrer data

To add referrer data to signatures using Cosign, you must:

- Set the `COSIGN_EXPERIMENTAL` environment variable to `1`.
- Add `--registry-referrers-mode oci-1-1` to the signature command.

For example:

```shell
COSIGN_EXPERIMENTAL=1 cosign sign --registry-referrers-mode oci-1-1 <container image>
```

NOTE:
While the GitLab container registry supports the OCI 1.1 manifest `subject` field, it does not fully
implement the [OCI 1.1 Referrers API](https://github.com/opencontainers/distribution-spec/blob/v1.1.0/spec.md#listing-referrers).
