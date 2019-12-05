# GitLab Container Registry

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/4040) in GitLab 8.8.
> - Docker Registry manifest `v1` support was added in GitLab 8.9 to support Docker
>   versions earlier than 1.10.
> - Starting from GitLab 8.12, if you have 2FA enabled in your account, you need
>   to pass a [personal access token](../../profile/personal_access_tokens.md) instead of your password in order to
>   login to GitLab's Container Registry.
> - Multiple level image names support was added in GitLab 9.1.

NOTE: **Note:**
This document is the user guide. To learn how to enable GitLab Container
Registry across your GitLab instance, visit the
[administrator documentation](../../../administration/packages/container_registry.md).

With the Docker Container Registry integrated into GitLab, every project can
have its own space to store its Docker images.

You can read more about Docker Registry at <https://docs.docker.com/registry/introduction/>.

## Enable the Container Registry for your project

If you cannot find the **Packages > Container Registry** entry under your
project's sidebar, it is not enabled in your GitLab instance. Ask your
administrator to enable GitLab Container Registry following the
[administration documentation](../../../administration/packages/container_registry.md).

If you are using GitLab.com, this is enabled by default so you can start using
the Registry immediately. Currently there is a soft (10GB) size restriction for
Registry on GitLab.com, as part of the [repository size limit](../../project/repository/index.md).

Once enabled for your GitLab instance, to enable Container Registry for your
project:

1. Go to your project's **Settings > General** page.
1. Expand the **Visibility, project features, permissions** section
   and enable the **Container Registry** feature on your project. For new
   projects this might be enabled by default. For existing projects
   (prior GitLab 8.8), you will have to explicitly enable it.
1. Press **Save changes** for the changes to take effect. You should now be able
   to see the **Packages > Container Registry**  link in the sidebar.

## Build and push images

> **Notes:**
>
> - Moving or renaming existing container registry repositories is not supported
>   once you have pushed images because the images are signed, and the
>   signature includes the repository name.
> - To move or rename a repository with a container registry you will have to
>   delete all existing images.

If you visit the **Packages > Container Registry** link under your project's
menu, you can see the explicit instructions to login to the Container Registry
using your GitLab credentials.

For example if the Registry's URL is `registry.example.com`, then you should be
able to login with:

```sh
docker login registry.example.com
```

Building and publishing images should be a straightforward process. Just make
sure that you are using the Registry URL with the namespace and project name
that is hosted on GitLab:

```sh
docker build -t registry.example.com/group/project/image .
docker push registry.example.com/group/project/image
```

Your image will be named after the following scheme:

```text
<registry URL>/<namespace>/<project>/<image>
```

GitLab supports up to three levels of image repository names.

Following examples of image tags are valid:

```text
registry.example.com/group/project:some-tag
registry.example.com/group/project/image:latest
registry.example.com/group/project/my/image:rc1
```

## Use images from GitLab Container Registry

To download and run a container from images hosted in GitLab Container Registry,
use `docker run`:

```sh
docker run [options] registry.example.com/group/project/image [arguments]
```

For more information on running Docker containers, visit the
[Docker documentation](https://docs.docker.com/engine/userguide/intro/).

## Control Container Registry from within GitLab

GitLab offers a simple Container Registry management panel. Go to your project
and click **Packages > Container Registry** in the project menu.

This view will show you all tags in your project and will easily allow you to
delete them.

## Build and push images using GitLab CI

NOTE: **Note:**
This feature requires GitLab 8.8 and GitLab Runner 1.2.

Make sure that your GitLab Runner is configured to allow building Docker images by
following the [Using Docker Build](../../../ci/docker/using_docker_build.md)
and [Using the GitLab Container Registry documentation](../../../ci/docker/using_docker_build.md#using-the-gitlab-container-registry).
Alternatively, you can [build images with Kaniko](../../../ci/docker/using_kaniko.md) if the Docker builds are not an option for you.

## Using with private projects

> Personal Access tokens were [introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11845) in GitLab 9.3.
> Project Deploy Tokens were [introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/17894) in GitLab 10.7

If a project is private, credentials will need to be provided for authorization.
There are two ways to do this:

- By using a [personal access token](../../profile/personal_access_tokens.md).
- By using a [deploy token](../../project/deploy_tokens/index.md).

The minimal scope needed for both of them is `read_registry`.

Example of using a token:

```sh
docker login registry.example.com -u <username> -p <token>
```

## Troubleshooting the GitLab Container Registry

### Docker connection error

A Docker connection error can occur when there are special characters in either the group,
project or branch name. Special characters can include:

- Leading underscore
- Trailing hyphen/dash

To get around this, you can [change the group path](../../group/index.md#changing-a-groups-path),
[change the project path](../../project/settings/index.md#renaming-a-repository) or change the branch
name.

### Troubleshoot as a GitLab server admin

Troubleshooting the GitLab Container Registry, most of the times, requires
administration access to the GitLab server.

[Read how to troubleshoot the Container Registry](../../../administration/packages/container_registry.md#troubleshooting).
