---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

> [!note]
> Rootless builds still require a runner that permits the system calls BuildKit uses to create
> user namespaces and mount points. Hosted runners on GitLab.com permit these calls and need no
> extra configuration, because they run in
> [privileged mode](../runners/hosted_runners/linux.md#docker-in-docker-support).
> On self-managed runners that use the Docker executor without privileged mode, builds can fail
> with permission errors. For more information, see
> [rootless build fails with permission errors](#rootless-build-fails-with-permission-errors).
> If you cannot change your runner security settings, use
> [rootless Buildah](buildah_rootless_multi_arch.md) to build images instead.

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

The `entrypoint: [""]` override is required.
By default, the `moby/buildkit:rootless` image starts the BuildKit daemon as a
long-running service.
Without the override, the job runs the daemon instead of the build command and
hangs until the job times out.

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

To push to a registry with a custom CA certificate, configure the certificate in a BuildKit
configuration file before the daemon starts.
For example:

```yaml
build-with-custom-certs:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p "$HOME/.docker"
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > "$HOME/.docker/config.json"
    - REG_HOST="${CI_REGISTRY%%/*}"
    - mkdir -p "$HOME/.config/buildkit/certs/$REG_HOST"
    - echo "$CA_CERT" > "$HOME/.config/buildkit/certs/$REG_HOST/ca.pem"
    - |
      cat > "$HOME/.config/buildkit/buildkitd.toml" << EOT
      [registry."$REG_HOST"]
        ca = ["$HOME/.config/buildkit/certs/$REG_HOST/ca.pem"]
      EOT
    - export SSL_CERT_FILE="$HOME/.config/buildkit/certs/$REG_HOST/ca.pem"
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

In this example:

- `REG_HOST="${CI_REGISTRY%%/*}"` extracts the hostname from the registry URL.
- `buildkitd.toml` configures BuildKit to trust the CA certificate for the target registry.
  BuildKit auto-discovers this file from `$HOME/.config/buildkit/`.
- `SSL_CERT_FILE` is required in addition to `buildkitd.toml` to cover TLS connections
  made before the BuildKit daemon fully initializes.

Add a `CA_CERT` CI/CD variable with the full certificate chain, including the root and
any intermediate certificates.
Because PEM certificates contain newlines, the value of `CA_CERT` cannot be masked.
To mask the value, use a [file-type variable](../../ci/variables/_index.md#use-file-type-cicd-variables)
instead and replace `echo "$CA_CERT"` with `cat "$CA_CERT"` in the `before_script`.

If the target registry uses the same certificate authority as your GitLab instance, and the
runner is configured with `tls-ca-file`, you can reference the predefined
[`CI_SERVER_TLS_CA_FILE`](../../ci/variables/predefined_variables.md) variable instead of a
`CA_CERT` variable.

## Migrate from Kaniko to BuildKit

BuildKit rootless is a secure alternative for Kaniko that offers improved performance, better
caching, and enhanced security features without privileged containers.

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

### Custom CA certificates

If your Kaniko jobs used custom CA certificates, you must configure those certificates explicitly
for BuildKit rootless.
Unlike Kaniko, the `moby/buildkit:rootless` image does not include a system certificate store.
You must configure CA certificates in a BuildKit configuration file before the daemon starts.

To migrate custom CA certificate configuration to BuildKit rootless:

1. Store the full certificate chain in a [CI/CD variable](../../ci/variables/_index.md) named
   `CA_CERT`.
   Include the root and any intermediate certificates.

1. Update your job configuration to use a `buildkitd.toml` file and the `SSL_CERT_FILE`
   environment variable.
   For the full example, see [add custom certificates](#add-custom-certificates).

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

When you build images with BuildKit, you might encounter the following issues.

### Build fails with authentication errors

If you encounter registry authentication failures:

- Verify that `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` variables are available.
- Check that you have push permissions to the target registry.
- For external registries, ensure authentication credentials are correctly configured
  in your project's CI/CD variables.

### Rootless build fails with permission errors

If a rootless build fails with a permission error, check the following:

- Ensure `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox` is set.
- Verify that the GitLab Runner has sufficient resources allocated.
- Check that no privileged operations are attempted in your `Dockerfile`.

On a Kubernetes runner, an AppArmor-related mount permission error can also block rootless
containers. For more information, see
[AppArmor mount permission errors on the Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/troubleshooting/#error-failed-to-share-mount-point-permission-denied).

If the failure matches the following error, the runner security policy is blocking a system call
that rootless BuildKit requires.

#### Error: `fork/exec /proc/self/exe: operation not permitted`

On a runner that uses the Docker executor without privileged mode, you might get one of the
following errors:

```plaintext
could not connect to unix:///run/user/1000/buildkit/buildkitd.sock after 10 trials
[rootlesskit:parent] error: failed to start the child: fork/exec /proc/self/exe: operation not permitted
```

This issue occurs because the runner seccomp profile blocks the system calls that rootless
BuildKit requires. Hosted runners on GitLab.com run in privileged mode and are not affected.

To resolve this issue on self-managed runners, configure the Docker executor
[`security_opt`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersdocker-section)
setting to permit only the system calls that BuildKit requires.

> [!warning]
> Do not set `security_opt` to `seccomp:unconfined`. Although it resolves the errors, it
> disables the container's default seccomp profile, which removes protection against dangerous
> system calls and reduces isolation. Instead, use a custom seccomp profile that permits only
> the required calls, or build images with rootless Buildah.

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
