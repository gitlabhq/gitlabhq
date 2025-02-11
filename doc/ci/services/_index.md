---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Services
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you configure CI/CD, you specify an image, which is used to create the container
where your jobs run. To specify this image, you use the `image` keyword.

You can specify an additional image by using the `services` keyword. This additional
image is used to create another container, which is available to the first container.
The two containers have access to one another and can communicate when running the job.

The service image can run any application, but the most common use
case is to run a database container, for example:

- [MySQL](mysql.md)
- [PostgreSQL](postgres.md)
- [Redis](redis.md)
- [GitLab](gitlab.md) as an example for a microservice offering a JSON API

Consider that you're developing a content management system that uses database for storage.
You need a database to test all features in the application. Running a database
container as a service image is a good use case in this scenario.

Use an existing image and run it as an additional container
instead of installing `mysql` every time you build a project.

You're not limited to only database services. You can add as many
services you need to `.gitlab-ci.yml` or manually modify the [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).
Any image found at [Docker Hub](https://hub.docker.com/) or your private container registry can be
used as a service.

Services inherit the same DNS servers, search domains, and additional hosts as
the CI container itself.

## How services are linked to the job

To better understand how container linking works, read
[Linking containers together](https://docs.docker.com/network/links/).

If you add `mysql` as service to your application, the image is
used to create a container that's linked to the job container.

The service container for MySQL is accessible under the hostname `mysql`.
To access your database service, connect to the host named `mysql` instead of a
socket or `localhost`. Read more in [accessing the services](#accessing-the-services).

## How the health check of services works

Services are designed to provide additional features which are **network accessible**.
They may be a database like MySQL, or Redis, and even `docker:dind` which
allows you to use Docker-in-Docker (DinD). It can be practically anything that's
required for the CI/CD job to proceed, and is accessed by network.

To make sure this works, the runner:

1. Checks which ports are exposed from the container by default.
1. Starts a special container that waits for these ports to be accessible.

If the second stage of the check fails, it prints the warning: `*** WARNING: Service XYZ probably didn't start properly`.
This issue can occur because:

- There is no opened port in the service.
- The service was not started properly before the timeout, and the port is not
  responding.

In most cases it affects the job, but there may be situations when the job
still succeeds even if that warning was printed. For example:

- The service was started shortly after the warning was raised, and the job is
  not using the linked service from the beginning. In that case, when the
  job needed to access the service, it may have been already there waiting for
  connections.
- The service container is not providing any networking service, but it's doing
  something with the job's directory (all services have the job directory mounted
  as a volume under `/builds`). In that case, the service does its job, and
  because the job is not trying to connect to it, it does not fail.

If the services start successfully, they start before the
[`before_script`](../yaml/_index.md#before_script) runs. This means you can
write a `before_script` that queries the service.

Services stop at the end of the job, even if the job fails.

## Using software provided by a service image

When you specify the `service`, this provides **network accessible**
services. A database is the simplest example of such a service.

The services feature does not add any software from the
defined `services` images to the job's container.

For example, if you have the following `services` defined in your job, the `php`,
`node` or `go` commands are **not** available for your script, and the job fails:

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
- Create your own Docker image, with all the required tools included,
  and use that in your job.

## Define `services` in the `.gitlab-ci.yml` file

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

Or you can pass some [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options)
for `image` and `services`:

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]
  services:
    - name: my-postgres:11.7
      alias: db,postgres,pg
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## Accessing the services

Let's say that you need a Wordpress instance to test some API integration with
your application. You can then use for example the
[`tutum/wordpress`](https://hub.docker.com/r/tutum/wordpress/) image in your
`.gitlab-ci.yml` file:

```yaml
services:
  - tutum/wordpress:latest
```

If you don't [specify a service alias](#available-settings-for-services),
when the job runs, `tutum/wordpress` is started. You have
access to it from your build container under two hostnames:

- `tutum-wordpress`
- `tutum__wordpress`

Hostnames with underscores are not RFC valid and may cause problems in third-party
applications.

The default aliases for the service's hostname are created from its image name
following these rules:

- Everything after the colon (`:`) is stripped.
- Slash (`/`) is replaced with double underscores (`__`) and the primary alias
  is created.
- Slash (`/`) is replaced with a single dash (`-`) and the secondary alias is
  created (requires GitLab Runner v1.1.0 or later).

To override the default behavior, you can
[specify one or more service aliases](#available-settings-for-services).

### Connecting services

You can use inter-dependent services with complex jobs, like end-to-end tests where an
external API needs to communicate with its own database.

For example, for an end-to-end test for a front-end application that uses an API, and where the API needs a database:

```yaml
end-to-end-tests:
  image: node:latest
  services:
    - name: selenium/standalone-firefox:${FIREFOX_VERSION}
      alias: firefox
    - name: registry.gitlab.com/organization/private-api:latest
      alias: backend-api
    - name: postgres:14.3
      alias: db postgres db
  variables:
    FF_NETWORK_PER_BUILD: 1
    POSTGRES_PASSWORD: supersecretpassword
    BACKEND_POSTGRES_HOST: postgres
  script:
    - npm install
    - npm test
```

For this solution to work, you must use
[the networking mode that creates a new network for each job](https://docs.gitlab.com/runner/executors/docker.html#create-a-network-for-each-job).

## Passing CI/CD variables to services

You can also pass custom CI/CD [variables](../variables/_index.md)
to fine tune your Docker `images` and `services` directly in the `.gitlab-ci.yml` file.
For more information, read about [`.gitlab-ci.yml` defined variables](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).

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

default:
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

## Available settings for `services`

> - Introduced in GitLab and GitLab Runner 9.4.

| Setting                           | Required                             | GitLab version | Description                                                                                                                                                                                                                                                                                                                         |
|-----------------------------------|--------------------------------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`                            | yes, when used with any other option | 9.4            | Full name of the image to use. If the full image name includes a registry hostname, use the `alias` option to define a shorter service access name. For more information, see [Accessing the services](#accessing-the-services).                                                                                                    |
| `entrypoint`                      | no                                   | 9.4            | Command or script to execute as the container's entrypoint. It's translated to the Docker `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint) directive, where each shell token is a separate string in the array. |
| `command`                         | no                                   | 9.4            | Command or script that should be used as the container's command. It's translated to arguments passed to Docker after the image's name. The syntax is similar to [`Dockerfile`'s `CMD`](https://docs.docker.com/reference/dockerfile/#cmd) directive, where each shell token is a separate string in the array.                     |
| `alias` <sup>1</sup> <sup>3</sup> | no                                   | 9.4            | Additional aliases to access the service from the job's container. Multiple aliases can be separated by spaces or commas. For more information, see [Accessing the services](#accessing-the-services).                                                                                                                              |
| `variables` <sup>2</sup>          | no                                   | 14.5           | Additional environment variables that are passed exclusively to the service. The syntax is the same as [Job Variables](../variables/_index.md). Service variables cannot reference themselves.                                                                                                                                      |

**Footnotes:**

1. Alias support for the Kubernetes executor was [introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2229) in GitLab Runner 12.8, and is only available for Kubernetes version 1.7 or later.
1. Service variables support for the Docker and the Kubernetes executor was [introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3158) in GitLab Runner 14.8.
1. Use alias as a container name for the Kubernetes executor was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421131) in GitLab Runner 17.9. For more information, see [Configuring the service containers name with the Kubernetes executor](#using-aliases-as-service-container-names-for-the-kubernetes-executor).

## Starting multiple services from the same image

> - Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options).

Before the new extended Docker configuration options, the following configuration
would not work properly:

```yaml
services:
  - mysql:latest
  - mysql:latest
```

The runner would start two containers, each that uses the `mysql:latest` image.
However, both of them would be added to the job's container with the `mysql` alias, based on
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

## Setting a command for the service

> - Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options).

Let's assume you have a `super/sql:latest` image with some SQL database
in it. You would like to use it as a service for your job. Let's also
assume that this image does not start the database process while starting
the container. The user needs to manually use `/usr/bin/super-sql run` as
a command to start the database.

Before the new extended Docker configuration options, you would need to:

- Create your own image based on the `super/sql:latest` image.
- Add the default command.
- Use the image in the job's configuration.

  - `my-super-sql:latest` image's Dockerfile:

    ```dockerfile
    FROM super/sql:latest
    CMD ["/usr/bin/super-sql", "run"]
    ```

  - In the job in the `.gitlab-ci.yml`:

    ```yaml
    services:
      - my-super-sql:latest
    ```

After the new extended Docker configuration options, you can
set a `command` in the `.gitlab-ci.yml` file instead:

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

The syntax of `command` is similar to [Dockerfile `CMD`](https://docs.docker.com/reference/dockerfile/#cmd).

## Using aliases as service container names for the Kubernetes executor

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421131) in GitLab and GitLab Runner 17.9.

You can use service aliases as service container names for the Kubernetes executor.
GitLab Runner names containers based on the following conditions:

- When multiple aliases are set for a service, the service container is named after the first alias that:
  - Isn't already used by another service container.
  - Follows the [Kubernetes constraints for label names](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names).
- When aliases can't be used to name a service container, GitLab Runner falls back to the `svc-i` pattern.

## Using `services` with `docker run` (Docker-in-Docker) side-by-side

Containers started with `docker run` can also connect to services provided by GitLab.

If booting a service is expensive or time consuming, you can
run tests from different client environments,
while booting up the tested service only once.

```yaml
access-service:
  stage: build
  image: docker:20.10.16
  services:
    - docker:dind                    # necessary for docker run
    - tutum/wordpress:latest
  variables:
    FF_NETWORK_PER_BUILD: "true"     # activate container-to-container networking
  script: |
    docker run --rm --name curl \
      --volume  "$(pwd)":"$(pwd)"    \
      --workdir "$(pwd)"             \
      --network=host                 \
      curlimages/curl:7.74.0 curl "http://tutum-wordpress"
```

For this solution to work, you must:

- Use [the networking mode that creates a new network for each job](https://docs.gitlab.com/runner/executors/docker.html#create-a-network-for-each-job).
- [Not use the Docker executor with Docker socket binding](../docker/using_docker_build.md#use-the-docker-executor-with-docker-socket-binding).
  If you must, then in the above example, instead of `host`, use the dynamic network name created for this job.

## How Docker integration works

Below is a high level overview of the steps performed by Docker during job
time.

1. Create any service container: `mysql`, `postgresql`, `mongodb`, `redis`.
1. Create a cache container to store all volumes as defined in `config.toml` and
   `Dockerfile` of build image (`ruby:2.6` as in above example).
1. Create a build container and link any service container to build container.
1. Start the build container, and send a job script to the container.
1. Run the job script.
1. Checkout code in: `/builds/group-name/project-name/`.
1. Run any step defined in `.gitlab-ci.yml`.
1. Check the exit status of build script.
1. Remove the build container and all created service containers.

## Capturing service container logs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3680) in GitLab Runner 15.6.

Logs generated by applications running in service containers can be captured for subsequent examination and debugging.
View service container logs when a service container starts successfully but causes job failures due to unexpected behavior.
The logs can indicate missing or incorrect configuration of the service
in the container.

`CI_DEBUG_SERVICES` should only be enabled when service containers are being actively debugged as there are both storage
and performance consequences to capturing service container logs.

To enable service logging, add the `CI_DEBUG_SERVICES` variable to the project's
`.gitlab-ci.yml` file:

```yaml
variables:
  CI_DEBUG_SERVICES: "true"
```

Accepted values are:

- Enabled: `TRUE`, `true`, `True`
- Disabled: `FALSE`, `false`, `False`

Any other values result in an error message and effectively disable the feature.

When enabled, logs for all service containers are captured and streamed into the jobs trace log concurrently with
other logs. Logs from each container are prefixed with the container's aliases, and displayed in a different color.

NOTE:
To diagnose job failures, you can adjust the logging level in your service container for which you want to capture logs.
The default logging level might not provide sufficient troubleshooting information.

WARNING:
Enabling `CI_DEBUG_SERVICES` might reveal masked variables. When `CI_DEBUG_SERVICES` is enabled,
service container logs and the CI job's logs are streamed to the job's trace log concurrently. This means that the
service container logs might get inserted into a job's masked log. This would thwart the variable masking mechanism
and result in the masked variable being revealed.

See [Mask a CI/CD Variable](../variables/_index.md#mask-a-cicd-variable)

## Debug a job locally

The following commands are run without root privileges. Verify that you can run Docker commands with your user account.

First start by creating a file named `build_script`:

```shell
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make runner-bin-host
EOF
```

Here we use as an example the GitLab Runner repository which contains a Makefile, so running `make` executes the target
defined in the Makefile. Instead of `make runner-bin-host`, you could run the command which is specific to your project.

Then create a service container:

```shell
docker run -d --name service-redis redis:latest
```

The previous command creates a service container named `service-redis` using the latest Redis image. The service
container runs in the background (`-d`).

Finally, create a build container by executing the `build_script` file we created earlier:

```shell
docker run --name build -i --link=service-redis:redis golang:latest /bin/bash < build_script
```

The above command creates a container named `build` that is spawned from the `golang:latest` image and has one service
linked to it. The `build_script` is piped using `stdin` to the bash interpreter which in turn executes the
`build_script` in the `build` container.

Use the following command to remove containers after testing is complete:

```shell
docker rm -f -v build service-redis
```

This forcefully (`-f`) removes the `build` container, the service container, and all volumes (`-v`) that were created
with the container creation.

## Security when using services containers

Docker privileged mode applies to services. This means that the service image container can access the host system. You should use container images from trusted sources only.

## Shared `/builds` directory

The build directory is mounted as a volume under `/builds` and is shared
between the job and services. The job checks the project out into
`/builds/$CI_PROJECT_PATH` after the services are running. Your service might
need to access project files or store artifacts. If so, wait for the directory
to exist and for `$CI_COMMIT_SHA` to be checked out. Any changes made before
the job finishes its checkout process are removed by the checkout process.

The service must detect when the job directory is populated and
ready for processing. For example, wait for a specific file to become available.

Services that start working immediately when launched are likely to fail, as the
job data may not be available yet. For example, containers use the `docker build`
command to make a network connection to the DinD service.
The service instructs its API to start a container image build. The Docker Engine
must have access to the files you're referencing in your Dockerfile. Hence, you
need access to the `CI_PROJECT_DIR` in the service. However, Docker Engine does not try to access it until
the `docker build` command is called in a job. At this time, the `/builds` directory
is already populated with data. The service that tries to write the `CI_PROJECT_DIR`
immediately after it started might fail with a `No such file or directory` error.

In scenarios where services that interact with job data are not controlled by the job itself, consider the
[Docker executor workflow](https://docs.gitlab.com/runner/executors/docker.html#docker-executor-workflow).
