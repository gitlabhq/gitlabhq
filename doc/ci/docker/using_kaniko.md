# Building images with kaniko and GitLab CI/CD

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/45512) in GitLab 11.2.
Requires GitLab Runner 11.2 and above.

[kaniko](https://github.com/GoogleContainerTools/kaniko) is a tool to build
container images from a Dockerfile, inside a container or Kubernetes cluster.

kaniko solves two problems with using the
[docker-in-docker build](using_docker_build.md#use-docker-in-docker-executor) method:

1. Docker-in-docker requires [privileged mode](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)
   in order to function, which is a significant security concern.
1. Docker-in-docker generally incurs a performance penalty and can be quite slow.

## Requirements

In order to utilize kaniko with GitLab, a [GitLab Runner](https://docs.gitlab.com/runner/)
using either the [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes.html),
[Docker](https://docs.gitlab.com/runner/executors/docker.html), or
[Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html)
executors is required.

## Building a Docker image with kaniko

When building an image with kaniko and GitLab CI/CD, you should be aware of a
few important details:

- The kaniko debug image is recommended (`gcr.io/kaniko-project/executor:debug`)
  because it has a shell, and a shell is required for an image to be used with
  GitLab CI/CD.
- The entrypoint will need to be [overridden](using_docker_images.md#overriding-the-entrypoint-of-an-image),
  otherwise the build script will not run.
- A Docker `config.json` file needs to be created with the authentication
  information for the desired container registry.

---

In the following example, kaniko is used to build a Docker image and then push
it to [GitLab Container Registry](../../user/project/container_registry.md).
The job will run only when a tag is pushed. A `config.json` file is created under
`/root/.docker` with the needed GitLab Container Registry credentials taken from the
[environment variables](../variables/README.md#predefined-variables-environment-variables)
GitLab CI/CD provides. In the last step, kaniko uses the `Dockerfile` under the
root directory of the project, builds the Docker image and pushes it to the
project's Container Registry while tagging it with the Git tag:

```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - mkdir -p /root/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /root/.docker/config.json
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
  only:
    - tags
```
