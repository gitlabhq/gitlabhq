---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Run your CI/CD jobs in Docker containers

You can run your CI/CD jobs in separate, isolated Docker containers.

When you run a Docker container on your local machine, it acts as a reproducible build environment.
You can run tests in the container, instead of testing on a dedicated CI/CD server.

To run CI/CD jobs in a Docker container, you need to:

- Register a runner that uses the Docker executor. Then all jobs run in a Docker container.
- Specify an image in your `.gitlab-ci.yml` file. The runner creates a container from this image
  and runs the jobs in it.
- Optional. Specify other images in your `.gitlab-ci.yml` file. These containers are known as
  ["services"](../services/index.md) and you can use them to run services like MySQL separately.

## Register a runner that uses the Docker executor

To use GitLab Runner with Docker you need to [register a runner](https://docs.gitlab.com/runner/register/)
that uses the Docker executor.

In this example, we first set up a temporary template to supply the services:

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
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "docker-ruby:2.6" \
  --executor "docker" \
  --template-config /tmp/test-config.template.toml \
  --docker-image ruby:2.6
```

The registered runner uses the `ruby:2.6` Docker image and runs two
services, `postgres:latest` and `mysql:latest`, both of which are
accessible during the build process.

## What is an image

The `image` keyword is the name of the Docker image the Docker executor
runs to perform the CI tasks.

By default, the executor pulls images only from [Docker Hub](https://hub.docker.com/).
However, you can configure the location in the `gitlab-runner/config.toml` file. For example,
you can set the [Docker pull policy](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)
to use local images.

For more information about images and Docker Hub, read
the [Docker Fundamentals](https://docs.docker.com/engine/understanding-docker/) documentation.

## Define `image` in the `.gitlab-ci.yml` file

You can define an image that's used for all jobs, and a list of
services that you want to use during build time:

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

> Introduced in GitLab and GitLab Runner 9.4.

When configuring the `image` or `services` entries, you can use a string or a map as
options:

- When using a string as an option, it must be the full name of the image to use
  (including the Registry part if you want to download the image from a Registry
  other than Docker Hub).
- When using a map as an option, then it must contain at least the `name`
  option, which is the same name of the image as used for the string setting.

For example, the following two definitions are equal:

1. Using a string as an option to `image` and `services`:

   ```yaml
   image: "registry.example.com/my/image:latest"

   services:
     - postgresql:9.4
     - redis:latest
   ```

1. Using a map as an option to `image` and `services`. The use of `image:name` is
   required:

   ```yaml
   image:
     name: "registry.example.com/my/image:latest"

   services:
     - name: postgresql:9.4
     - name: redis:latest
   ```

### Available settings for `image`

> Introduced in GitLab and GitLab Runner 9.4.

| Setting    | Required | GitLab version | Description |
|------------|----------|----------------| ----------- |
| `name`     | yes, when used with any other option      | 9.4 |Full name of the image to use. It should contain the Registry part if needed. |
| `entrypoint` | no     | 9.4 |Command or script to execute as the container's entrypoint. It's translated to Docker's `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) directive, where each shell token is a separate string in the array. |

### Overriding the entrypoint of an image

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options).

Before showing the available entrypoint override methods, let's describe
how the runner starts. It uses a Docker image for the containers used in the
CI/CD jobs:

1. The runner starts a Docker container using the defined entrypoint (default
   from `Dockerfile` that may be overridden in `.gitlab-ci.yml`)
