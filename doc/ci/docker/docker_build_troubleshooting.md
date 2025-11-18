---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Docker Build
---

## Error: `docker: Cannot connect to the Docker daemon at tcp://docker:2375`

This error is common when you are using [Docker-in-Docker](using_docker_build.md#use-docker-in-docker)
v19.03 or later:

```plaintext
docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?
```

This error occurs because Docker starts on TLS automatically.

- If this is your first time setting it up, see
  [use the Docker executor with the Docker image](using_docker_build.md#use-docker-in-docker).
- If you are upgrading from v18.09 or earlier, see the
  [upgrade guide](https://about.gitlab.com/blog/2019/07/31/docker-in-docker-with-docker-19-dot-03/).

This error can also occur with the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind) when attempts are made to access the Docker-in-Docker service before it has fully started up. For a more detailed explanation, see [issue 27215](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27215).

## Docker `no such host` error

You might get an error that says
`docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`.

This issue can occur when the service's image name
[includes a registry hostname](../services/_index.md#available-settings-for-services). For example:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - registry.hub.docker.com/library/docker:24.0.5-dind
```

A service's hostname is [derived from the full image name](../services/_index.md#accessing-the-services).
However, the shorter service hostname `docker` is expected.
To allow service resolution and access, add an explicit alias for the service name `docker`:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - name: registry.hub.docker.com/library/docker:24.0.5-dind
      alias: docker
```

## Error: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

You might get the following error when trying to run a `docker` command
to access a `dind` service:

```shell
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Make sure your job has defined these environment variables:

- `DOCKER_HOST`
- `DOCKER_TLS_CERTDIR` (optional)
- `DOCKER_TLS_VERIFY` (optional)

You may also want to update the image that provides the Docker
client. For example, the [`docker/compose` images are obsolete](https://hub.docker.com/r/docker/compose) and should be
replaced with [`docker`](https://hub.docker.com/_/docker).

As described in [runner issue 30944](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30944#note_1514250909),
this error can happen if your job previously relied on environment variables derived from the deprecated
[Docker `--link` parameter](https://docs.docker.com/network/links/#environment-variables),
such as `DOCKER_PORT_2375_TCP`. Your job fails with this error if:

- Your CI/CD image relies on a legacy variable, such as `DOCKER_PORT_2375_TCP`.
- The [runner feature flag `FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags.html) is set to `true`.
- `DOCKER_HOST` is not explicitly set.

## Error: `unauthorized: incorrect username or password`

This error appears when you use the deprecated variable, `CI_BUILD_TOKEN`:

```plaintext
Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

To prevent users from receiving this error, you should:

- Use [CI_JOB_TOKEN](../jobs/ci_job_token.md) instead.
- Change from `gitlab-ci-token/CI_BUILD_TOKEN` to `$CI_REGISTRY_USER/$CI_REGISTRY_PASSWORD`.

## Error during connect: `no such host`

This error appears when the `dind` service has failed to start:

```plaintext
error during connect: Post "https://docker:2376/v1.24/auth": dial tcp: lookup docker on 127.0.0.11:53: no such host
```

Check the job log to see if `mount: permission denied (are you root?)`
appears. For example:

```plaintext
Service container logs:
2023-08-01T16:04:09.541703572Z Certificate request self-signature ok
2023-08-01T16:04:09.541770852Z subject=CN = docker:dind server
2023-08-01T16:04:09.556183222Z /certs/server/cert.pem: OK
2023-08-01T16:04:10.641128729Z Certificate request self-signature ok
2023-08-01T16:04:10.641173149Z subject=CN = docker:dind client
2023-08-01T16:04:10.656089908Z /certs/client/cert.pem: OK
2023-08-01T16:04:10.659571093Z ip: can't find device 'ip_tables'
2023-08-01T16:04:10.660872131Z modprobe: can't change directory to '/lib/modules': No such file or directory
2023-08-01T16:04:10.664620455Z mount: permission denied (are you root?)
2023-08-01T16:04:10.664692175Z Could not mount /sys/kernel/security.
2023-08-01T16:04:10.664703615Z AppArmor detection and --privileged mode might break.
2023-08-01T16:04:10.665952353Z mount: permission denied (are you root?)
```

This indicates the GitLab Runner does not have permission to start the
`dind` service:

1. Check that `privileged = true` is set in the `config.toml`.
1. Make sure the CI job has the right Runner tags to use these
   privileged runners.

## Error: `cgroups: cgroup mountpoint does not exist: unknown`

There is a known incompatibility introduced by Docker Engine 20.10.

When the host uses Docker Engine 20.10 or later, then the `docker:dind` service in a version older than 20.10 does
not work as expected.

While the service itself will start without problems, trying to build the container image results in the error:

```plaintext
cgroups: cgroup mountpoint does not exist: unknown
```

To resolve this issue, update the `docker:dind` container to version at least 20.10.x,
for example `docker:24.0.5-dind`.

The opposite configuration (`docker:24.0.5-dind` service and Docker Engine on the host in version
19.06.x or older) works without problems. For the best strategy, you should to frequently test and update
job environment versions to the newest. This brings new features, improved security and - for this specific
case - makes the upgrade on the underlying Docker Engine on the runner's host transparent for the job.

## Error: `failed to verify certificate: x509: certificate signed by unknown authority`

This error can appear when Docker commands like `docker build` or `docker pull` are executed in a Docker-in-Docker
environment where custom or private certificates are used (for example, Zscaler certificates):

```plaintext
error pulling image configuration: download failed after attempts=6: tls: failed to verify certificate: x509: certificate signed by unknown authority
```

This error occurs because Docker commands in a Docker-in-Docker environment
use two separate containers:

- The **build container** runs the Docker client (`/usr/bin/docker`) and executes your job's script commands.
- The **service container** (often named `svc`) runs the Docker daemon that processes most Docker commands.

When your organization uses custom certificates, both containers need these certificates.
Without proper certificate configuration in both containers, Docker operations that connect to external
registries or services will fail with certificate errors.

To resolve this issue:

1. Store your root certificate as a [CI/CD variable](../variables/_index.md#define-a-cicd-variable-in-the-ui) named `CA_CERTIFICATE`.
   The certificate should be in this format:

   ```plaintext
   -----BEGIN CERTIFICATE-----
   (certificate content)
   -----END CERTIFICATE-----
   ```

1. Configure your pipeline to install the certificate in the service container before starting the Docker daemon. For example:

   ```yaml
   image_build:
     stage: build
     image:
       name: docker:19.03
     variables:
       DOCKER_HOST: tcp://localhost:2375
       DOCKER_TLS_CERTDIR: ""
       CA_CERTIFICATE: "$CA_CERTIFICATE"
     services:
       - name: docker:19.03-dind
         command:
           - /bin/sh
           - -c
           - |
             echo "$CA_CERTIFICATE" > /usr/local/share/ca-certificates/custom-ca.crt && \
             update-ca-certificates && \
             dockerd-entrypoint.sh || exit
     script:
       - docker info
       - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
       - docker build -t "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}" .
       - docker push "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}"
   ```
