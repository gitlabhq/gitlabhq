---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Using Docker images

GitLab CI/CD in conjunction with [GitLab Runner](../runners/README.md) can use
[Docker Engine](https://www.docker.com/) to test and build any application.

Docker is an open-source project that allows you to use predefined images to
run applications in independent "containers" that are run within a single Linux
instance. [Docker Hub](https://hub.docker.com/) has a rich database of pre-built images that can be
used to test and build your applications.

When used with GitLab CI/CD, Docker runs each job in a separate and isolated
container using the predefined image that's set up in
[`.gitlab-ci.yml`](../yaml/README.md).

This makes it easier to have a simple and reproducible build environment that
can also run on your workstation. The added benefit is that you can test all
the commands that we explore later from your shell, rather than having to
test them on a dedicated CI server.

## Register Docker Runner

To use GitLab Runner with Docker you need to [register a new runner](https://docs.gitlab.com/runner/register/)
to use the `docker` executor.

An example can be seen below. First we set up a temporary template to supply the services:

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

Then we register the runner using the template that was just created:

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

By default, the executor only pulls images from [Docker Hub](https://hub.docker.com/),
however this can be configured in the `gitlab-runner/config.toml` by setting
the [Docker pull policy](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work) to allow using local images.

For more information about images and Docker Hub, please read
the [Docker Fundamentals](https://docs.docker.com/engine/understanding-docker/) documentation.

## What is a service

The `services` keyword defines just another Docker image that's run during
your job and is linked to the Docker image that the `image` keyword defines.
This allows you to access the service image during build time.

The service image can run any application, but the most common use case is to
run a database container, for example, `mysql`. It's easier and faster to use an
existing image and run it as an additional container than install `mysql` every
time the project is built.

You're not limited to have only database services. You can add as many
services you need to `.gitlab-ci.yml` or manually modify `config.toml`.
Any image found at [Docker Hub](https://hub.docker.com/) or your private Container Registry can be
used as a service.

Services inherit the same DNS servers, search domains, and additional hosts as
the CI container itself.

You can see some widely used services examples in the relevant documentation of
[CI services examples](../services/README.md).

### How services are linked to the job

To better understand how the container linking works, read
[Linking containers together](https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/).

To summarize, if you add `mysql` as service to your application, the image is
then used to create a container that's linked to the job container.

The service container for MySQL is accessible under the hostname `mysql`.
So, in order to access your database service you have to connect to the host
named `mysql` instead of a socket or `localhost`. Read more in [accessing the
services](#accessing-the-services).

### How the health check of services works

Services are designed to provide additional functionality which is **network accessible**.
It may be a database like MySQL, or Redis, and even `docker:stable-dind` which
allows you to use Docker in Docker. It can be practically anything that's
required for the CI/CD job to proceed and is accessed by network.

To make sure this works, the runner:

1. Checks which ports are exposed from the container by default.
1. Starts a special container that waits for these ports to be accessible.

When the second stage of the check fails, either because there is no opened port in the
service, or the service was not started properly before the timeout and the port is not
responding, it prints the warning: `*** WARNING: Service XYZ probably didn't start properly`.

In most cases it affects the job, but there may be situations when the job
still succeeds even if that warning was printed. For example:

- The service was started a little after the warning was raised, and the job is
  not using the linked service from the beginning. In that case, when the
  job needed to access the service, it may have been already there waiting for
  connections.
- The service container is not providing any networking service, but it's doing
  something with the job's directory (all services have the job directory mounted
  as a volume under `/builds`). In that case, the service does its job, and
  since the job is not trying to connect to it, it does not fail.

### What services are not for

As it was mentioned before, this feature is designed to provide **network accessible**
services. A database is the simplest example of such a service.

The services feature is not designed to, and does not add any software from the
defined `services` image(s) to the job's container.

For example, if you have the following `services` defined in your job, the `php`,
`node` or `go` commands are **not** available for your script, and thus
the job fails:

```yaml
job:
  services:
    - php:7
    - node:latest
    - golang:1.10
  image: alpine:3.7
  script:
    - php -v
    - node -v
    - go version
```

If you need to have `php`, `node` and `go` available for your script, you should
either:

- Choose an existing Docker image that contains all required tools.
- Create your own Docker image, with all the required tools included
  and use that in your job.

### Accessing the services

Let's say that you need a Wordpress instance to test some API integration with
your application.

You can then use for example the [tutum/wordpress](https://hub.docker.com/r/tutum/wordpress/) image in your
`.gitlab-ci.yml`:

```yaml
services:
  - tutum/wordpress:latest
```

If you don't [specify a service alias](#available-settings-for-services),
when the job is run, `tutum/wordpress` is started and you have
access to it from your build container under two hostnames to choose from:

- `tutum-wordpress`
- `tutum__wordpress`

Hostnames with underscores are not RFC valid and may cause problems in 3rd party
applications.

The default aliases for the service's hostname are created from its image name
following these rules:

- Everything after the colon (`:`) is stripped.
- Slash (`/`) is replaced with double underscores (`__`) and the primary alias
  is created.
- Slash (`/`) is replaced with a single dash (`-`) and the secondary alias is
  created (requires GitLab Runner v1.1.0 or higher).

To override the default behavior, you can
[specify a service alias](#available-settings-for-services).

## Define `image` and `services` from `.gitlab-ci.yml`

You can simply define an image that's used for all jobs and a list of
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

It's also possible to define different images and services per job:

```yaml
default:
  before_script:
    - bundle install

test:2.6:
  image: ruby:2.6
  services:
    - postgres:11.7
  script:
    - bundle exec rake spec

test:2.7:
  image: ruby:2.7
  services:
    - postgres:12.2
  script:
    - bundle exec rake spec
```

Or you can pass some [extended configuration options](#extended-docker-configuration-options)
for `image` and `services`:

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]

  services:
    - name: my-postgres:11.7
      alias: db-postgres
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]

  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## Passing environment variables to services

You can also pass custom environment [variables](../variables/README.md)
to fine tune your Docker `images` and `services` directly in the `.gitlab-ci.yml` file.
For more information, see [custom environment variables](../variables/README.md#gitlab-ciyml-defined-variables)

```yaml
# The following variables are automatically passed down to the Postgres container
# as well as the Ruby container and available within each.
variables:
  HTTPS_PROXY: "https://10.1.1.1:8090"
  HTTP_PROXY: "https://10.1.1.1:8090"
  POSTGRES_DB: "my_custom_db"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "example"
  PGDATA: "/var/lib/postgresql/data"
  POSTGRES_INITDB_ARGS: "--encoding=UTF8 --data-checksums"

services:
  - name: postgres:11.7
    alias: db
    entrypoint: ["docker-entrypoint.sh"]
    command: ["postgres"]

image:
  name: ruby:2.6
  entrypoint: ["/bin/bash"]

before_script:
  - bundle install

test:
  script:
    - bundle exec rake spec
```

## Extended Docker configuration options

> Introduced in GitLab and GitLab Runner 9.4.

When configuring the `image` or `services` entries, you can use a string or a map as
options:

- when using a string as an option, it must be the full name of the image to use
  (including the Registry part if you want to download the image from a Registry
  other than Docker Hub)
- when using a map as an option, then it must contain at least the `name`
  option, which is the same name of the image as used for the string setting

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
| `name`     | yes, when used with any other option      | 9.4 |Full name of the image that should be used. It should contain the Registry part if needed. |
| `entrypoint` | no     | 9.4 |Command or script that should be executed as the container's entrypoint. It's translated to Docker's `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) directive, where each shell token is a separate string in the array. |

### Available settings for `services`

> Introduced in GitLab and GitLab Runner 9.4.

| Setting    | Required | GitLab version | Description |
|------------|----------|----------------| ----------- |
| `name`       | yes, when used with any other option  | 9.4 | Full name of the image that should be used. It should contain the Registry part if needed. |
| `entrypoint` | no     | 9.4 |Command or script that should be executed as the container's entrypoint. It's translated to Docker's `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) directive, where each shell token is a separate string in the array. |
| `command`    | no       | 9.4 |Command or script that should be used as the container's command. It's translated to arguments passed to Docker after the image's name. The syntax is similar to [`Dockerfile`'s `CMD`](https://docs.docker.com/engine/reference/builder/#cmd) directive, where each shell token is a separate string in the array. |
| `alias` (1)     | no       | 9.4 |Additional alias that can be used to access the service from the job's container. Read [Accessing the services](#accessing-the-services) for more information. |

(1) Alias support for the Kubernetes executor was [introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2229) in GitLab Runner 12.8, and is only available for Kubernetes version 1.7 or later.

### Starting multiple services from the same image

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](#extended-docker-configuration-options).

Before the new extended Docker configuration options, the following configuration
would not work properly:

```yaml
services:
  - mysql:latest
  - mysql:latest
```

The runner would start two containers using the `mysql:latest` image, but both
of them would be added to the job's container with the `mysql` alias based on
the [default hostname naming](#accessing-the-services). This would end with one
of the services not being accessible.

After the new extended Docker configuration options, the above example would
look like:

```yaml
services:
  - name: mysql:latest
    alias: mysql-1
  - name: mysql:latest
    alias: mysql-2
```

The runner still starts two containers using the `mysql:latest` image,
however now each of them are also accessible with the alias configured
in `.gitlab-ci.yml` file.

### Setting a command for the service

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](#extended-docker-configuration-options).

Let's assume you have a `super/sql:latest` image with some SQL database
inside it and you would like to use it as a service for your job. Let's also
assume that this image does not start the database process while starting
the container and the user needs to manually use `/usr/bin/super-sql run` as
a command to start the database.

Before the new extended Docker configuration options, you would need to create
your own image based on the `super/sql:latest` image, add the default command,
and then use it in job's configuration, like:

```dockerfile
# my-super-sql:latest image's Dockerfile

FROM super/sql:latest
CMD ["/usr/bin/super-sql", "run"]
```

```yaml
# .gitlab-ci.yml

services:
  - my-super-sql:latest
```

After the new extended Docker configuration options, you can now simply
set a `command` in `.gitlab-ci.yml`, like:

```yaml
# .gitlab-ci.yml

services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

As you can see, the syntax of `command` is similar to [Dockerfile's `CMD`](https://docs.docker.com/engine/reference/builder/#cmd).

### Overriding the entrypoint of an image

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](#extended-docker-configuration-options).

Before showing the available entrypoint override methods, let's describe shortly
how the runner starts and uses a Docker image for the containers used in the
CI jobs:

1. The runner starts a Docker container using the defined entrypoint (default
   from `Dockerfile` that may be overridden in `.gitlab-ci.yml`)
1. The runner attaches itself to a running container.
1. The runner prepares a script (the combination of
   [`before_script`](../yaml/README.md#before_script),
   [`script`](../yaml/README.md#script),
   and [`after_script`](../yaml/README.md#after_script)).
1. The runner sends the script to the container's shell STDIN and receives the
   output.

To override the entrypoint of a Docker image, the recommended solution is to
define an empty `entrypoint` in `.gitlab-ci.yml`, so the runner does not start
a useless shell layer. However, that does not work for all Docker versions, and
you should check which one your runner is using. Specifically:

- If Docker 17.06 or later is used, the `entrypoint` can be set to an empty value.
- If Docker 17.03 or previous versions are used, the `entrypoint` can be set to
  `/bin/sh -c`, `/bin/bash -c` or an equivalent shell available in the image.

The syntax of `image:entrypoint` is similar to [Dockerfile's `ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint).

Let's assume you have a `super/sql:experimental` image with some SQL database
inside it and you would like to use it as a base image for your job because you
want to execute some tests with this database binary. Let's also assume that
this image is configured with `/usr/bin/super-sql run` as an entrypoint. That
means that when starting the container without additional options, it runs
the database's process, while the runner expects that the image has no
entrypoint or that the entrypoint is prepared to start a shell command.

With the extended Docker configuration options, instead of creating your
own image based on `super/sql:experimental`, setting the `ENTRYPOINT`
to a shell, and then using the new image in your CI job, you can now simply
define an `entrypoint` in `.gitlab-ci.yml`.

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

The image and services defined this way are added to all job run by
that runner.

## Define an image from a private Container Registry

To access private container registries, the GitLab Runner process can use:

- [Statically defined credentials](#using-statically-defined-credentials). That is, a username and password for a specific registry.
- [Credentials Store](#using-credentials-store). For more information, see [the relevant Docker documentation](https://docs.docker.com/engine/reference/commandline/login/#credentials-store).
- [Credential Helpers](#using-credential-helpers). For more information, see [the relevant Docker documentation](https://docs.docker.com/engine/reference/commandline/login/#credential-helpers).

To define which should be used, the GitLab Runner process reads the configuration in the following order:

- `DOCKER_AUTH_CONFIG` variable provided as either:
  - A [variable](../variables/README.md#gitlab-cicd-environment-variables) in `.gitlab-ci.yml`.
  - A project's variables stored on the projects **Settings > CI/CD** page.
- `DOCKER_AUTH_CONFIG` variable provided as environment variable in `config.toml` of the runner.
- `config.json` file placed in `$HOME/.docker` directory of the user running GitLab Runner process.
  If the `--user` flag is provided to run the GitLab Runner child processes as unprivileged user,
  the home directory of the main GitLab Runner process user is used.

GitLab Runner reads this configuration **only** from `config.toml` and ignores it if
it's provided as an environment variable. This is because GitLab Runner uses **only**
`config.toml` configuration and does not interpolate **ANY** environment variables at
runtime.

### Requirements and limitations

- This feature requires GitLab Runner **1.8** or higher.
- For GitLab Runner versions **>= 0.6, <1.8** there was a partial
  support for using private registries, which required manual configuration
  of credentials on runner's host. We recommend to upgrade your runner to
  at least version **1.8** if you want to use private registries.
- Available for [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html)
  in GitLab Runner 13.1 and later.
- [Credentials Store](#using-credentials-store) and [Credential Helpers](#using-credential-helpers) require binaries to be added to the GitLab Runner's `$PATH`, and require access to do so. Therefore, these features are not available on shared runners or any other runner where the user does not have access to the environment where the runner is installed.

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
image, which is private and requires you to sign in to a private container
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
  read `~/.docker/config.json`, so you need to prepare the required
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

1. Create a [variable](../variables/README.md#gitlab-cicd-environment-variables) `DOCKER_AUTH_CONFIG` with the content of the
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

### Using Credentials Store

> Support for using Credentials Store was added in GitLab Runner 9.5.

To configure credentials store, follow these steps:

1. To use a credentials store, you need an external helper program to interact with a specific keychain or external store.
   Make sure helper program is available in GitLab Runner `$PATH`.

1. Make GitLab Runner use it. There are two ways to accomplish this. Either:

   - Create a
     [variable](../variables/README.md#gitlab-cicd-environment-variables)
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

`credsStore` is used to access ALL the registries.
If you want to use both images from private registry and public images from Docker Hub,
pulling from Docker Hub would fail, because Docker daemon tries to use the same credentials for **ALL** the registries.

### Using Credential Helpers

> Support for using Credential Helpers was added in GitLab Runner 12.0

As an example, let's assume that you want to use the `aws_account_id.dkr.ecr.region.amazonaws.com/private/image:latest`
image which is private and requires you to log in into a private container registry.

To configure access for `aws_account_id.dkr.ecr.region.amazonaws.com`, follow these steps:

1. Make sure `docker-credential-ecr-login` is available in GitLab Runner's `$PATH`.
1. Have any of the following [AWS credentials setup](https://github.com/awslabs/amazon-ecr-credential-helper#aws-credentials).
   Make sure that GitLab Runner can access the credentials.
1. Make GitLab Runner use it. There are two ways to accomplish this. Either:

   - Create a [variable](../variables/README.md#gitlab-cicd-environment-variables)
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

     This configures Docker to use the credential helper for all Amazon ECR registries.

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

## Configuring services

Many services accept environment variables which allow you to easily change
database names or set account names depending on the environment.

GitLab Runner 0.5.0 and up passes all YAML-defined variables to the created
service containers.

For all possible configuration variables check the documentation of each image
provided in their corresponding Docker hub page.

All variables are passed to all services containers. It's not
designed to distinguish which variable should go where.

### PostgreSQL service example

See the specific documentation for
[using PostgreSQL as a service](../services/postgres.md).

### MySQL service example

See the specific documentation for
[using MySQL as a service](../services/mysql.md).

## How Docker integration works

Below is a high level overview of the steps performed by Docker during job
time.

1. Create any service container: `mysql`, `postgresql`, `mongodb`, `redis`.
1. Create cache container to store all volumes as defined in `config.toml` and
   `Dockerfile` of build image (`ruby:2.6` as in above example).
1. Create build container and link any service container to build container.
1. Start build container and send job script to the container.
1. Run job script.
1. Checkout code in: `/builds/group-name/project-name/`.
1. Run any step defined in `.gitlab-ci.yml`.
1. Check exit status of build script.
1. Remove build container and all created service containers.

## How to debug a job locally

The following commands are run without root privileges. You should be
able to run Docker with your regular user account.

First start with creating a file named `build_script`:

```shell
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make
EOF
```

Here we use as an example the GitLab Runner repository which contains a
Makefile, so running `make` executes the commands defined in the Makefile.
Your mileage may vary, so instead of `make` you could run the command which
is specific to your project.

Then create some service containers:

```shell
docker run -d --name service-mysql mysql:latest
docker run -d --name service-postgres postgres:latest
```

This creates two service containers, named `service-mysql` and
`service-postgres` which use the latest MySQL and PostgreSQL images
respectively. They both run in the background (`-d`).

Finally, create a build container by executing the `build_script` file we
created earlier:

```shell
docker run --name build -i --link=service-mysql:mysql --link=service-postgres:postgres ruby:2.6 /bin/bash < build_script
```

The above command creates a container named `build` that's spawned from
the `ruby:2.6` image and has two services linked to it. The `build_script` is
piped using STDIN to the bash interpreter which in turn executes the
`build_script` in the `build` container.

When you finish testing and no longer need the containers, you can remove them
with:

```shell
docker rm -f -v build service-mysql service-postgres
```

This forcefully (`-f`) removes the `build` container, the two service
containers as well as all volumes (`-v`) that were created with the container
creation.
