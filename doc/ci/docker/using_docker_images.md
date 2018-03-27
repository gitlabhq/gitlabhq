# Using Docker images

GitLab CI in conjunction with [GitLab Runner](../runners/README.md) can use
[Docker Engine](https://www.docker.com/) to test and build any application.

Docker is an open-source project that allows you to use predefined images to
run applications in independent "containers" that are run within a single Linux
instance. [Docker Hub][hub] has a rich database of pre-built images that can be
used to test and build your applications.

Docker, when used with GitLab CI, runs each job in a separate and isolated
container using the predefined image that is set up in
[`.gitlab-ci.yml`](../yaml/README.md).

This makes it easier to have a simple and reproducible build environment that
can also run on your workstation. The added benefit is that you can test all
the commands that we will explore later from your shell, rather than having to
test them on a dedicated CI server.

## Register Docker Runner

To use GitLab Runner with Docker you need to [register a new Runner][register]
to use the `docker` executor.

A one-line example can be seen below:

```bash
sudo gitlab-runner register \
  --url "https://gitlab.example.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "docker-ruby-2.1" \
  --executor "docker" \
  --docker-image ruby:2.1 \
  --docker-postgres latest \
  --docker-mysql latest
```

The registered runner will use the `ruby:2.1` Docker image and will run two
services, `postgres:latest` and `mysql:latest`, both of which will be
accessible during the build process.

## What is an image

The `image` keyword is the name of the Docker image the Docker executor
will run to perform the CI tasks.

By default, the executor will only pull images from [Docker Hub][hub],
but this can be configured in the `gitlab-runner/config.toml` by setting
the [Docker pull policy][] to allow using local images.

For more information about images and Docker Hub please read
the [Docker Fundamentals][] documentation.

## What is a service

The `services` keyword defines just another Docker image that is run during
your job and is linked to the Docker image that the `image` keyword defines.
This allows you to access the service image during build time.

The service image can run any application, but the most common use case is to
run a database container, e.g., `mysql`. It's easier and faster to use an
existing image and run it as an additional container than install `mysql` every
time the project is built.

You are not limited to have only database services. You can add as many
services you need to `.gitlab-ci.yml` or manually modify `config.toml`.
Any image found at [Docker Hub][hub] or your private Container Registry can be
used as a service.

You can see some widely used services examples in the relevant documentation of
[CI services examples](../services/README.md).

### How services are linked to the job

To better understand how the container linking works, read
[Linking containers together][linking-containers].

To summarize, if you add `mysql` as service to your application, the image will
then be used to create a container that is linked to the job container.

The service container for MySQL will be accessible under the hostname `mysql`.
So, in order to access your database service you have to connect to the host
named `mysql` instead of a socket or `localhost`. Read more in [accessing the
services](#accessing-the-services).

### How the health check of services works

Services are designed to provide additional functionality which is **network accessible**.
It may be a database like MySQL, or Redis, and even `docker:dind` which
allows you to use Docker in Docker. It can be practically anything that is
required for the CI/CD job to proceed and is accessed by network.

To make sure this works, the Runner:

1. checks which ports are exposed from the container by default
1. starts a special container that waits for these ports to be accessible

When the second stage of the check fails, either because there is no opened port in the
service, or the service was not started properly before the timeout and the port is not
responding, it prints the warning: `*** WARNING: Service XYZ probably didn't start properly`.

In most cases it will affect the job, but there may be situations when the job
will still succeed even if that warning was printed. For example:

- The service was started a little after the warning was raised, and the job is
  not using the linked service from the very beginning. In that case, when the
  job needed to access the service, it may have been already there waiting for
  connections.
- The service container is not providing any networking service, but it's doing
  something with the job's directory (all services have the job directory mounted
  as a volume under `/builds`). In that case, the service will do its job, and
  since the job is not trying to connect to it, it won't fail.

### What services are not for

As it was mentioned before, this feature is designed to provide **network accessible**
services. A database is the simplest example of such a service.

NOTE: **Note:**
The services feature is not designed to, and will not add any software from the
defined `services` image(s) to the job's container.

For example, if you have the following `services` defined in your job, the `php`,
`node` or `go` commands will **not** be available for your script, and thus
the job will fail:

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

- choose an existing Docker image that contains all required tools, or
- create your own Docker image, which will have all the required tools included
  and use that in your job

### Accessing the services

Let's say that you need a Wordpress instance to test some API integration with
your application.

You can then use for example the [tutum/wordpress][] image in your
`.gitlab-ci.yml`:

```yaml
services:
- tutum/wordpress:latest
```

If you don't [specify a service alias](#available-settings-for-services),
when the job is run, `tutum/wordpress` will be started and you will have
access to it from your build container under two hostnames to choose from:

- `tutum-wordpress`
- `tutum__wordpress`

>**Note:**
Hostnames with underscores are not RFC valid and may cause problems in 3rd party
applications.

The default aliases for the service's hostname are created from its image name
following these rules:

- Everything after the colon (`:`) is stripped
- Slash (`/`) is replaced with double underscores (`__`) and the primary alias
  is created
- Slash (`/`) is replaced with a single dash (`-`) and the secondary alias is
  created (requires GitLab Runner v1.1.0 or higher)

To override the default behavior, you can
[specify a service alias](#available-settings-for-services).

## Define `image` and `services` from `.gitlab-ci.yml`

You can simply define an image that will be used for all jobs and a list of
services that you want to use during build time:

```yaml
image: ruby:2.2

services:
  - postgres:9.3

before_script:
  - bundle install

test:
  script:
  - bundle exec rake spec
```

It is also possible to define different images and services per job:

```yaml
before_script:
  - bundle install

test:2.1:
  image: ruby:2.1
  services:
  - postgres:9.3
  script:
  - bundle exec rake spec

test:2.2:
  image: ruby:2.2
  services:
  - postgres:9.4
  script:
  - bundle exec rake spec
```

Or you can pass some [extended configuration options](#extended-docker-configuration-options)
for `image` and `services`:

```yaml
image:
  name: ruby:2.2
  entrypoint: ["/bin/bash"]

services:
- name: my-postgres:9.4
  alias: db-postgres
  entrypoint: ["/usr/local/bin/db-postgres"]
  command: ["start"]

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
| `entrypoint` | no     | 9.4 |Command or script that should be executed as the container's entrypoint. It will be translated to Docker's `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`][entrypoint] directive, where each shell token is a separate string in the array. |

### Available settings for `services`

> Introduced in GitLab and GitLab Runner 9.4.

| Setting    | Required | GitLab version | Description |
|------------|----------|----------------| ----------- |
| `name`       | yes, when used with any other option  | 9.4 | Full name of the image that should be used. It should contain the Registry part if needed. |
| `entrypoint` | no     | 9.4 |Command or script that should be executed as the container's entrypoint. It will be translated to Docker's `--entrypoint` option while creating the container. The syntax is similar to [`Dockerfile`'s `ENTRYPOINT`][entrypoint] directive, where each shell token is a separate string in the array. |
| `command`    | no       | 9.4 |Command or script that should be used as the container's command. It will be translated to arguments passed to Docker after the image's name. The syntax is similar to [`Dockerfile`'s `CMD`][cmd] directive, where each shell token is a separate string in the array. |
| `alias`      | no       | 9.4 |Additional alias that can be used to access the service from the job's container. Read [Accessing the services](#accessing-the-services) for more information. |

### Starting multiple services from the same image

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended
configuration options](#extended-docker-configuration-options).

Before the new extended Docker configuration options, the following configuration
would not work properly:

```yaml
services:
- mysql:latest
- mysql:latest
```

The Runner would start two containers using the `mysql:latest` image, but both
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

The Runner will still start two containers using the `mysql:latest` image,
but now each of them will also be accessible with the alias configured
in `.gitlab-ci.yml` file.

### Setting a command for the service

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended
configuration options](#extended-docker-configuration-options).

Let's assume you have a `super/sql:latest` image with some SQL database
inside it and you would like to use it as a service for your job. Let's also
assume that this image doesn't start the database process while starting
the container and the user needs to manually use `/usr/bin/super-sql run` as
a command to start the database.

Before the new extended Docker configuration options, you would need to create
your own image based on the `super/sql:latest` image, add the default command,
and then use it in job's configuration, like:

```Dockerfile
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

As you can see, the syntax of `command` is similar to [Dockerfile's `CMD`][cmd].

### Overriding the entrypoint of an image

> Introduced in GitLab and GitLab Runner 9.4. Read more about the [extended
configuration options](#extended-docker-configuration-options).

Before showing the available entrypoint override methods, let's describe shortly
how the Runner starts and uses a Docker image for the containers used in the
CI jobs:

1. The Runner starts a Docker container using the defined entrypoint (default
   from `Dockerfile` that may be overridden in `.gitlab-ci.yml`)
1. The Runner attaches itself to a running container.
1. The Runner prepares a script (the combination of
   [`before_script`](../yaml/README.md#before_script),
   [`script`](../yaml/README.md#script),
   and [`after_script`](../yaml/README.md#after_script)).
1. The Runner sends the script to the container's shell STDIN and receives the
   output.

To override the entrypoint of a Docker image, the recommended solution is to
define an empty `entrypoint` in `.gitlab-ci.yml`, so the Runner doesn't start
a useless shell layer. However, that will not work for all Docker versions, and
you should check which one your Runner is using. Specifically:

- If Docker 17.06 or later is used, the `entrypoint` can be set to an empty value.
- If Docker 17.03 or previous versions are used, the `entrypoint` can be set to
  `/bin/sh -c`, `/bin/bash -c` or an equivalent shell available in the image.

The syntax of `image:entrypoint` is similar to [Dockerfile's `ENTRYPOINT`][entrypoint].

----

Let's assume you have a `super/sql:experimental` image with some SQL database
inside it and you would like to use it as a base image for your job because you
want to execute some tests with this database binary. Let's also assume that
this image is configured with `/usr/bin/super-sql run` as an entrypoint. That
means that when starting the container without additional options, it will run
the database's process, while Runner expects that the image will have no
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

```
[runners.docker]
  image = "ruby:2.1"
  services = ["mysql:latest", "postgres:latest"]
```

The image and services defined this way will be added to all job run by
that runner.

## Define an image from a private Container Registry

> **Notes:**
- This feature requires GitLab Runner **1.8** or higher
- For GitLab Runner versions **>= 0.6, <1.8** there was a partial
  support for using private registries, which required manual configuration
  of credentials on runner's host. We recommend to upgrade your Runner to
  at least version **1.8** if you want to use private registries.
- If the repository is private you need to authenticate your GitLab Runner in the
  registry. Learn more about how [GitLab Runner works in this case][runner-priv-reg].

As an example, let's assume that you want to use the `registry.example.com/private/image:latest`
image which is private and requires you to login into a private container registry.

Let's also assume that these are the login credentials:

| Key      | Value                |
|----------|----------------------|
| registry | registry.example.com |
| username | my_username          |
| password | my_password          |

To configure access for `registry.example.com`, follow these steps:

1. Find what the value of `DOCKER_AUTH_CONFIG` should be. There are two ways to
   accomplish this:
     - **First way -** Do a `docker login` on your local machine:

         ```bash
         docker login registry.example.com --username my_username --password my_password
         ```

          Then copy the content of `~/.docker/config.json`.
     - **Second way -** In some setups, it's possible that Docker client will use
       the available system keystore to store the result of `docker login`. In
       that case, it's impossible to read `~/.docker/config.json`, so you will
       need to prepare the required base64-encoded version of
       `${username}:${password}` manually. Open a terminal and execute the
       following command:

           ```bash
           echo -n "my_username:my_password" | base64

           # Example output to copy
           bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=
           ```

1. Create a [secret variable] `DOCKER_AUTH_CONFIG` with the content of the
   Docker configuration file as the value:

     ```json
     {
         "auths": {
             "registry.example.com": {
                 "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
             }
         }
     }
     ```

1. Optionally,if you followed the first way of finding the `DOCKER_AUTH_CONFIG`
   value, do a `docker logout` on your computer if you don't need access to the
   registry from it:

     ```bash
     docker logout registry.example.com
     ```

1. You can now use any private image from `registry.example.com` defined in
   `image` and/or `services` in your `.gitlab-ci.yml` file:

      ```yaml
      image: my.registry.tld:5000/namespace/image:tag
      ```

      In the example above, GitLab Runner will look at `my.registry.tld:5000` for the
      image `namespace/image:tag`.

You can add configuration for as many registries as you want, adding more
registries to the `"auths"` hash as described above.

## Configuring services

Many services accept environment variables which allow you to easily change
database names or set account names depending on the environment.

GitLab Runner 0.5.0 and up passes all YAML-defined variables to the created
service containers.

For all possible configuration variables check the documentation of each image
provided in their corresponding Docker hub page.

*Note: All variables will be passed to all services containers. It's not
designed to distinguish which variable should go where.*

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
   `Dockerfile` of build image (`ruby:2.1` as in above example).
1. Create build container and link any service container to build container.
1. Start build container and send job script to the container.
1. Run job script.
1. Checkout code in: `/builds/group-name/project-name/`.
1. Run any step defined in `.gitlab-ci.yml`.
1. Check exit status of build script.
1. Remove build container and all created service containers.

## How to debug a job locally

*Note: The following commands are run without root privileges. You should be
able to run Docker with your regular user account.*

First start with creating a file named `build_script`:

```bash
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make
EOF
```

Here we use as an example the GitLab Runner repository which contains a
Makefile, so running `make` will execute the commands defined in the Makefile.
Your mileage may vary, so instead of `make` you could run the command which
is specific to your project.

Then create some service containers:

```
docker run -d --name service-mysql mysql:latest
docker run -d --name service-postgres postgres:latest
```

This will create two service containers, named `service-mysql` and
`service-postgres` which use the latest MySQL and PostgreSQL images
respectively. They will both run in the background (`-d`).

Finally, create a build container by executing the `build_script` file we
created earlier:

```
docker run --name build -i --link=service-mysql:mysql --link=service-postgres:postgres ruby:2.1 /bin/bash < build_script
```

The above command will create a container named `build` that is spawned from
the `ruby:2.1` image and has two services linked to it. The `build_script` is
piped using STDIN to the bash interpreter which in turn executes the
`build_script` in the `build` container.

When you finish testing and no longer need the containers, you can remove them
with:

```
docker rm -f -v build service-mysql service-postgres
```

This will forcefully (`-f`) remove the `build` container, the two service
containers as well as all volumes (`-v`) that were created with the container
creation.

[Docker Fundamentals]: https://docs.docker.com/engine/understanding-docker/
[docker pull policy]: https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work
[hub]: https://hub.docker.com/
[linking-containers]: https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/
[tutum/wordpress]: https://hub.docker.com/r/tutum/wordpress/
[postgres-hub]: https://hub.docker.com/r/_/postgres/
[mysql-hub]: https://hub.docker.com/r/_/mysql/
[runner-priv-reg]: http://docs.gitlab.com/runner/configuration/advanced-configuration.html#using-a-private-container-registry
[secret variable]: ../variables/README.md#secret-variables
[entrypoint]: https://docs.docker.com/engine/reference/builder/#entrypoint
[cmd]: https://docs.docker.com/engine/reference/builder/#cmd
[register]: https://docs.gitlab.com/runner/register/
