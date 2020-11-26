---
type: reference, howto
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Container Scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/3672) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.4.

Your application's Docker image may itself be based on Docker images that contain known
vulnerabilities. By including an extra job in your pipeline that scans for those vulnerabilities and
displays them in a merge request, you can use GitLab to audit your Docker-based apps.
By default, container scanning in GitLab is based on [Clair](https://github.com/quay/clair) and
[Klar](https://github.com/optiopay/klar), which are open-source tools for vulnerability static analysis in
containers. [GitLab's Klar analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/klar/)
scans the containers and serves as a wrapper for Clair.

To integrate security scanners other than Clair and Klar into GitLab, see
[Security scanner integration](../../../development/integrations/secure.md).

You can enable container scanning by doing one of the following:

- [Include the CI job](#configuration) in your existing `.gitlab-ci.yml` file.
- Implicitly use [Auto Container Scanning](../../../topics/autodevops/stages.md#auto-container-scanning)
  provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab compares the found vulnerabilities between the source and target branches, and shows the
information directly in the merge request.

![Container Scanning Widget](img/container_scanning_v13_2.png)

<!-- NOTE: The container scanning tool references the following heading in the code, so if you
           make a change to this heading, make sure to update the documentation URLs used in the
           container scanning tool (https://gitlab.com/gitlab-org/security-products/analyzers/klar) -->

## Requirements

To enable container scanning in your pipeline, you need the following:

- [GitLab Runner](https://docs.gitlab.com/runner/) with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html)
  or [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
- Docker `18.09.03` or higher installed on the same computer as the runner. If you're using the
  shared runners on GitLab.com, then this is already the case.
- An image matching [Clair's list of supported distributions](https://quay.github.io/claircore/).
- [Build and push](../../packages/container_registry/index.md#build-and-push-by-using-gitlab-cicd)
  your Docker image to your project's container registry. The name of the Docker image should use
  the following [predefined environment variables](../../../ci/variables/predefined_variables.md):

  ```plaintext
  $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  ```

  You can use these directly in your `.gitlab-ci.yml` file:

  ```yaml
  build:
    image: docker:19.03.12
    stage: build
    services:
      - docker:19.03.12-dind
    variables:
      IMAGE_TAG: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
    script:
      - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
      - docker build -t $IMAGE_TAG .
      - docker push $IMAGE_TAG
  ```

## Configuration

How you enable container scanning depends on your GitLab version:

- GitLab 11.9 and later: [Include](../../../ci/yaml/README.md#includetemplate) the
  [`Container-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml)
  that comes with your GitLab installation.
- GitLab versions earlier than 11.9: Copy and use the job from the
  [`Container-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml).
- GitLab 13.6 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/263482) better support for [FIPS](https://csrc.nist.gov/publications/detail/fips/140/2/final) by upgrading the `CS_MAJOR_VERSION` from `2` to `3`.

To include the `Container-Scanning.gitlab-ci.yml` template (GitLab 11.9 and later), add the
following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Container-Scanning.gitlab-ci.yml
```

The included template:

- Creates a `container_scanning` job in your CI/CD pipeline.
- Pulls the built Docker image from your project's [container registry](../../packages/container_registry/index.md)
  (see [requirements](#requirements)) and scans it for possible vulnerabilities.

GitLab saves the results as a
[Container Scanning report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportscontainer_scanning)
that you can download and analyze later. When downloading, you always receive the most-recent
artifact.

The following is a sample `.gitlab-ci.yml` that builds your Docker image, pushes it to the container
registry, and scans the containers:

```yaml
variables:
  DOCKER_DRIVER: overlay2

stages:
  - build
  - test

build:
  image: docker:stable
  stage: build
  services:
    - docker:19.03.12-dind
  variables:
    IMAGE: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  script:
    - docker info
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
    - docker build -t $IMAGE .
    - docker push $IMAGE

include:
  - template: Container-Scanning.gitlab-ci.yml
```

### Customizing the container scanning settings

There may be cases where you want to customize how GitLab scans your containers. For example, you
may want to enable more verbose output from Clair or Klar, access a Docker registry that requires
authentication, and more. To change such settings, use the [`variables`](../../../ci/yaml/README.md#variables)
parameter in your `.gitlab-ci.yml` to set [environment variables](#available-variables).
The environment variables you set in your `.gitlab-ci.yml` overwrite those in
`Container-Scanning.gitlab-ci.yml`.

This example [includes](../../../ci/yaml/README.md#include) the container scanning template and
enables verbose output from Clair by setting the `CLAIR_OUTPUT` environment variable to `High`:

```yaml
include:
  - template: Container-Scanning.gitlab-ci.yml

variables:
  CLAIR_OUTPUT: High
```

Version `3` of the `container_scanning` Docker image uses [`centos:centos8`](https://hub.docker.com/_/centos)
as the new base. It also removes the use of the [start.sh](https://gitlab.com/gitlab-org/security-products/analyzers/klar/-/merge_requests/77)
script and instead executes the analyzer by default. Any customizations made to the
`container_scanning` job's [`before_script`](../../../ci/yaml/README.md#before_script)
and [`after_script`](../../../ci/yaml/README.md#after_script)
blocks may not work with the new version. To roll back to the previous [`alpine:3.11.3`](https://hub.docker.com/_/alpine)-based
Docker image, you can specify the major version through the [`CS_MAJOR_VERSION`](#available-variables)
variable.

This example [includes](../../../ci/yaml/README.md#include) the container scanning template and
enables version `2` of the analyzer:

```yaml
include:
  - template: Container-Scanning.gitlab-ci.yml

variables:
  CS_MAJOR_VERSION: '2'
```

<!-- NOTE: The container scanning tool references the following heading in the code, so if you"
     make a change to this heading, make sure to update the documentation URLs used in the"
     container scanning tool (https://gitlab.com/gitlab-org/security-products/analyzers/klar)" -->

#### Available variables

You can [configure](#customizing-the-container-scanning-settings) container
scanning by using the following environment variables:

| Environment Variable           | Default       | Description |
| ------------------------------ | ------------- | ----------- |
| `ADDITIONAL_CA_CERT_BUNDLE`    | `""`          | Bundle of CA certs that you want to trust. |
| `CLAIR_DB_CONNECTION_STRING`   | `postgresql://postgres:password@clair-vulnerabilities-db:5432/postgres?sslmode=disable&statement_timeout=60000` | This variable represents the [connection string](https://www.postgresql.org/docs/9.3/libpq-connect.html#AEN39692) to the [PostgreSQL server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db) database and **shouldn't be changed** unless you're running the image locally as described in the [Running the standalone container scanning tool](#running-the-standalone-container-scanning-tool) section. The host value for the connection string must match the [alias](https://gitlab.com/gitlab-org/gitlab/-/blob/898c5da43504eba87b749625da50098d345b60d6/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml#L23) value of the `Container-Scanning.gitlab-ci.yml` template file, which defaults to `clair-vulnerabilities-db`. |
| `CLAIR_DB_IMAGE`               | `arminc/clair-db:latest` | The Docker image name and tag for the [PostgreSQL server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db). It can be useful to override this value with a specific version, for example, to provide a consistent set of vulnerabilities for integration testing purposes, or to refer to a locally hosted vulnerabilities database for an on-premise offline installation. |
| `CLAIR_DB_IMAGE_TAG`           | `latest`      | (**DEPRECATED - use `CLAIR_DB_IMAGE` instead**) The Docker image tag for the [PostgreSQL server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db). It can be useful to override this value with a specific version, for example, to provide a consistent set of vulnerabilities for integration testing purposes. |
| `CLAIR_OUTPUT`                 | `Unknown`     | Severity level threshold. Vulnerabilities with severity level higher than or equal to this threshold are outputted. Supported levels are `Unknown`, `Negligible`, `Low`, `Medium`, `High`, `Critical` and `Defcon1`. |
| `CLAIR_TRACE`                  | `"false"`     | Set to true to enable more verbose output from the clair server process. |
| `CLAIR_VULNERABILITIES_DB_URL` | `clair-vulnerabilities-db` | (**DEPRECATED - use `CLAIR_DB_CONNECTION_STRING` instead**) This variable is explicitly set in the [services section](https://gitlab.com/gitlab-org/gitlab/-/blob/898c5da43504eba87b749625da50098d345b60d6/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml#L23) of the `Container-Scanning.gitlab-ci.yml` file and defaults to `clair-vulnerabilities-db`. This value represents the address that the [PostgreSQL server hosting the vulnerabilities definitions](https://hub.docker.com/r/arminc/clair-db) is running on and **shouldn't be changed** unless you're running the image locally as described in the [Running the standalone container scanning tool](#running-the-standalone-container-scanning-tool) section. |
| `CI_APPLICATION_REPOSITORY`    | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` | Docker repository URL for the image to be scanned. |
| `CI_APPLICATION_TAG`           | `$CI_COMMIT_SHA` | Docker repository tag for the image to be scanned. |
| `CS_MAJOR_VERSION`             | `3` | The major version of the Docker image tag. |
| `DOCKER_IMAGE`                 | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` | The Docker image to be scanned. If set, this variable overrides the `$CI_APPLICATION_REPOSITORY` and `$CI_APPLICATION_TAG` variables. |
| `DOCKER_INSECURE`              | `"false"`     | Allow [Klar](https://github.com/optiopay/klar) to access secure Docker registries using HTTPS with bad (or self-signed) SSL certificates. |
| `DOCKER_PASSWORD`              | `$CI_REGISTRY_PASSWORD` | Password for accessing a Docker registry requiring authentication. |
| `DOCKER_USER`                  | `$CI_REGISTRY_USER` | Username for accessing a Docker registry requiring authentication. |
| `DOCKERFILE_PATH`              | `Dockerfile`  | The path to the `Dockerfile` to be used for generating remediations. By default, the scanner looks for a file named `Dockerfile` in the root directory of the project, so this variable should only be configured if your `Dockerfile` is in a non-standard location, such as a subdirectory. See [Solutions for vulnerabilities](#solutions-for-vulnerabilities-auto-remediation) for more details. |
| `KLAR_TRACE`                   | `"false"`     | Set to true to enable more verbose output from klar. |
| `REGISTRY_INSECURE`            | `"false"`     | Allow [Klar](https://github.com/optiopay/klar) to access insecure registries (HTTP only). Should only be set to `true` when testing the image locally. |
| `SECURE_ANALYZERS_PREFIX`      | `"registry.gitlab.com/gitlab-org/security-products/analyzers"` | Set the Docker registry base address from which to download the analyzer. |
| `SECURE_LOG_LEVEL`             | `info`        | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. |

### Overriding the container scanning template

If you want to override the job definition (for example, to change properties like `variables`), you
must declare a `container_scanning` job after the template inclusion, and then
specify any additional keys. For example:

```yaml
include:
  - template: Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

CAUTION: **Deprecated:**
GitLab 13.0 and later doesn't support [`only` and `except`](../../../ci/yaml/README.md#onlyexcept-basic).
When overriding the template, you must use [`rules`](../../../ci/yaml/README.md#rules)
instead.

### Vulnerability allowlisting

To allowlist specific vulnerabilities, follow these steps:

1. Set `GIT_STRATEGY: fetch` in your `.gitlab-ci.yml` file by following the instructions in
   [overriding the container scanning template](#overriding-the-container-scanning-template).
1. Define the allowlisted vulnerabilities in a YAML file named `vulnerability-allowlist.yml`. This must use
   the format described in the [allowlist example file](https://gitlab.com/gitlab-org/security-products/analyzers/klar/-/raw/master/testdata/vulnerability-allowlist.yml).
1. Add the `vulnerability-allowlist.yml` file to your project's Git repository.

### Running container scanning in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the container scanning job to
successfully run. For more information, see [Offline environments](../offline_deployments/index.md).

#### Requirements for offline container Scanning

To use container scanning in an offline environment, you need:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- To configure a local Docker container registry with copies of the container scanning [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/klar) images, found in the [container scanning container registry](https://gitlab.com/gitlab-org/security-products/analyzers/klar/container_registry).

Note that GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

##### Support for Custom Certificate Authorities

Support for custom certificate authorities was introduced in the following versions:

| Analyzer | Version |
| -------- | ------- |
| `klar` | [v2.3.0](https://gitlab.com/gitlab-org/security-products/analyzers/klar/-/releases/v2.3.0) |

#### Make GitLab container scanning analyzer images available inside your Docker registry

For container scanning, import the following default images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/gitlab-org/security-products/analyzers/klar
https://hub.docker.com/r/arminc/clair-db
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which you can import or temporarily access external resources. Note that these scanners
are [updated periodically](../index.md#maintenance-and-update-of-the-vulnerabilities-database)
with new definitions, so consider if you are able to make periodic updates yourself.

For more information, see [the specific steps on how to update an image with a pipeline](#automating-container-scanning-vulnerability-database-updates-with-a-pipeline).

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

#### Set container scanning CI job variables to use local container scanner analyzers

1. [Override the container scanning template](#overriding-the-container-scanning-template) in your `.gitlab-ci.yml` file to refer to the Docker images hosted on your local Docker container registry:

   ```yaml
   include:
     - template: Container-Scanning.gitlab-ci.yml

   container_scanning:
     image: $CI_REGISTRY/namespace/gitlab-klar-analyzer
     variables:
       CLAIR_DB_IMAGE: $CI_REGISTRY/namespace/clair-vulnerabilities-db
   ```

1. If your local Docker container registry is running securely over `HTTPS`, but you're using a
   self-signed certificate, then you must set `DOCKER_INSECURE: "true"` in the above
   `container_scanning` section of your `.gitlab-ci.yml`.

#### Automating container scanning vulnerability database updates with a pipeline

It can be worthwhile to set up a [scheduled pipeline](../../../ci/pipelines/schedules.md) to
build a new version of the vulnerabilities database on a preset schedule. Automating
this with a pipeline means you won't have to do it manually each time. You can use the following
`.gitlab-yml.ci` as a template:

```yaml
image: docker:stable

stages:
  - build

build_latest_vulnerabilities:
  stage: build
  services:
    - docker:19.03.12-dind
  script:
    - docker pull arminc/clair-db:latest
    - docker tag arminc/clair-db:latest $CI_REGISTRY/namespace/clair-vulnerabilities-db
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
    - docker push $CI_REGISTRY/namespace/clair-vulnerabilities-db
```

The above template works for a GitLab Docker registry running on a local installation, however, if you're using a non-GitLab Docker registry, you'll need to change the `$CI_REGISTRY` value and the `docker login` credentials to match the details of your local registry.

## Running the standalone container scanning tool

It's possible to run the [GitLab container scanning tool](https://gitlab.com/gitlab-org/security-products/analyzers/klar)
against a Docker container without needing to run it within the context of a CI job. To scan an
image directly, follow these steps:

1. Run [Docker Desktop](https://www.docker.com/products/docker-desktop) or [Docker Machine](https://github.com/docker/machine).
1. Run the latest [prefilled vulnerabilities database](https://hub.docker.com/repository/docker/arminc/clair-db) Docker image:

   ```shell
   docker run -p 5432:5432 -d --name clair-db arminc/clair-db:latest
   ```

1. Configure an environment variable to point to your local machine's IP address (or insert your IP address instead of the `LOCAL_MACHINE_IP_ADDRESS` variable in the `CLAIR_DB_CONNECTION_STRING` in the next step):

   ```shell
   export LOCAL_MACHINE_IP_ADDRESS=your.local.ip.address
   ```

1. Run the analyzer's Docker image, passing the image and tag you want to analyze in the `CI_APPLICATION_REPOSITORY` and `CI_APPLICATION_TAG` environment variables:

   ```shell
   docker run \
     --interactive --rm \
     --volume "$PWD":/tmp/app \
     -e CI_PROJECT_DIR=/tmp/app \
     -e CLAIR_DB_CONNECTION_STRING="postgresql://postgres:password@${LOCAL_MACHINE_IP_ADDRESS}:5432/postgres?sslmode=disable&statement_timeout=60000" \
     -e CI_APPLICATION_REPOSITORY=registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256 \
     -e CI_APPLICATION_TAG=bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e \
     registry.gitlab.com/gitlab-org/security-products/analyzers/klar
   ```

The results are stored in `gl-container-scanning-report.json`.

## Reports JSON format

The container scanning tool emits a JSON report file. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json).

Here's an example container scanning report:

```json-doc
{
  "version": "2.3",
  "vulnerabilities": [
    {
      "id": "ac0997ad-1006-4c81-81fb-ee2bbe6e78e3",
      "category": "container_scanning",
      "message": "CVE-2019-3462 in apt",
      "description": "Incorrect sanitation of the 302 redirect field in HTTP transport method of apt versions 1.4.8 and earlier can lead to content injection by a MITM attacker, potentially leading to remote code execution on the target machine.",
      "severity": "High",
      "confidence": "Unknown",
      "solution": "Upgrade apt from 1.4.8 to 1.4.9",
      "scanner": {
        "id": "klar",
        "name": "klar"
      },
      "location": {
        "dependency": {
          "package": {
            "name": "apt"
          },
          "version": "1.4.8"
        },
        "operating_system": "debian:9",
        "image": "registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e"
      },
      "identifiers": [
        {
          "type": "cve",
          "name": "CVE-2019-3462",
          "value": "CVE-2019-3462",
          "url": "https://security-tracker.debian.org/tracker/CVE-2019-3462"
        }
      ],
      "links": [
        {
          "url": "https://security-tracker.debian.org/tracker/CVE-2019-3462"
        }
      ]
    }
  ],
  "remediations": [
    {
      "fixes": [
        {
          "id": "c0997ad-1006-4c81-81fb-ee2bbe6e78e3"
        }
      ],
      "summary": "Upgrade apt from 1.4.8 to 1.4.9",
      "diff": "YXB0LWdldCB1cGRhdGUgJiYgYXB0LWdldCB1cGdyYWRlIC15IGFwdA=="
    }
  ]
}
```

## Security Dashboard

The [Security Dashboard](../security_dashboard/index.md) shows you an overview of all
the security vulnerabilities in your groups, projects and pipelines.

## Vulnerabilities database update

For more information about the vulnerabilities database update, check the
[maintenance table](../index.md#maintenance-and-update-of-the-vulnerabilities-database).

## Interacting with the vulnerabilities

After a vulnerability is found, you can [interact with it](../index.md#interacting-with-the-vulnerabilities).

## Solutions for vulnerabilities (auto-remediation)

Some vulnerabilities can be fixed by applying the solution that GitLab
automatically generates.

To enable remediation support, the scanning tool _must_ have access to the `Dockerfile` specified by
the [`DOCKERFILE_PATH`](#available-variables) environment variable. To ensure that the scanning tool
has access to this
file, it's necessary to set [`GIT_STRATEGY: fetch`](../../../ci/runners/README.md#git-strategy) in
your `.gitlab-ci.yml` file by following the instructions described in this document's
[overriding the container scanning template](#overriding-the-container-scanning-template) section.

Read more about the [solutions for vulnerabilities](../index.md#automatic-remediation-for-vulnerabilities).

## Troubleshooting

### `docker: Error response from daemon: failed to copy xattrs`

When the runner uses the `docker` executor and NFS is used
(for example, `/var/lib/docker` is on an NFS mount), container scanning might fail with
an error like the following:

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

This is a result of a bug in Docker which is now [fixed](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt").
To prevent the error, ensure the Docker version that the runner is using is
`18.09.03` or higher. For more information, see
[issue #10241](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "Investigate why Container Scanning is not working with NFS mounts").

### Getting warning message `gl-container-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).
