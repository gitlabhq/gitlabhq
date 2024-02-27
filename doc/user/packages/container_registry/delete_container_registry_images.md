---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Delete container images from the container registry

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can delete container images from your container registry.

WARNING:
Deleting container images is a destructive action and can't be undone. To restore
a deleted container image, you must rebuild and re-upload it.

## Garbage collection

Deleting a container image on self-managed instances doesn't free up storage space, it only marks the image
as eligible for deletion. To actually delete unreferenced container images and recover storage space, administrators
must run [garbage collection](../../../administration/packages/container_registry.md#container-registry-garbage-collection).

On GitLab.com, the latest version of the container registry includes an automatic online garbage
collector. For more information, see [this blog post](https://about.gitlab.com/blog/2021/10/25/gitlab-com-container-registry-update/).
In this new version of the container registry, the following are automatically scheduled
for deletion in 24 hours if left unreferenced:

- Layers that aren't referenced by any image manifest.
- Image manifests that have no tags and aren't referenced by another manifest (like multi-architecture images).

The online garbage collector is an instance-wide feature, and applies to all namespaces.

## Use the GitLab UI

To delete container images using the GitLab UI:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. For:
   - A group, select **Operate > Container Registry**.
   - A project, select **Deploy > Container Registry**.
1. From the **Container Registry** page, you can select what you want to delete,
   by either:

   - Deleting the entire repository, and all the tags it contains, by selecting
     the red **{remove}** **Trash** icon.
   - Navigating to the repository, and deleting tags individually or in bulk
     by selecting the red **{remove}** **Trash** icon next to the tag you want
     to delete.

1. On the dialog, select **Remove tag**.

## Use the GitLab API

You can use the API to automate the process of deleting container images. For more
information, see the following endpoints:

- [Delete a Registry repository](../../../api/container_registry.md#delete-registry-repository)
- [Delete an individual Registry repository tag](../../../api/container_registry.md#delete-a-registry-repository-tag)
- [Delete Registry repository tags in bulk](../../../api/container_registry.md#delete-registry-repository-tags-in-bulk)

## Use GitLab CI/CD

NOTE:
GitLab CI/CD doesn't provide a built-in way to remove your container images. This example uses a
third-party tool called [reg](https://github.com/genuinetools/reg) that talks to the GitLab Registry API.
For assistance with this third-party tool, see [the issue queue for reg](https://github.com/genuinetools/reg/issues).

The following example defines two stages: `build`, and `clean`. The `build_image` job builds a container
image for the branch, and the `delete_image` job deletes it. The `reg` executable is downloaded and used to
remove the container image matching the `$CI_PROJECT_PATH:$CI_COMMIT_REF_SLUG`
[predefined CI/CD variable](../../../ci/variables/predefined_variables.md).

To use this example, change the `IMAGE_TAG` variable to match your needs.

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
  before_script:
    - curl --fail --show-error --location "https://github.com/genuinetools/reg/releases/download/v$REG_VERSION/reg-linux-amd64" --output ./reg
    - echo "$REG_SHA256  ./reg" | sha256sum -c -
    - chmod a+x ./reg
  image: curlimages/curl:7.86.0
  script:
    - ./reg rm -d --auth-url $CI_REGISTRY -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $IMAGE_TAG
  stage: clean
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
    REG_SHA256: ade837fc5224acd8c34732bf54a94f579b47851cc6a7fd5899a98386b782e228
    REG_VERSION: 0.16.1
  only:
    - branches
  except:
    - main
```

NOTE:
You can download the latest `reg` release from [the releases page](https://github.com/genuinetools/reg/releases), then update
the code example by changing the `REG_SHA256` and `REG_VERSION` variables defined in the `delete_image` job.

## Use a cleanup policy

You can create a per-project [cleanup policy](reduce_container_registry_storage.md#cleanup-policy) to ensure older tags and
images are regularly removed from the container registry.
