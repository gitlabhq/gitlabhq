---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
type: index
---

# Services

The `services` keyword defines a Docker image that runs during a `job`
linked to the Docker image that the image keyword defines. This allows
you to access the service image during build time.

The service image can run any application, but the most common use
case is to run a database container, for example:

- [MySQL](mysql.md)
- [PostgreSQL](postgres.md)
- [Redis](redis.md)
- [GitLab](gitlab.md) as an example for a microservice offering a JSON API

It's easier and faster to use an existing image and run it as an additional container
than to install `mysql`, for example, every time the project is built.

You're not limited to only database services. You can add as many
services you need to `.gitlab-ci.yml` or manually modify `config.toml`.
Any image found at [Docker Hub](https://hub.docker.com/) or your private Container Registry can be
used as a service.

Services inherit the same DNS servers, search domains, and additional hosts as
the CI container itself.

## How services are linked to the job

To better understand how container linking works, read
[Linking containers together](https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/).

If you add `mysql` as service to your application, the image is
used to create a container that's linked to the job container.

The service container for MySQL is accessible under the hostname `mysql`.
To access your database service, connect to the host named `mysql` instead of a
socket or `localhost`. Read more in [accessing the services](#accessing-the-services).

## How the health check of services works

Services are designed to provide additional features which are **network accessible**.
They may be a database like MySQL, or Redis, and even `docker:stable-dind` which
allows you to use Docker-in-Docker. It can be practically anything that's
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

## What services are not for

As mentioned before, this feature is designed to provide **network accessible**
services. A database is the simplest example of such a service.

The services feature is not designed to, and does not, add any software from the
defined `services` image(s) to the job's container.

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
      alias: db-postgres
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
  created (requires GitLab Runner v1.1.0 or higher).

To override the default behavior, you can
[specify a service alias](#available-settings-for-services).

## Passing CI/CD variables to services

You can also pass custom CI/CD [variables](../variables/index.md)
to fine tune your Docker `images` and `services` directly in the `.gitlab-ci.yml` file.
For more information, read about [`.gitlab-ci.yml` defined variables](../variables/index.md#create-a-custom-cicd-variable-in-the-gitlab-ciyml-file).

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

## Available settings for `services`

> Introduced in GitLab and GitLab Runner 9.4.

| Setting    | Required | GitLab version | Description |
|------------|----------|----------------| ----------- |
| `name`       | yes, when used with any other option  | 9.4 | Full name of the image to use. If the full image name includes a registry hostname, use the `alias` option to define a shorter service access name. For more information, see [Accessing the services](#accessing-the-services). |
| `entrypoint` | no     | 9.4 |Command or script to execute as the container's entrypoint. It's translated to Docker's `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) directive, where each shell token is a separate string in the array. |
| `command`    | no       | 9.4 |Command or script that should be used as the container's command. It's translated to arguments passed to Docker after the image's name. The syntax is similar to [`Dockerfile`'s `CMD`](https://docs.docker.com/engine/reference/builder/#cmd) directive, where each shell token is a separate string in the array. |
| `alias` (1)     | no       | 9.4 |Additional alias that can be used to access the service from the job's container. Read [Accessing the services](#accessing-the-services) for more information. |

(1) Alias support for the Kubernetes executor was [introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2229) in GitLab Runner 12.8, and is only available for Kubernetes version 1.7 or later.

## Starting multiple services from the same image

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options).

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

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended configuration options](../docker/using_docker_images.md#extended-docker-configuration-options).

Let's assume you have a `super/sql:latest` image with some SQL database
in it. You would like to use it as a service for your job. Let's also
assume that this image does not start the database process while starting
the container. The user needs to manually use `/usr/bin/super-sql run` as
a command to start the database.

Before the new extended Docker configuration options, you would need to:

- Create your own image based on the `super/sql:latest` image.
- Add the default command.
- Use the image in the job's configuration:

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

After the new extended Docker configuration options, you can
set a `command` in the `.gitlab-ci.yml` file instead:

```yaml
# .gitlab-ci.yml

services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

The syntax of `command` is similar to [Dockerfile's `CMD`](https://docs.docker.com/engine/reference/builder/#cmd).

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

## Debug a job locally

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
Instead of `make`, you could run the command which is specific to your project.

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
piped using `stdin` to the bash interpreter which in turn executes the
`build_script` in the `build` container.

When you finish testing and no longer need the containers, you can remove them
with:

```shell
docker rm -f -v build service-mysql service-postgres
```

This forcefully (`-f`) removes the `build` container, the two service
containers, and all volumes (`-v`) that were created with the container
creation.
