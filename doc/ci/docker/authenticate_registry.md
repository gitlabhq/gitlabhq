---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authenticate with registry in Docker-in-Docker
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you use Docker-in-Docker, the
[standard authentication methods](using_docker_images.md#access-an-image-from-a-private-container-registry)
do not work, because a fresh Docker daemon is started with the service.

## Option 1: Run `docker login`

In [`before_script`](../yaml/_index.md#before_script), run `docker login`:

```yaml
default:
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - echo "$DOCKER_REGISTRY_PASS" | docker login $DOCKER_REGISTRY --username $DOCKER_REGISTRY_USER --password-stdin
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

To sign in to Docker Hub, leave `$DOCKER_REGISTRY`
empty or remove it.

## Option 2: Mount `~/.docker/config.json` on each job

If you are an administrator for GitLab Runner, you can mount a file
with the authentication configuration to `~/.docker/config.json`.
Then every job that the runner picks up is already authenticated. If you
are using the official `docker:24.0.5` image, the home directory is
under `/root`.

If you mount the configuration file, any `docker` command
that modifies the `~/.docker/config.json` fails. For example, `docker login`
fails, because the file is mounted as read-only. Do not change it from
read-only, because this causes problems.

Here is an example of `/opt/.docker/config.json` that follows the
[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)
documentation:

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
        }
    }
}
```

### Docker

Update the
[volume mounts](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section)
to include the file.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/opt/.docker/config.json:/root/.docker/config.json:ro"]
```

### Kubernetes

Create a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) with the content
of this file. You can do this with a command like:

```shell
kubectl create configmap docker-client-config --namespace gitlab-runner --from-file /opt/.docker/config.json
```

Update the [volume mounts](https://docs.gitlab.com/runner/executors/kubernetes/index.html#custom-volume-mount)
to include the file.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-client-config"
      mount_path = "/root/.docker/config.json"
      # If you are running GitLab Runner 13.5
      # or lower you can remove this
      sub_path = "config.json"
```

## Option 3: Use `DOCKER_AUTH_CONFIG`

If you already have
[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)
defined, you can use the variable and save it in
`~/.docker/config.json`.

You can define this authentication in several ways:

- In [`pre_build_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
  in the runner configuration file.
- In [`before_script`](../yaml/_index.md#before_script).
- In [`script`](../yaml/_index.md#script).

The following example shows [`before_script`](../yaml/_index.md#before_script).
The same commands apply for any solution you implement.

```yaml
default:
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - mkdir -p $HOME/.docker
    - echo $DOCKER_AUTH_CONFIG > $HOME/.docker/config.json
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```
