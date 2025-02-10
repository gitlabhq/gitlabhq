---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Use Buildah in a rootless container with GitLab Runner Operator on OpenShift'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This tutorial teaches you how to successfully build images using the `buildah` tool,
with GitLab Runner deployed using [GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator)
on an OpenShift cluster.

This guide is an adaptation of [using Buildah to build images in a rootless OpenShift container](https://github.com/containers/buildah/blob/main/docs/tutorials/05-openshift-rootless-build.md)
documentation for GitLab Runner Operator.

To complete this tutorial, you will:

1. [Configure the Buildah image](#configure-the-buildah-image)
1. [Configure the service account](#configure-the-service-account)
1. [Configure the job](#configure-the-job)

## Prerequisites

- A runner already deployed to a `gitlab-runner` namespace.

## Configure the Buildah image

We start by preparing a custom image based on the `quay.io/buildah/stable:v1.23.1` image.

1. Create the `Containerfile-buildah` file:

   ```shell
   cat > Containerfile-buildah <<EOF
   FROM quay.io/buildah/stable:v1.23.1

   RUN touch /etc/subgid /etc/subuid \
   && chmod g=u /etc/subgid /etc/subuid /etc/passwd \
   && echo build:10000:65536 > /etc/subuid \
   && echo build:10000:65536 > /etc/subgid

   # Use chroot since the default runc does not work when running rootless
   RUN echo "export BUILDAH_ISOLATION=chroot" >> /home/build/.bashrc

   # Use VFS since fuse does not work
   RUN mkdir -p /home/build/.config/containers \
   && (echo '[storage]';echo 'driver = "vfs"') > /home/build/.config/containers/storage.conf

   # The buildah container will run as `build` user
   USER build
   WORKDIR /home/build
   EOF
   ```

1. Build and push the Buildah image to a container registry. Let's push to the
   [GitLab container registry](../../user/packages/container_registry/_index.md):

   ```shell
   docker build -f Containerfile-buildah -t registry.example.com/group/project/buildah:1.23.1 .
   docker push registry.example.com/group/project/buildah:1.23.1
   ```

## Configure the service account

For these steps, you need to run the commands in a terminal connected to the OpenShift cluster.

1. Run this command to create a service account named `buildah-sa`:

   ```shell
   oc create -f - <<EOF
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: buildah-sa
     namespace: gitlab-runner
   EOF
   ```

1. Give the created service account the ability to run with `anyuid` [SCC](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html):

   ```shell
   oc adm policy add-scc-to-user anyuid -z buildah-sa -n gitlab-runner
   ```

1. Use a [runner configuration template](https://docs.gitlab.com/runner/configuration/configuring_runner_operator.html#customize-configtoml-with-a-configuration-template)
   to configure Operator to use the service account we just created. Create a `custom-config.toml` file that contains:

   ```toml
   [[runners]]
     [runners.kubernetes]
         service_account_overwrite_allowed = "buildah-*"
   ```

1. Create a `ConfigMap` named `custom-config-toml` from the `custom-config.toml` file:

   ```shell
   oc create configmap custom-config-toml --from-file config.toml=custom-config.toml -n gitlab-runner
   ```

1. Set the `config` property of the `Runner` by updating its [Custom Resource Definition (CRD) file](https://docs.gitlab.com/runner/install/operator.html#install-gitlab-runner):

   ```yaml
   apiVersion: apps.gitlab.com/v1beta2
   kind: Runner
   metadata:
     name: builah-runner
   spec:
     gitlabUrl: https://gitlab.example.com
     token: gitlab-runner-secret
     config: custom-config-toml
   ```

## Configure the job

The final step is to set up a GitLab CI/CD configuration file in you project to use
the image we built and the configured service account:

```yaml
build:
  stage: build
  image: registry.example.com/group/project/buildah:1.23.1
  variables:
    STORAGE_DRIVER: vfs
    BUILDAH_FORMAT: docker
    BUILDAH_ISOLATION: chroot
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
    KUBERNETES_SERVICE_ACCOUNT_OVERWRITE: "buildah-sa"
  before_script:
    # Log in to the GitLab container registry
    - buildah login -u "$CI_REGISTRY_USER" --password $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

The job should use the image that we built as the value of `image` keyword.

The `KUBERNETES_SERVICE_ACCOUNT_OVERWRITE` variable should have the value of the
service account name that we created.

Congratulations, you've successfully built an image with Buildah in a rootless container!

## Troubleshooting

There is a [known issue](https://github.com/containers/buildah/issues/4049) with running as non-root.
You might need to use a [workaround](https://docs.gitlab.com/runner/configuration/configuring_runner_operator.html#configure-setfcap)
if you are using an OpenShift runner.
