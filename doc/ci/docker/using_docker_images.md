---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Run your CI/CD jobs in Docker containers
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can run your CI/CD jobs in Docker containers hosted on dedicated CI/CD build servers or your local machine.

To run CI/CD jobs in a Docker container, you need to:

1. Register a runner and configure it to use the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html).
1. Specify the container image where you want to run the CI/CD jobs in the `.gitlab-ci.yml` file.
1. Optional. Run other services, like MySQL, in containers. Do this by specifying [services](../services/_index.md)
   in your `.gitlab-ci.yml` file.

## Register a runner that uses the Docker executor

To use GitLab Runner with Docker you need to [register a runner](https://docs.gitlab.com/runner/register/)
that uses the Docker executor.

This example shows how to set up a temporary template to supply services:

```shell
cat > /tmp/test-config.template.toml << EOF
[[runners]]
[runners.docker]
[[runners.docker.services]]
name = "postgres:latest"
[[runners.docker.services]]
name = "mysql:latest"
EOF
```

Then use this template to register the runner:

```shell
sudo gitlab-runner register \
  --url "https://gitlab.example.com/" \
  --token "$RUNNER_TOKEN" \
  --description "docker-ruby:2.6" \
  --executor "docker" \
  --template-config /tmp/test-config.template.toml \
  --docker-image ruby:3.3
```

The registered runner uses the `ruby:2.6` Docker image and runs two
services, `postgres:latest` and `mysql:latest`, both of which are
accessible during the build process.

## What is an image

The `image` keyword is the name of the Docker image the Docker executor
uses to run CI/CD jobs.

By default, the executor pulls images from [Docker Hub](https://hub.docker.com/).
However, you can configure the registry location in the `gitlab-runner/config.toml` file.
For example, you can set the [Docker pull policy](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)
to use local images.

For more information about images and Docker Hub, see
the [Docker overview](https://docs.docker.com/get-started/overview/).

## Image requirements

Any image used to run a CI/CD job must have the following applications installed:

- `sh` or `bash`
- `grep`

## Define `image` in the `.gitlab-ci.yml` file

You can define an image that's used for all jobs, and a list of
services that you want to use during runtime:

```yaml
default:
  image: ruby:2.6
  services:
    - postgres:11.7
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

The image name must be in one of the following formats:

- `image: <image-name>` (Same as using `<image-name>` with the `latest` tag)
- `image: <image-name>:<tag>`
- `image: <image-name>@<digest>`

## Extended Docker configuration options

> - Introduced in GitLab and GitLab Runner 9.4.

You can use a string or a map for the `image` or `services` entries:

- Strings must include the full image name
  (including the registry, if you want to download the image from a registry
  other than Docker Hub).
- Maps must contain at least the `name` option,
  which is the same image name as used for the string setting.

For example, the following two definitions are equal:

- A string for `image` and `services`:

  ```yaml
  image: "registry.example.com/my/image:latest"

  services:
    - postgresql:14.3
    - redis:latest
  ```

- A map for `image` and `services`. The `image:name` is
  required:

  ```yaml
  image:
    name: "registry.example.com/my/image:latest"

  services:
    - name: postgresql:14.3
    - name: redis:latest
  ```

## Where scripts are executed

When a CI job runs in a Docker container, the `before_script`, `script`, and `after_script` commands run in the `/builds/<project-path>/` directory. Your image may have a different default `WORKDIR` defined. To move to your `WORKDIR`, save the `WORKDIR` as an environment variable so you can reference it in the container during the job's runtime.

### Override the entrypoint of an image

> - Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options).

Before explaining the available entrypoint override methods, let's describe
how the runner starts. It uses a Docker image for the containers used in the
CI/CD jobs:

1. The runner starts a Docker container using the defined entrypoint. The default
   from `Dockerfile` that may be overridden in the `.gitlab-ci.yml` file.
1. The runner attaches itself to a running container.
1. The runner prepares a script (the combination of
   [`before_script`](../yaml/_index.md#before_script),
   [`script`](../yaml/_index.md#script),
   and [`after_script`](../yaml/_index.md#after_script)).
1. The runner sends the script to the container's shell `stdin` and receives the
   output.

To override the [entrypoint](https://docs.gitlab.com/runner/executors/docker.html#configure-a-docker-entrypoint) of a Docker image,
in the `.gitlab-ci.yml` file:

- For Docker 17.06 and later, set `entrypoint` to an empty value.
- For Docker 17.03 and earlier, set `entrypoint` to
  `/bin/sh -c`, `/bin/bash -c`, or an equivalent shell available in the image.

The syntax of `image:entrypoint` is similar to [Dockerfile `ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint).

Let's assume you have a `super/sql:experimental` image with a SQL database
in it. You want to use it as a base image for your job because you
want to execute some tests with this database binary. Let's also assume that
this image is configured with `/usr/bin/super-sql run` as an entrypoint. When
the container starts without additional options, it runs
the database's process. The runner expects that the image has no
entrypoint or that the entrypoint is prepared to start a shell command.

With the extended Docker configuration options, instead of:

- Creating your own image based on `super/sql:experimental`.
- Setting the `ENTRYPOINT` to a shell.
- Using the new image in your CI job.

You can now define an `entrypoint` in the `.gitlab-ci.yml` file.

**For Docker 17.06 and later:**

```yaml
image:
  name: super/sql:experimental
  entrypoint: [""]
```

**For Docker 17.03 and earlier:**

```yaml
image:
  name: super/sql:experimental
  entrypoint: ["/bin/sh", "-c"]
```

## Define image and services in `config.toml`

In the `config.toml` file, you can define:

- In the [`[runners.docker]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdocker-section) section,
  the container image used to run CI/CD jobs
- In the [`[[runners.docker.services]]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdockerservices-section) section,
  the [services](../services/_index.md) container

```toml
[runners.docker]
  image = "ruby:latest"
  services = ["mysql:latest", "postgres:latest"]
```

The image and services defined this way are added to all jobs run by
that runner.

## Access an image from a private container registry

To access private container registries, the GitLab Runner process can use:

- [Statically defined credentials](#use-statically-defined-credentials). A username and password for a specific registry.
- [Credentials Store](#use-a-credentials-store). For more information, see [the relevant Docker documentation](https://docs.docker.com/reference/cli/docker/login/#credential-stores).
- [Credential Helpers](#use-credential-helpers). For more information, see [the relevant Docker documentation](https://docs.docker.com/reference/cli/docker/login/#credential-helpers).

To define which option should be used, the runner process reads the configuration in this order:

- A `DOCKER_AUTH_CONFIG` [CI/CD variable](../variables/_index.md).
- A `DOCKER_AUTH_CONFIG` environment variable set in the runner's `config.toml` file.
- A `config.json` file in `$HOME/.docker` directory of the user running the process.
  If the `--user` flag is provided to run the child processes as unprivileged user,
  the home directory of the main runner process user is used.

### Requirements and limitations

- Available for [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/index.html)
  in GitLab Runner 13.1 and later.
- [Credentials Store](#use-a-credentials-store) and [Credential Helpers](#use-credential-helpers)
  require binaries to be added to the GitLab Runner `$PATH`, and require access to do so. Therefore,
  these features are not available on instance runners, or any other runner where the user does not
  have access to the environment where the runner is installed.

### Use statically-defined credentials

You can access a private registry using two approaches. Both require setting the CI/CD variable
`DOCKER_AUTH_CONFIG` with appropriate authentication information.

1. Per-job: To configure one job to access a private registry, add
   `DOCKER_AUTH_CONFIG` as a [CI/CD variable](../variables/_index.md).
1. Per-runner: To configure a runner so all its jobs can access a
   private registry, add `DOCKER_AUTH_CONFIG` as an environment variable in the
   runner's configuration.

See below for examples of each.

#### Determine your `DOCKER_AUTH_CONFIG` data

As an example, let's assume you want to use the `registry.example.com:5000/private/image:latest`
image. This image is private and requires you to sign in to a private container
registry.

Let's also assume that these are the sign-in credentials:

| Key      | Value                       |
|:---------|:----------------------------|
| registry | `registry.example.com:5000` |
| username | `my_username`               |
| password | `my_password`               |

Use one of the following methods to determine the value for `DOCKER_AUTH_CONFIG`:

- Do a `docker login` on your local machine:

  ```shell
  docker login registry.example.com:5000 --username my_username --password my_password
  ```

  Then copy the content of `~/.docker/config.json`.

  If you don't need access to the registry from your computer, you
  can do a `docker logout`:

  ```shell
  docker logout registry.example.com:5000
  ```

- In some setups, it's possible the Docker client uses the available system key
  store to store the result of `docker login`. In that case, it's impossible to
  read `~/.docker/config.json`, so you must prepare the required
  base64-encoded version of `${username}:${password}` and create the Docker
  configuration JSON manually. Open a terminal and execute the following command:

  ```shell
  # The use of printf (as opposed to echo) prevents encoding a newline in the password.
  printf "my_username:my_password" | openssl base64 -A

  # Example output to copy
  bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=
  ```

  NOTE:
  If your username includes special characters like `@`, you must escape them with a backslash (<code>&#92;</code>) to prevent authentication problems.

  Create the Docker JSON configuration content as follows:

  ```json
  {
      "auths": {
          "registry.example.com:5000": {
              "auth": "(Base64 content from above)"
          }
      }
  }
  ```

#### Configure a job

To configure a single job with access for `registry.example.com:5000`,
follow these steps:

1. Create a [CI/CD variable](../variables/_index.md) `DOCKER_AUTH_CONFIG` with the content of the
   Docker configuration file as the value:

   ```json
   {
       "auths": {
           "registry.example.com:5000": {
               "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
           }
       }
   }
   ```

1. You can now use any private image from `registry.example.com:5000` defined in
   `image` or `services` in your `.gitlab-ci.yml` file:

   ```yaml
   image: registry.example.com:5000/namespace/image:tag
   ```

   In the example above, GitLab Runner looks at `registry.example.com:5000` for the
   image `namespace/image:tag`.

You can add configuration for as many registries as you want, adding more
registries to the `"auths"` hash as described above.

The full `hostname:port` combination is required everywhere
for the runner to match the `DOCKER_AUTH_CONFIG`. For example, if
`registry.example.com:5000/namespace/image:tag` is specified in the `.gitlab-ci.yml` file,
then the `DOCKER_AUTH_CONFIG` must also specify `registry.example.com:5000`.
Specifying only `registry.example.com` does not work.

### Configuring a runner

If you have many pipelines that access the same registry, you should
set up registry access at the runner level. This
allows pipeline authors to have access to a private registry just by
running a job on the appropriate runner. It also helps simplify registry
changes and credential rotations.

This means that any job on that runner can access the
registry with the same privilege, even across projects. If you need to
control access to the registry, you need to be sure to control
access to the runner.

To add `DOCKER_AUTH_CONFIG` to a runner:

1. Modify the runner's `config.toml` file as follows:

   ```toml
   [[runners]]
     environment = ["DOCKER_AUTH_CONFIG={\"auths\":{\"registry.example.com:5000\":{\"auth\":\"bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=\"}}}"]
   ```

   - The double quotes included in the `DOCKER_AUTH_CONFIG`
     data must be escaped with backslashes. This prevents them from being
     interpreted as TOML.
   - The `environment` option is a list. Your runner may
     have existing entries and you should add this to the list, not replace
     it.

1. Restart the runner service.

### Use a Credentials Store

To configure a Credentials Store:

1. To use a Credentials Store, you need an external helper program to interact with a specific keychain or external store.
   Make sure the helper program is available in the GitLab Runner `$PATH`.

1. Make GitLab Runner use it. You can accomplish this by using one of the following options:

   - Create a
     [CI/CD variable](../variables/_index.md)
     `DOCKER_AUTH_CONFIG` with the content of the
     Docker configuration file as the value:

     ```json
       {
         "credsStore": "osxkeychain"
       }
     ```

   - Or, if you're running self-managed runners, add the above JSON to
     `${GITLAB_RUNNER_HOME}/.docker/config.json`. GitLab Runner reads this configuration file
     and uses the needed helper for this specific repository.

`credsStore` is used to access **all** the registries.
If you use both images from a private registry and public images from Docker Hub,
pulling from Docker Hub fails. Docker daemon tries to use the same credentials for **all** the registries.

### Use Credential Helpers

> - Introduced in GitLab Runner 12.0.

As an example, let's assume that you want to use the `<aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest`
image. This image is private and requires you to sign in to a private container registry.

To configure access for `<aws_account_id>.dkr.ecr.<region>.amazonaws.com`, follow these steps:

1. Make sure [`docker-credential-ecr-login`](https://github.com/awslabs/amazon-ecr-credential-helper) is available in the GitLab Runner `$PATH`.
1. Have any of the following [AWS credentials setup](https://github.com/awslabs/amazon-ecr-credential-helper#aws-credentials).
   Make sure that GitLab Runner can access the credentials.
1. Make GitLab Runner use it. You can accomplish this by using one of the following options:

   - Create a [CI/CD variable](../variables/_index.md)
     `DOCKER_AUTH_CONFIG` with the content of the
     Docker configuration file as the value:

     ```json
     {
       "credHelpers": {
         "<aws_account_id>.dkr.ecr.<region>.amazonaws.com": "ecr-login"
       }
     }
     ```

     This configures Docker to use the Credential Helper for a specific registry.

     Instead, you can configure Docker to use the Credential Helper for all Amazon Elastic Container Registry (ECR) registries:

     ```json
     {
       "credsStore": "ecr-login"
     }
     ```

     NOTE:
     If you use `{"credsStore": "ecr-login"}`, set the region explicitly in the AWS shared configuration file (`~/.aws/config`). The region must be specified when the ECR Credential Helper retrieves the authorization token.

   - Or, if you're running self-managed runners,
     add the previous JSON to `${GITLAB_RUNNER_HOME}/.docker/config.json`.
     GitLab Runner reads this configuration file and uses the needed helper for this
     specific repository.

1. You can now use any private image from `<aws_account_id>.dkr.ecr.<region>.amazonaws.com` defined in
   `image` and/or `services` in your `.gitlab-ci.yml` file:

   ```yaml
   image: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest
   ```

   In the example, GitLab Runner looks at `<aws_account_id>.dkr.ecr.<region>.amazonaws.com` for the
   image `private/image:latest`.

You can add configuration for as many registries as you want, adding more
registries to the `"credHelpers"` hash.

### Use checksum to keep your image secure

Use the image checksum in your job definition in your `.gitlab-ci.yml` file to verify the integrity of the image. A failed image integrity verification prevents you from using a modified container.

To use the image checksum you have to append the checksum at the end:

```yaml
image: ruby:2.6.8@sha256:d1dbaf9665fe8b2175198e49438092fdbcf4d8934200942b94425301b17853c7
```

To get the image checksum, on the image `TAG` tab, view the `DIGEST` column.
For example, view the [Ruby image](https://hub.docker.com/_/ruby?tab=tags).
The checksum is a random string, like `6155f0235e95`.

You can also get the checksum of any image on your system with the command `docker images --digests`:

```shell
❯ docker images --digests
REPOSITORY                                                        TAG       DIGEST                                                                    (...)
gitlab/gitlab-ee                                                  latest    sha256:723aa6edd8f122d50cae490b1743a616d54d4a910db892314d68470cc39dfb24   (...)
gitlab/gitlab-runner                                              latest    sha256:4a18a80f5be5df44cb7575f6b89d1fdda343297c6fd666c015c0e778b276e726   (...)
```

## Creating a Custom GitLab Runner Docker Image

You can create a custom GitLab Runner Docker image to package AWS CLI and Amazon ECR Credential Helper. This setup facilitates
secure and streamlined interactions with AWS services, especially for containerized applications. For example, use this setup
to manage, deploy, and update Docker images on Amazon ECR. This setup helps avoid time consuming, error-prone configurations,
and manual credential management.

1. [Authenticate GitLab with AWS](../cloud_deployment/_index.md#authenticate-gitlab-with-aws).
1. Create a `Dockerfile` with the following content:

   ```Dockerfile
   # Control package versions
   ARG GITLAB_RUNNER_VERSION=v17.3.0
   ARG AWS_CLI_VERSION=2.17.36

   # AWS CLI and Amazon ECR Credential Helper
   FROM amazonlinux as aws-tools
   RUN set -e \
       && yum update -y \
       && yum install -y --allowerasing git make gcc curl unzip \
       && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip" \
       && unzip awscliv2.zip && ./aws/install -i /usr/local/bin \
       && yum clean all

   # Download and install ECR Credential Helper
   RUN curl --location --output  /usr/local/bin/docker-credential-ecr-login "https://github.com/awslabs/amazon-ecr-credential-helper/releases/latest/download/docker-credential-ecr-login-linux-amd64"
   RUN chmod +x /usr/local/bin/docker-credential-ecr-login

   # Configure the ECR Credential Helper
   RUN mkdir -p /root/.docker
   RUN echo '{ "credsStore": "ecr-login" }' > /root/.docker/config.json

   # Final image based on GitLab Runner
   FROM gitlab/gitlab-runner:${GITLAB_RUNNER_VERSION}

   # Install necessary packages
   RUN apt-get update \
       && apt-get install -y --no-install-recommends jq procps curl unzip groff libgcrypt20 tar gzip less openssh-client \
       && apt-get clean && rm -rf /var/lib/apt/lists/*

   # Copy AWS CLI and Amazon ECR Credential Helper binaries
   COPY --from=aws-tools /usr/local/bin/ /usr/local/bin/

   # Copy ECR Credential Helper Configuration
   COPY --from=aws-tools /root/.docker/config.json /root/.docker/config.json
   ```

1. To build the custom GitLab Runner Docker image in a `.gitlab-ci.yml`, include the following example below:

   ```yaml
   variables:
     DOCKER_DRIVER: overlay2
     IMAGE_NAME: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME
     GITLAB_RUNNER_VERSION: v17.3.0
     AWS_CLI_VERSION: 2.17.36

   stages:
     - build

   build-image:
     stage: build
     script:
       - echo "Logging into GitLab container registry..."
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
       - echo "Building Docker image..."
       - docker build --build-arg GITLAB_RUNNER_VERSION=${GITLAB_RUNNER_VERSION} --build-arg AWS_CLI_VERSION=${AWS_CLI_VERSION} -t ${IMAGE_NAME} .
       - echo "Pushing Docker image to GitLab container registry..."
       - docker push ${IMAGE_NAME}
     rules:
       - changes:
           - Dockerfile
   ```

1. [Register the runner](https://docs.gitlab.com/runner/register/index.html#docker).
