---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: howto
---

# Use kaniko to build Docker images **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45512) in GitLab 11.2. Requires GitLab Runner 11.2 and above.

[kaniko](https://github.com/GoogleContainerTools/kaniko) is a tool to build
container images from a Dockerfile, inside a container or Kubernetes cluster.

kaniko solves two problems with using the
[Docker-in-Docker build](using_docker_build.md#use-docker-in-docker)
method:

- Docker-in-Docker requires [privileged mode](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)
  to function, which is a significant security concern.
- Docker-in-Docker generally incurs a performance penalty and can be quite slow.

## Prerequisites

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
- The entrypoint needs to be [overridden](using_docker_images.md#override-the-entrypoint-of-an-image),
  otherwise the build script doesn't run.

In the following example, kaniko is used to:

1. Build a Docker image.
1. Then push it to [GitLab Container Registry](../../user/packages/container_registry/index.md).

The job runs only when a tag is pushed. A `config.json` file is created under
`/kaniko/.docker` with the needed GitLab Container Registry credentials taken from the
[predefined CI/CD variables](../variables/index.md#predefined-cicd-variables)
GitLab CI/CD provides. These are automatically read by the Kaniko tool.

In the last step, kaniko uses the `Dockerfile` under the
root directory of the project, builds the Docker image and pushes it to the
project's Container Registry while tagging it with the Git tag:

```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.9.0-debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context "${CI_PROJECT_DIR}"
      --dockerfile "${CI_PROJECT_DIR}/Dockerfile"
      --destination "${CI_REGISTRY_IMAGE}:${CI_COMMIT_TAG}"
  rules:
    - if: $CI_COMMIT_TAG
```

If you authenticate against the [Dependency Proxy](../../user/packages/dependency_proxy/index.md#authenticate-within-cicd),
you must add the corresponding CI/CD variables for authentication to the `config.json` file:

```yaml
- echo "{\"auths\":{\"${CI_REGISTRY}\":{\"auth\":\"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"},\"$CI_DEPENDENCY_PROXY_SERVER\":{\"auth\":\"$(printf "%s:%s" ${CI_DEPENDENCY_PROXY_USER} "${CI_DEPENDENCY_PROXY_PASSWORD}" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
```

### Building an image with kaniko behind a proxy

If you use a custom GitLab Runner behind an http(s) proxy, kaniko needs to be set
up accordingly. This means:

- Passing the `http_proxy` environment variables as build arguments so the Dockerfile
  instructions can use the proxy when building the image.

The previous example can be extended as follows:

```yaml
build:
  stage: build
  variables:
    http_proxy: <your-proxy>
    https_proxy: <your-proxy>
    no_proxy: <your-no-proxy>
  image:
    name: gcr.io/kaniko-project/executor:v1.9.0-debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context "${CI_PROJECT_DIR}"
      --build-arg http_proxy=$http_proxy
      --build-arg https_proxy=$https_proxy
      --build-arg no_proxy=$no_proxy
      --dockerfile "${CI_PROJECT_DIR}/Dockerfile"
      --destination "${CI_REGISTRY_IMAGE}:${CI_COMMIT_TAG}"
  rules:
    - if: $CI_COMMIT_TAG
```

## Build a multi-arch image

You can build [multi-arch images](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/)
inside a container by using [`manifest-tool`](https://github.com/estesp/manifest-tool).

For a detailed guide on how to build a multi-arch image, read [Building a multi-arch container image in unprivileged containers](https://blog.siemens.com/2022/07/building-a-multi-arch-container-image-in-unprivileged-containers/).

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
  - |
    echo "-----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----" >> /kaniko/ssl/certs/additional-ca-cert-bundle.crt
```

## Video walkthrough of a working example

The [Least Privilege Container Builds with Kaniko on GitLab](https://www.youtube.com/watch?v=d96ybcELpFs)
video is a walkthrough of the [Kaniko Docker Build](https://gitlab.com/guided-explorations/containers/kaniko-docker-build)
Guided Exploration project pipeline. It was tested on:

- [GitLab.com shared runners](../runners/index.md)
- [The Kubernetes runner executor](https://docs.gitlab.com/runner/executors/kubernetes.html)

The example can be copied to your own group or instance for testing. More details
on what other GitLab CI patterns are demonstrated are available at the project page.

## Troubleshooting

### 403 error: "error checking push permissions"

If you receive this error, it might be due to an outside proxy. Setting the `http_proxy`
and `https_proxy` [environment variables](../../administration/packages/container_registry.md#running-the-docker-daemon-with-a-proxy)
can fix the problem.
