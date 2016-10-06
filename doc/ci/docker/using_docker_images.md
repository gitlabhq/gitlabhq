# Using Docker Images

GitLab CI in conjunction with [GitLab Runner](../runners/README.md) can use
[Docker Engine](https://www.docker.com/) to test and build any application.

Docker is an open-source project that allows you to use predefined images to
run applications in independent "containers" that are run within a single Linux
instance. [Docker Hub][hub] has a rich database of pre-built images that can be
used to test and build your applications.

Docker, when used with GitLab CI, runs each build in a separate and isolated
container using the predefined image that is set up in
[`.gitlab-ci.yml`](../yaml/README.md).

This makes it easier to have a simple and reproducible build environment that
can also run on your workstation. The added benefit is that you can test all
the commands that we will explore later from your shell, rather than having to
test them on a dedicated CI server.

## Register docker runner

To use GitLab Runner with docker you need to register a new runner to use the
`docker` executor:

```bash
gitlab-ci-multi-runner register \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "docker-ruby-2.1" \
  --executor "docker" \
  --docker-image ruby:2.1 \
  --docker-postgres latest \
  --docker-mysql latest
```

The registered runner will use the `ruby:2.1` docker image and will run two
services, `postgres:latest` and `mysql:latest`, both of which will be
accessible during the build process.

## What is image

The `image` keyword is the name of the docker image that is present in the
local Docker Engine (list all images with `docker images`) or any image that
can be found at [Docker Hub][hub]. For more information about images and Docker
Hub please read the [Docker Fundamentals][] documentation.

In short, with `image` we refer to the docker image, which will be used to
create a container on which your build will run.

## What is service

The `services` keyword defines just another docker image that is run during
your build and is linked to the docker image that the `image` keyword defines.
This allows you to access the service image during build time.

The service image can run any application, but the most common use case is to
run a database container, eg. `mysql`. It's easier and faster to use an
existing image and run it as an additional container than install `mysql` every
time the project is built.

You can see some widely used services examples in the relevant documentation of
[CI services examples](../services/README.md).

### How is service linked to the build

To better understand how the container linking works, read
[Linking containers together][linking-containers].

To summarize, if you add `mysql` as service to your application, the image will
then be used to create a container that is linked to the build container.

The service container for MySQL will be accessible under the hostname `mysql`.
So, in order to access your database service you have to connect to the host
named `mysql` instead of a socket or `localhost`.

## Overwrite image and services

See [How to use other images as services](#how-to-use-other-images-as-services).

## How to use other images as services

You are not limited to have only database services. You can add as many
services you need to `.gitlab-ci.yml` or manually modify `config.toml`.
Any image found at [Docker Hub][hub] can be used as a service.

## Define image and services from `.gitlab-ci.yml`

You can simply define an image that will be used for all jobs and a list of
services that you want to use during build time.

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

## Define image and services in `config.toml`

Look for the `[runners.docker]` section:

```
[runners.docker]
  image = "ruby:2.1"
  services = ["mysql:latest", "postgres:latest"]
```

The image and services defined this way will be added to all builds run by
that runner.

## Define an image from a private Docker registry

Starting with GitLab Runner 0.6.0, you are able to define images located to
private registries that could also require authentication.

All you have to do is be explicit on the image definition in `.gitlab-ci.yml`.

```yaml
image: my.registry.tld:5000/namepace/image:tag
```

In the example above, GitLab Runner will look at `my.registry.tld:5000` for the
image `namespace/image:tag`.

If the repository is private you need to authenticate your GitLab Runner in the
registry. Learn how to do that on
[GitLab Runner's documentation][runner-priv-reg].

## Accessing the services

Let's say that you need a Wordpress instance to test some API integration with
your application.

You can then use for example the [tutum/wordpress][] image in your
`.gitlab-ci.yml`:

```yaml
services:
- tutum/wordpress:latest
```

When the build is run, `tutum/wordpress` will be started and you will have
access to it from your build container under the hostname `tutum__wordpress`.

The alias hostname for the service is made from the image name following these
rules:

1. Everything after `:` is stripped
2. Slash (`/`) is replaced with double underscores (`__`)

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

Below is a high level overview of the steps performed by docker during build
time.

1. Create any service container: `mysql`, `postgresql`, `mongodb`, `redis`.
1. Create cache container to store all volumes as defined in `config.toml` and
   `Dockerfile` of build image (`ruby:2.1` as in above example).
1. Create build container and link any service container to build container.
1. Start build container and send build script to the container.
1. Run build script.
1. Checkout code in: `/builds/group-name/project-name/`.
1. Run any step defined in `.gitlab-ci.yml`.
1. Check exit status of build script.
1. Remove build container and all created service containers.

## How to debug a build locally

*Note: The following commands are run without root privileges. You should be
able to run docker with your regular user account.*

First start with creating a file named `build_script`:

```bash
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-ci-multi-runner.git /builds/gitlab-org/gitlab-ci-multi-runner
cd /builds/gitlab-org/gitlab-ci-multi-runner
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
[hub]: https://hub.docker.com/
[linking-containers]: https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/
[tutum/wordpress]: https://hub.docker.com/r/tutum/wordpress/
[postgres-hub]: https://hub.docker.com/r/_/postgres/
[mysql-hub]: https://hub.docker.com/r/_/mysql/
[runner-priv-reg]: https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/docs/configuration/advanced-configuration.md#using-a-private-docker-registry
