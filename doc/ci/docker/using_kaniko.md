---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Building images with kaniko and GitLab CI/CD

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45512) in GitLab 11.2. Requires GitLab Runner 11.2 and above.

[kaniko](https://github.com/GoogleContainerTools/kaniko) is a tool to build
container images from a Dockerfile, inside a container or Kubernetes cluster.

kaniko solves two problems with using the
[Docker-in-Docker
build](using_docker_build.md#use-docker-in-docker-workflow-with-docker-executor) method:

- Docker-in-Docker requires [privileged mode](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)
  to function, which is a significant security concern.
- Docker-in-Docker generally incurs a performance penalty and can be quite slow.

## Requirements

To use kaniko with GitLab, [a runner](https://docs.gitlab.com/runner/) with one
of the following executors is required:

- [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes.html).
- [Docker](https://docs.gitlab.com/runner/executors/docker.html).
- [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html).

## Building a Docker image with kaniko

When building an image with kaniko and GitLab CI/CD, you should be aware of a
few important details:

- The kaniko debug image is recommended (`gcr.io/kaniko-project/executor:debug`)
  because it has a shell, and a shell is required for an image to be used with
  GitLab CI/CD.
- The entrypoint needs to be [overridden](using_docker_images.md#overriding-the-entrypoint-of-an-image),
  otherwise the build script doesn't run.
- A Docker `config.json` file needs to be created with the authentication
  information for the desired container registry.

In the following example, kaniko is used to:

1. Build a Docker image.
1. Then push it to [GitLab Container Registry](../../user/packages/container_registry/index.md).

The job runs only when a tag is pushed. A `config.json` file is created under
`/kaniko/.docker` with the needed GitLab Container Registry credentials taken from the
[environment variables](../variables/README.md#predefined-environment-variables)
GitLab CI/CD provides.

In the last step, kaniko uses the `Dockerfile` under the
root directory of the project, builds the Docker image and pushes it to the
project's Container Registry while tagging it with the Git tag:

```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
  only:
    - tags
```

## Using a registry with a custom certificate

When trying to push to a Docker registry that uses a certificate that is signed
by a custom CA, you might get the following error:

```shell
$ /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --no-push
INFO[0000] Downloading base image registry.gitlab.example.com/group/docker-image
error building image: getting stage builder for stage 0: Get https://registry.gitlab.example.com/v2/: x509: certificate signed by unknown authority
```

This can be solved by adding your CA's certificate to the kaniko certificate
store:

```yaml
before_script:
  - mkdir -p /kaniko/.docker
  - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /kaniko/.docker/config.json
  - |
    echo "-----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----" >> /kaniko/ssl/certs/additional-ca-cert-bundle.crt
```

## Video walkthrough of a working example

The [Least Privilege Container Builds with Kaniko on GitLab](https://www.youtube.com/watch?v=d96ybcELpFs)
video is a walkthrough of the [Kaniko Docker Build](https://gitlab.com/guided-explorations/containers/kaniko-docker-build)
Guided Exploration project pipeline. It was tested on:

- [GitLab.com shared runners](../../user/gitlab_com/index.md#shared-runners)
- [The Kubernetes runner executor](https://docs.gitlab.com/runner/executors/kubernetes.html)

The example can be copied to your own group or instance for testing. More details
on what other GitLab CI patterns are demonstrated are available at the project page.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
