---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Build Docker images with BuildKit
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[BuildKit](https://docs.docker.com/build/buildkit/) is the build engine used by Docker
and provides multi-platform builds and build caching.

## BuildKit methods

BuildKit offers the following methods to build Docker images:

| Method            | Security requirement     | Commands                 | Use when you need |
| ----------------- | ------------------------ | ------------------------ | ----------------- |
| BuildKit rootless | No privileged containers | `buildctl-daemonless.sh` | Maximum security or a replacement for Kaniko |
| Docker Buildx     | Requires `docker:dind`   | `docker buildx`          | Familiar Docker workflow |
| Native BuildKit   | Requires `docker:dind`   | `buildctl`               | Advanced BuildKit control |

## Prerequisites

- GitLab Runner with Docker executor
- Docker 19.03 or later to use Docker Buildx
- A project with a `Dockerfile`

## BuildKit rootless

BuildKit in standalone mode provides rootless image builds without Docker daemon dependency.
This method eliminates privileged containers entirely and provides a direct replacement for Kaniko builds.

Key differences from other methods:

- Uses the `moby/buildkit:rootless` image
- Includes `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox` for rootless operation
- Uses `buildctl-daemonless.sh` to manage BuildKit daemon automatically
- No Docker daemon or privileged container dependency
- Requires manual registry authentication setup

### Authenticate with container registries

GitLab CI/CD provides automatic authentication for the GitLab container registry through
predefined variables. For BuildKit rootless, you must manually create the Docker
configuration file.

#### Authenticate with the GitLab container registry

GitLab automatically provides these predefined variables:

- `CI_REGISTRY`: Registry URL
- `CI_REGISTRY_USER`: Registry username
- `CI_REGISTRY_PASSWORD`: Registry password

To configure authentication for rootless builds, add a `before_script` configuration
to your jobs. For example:

```yaml
before_script:
  - mkdir -p ~/.docker
  - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
```

#### Authenticate with multiple registries

To authenticate with additional container registries, combine authentication entries
in your `before_script` section. For example:

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"docker.io\": {
          \"auth\": \"$(printf "%s:%s" "${DOCKER_HUB_USER}" "${DOCKER_HUB_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

#### Authenticate with the dependency proxy

To pull images through the GitLab dependency proxy, configure the authentication
in your `before_script` section. For example:

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"$(echo -n $CI_DEPENDENCY_PROXY_SERVER | awk -F[:] '{print $1}')\": {
          \"auth\": \"$(printf "%s:%s" ${CI_DEPENDENCY_PROXY_USER} "${CI_DEPENDENCY_PROXY_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

For more information, see [authenticate within CI/CD](../../user/packages/dependency_proxy/_index.md#authenticate-within-cicd).

### Build images in rootless mode

To build images without Docker daemon dependency, add a job similar to this example:

```yaml
build-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### Build multi-platform images in rootless mode

To build images for multiple architectures in rootless mode, configure your job
to specify the target platforms. For example:

```yaml
build-multiarch-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --opt platform=linux/amd64,linux/arm64 \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### Use caching in rootless mode

To enable registry-based caching for faster subsequent builds, configure cache
import and export in your build job. For example:

```yaml
build-cached-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --export-cache type=registry,ref=$CACHE_IMAGE \
        --import-cache type=registry,ref=$CACHE_IMAGE \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### Use a registry mirror in rootless mode

Registry mirrors provide faster image pulls and can help with rate limiting or network restrictions.

To configure registry mirrors, create a `buildkit.toml` file that specifies the mirror endpoints. For example:

```yaml
build-mirror-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox --config /tmp/buildkit.toml
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
    - cat <<'EOF' > /tmp/buildkit.toml
      [registry."docker.io"]
        mirrors = ["mirror.example.com"]
      EOF
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

In this example, replace `mirror.example.com` with your registry mirror URL.

### Configure proxy settings

If your GitLab Runner operates behind an HTTP(S) proxy, configure proxy settings
as variables in your job. For example:

```yaml
build-behind-proxy:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    http_proxy: <your-proxy>
    https_proxy: <your-proxy>
    no_proxy: <your-no-proxy>
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

In this example, replace `<your-proxy>` and `<your-no-proxy>` with your proxy configuration.

### Add custom certificates

To push to a registry using custom CA certificates, add the certificate to the
container's certificate store before building. For example:

```yaml
build-with-custom-certs:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - |
      echo "-----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----" >> /etc/ssl/certs/ca-certificates.crt
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

In this example, replace the certificate placeholder with your actual certificate content.

## Migrate from Kaniko to BuildKit

BuildKit rootless is a secure alternative for Kaniko.
It offers improved performance, better caching, and enhanced security features while
maintaining rootless operation.

### Update your configuration

Update your existing Kaniko configuration to use the BuildKit rootless method. For example:

Before, with Kaniko:

```yaml
build:
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

After, with BuildKit rootless:

```yaml
build:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## Alternative BuildKit methods

If you don't need rootless builds, BuildKit offers additional methods that require
the `docker:dind` service but provide familiar workflows or advanced features.

### Docker Buildx

Docker Buildx extends Docker build capabilities with BuildKit features while maintaining
familiar command syntax. This method requires the `docker:dind` service.

#### Build basic images

To build Docker images with Buildx, configure your job with the `docker:dind` service
and create a `buildx` builder. For example:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-image:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --push .
  after_script:
    - docker buildx rm builder
```

#### Build multi-platform images

Multi-platform builds create images for different architectures in a single build command.
The resulting manifest supports multiple architectures,
and Docker automatically selects the appropriate image for each deployment target.

To build images for multiple architectures, add the `--platform` flag to specify
target architectures. For example:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-multiplatform:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name multibuilder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --platform linux/amd64,linux/arm64
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm multibuilder
```

#### Use build caching

Registry-based caching stores build layers in a container registry for reuse across builds.

The `mode=max` option exports all layers to the cache
and provides maximum reuse potential for subsequent builds.

To use build caching, add cache options to your build command. For example:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"
  CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache

build-with-cache:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name cached-builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --cache-from type=registry,ref=$CACHE_IMAGE
        --cache-to type=registry,ref=$CACHE_IMAGE,mode=max
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm cached-builder
```

### Native BuildKit

Use native BuildKit `buildctl` commands for more control over the build process.
This method requires the `docker:dind` service.

To use BuildKit directly, configure your job with the BuildKit image and `docker:dind` service. For example:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-with-buildkit:
  image: moby/buildkit:latest
  services:
    - docker:dind
  stage: build
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## Troubleshooting

### Build fails with authentication errors

If you encounter registry authentication failures:

- Verify that `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` variables are available.
- Check that you have push permissions to the target registry.
- For external registries, ensure authentication credentials are correctly configured
  in your project's CI/CD variables.

### Rootless build fails with permission errors

For permission-related issues in rootless mode:

- Ensure `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox` is set.
- Verify that the GitLab Runner has sufficient resources allocated.
- Check that no privileged operations are attempted in your `Dockerfile`.

If you receive `[rootlesskit:child ] error: failed to share mount point: /: permission denied`
on a Kubernetes runner, AppArmor is blocking the mount syscall required for BuildKit.

To resolve this issue, add the following to your runner configuration:

```toml
[runners.kubernetes.pod_annotations]
  "container.apparmor.security.beta.kubernetes.io/build" = "unconfined"
```

### Error: `invalid local: stat path/to/image/Dockerfile: not a directory`

You might get an error that states `invalid local: stat path/to/image/Dockerfile: not a directory`.

This issue occurs when you specify a file path instead of a directory path for the
`--local dockerfile=` parameter. BuildKit expects a directory path that contains
a file named `Dockerfile`.

To resolve this issue, use the directory path instead of the full file path. For example:

- Use: `--local dockerfile=path/to/image`
- Instead of: `--local dockerfile=path/to/image/Dockerfile`

### Multi-platform builds fail

For multi-platform build issues:

- Verify that base images in your `Dockerfile` support the target architectures.
- Check that architecture-specific dependencies are available for all target platforms.
- Consider using conditional statements in your `Dockerfile` for architecture-specific logic.
