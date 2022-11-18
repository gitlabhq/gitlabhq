---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Container Registry **(FREE)**

> Searching by image repository name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31322) in GitLab 13.0.

NOTE:
If you pull container images from Docker Hub, you can use the [GitLab Dependency Proxy](../dependency_proxy/index.md#use-the-dependency-proxy-for-docker-images) 
to avoid rate limits and speed up your pipelines.

With the Docker Container Registry integrated into GitLab, every GitLab project can
have its own space to store its Docker images.

You can read more about Docker Registry at <https://docs.docker.com/registry/introduction/>.

This document is the user guide. To learn how to enable the Container
Registry for your GitLab instance, visit the
[administrator documentation](../../../administration/packages/container_registry.md).

## View the Container Registry

You can view the Container Registry for a project or group.

1. Go to your project or group.
1. Go to **Packages and registries > Container Registry**.

You can search, sort, filter, and [delete](#delete-images-using-the-gitlab-ui)
containers on this page. You can share a filtered view by copying the URL from your browser.

Only members of the project or group can access a private project's Container Registry.

If a project is public, so is the Container Registry.

### View the tags of a specific image

You can view a list of tags associated with a given container image:

1. Go to your project or group.
1. Go to **Packages and registries > Container Registry**.
1. Select the container image you are interested in.

This brings up the Container Registry **Tag Details** page. You can view details about each tag,
such as when it was published, how much storage it consumes, and the manifest and configuration
digests.

You can search, sort (by tag name), filter, and [delete](#delete-images-using-the-gitlab-ui)
tags on this page. You can share a filtered view by copying the URL from your browser.

## Use images from the Container Registry

To download and run a container image hosted in the GitLab Container Registry:

1. Copy the link to your container image:
   - Go to your project or group's **Packages and registries > Container Registry**
     and find the image you want.
   - Next to the image name, select **Copy**.

    ![Container Registry image URL](img/container_registry_hover_path_13_4.png)

1. Use `docker run` with the image link:

   ```shell
   docker run [options] registry.example.com/group/project/image [arguments]
   ```

[Authentication](#authenticate-with-the-container-registry) is needed to download images from a private repository.

For more information on running Docker containers, visit the
[Docker documentation](https://docs.docker.com/get-started/).

## Image naming convention

Images follow this naming convention:

```plaintext
<registry URL>/<namespace>/<project>/<image>
```

If your project is `gitlab.example.com/mynamespace/myproject`, for example,
then your image must be named `gitlab.example.com/mynamespace/myproject` at a minimum.

You can append additional names to the end of an image name, up to two levels deep.

For example, these are all valid image names for images in the project named `myproject`:

```plaintext
registry.example.com/mynamespace/myproject:some-tag
```

```plaintext
registry.example.com/mynamespace/myproject/image:latest
```

```plaintext
registry.example.com/mynamespace/myproject/my/image:rc1
```

## Authenticate with the Container Registry

To authenticate with the Container Registry, you can use a:

- [Personal access token](../../profile/personal_access_tokens.md).
- [Deploy token](../../project/deploy_tokens/index.md).
- [Project access token](../../project/settings/project_access_tokens.md).
- [Group access token](../../group/settings/group_access_tokens.md).

All of these require the minimum scope to be:

- For read (pull) access, `read_registry`.
- For write (push) access, `write_registry` & `read_registry`.

To authenticate, run the `docker` command. For example:

   ```shell
   docker login registry.example.com -u <username> -p <token>
   ```

## Build and push images by using Docker commands

Before you can build and push images, you must [authenticate](#authenticate-with-the-container-registry) with the Container Registry.

To build and push to the Container Registry:

1. Authenticate with the Container Registry.

1. Run the command to build or push. For example, to build:

   ```shell
   docker build -t registry.example.com/group/project/image .
   ```

   Or to push:

   ```shell
   docker push registry.example.com/group/project/image
   ```

To view these commands, go to your project's **Packages and registries > Container Registry**.

## Build and push by using GitLab CI/CD

Use [GitLab CI/CD](../../../ci/yaml/index.md) to build and push images to the
Container Registry. Use it to test, build, and deploy your project from the Docker
image you created.

### Authenticate by using GitLab CI/CD

Before you can build and push images by using GitLab CI/CD, you must authenticate with the Container Registry.

To use CI/CD to authenticate, you can use:

- The `CI_REGISTRY_USER` CI/CD variable.

  This variable has read-write access to the Container Registry and is valid for
  one job only. Its password is also automatically created and assigned to `CI_REGISTRY_PASSWORD`.

  ```shell
  docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  ```

- A [CI job token](../../../ci/jobs/ci_job_token.md).

  ```shell
  docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  ```

- A [deploy token](../../project/deploy_tokens/index.md#gitlab-deploy-token) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `write_registry`.

  ```shell
  docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
  ```

- A [personal access token](../../profile/personal_access_tokens.md) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `write_registry`.

  ```shell
  docker login -u <username> -p <access_token> $CI_REGISTRY
  ```

### Configure your `.gitlab-ci.yml` file

You can configure your `.gitlab-ci.yml` file to build and push images to the Container Registry.

- If multiple jobs require authentication, put the authentication command in the `before_script`.
- Before building, use `docker build --pull` to fetch changes to base images. It takes slightly
  longer, but it ensures your image is up-to-date.
- Before each `docker run`, do an explicit `docker pull` to fetch
  the image that was just built. This step is especially important if you are
  using multiple runners that cache images locally.

  If you use the Git SHA in your image tag, each job is unique and you
  should never have a stale image. However, it's still possible to have a
  stale image if you re-build a given commit after a dependency has changed.
- Don't build directly to the `latest` tag because multiple jobs may be
  happening simultaneously.

### Container Registry examples with GitLab CI/CD

If you're using Docker-in-Docker on your runners, this is how your `.gitlab-ci.yml`
should look:

```yaml
build:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY/group/project/image:latest .
    - docker push $CI_REGISTRY/group/project/image:latest
```

You can also make use of [other CI/CD variables](../../../ci/variables/index.md) to avoid hard-coding:

```yaml
build:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
```

In this example, `$CI_REGISTRY_IMAGE` resolves to the address of the registry tied
to this project. `$CI_COMMIT_REF_NAME` resolves to the branch or tag name, which
can contain forward slashes. Image tags can't contain forward slashes. Use
`$CI_COMMIT_REF_SLUG` as the image tag. You can declare the variable, `$IMAGE_TAG`,
combining `$CI_REGISTRY_IMAGE` and `$CI_REGISTRY_IMAGE` to save some typing in the
`script` section.

Here's a more elaborate example that splits up the tasks into 4 pipeline stages,
including two tests that run in parallel. The `build` is stored in the container
registry and used by subsequent stages, downloading the image
when needed. Changes to `main` also get tagged as `latest` and deployed using
an application-specific deploy script:

```yaml
image: docker:20.10.16
services:
  - docker:20.10.16-dind

stages:
  - build
  - test
  - release
  - deploy

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"
  CONTAINER_TEST_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  CONTAINER_RELEASE_IMAGE: $CI_REGISTRY_IMAGE:latest

before_script:
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

build:
  stage: build
  script:
    - docker build --pull -t $CONTAINER_TEST_IMAGE .
    - docker push $CONTAINER_TEST_IMAGE

test1:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/tests

test2:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/another/test

release-image:
  stage: release
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker tag $CONTAINER_TEST_IMAGE $CONTAINER_RELEASE_IMAGE
    - docker push $CONTAINER_RELEASE_IMAGE
  only:
    - main

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - main
  environment: production
```

NOTE:
This example explicitly calls `docker pull`. If you prefer to implicitly pull the
built image using `image:`, and use either the [Docker](https://docs.gitlab.com/runner/executors/docker.html)
or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes.html) executor,
make sure that [`pull_policy`](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)
is set to `always`.

### Using a Docker-in-Docker image from your Container Registry

To use your own Docker images for Docker-in-Docker, follow these steps
in addition to the steps in the
[Docker-in-Docker](../../../ci/docker/using_docker_build.md#use-docker-in-docker) section:

1. Update the `image` and `service` to point to your registry.
1. Add a service [alias](../../../ci/services/index.md#available-settings-for-services).

Below is an example of what your `.gitlab-ci.yml` should look like:

```yaml
build:
  image: $CI_REGISTRY/group/project/docker:20.10.16
  services:
    - name: $CI_REGISTRY/group/project/docker:20.10.16-dind
      alias: docker
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

If you forget to set the service alias, the `docker:20.10.16` image is unable to find the
`dind` service, and an error like the following is thrown:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

### Using a Docker-in-Docker image with Dependency Proxy

To use your own Docker images with Dependency Proxy, follow these steps
in addition to the steps in the
[Docker-in-Docker](../../../ci/docker/using_docker_build.md#use-docker-in-docker) section:

1. Update the `image` and `service` to point to your registry.
1. Add a service [alias](../../../ci/services/index.md#available-settings-for-services).

Below is an example of what your `.gitlab-ci.yml` should look like:

```yaml
build:
  image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:20.10.16
  services:
    - name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:18.09.7-dind
      alias: docker
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

If you forget to set the service alias, the `docker:20.10.16` image is unable to find the
`dind` service, and an error like the following is thrown:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

## Delete images

You can delete images from your Container Registry in multiple ways.

WARNING:
Deleting images is a destructive action and can't be undone. To restore
a deleted image, you must rebuild and re-upload it.

On self-managed instances, deleting an image doesn't free up storage space - it only marks the image
as eligible for deletion. To actually delete images and recover storage space, in case they're
unreferenced, administrators must run [garbage collection](../../../administration/packages/container_registry.md#container-registry-garbage-collection).

On GitLab.com, the latest version of the Container Registry includes an automatic online garbage
collector. For more information, see [this blog post](https://about.gitlab.com/blog/2021/10/25/gitlab-com-container-registry-update/).
The automatic online garbage collector is an instance-wide feature, rolling out gradually to a subset
of the user base. Some new image repositories created from GitLab 14.5 onward are served by this
new version of the Container Registry. In this new version of the Container Registry, layers that aren't
referenced by any image manifest, and image manifests that have no tags and aren't referenced by another
manifest (such as multi-architecture images), are automatically scheduled for deletion after 24 hours if
left unreferenced.

### Delete images using the GitLab UI

To delete images using the GitLab UI:

1. Go to your project's or group's **Packages and registries > Container Registry**.
1. From the **Container Registry** page, you can select what you want to delete,
   by either:

   - Deleting the entire repository, and all the tags it contains, by selecting
     the red **{remove}** **Trash** icon.
   - Navigating to the repository, and deleting tags individually or in bulk
     by selecting the red **{remove}** **Trash** icon next to the tag you want
     to delete.

1. In the dialog box, select **Remove tag**.

### Delete images using the API

If you want to automate the process of deleting images, GitLab provides an API. For more
information, see the following endpoints:

- [Delete a Registry repository](../../../api/container_registry.md#delete-registry-repository)
- [Delete an individual Registry repository tag](../../../api/container_registry.md#delete-a-registry-repository-tag)
- [Delete Registry repository tags in bulk](../../../api/container_registry.md#delete-registry-repository-tags-in-bulk)

### Delete images using GitLab CI/CD

WARNING:
GitLab CI/CD doesn't provide a built-in way to remove your images. This example
uses a third-party tool called [reg](https://github.com/genuinetools/reg)
that talks to the GitLab Registry API. You are responsible for your own actions.
For assistance with this tool, see
[the issue queue for reg](https://github.com/genuinetools/reg/issues).

The following example defines two stages: `build`, and `clean`. The
`build_image` job builds the Docker image for the branch, and the
`delete_image` job deletes it. The `reg` executable is downloaded and used to
remove the image matching the `$CI_PROJECT_PATH:$CI_COMMIT_REF_SLUG`
[predefined CI/CD variable](../../../ci/variables/predefined_variables.md).

To use this example, change the `IMAGE_TAG` variable to match your needs:

```yaml
stages:
  - build
  - clean

build_image:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
  only:
    - branches
  except:
    - main

delete_image:
  image: docker:20.10.16
  stage: clean
  services:
    - docker:20.10.16-dind
  variables:
    IMAGE_TAG: $CI_PROJECT_PATH:$CI_COMMIT_REF_SLUG
    REG_SHA256: ade837fc5224acd8c34732bf54a94f579b47851cc6a7fd5899a98386b782e228
    REG_VERSION: 0.16.1
  before_script:
    - apk add --no-cache curl
    - curl --fail --show-error --location "https://github.com/genuinetools/reg/releases/download/v$REG_VERSION/reg-linux-amd64" --output /usr/local/bin/reg
    - echo "$REG_SHA256  /usr/local/bin/reg" | sha256sum -c -
    - chmod a+x /usr/local/bin/reg
  script:
    - /usr/local/bin/reg rm -d --auth-url $CI_REGISTRY -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $IMAGE_TAG
  only:
    - branches
  except:
    - main
```

NOTE:
You can download the latest `reg` release from
[the releases page](https://github.com/genuinetools/reg/releases), then update
the code example by changing the `REG_SHA256` and `REG_VERSION` variables
defined in the `delete_image` job.

### Delete images by using a cleanup policy

You can create a per-project [cleanup policy](reduce_container_registry_storage.md#cleanup-policy) to ensure older tags and images are regularly removed from the
Container Registry.

## Known issues

Moving or renaming existing Container Registry repositories is not supported
after you have pushed images. The images are stored in a path that matches
the repository path. To move or rename a repository with a
Container Registry, you must delete all existing images.
Community suggestions to work around this known issue have been shared in
[issue 18383](https://gitlab.com/gitlab-org/gitlab/-/issues/18383#possible-workaround).

## Disable the Container Registry for a project

The Container Registry is enabled by default.

You can, however, remove the Container Registry for a project:

1. Go to your project's **Settings > General** page.
1. Expand the **Visibility, project features, permissions** section
   and disable **Container Registry**.
1. Select **Save changes**.

The **Packages and registries > Container Registry** entry is removed from the project's sidebar.

## Change visibility of the Container Registry

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18792) in GitLab 14.2.

By default, the Container Registry is visible to everyone with access to the project.
You can, however, change the visibility of the Container Registry for a project.

See the [Container Registry visibility permissions](#container-registry-visibility-permissions)
for more details about the permissions that this setting grants to users.

1. Go to your project's **Settings > General** page.
1. Expand the section **Visibility, project features, permissions**.
1. Under **Container Registry**, select an option from the dropdown list:

   - **Everyone With Access** (Default): The Container Registry is visible to everyone with access
   to the project. If the project is public, the Container Registry is also public. If the project
   is internal or private, the Container Registry is also internal or private.

   - **Only Project Members**: The Container Registry is visible only to project members with
   Reporter role or higher. This visibility is similar to the behavior of a private project with Container
   Registry visibility set to **Everyone With Access**.

1. Select **Save changes**.

## Container Registry visibility permissions

The ability to view the Container Registry and pull images is controlled by the Container Registry's
visibility permissions. You can change this through the [visibility setting on the UI](#change-visibility-of-the-container-registry)
or the [API](../../../api/container_registry.md#change-the-visibility-of-the-container-registry).
[Other permissions](../../permissions.md)
such as updating the Container Registry and pushing or deleting images are not affected by
this setting. However, disabling the Container Registry disables all Container Registry operations.

|                      |                       | Anonymous<br/>(Everyone on internet) | Guest | Reporter, Developer, Maintainer, Owner |
| -------------------- | --------------------- | --------- | ----- | ------------------------------------------ |
| Public project with Container Registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API)   | View Container Registry <br/> and pull images | Yes       | Yes   | Yes      |
| Public project with Container Registry visibility <br/> set to **Only Project Members** (UI) or `private` (API)   | View Container Registry <br/> and pull images | No        | No    | Yes      |
| Internal project with Container Registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API) | View Container Registry <br/> and pull images | No        | Yes   | Yes      |
| Internal project with Container Registry visibility <br/> set to **Only Project Members** (UI) or `private` (API) | View Container Registry <br/> and pull images | No        | No    | Yes      |
| Private project with Container Registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API)  | View Container Registry <br/> and pull images | No        | No    | Yes      |
| Private project with Container Registry visibility <br/> set to **Only Project Members** (UI) or `private` (API)  | View Container Registry <br/> and pull images | No        | No    | Yes      |
| Any project with Container Registry `disabled` | All operations on Container Registry | No | No | No |

## Troubleshooting the GitLab Container Registry

### Migrating OCI container images to GitLab Container Registry

Migrating built container images to the GitLab registry is not a current feature. However, an [epic](https://gitlab.com/groups/gitlab-org/-/epics/5210) is open to track the work on this feature.

Some third-party tools can help migrate container images, for example, [skopeo](https://github.com/containers/skopeo), which can [copy container images](https://github.com/containers/skopeo#copying-images) between various storage mechanisms. You can use skopeo to copy from container registries, container storage backends, local directories, and local OCI-layout directories to the GitLab Container Registry.

### Docker connection error

A Docker connection error can occur when there are special characters in either the group,
project or branch name. Special characters can include:

- Leading underscore
- Trailing hyphen/dash

To get around this, you can [change the group path](../../group/manage.md#change-a-groups-path),
[change the project path](../../project/settings/index.md#rename-a-repository) or change the branch
name.

You may also get a `404 Not Found` or `Unknown Manifest` message if you are using
a Docker Engine version earlier than 17.12. Later versions of Docker Engine use
[the v2 API](https://docs.docker.com/registry/spec/manifest-v2-2/).

The images in your GitLab Container Registry must also use the Docker v2 API.
For information on how to update your images, see the [Docker help](https://docs.docker.com/registry/spec/deprecated-schema-v1).

### `Blob unknown to registry` error when pushing a manifest list

When [pushing a Docker manifest list](https://docs.docker.com/engine/reference/commandline/manifest/#create-and-push-a-manifest-list)
to the GitLab Container Registry, you may receive the error
`manifest blob unknown: blob unknown to registry`. This error is likely caused by having multiple images
with different architectures, spread out over several repositories instead of the same repository.

For example, you may have two images, each representing an architecture:

- The `amd64` platform
- The `arm64v8` platform

To build a multi-arch image with these images, you must push them to the same repository as the
multi-arch image.

To address the `Blob unknown to registry` error, include the architecture in the tag name of
individual images. For example, use `mygroup/myapp:1.0.0-amd64` and `mygroup/myapp:1.0.0-arm64v8`.
You can then tag the manifest list with `mygroup/myapp:1.0.0`.

### Troubleshoot as a GitLab server administrator

Troubleshooting the GitLab Container Registry, most of the times, requires
you to sign in to GitLab server with administrator access.

[Read how to troubleshoot the Container Registry](../../../administration/packages/container_registry.md#troubleshooting).

### Unable to change path or transfer a project

If you try to change a project's path or transfer a project to a new namespace,
you may receive one of the following errors:

- "Project cannot be transferred, because tags are present in its container registry."
- "Namespace cannot be moved because at least one project has tags in container registry."

This issue occurs when the project has images in the Container Registry.
You must delete or move these images before you can change the path or transfer
the project.

The following procedure uses these sample project names:

- For the current project: `gitlab.example.com/org/build/sample_project/cr:v2.9.1`
- For the new project: `gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1`

Use your own URLs to complete the following steps:

1. Download the Docker images on your computer:

   ```shell
   docker login gitlab.example.com
   docker pull gitlab.example.com/org/build/sample_project/cr:v2.9.1
   ```

   NOTE:
   For container registry authentication, use either a
   [personal access token](../../profile/personal_access_tokens.md) or a
   [deploy token](../../project/deploy_tokens/index.md).

1. Rename the images to match the new project name:

   ```shell
   docker tag gitlab.example.com/org/build/sample_project/cr:v2.9.1 gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1
   ```

1. Delete the images in the old project by using the [UI](#delete-images) or [API](../../../api/packages.md#delete-a-project-package).
   There may be a delay while the images are queued and deleted.
1. Change the path or transfer the project by going to **Settings > General**
   and expanding **Advanced**.
1. Restore the images:

   ```shell
   docker push gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1
   ```

Follow [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18383) for details.

### Tags on S3 backend remain after successful deletion requests

With S3 as your storage backend, tags may remain even though:

- In the UI, you see that the tags are scheduled for deletion.
- In the API, you get an HTTP `200` response.
- The registry log shows a successful `Delete` request.

An example `DELETE` request in the registry log:

```shell
{"content_type":"","correlation_id":"01FQGNSKVMHQEAVE21KYTJN2P4","duration_ms":62,"host":"localhost:5000","level":"info","method":"DELETE","msg":"access","proto":"HTTP/1.1","referrer":"","remote_addr":"127.0.0.1:47498","remote_ip":"127.0.0.1","status":202,"system":"http","time":"2021-12-22T08:58:15Z","ttfb_ms":62,"uri":"/v2/<path to repo>/tags/reference/<tag_name>","user_agent":"GitLab/<version>","written_bytes":0}
```

There may be some errors not properly cached. Follow these steps to investigate further:

1. In your configuration file, set the registry's log level to `debug`, and the S3 driver's log
   level to `logdebugwithhttpbody`. For Omnibus, make these edits in the `gitlab.rb` file:

   ```shell
      # Change the registry['log_level'] to debug
      registry['log_level'] = 'debug'

      # Set log level for registry log from storage side
      registry['storage'] = {
        's3' => {
          'bucket' => 'your-s3-bucket',
          'region' => 'your-s3-region'
        },

        'loglevel' = "logdebugwithhttpbody"
      }
   ```

   Then save and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Attempt to delete one or more tags using the GitLab UI or API.

1. Inspect the registry logs and look for a response from S3. Although the response could be
   `200 OK`, the body might have the error `AccessDenied`. This indicates a permission problem from
   the S3 side.

1. Ensure your S3 configuration has the `deleteObject` permission scope. Here's an
   [example role for an S3 bucket](../../../administration/object_storage.md#iam-permissions).
   Once adjusted, trigger another tag deletion. You should be able to successfully delete tags.

Follow [this issue](https://gitlab.com/gitlab-org/container-registry/-/issues/551) for details.

### Tags temporarily cannot be marked for deletion

GitLab is [migrating to the next generation of the Container Registry](https://gitlab.com/groups/gitlab-org/-/epics/5523).
During the migration, you may encounter difficulty deleting tags.
If you encounter an error, it's likely that your image repository is in the process of being migrated.
Wait a few minutes and try again.

### `unauthorized: authentication required` when pushing large images

When pushing large images, you might get an error like the following:

```shell
docker push gitlab.example.com/myproject/docs:latest
The push refers to a repository [gitlab.example.com/myproject/docs]
630816f32edb: Preparing
530d5553aec8: Preparing
...
4b0bab9ff599: Waiting
d1c800db26c7: Waiting
42755cf4ee95: Waiting
unauthorized: authentication required
```

On self-managed GitLab instances, by default, tokens for the Container Registry expire every five minutes.
When pushing larger images, or images that take longer than five minutes to push,
you might encounter this error. On GitLab.com, the expiration time is 15 minutes.

If you are using self-managed GitLab, you can ask an administrator to
[increase the token duration](../../../administration/packages/container_registry.md#increase-token-duration)
if necessary.