1. The runner attaches itself to a running container.
1. The runner prepares a script (the combination of
   [`before_script`](../yaml/README.md#before_script),
   [`script`](../yaml/README.md#script),
   and [`after_script`](../yaml/README.md#after_script)).
1. The runner sends the script to the container's shell `stdin` and receives the
   output.

To override the entrypoint of a Docker image, you should
define an empty `entrypoint` in `.gitlab-ci.yml`, so the runner does not start
a useless shell layer. However, that does not work for all Docker versions, and
you should check which one your runner is using:

- _If Docker 17.06 or later is used,_ the `entrypoint` can be set to an empty value.
- _If Docker 17.03 or previous versions are used,_ the `entrypoint` can be set to
  `/bin/sh -c`, `/bin/bash -c` or an equivalent shell available in the image.

The syntax of `image:entrypoint` is similar to [Dockerfile's `ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint).

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

**For Docker 17.06+:**

```yaml
image:
  name: super/sql:experimental
  entrypoint: [""]
```

**For Docker =< 17.03:**

```yaml
image:
  name: super/sql:experimental
  entrypoint: ["/bin/sh", "-c"]
```

## Define image and services in `config.toml`

Look for the `[runners.docker]` section:

```toml
[runners.docker]
  image = "ruby:latest"
  services = ["mysql:latest", "postgres:latest"]
```

The image and services defined this way are added to all jobs run by
that runner.

## Define an image from a private Container Registry

To access private container registries, the GitLab Runner process can use:

- [Statically defined credentials](#using-statically-defined-credentials). That is, a username and password for a specific registry.
- [Credentials Store](#use-a-credentials-store). For more information, read [the relevant Docker documentation](https://docs.docker.com/engine/reference/commandline/login/#credentials-store).
- [Credential Helpers](#use-credential-helpers). For more information, read [the relevant Docker documentation](https://docs.docker.com/engine/reference/commandline/login/#credential-helpers).

To define which should be used, the GitLab Runner process reads the configuration in the following order:

- `DOCKER_AUTH_CONFIG` variable provided as either:
  - A [CI/CD variable](../variables/README.md) in `.gitlab-ci.yml`.
  - A project's variables stored on the projects **Settings > CI/CD** page.
- `DOCKER_AUTH_CONFIG` variable provided as environment variable in `config.toml` of the runner.
- `config.json` file placed in `$HOME/.docker` directory of the user running GitLab Runner process.
  If the `--user` flag is provided to run the GitLab Runner child processes as unprivileged user,
  the home directory of the main GitLab Runner process user is used.

GitLab Runner reads this configuration **only** from `config.toml` and ignores it if
it's provided as an environment variable. This is because GitLab Runner uses **only**
`config.toml` configuration and does not interpolate **any** environment variables at
runtime.

### Requirements and limitations

- This feature requires GitLab Runner **1.8** or higher.
- For GitLab Runner versions **>= 0.6, <1.8** there was a partial
  support for using private registries, which required manual configuration
  of credentials on runner's host. We recommend to upgrade your runner to
  at least version **1.8** if you want to use private registries.
- Available for [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html)
  in GitLab Runner 13.1 and later.
- [Credentials Store](#use-a-credentials-store) and [Credential Helpers](#use-credential-helpers) require binaries to be added to the GitLab Runner's `$PATH`, and require access to do so. Therefore, these features are not available on shared runners, or any other runner where the user does not have access to the environment where the runner is installed.

### Using statically-defined credentials

There are two approaches that you can take in order to access a
private registry. Both require setting the environment variable
`DOCKER_AUTH_CONFIG` with appropriate authentication information.

1. Per-job: To configure one job to access a private registry, add
   `DOCKER_AUTH_CONFIG` as a job variable.
1. Per-runner: To configure a runner so all its jobs can access a
   private registry, add `DOCKER_AUTH_CONFIG` to the environment in the
   runner's configuration.

See below for examples of each.

#### Determining your `DOCKER_AUTH_CONFIG` data

As an example, let's assume you want to use the `registry.example.com:5000/private/image:latest`
image. This image is private and requires you to sign in to a private container
registry.

Let's also assume that these are the sign-in credentials:

| Key      | Value                       |
|:---------|:----------------------------|
| registry | `registry.example.com:5000` |
| username | `my_username`               |
| password | `my_password`               |

Use one of the following methods to determine the value of `DOCKER_AUTH_CONFIG`:

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

- In some setups, it's possible that Docker client uses the available system key
  store to store the result of `docker login`. In that case, it's impossible to
  read `~/.docker/config.json`, so you must prepare the required
  base64-encoded version of `${username}:${password}` and create the Docker
  configuration JSON manually. Open a terminal and execute the following command:

  ```shell
  # The use of "-n" - prevents encoding a newline in the password.
  echo -n "my_username:my_password" | base64

  # Example output to copy
  bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=
  ```

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

#### Configuring a job

To configure a single job with access for `registry.example.com:5000`,
follow these steps:

1. Create a [CI/CD variable](../variables/README.md) `DOCKER_AUTH_CONFIG` with the content of the
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
   `image` and/or `services` in your `.gitlab-ci.yml` file:

   ```yaml
   image: registry.example.com:5000/namespace/image:tag
   ```

   In the example above, GitLab Runner looks at `registry.example.com:5000` for the
   image `namespace/image:tag`.

You can add configuration for as many registries as you want, adding more
registries to the `"auths"` hash as described above.

The full `hostname:port` combination is required everywhere
for the runner to match the `DOCKER_AUTH_CONFIG`. For example, if
`registry.example.com:5000/namespace/image:tag` is specified in `.gitlab-ci.yml`,
then the `DOCKER_AUTH_CONFIG` must also specify `registry.example.com:5000`.
Specifying only `registry.example.com` does not work.

### Configuring a runner

If you have many pipelines that access the same registry, it is
probably better to set up registry access at the runner level. This
allows pipeline authors to have access to a private registry just by
running a job on the appropriate runner. It also makes registry
changes and credential rotations much simpler.

Of course this means that any job on that runner can access the
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

To configure a credentials store:

1. To use a credentials store, you need an external helper program to interact with a specific keychain or external store.
   Make sure the helper program is available in GitLab Runner `$PATH`.

1. Make GitLab Runner use it. There are two ways to accomplish this. Either:

   - Create a
     [CI/CD variable](../variables/README.md)
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

> Support for using Credential Helpers was added in GitLab Runner 12.0

As an example, let's assume that you want to use the `aws_account_id.dkr.ecr.region.amazonaws.com/private/image:latest`
image. This image is private and requires you to log in into a private container registry.

To configure access for `aws_account_id.dkr.ecr.region.amazonaws.com`, follow these steps:

1. Make sure `docker-credential-ecr-login` is available in GitLab Runner's `$PATH`.
1. Have any of the following [AWS credentials setup](https://github.com/awslabs/amazon-ecr-credential-helper#aws-credentials).
   Make sure that GitLab Runner can access the credentials.
1. Make GitLab Runner use it. There are two ways to accomplish this. Either:

   - Create a [CI/CD variable](../variables/README.md)
     `DOCKER_AUTH_CONFIG` with the content of the
     Docker configuration file as the value:

     ```json
     {
       "credHelpers": {
         "aws_account_id.dkr.ecr.region.amazonaws.com": "ecr-login"
       }
     }
     ```

     This configures Docker to use the credential helper for a specific registry.

     or

     ```json
     {
       "credsStore": "ecr-login"
     }
     ```

     This configures Docker to use the credential helper for all Amazon Elastic Container Registry (ECR) registries.

   - Or, if you're running self-managed runners,
     add the above JSON to `${GITLAB_RUNNER_HOME}/.docker/config.json`.
     GitLab Runner reads this configuration file and uses the needed helper for this
     specific repository.

1. You can now use any private image from `aws_account_id.dkr.ecr.region.amazonaws.com` defined in
   `image` and/or `services` in your `.gitlab-ci.yml` file:

   ```yaml
   image: aws_account_id.dkr.ecr.region.amazonaws.com/private/image:latest
   ```

   In the example above, GitLab Runner looks at `aws_account_id.dkr.ecr.region.amazonaws.com` for the
   image `private/image:latest`.

You can add configuration for as many registries as you want, adding more
registries to the `"credHelpers"` hash as described above.
