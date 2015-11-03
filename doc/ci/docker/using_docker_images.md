# Using Docker Images
GitLab CI can use [Docker Engine](https://www.docker.com/) to build projects. 

Docker is an open-source project that allows to use predefined images to run applications 
in independent "containers" that are run within a single Linux instance. 
[Docker Hub](https://registry.hub.docker.com/) have rich database of  built images that can be used to build applications.

Docker when used with GitLab CI runs each build in separate and isolated container using predefined image and always from scratch.
It makes it easier to have simple and reproducible build environment that can also be run on your workstation.
This allows you to test all commands from your shell, rather than having to test them on a CI server.

### Register Docker runner
To use GitLab Runner with Docker you need to register new runner to use `docker` executor:

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

**The registered runner will use `ruby:2.1` image and will run two services (`postgres:latest` and `mysql:latest`) that will be accessible for time of the build.**

### What is image?
The image is the name of any repository that is present in local Docker Engine or any repository that can be found at [Docker Hub](https://registry.hub.docker.com/). 
For more information about the image and Docker Hub please read the [Docker Fundamentals](https://docs.docker.com/introduction/understanding-docker/).

### What is service?
Service is just another image that is run for time of your build and is linked to your build. This allows you to access the service image during build time. 
The service image can run any application, but most common use case is to run some database container, ie.: `mysql`. 
It's easier and faster to use existing image, run it as additional container than install `mysql` every time project is built.

#### How is service linked to the build?
There's good document that describes how Docker linking works: [Linking containers together](https://docs.docker.com/userguide/dockerlinks/). 
To summarize: if you add `mysql` as service to your application, the image will be used to create container that is linked to build container. 
The service container for MySQL will be accessible under hostname `mysql`.
So, **to access your database service you have to connect to host: `mysql` instead of socket or `localhost`**.

### How to use other images as services?
You are not limited to have only database services. 
You can hand modify `config.toml` to add any image as service found at [Docker Hub](https://registry.hub.docker.com/). 
Look for `[runners.docker]` section:
```
[runners.docker]
  image = "ruby:2.1"
  services = ["mysql:latest", "postgres:latest"]
```

For example you need `wordpress` instance to test some API integration with `Wordpress`. 
You can for example use this image: [tutum/wordpress](https://registry.hub.docker.com/u/tutum/wordpress/). 
This is image that have fully preconfigured `wordpress` and have `MySQL` server built-in:
```
[runners.docker]
  image = "ruby:2.1"
  services = ["mysql:latest", "postgres:latest", "tutum/wordpress:latest"]
```

Next time when you run your application the `tutum/wordpress` will be started 
and you will have access to it from your build container under hostname: `tutum_wordpress`.

Alias hostname for the service is made from the image name:
1. Everything after `:` is stripped,
2. '/' is replaced to `_`.

### Configuring services
Many services accept environment variables, which allow you to easily change database names or set account names depending on the environment.

GitLab Runner 0.5.0 and up passes all YAML-defined variables to created service containers.

1. To configure database name for [postgres](https://registry.hub.docker.com/u/library/postgres/) service,
you need to set POSTGRES_DB.

    ```yaml
    services:
    - postgres
    
    variables:
      POSTGRES_DB: gitlab
    ```

1. To use [mysql](https://registry.hub.docker.com/u/library/mysql/) service with empty password for time of build, 
you need to set MYSQL_ALLOW_EMPTY_PASSWORD.

    ```yaml
    services:
    - mysql
    
    variables:
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    ```

For other possible configuration variables check the 
https://registry.hub.docker.com/u/library/mysql/ or https://registry.hub.docker.com/u/library/postgres/
or README page for any other Docker image.

**Note: All variables will passed to all service containers. It's not designed to distinguish which variable should go where.**

### Overwrite image and services
It's possible to overwrite `docker-image` and specify services from `.gitlab-ci.yml`.
If you add to your YAML the `image` and the `services` these parameters
be used instead of the ones that were specified during runner's registration.
```
image: ruby:2.2
services:
  - postgres:9.3
before_install:
  - bundle install
  
test:
  script:
  - bundle exec rake spec
```

It's possible to define image and service per-job:
```
before_install:
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

#### How to enable overwriting?
To enable overwriting you have to **enable it first** (it's disabled by default for security reasons). 
You can do that by hand modifying runner configuration: `config.toml`. 
Please go to section where is `[runners.docker]` definition for your runner. 
Add `allowed_images` and `allowed_services` to specify what images are allowed to be picked from `.gitlab-ci.yml`:
```
[runners.docker]
  image = "ruby:2.1"
  allowed_images = ["ruby:*", "python:*"]
  allowed_services = ["mysql:*", "redis:*"]
```
This enables you to use in your `.gitlab-ci.yml` any image that matches above wildcards. 
You will be able to pick only `ruby` and `python` images. 
The same rule can be applied to limit services. 

If you are courageous enough, you can make it fully open and accept everything:
```
[runners.docker]
  image = "ruby:2.1"
  allowed_images = ["*", "*/*"]
  allowed_services = ["*", "*/*"]
```

**It the feature is not enabled, or image isn't allowed the error message will be put into the build log.**

### How Docker integration works
1. Create any service container: `mysql`, `postgresql`, `mongodb`, `redis`.
1. Create cache container to store all volumes as defined in `config.toml` and `Dockerfile` of build image (`ruby:2.1` as in above example).
1. Create build container and link any service container to build container.
1. Start build container and send build script to the container.
1. Run build script.
1. Checkout code in: `/builds/group-name/project-name/`.
1. Run any step defined in `.gitlab-ci.yml`.
1. Check exit status of build script.
1. Remove build container and all created service containers.

### How to debug a build locally
1. Create a file with build script:
```bash
$ cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-ci-multi-runner.git /builds/gitlab-org/gitlab-ci-multi-runner
cd /builds/gitlab-org/gitlab-ci-multi-runner
make <- or any other build step
EOF
```

1. Create service containers:
```
$ docker run -d -n service-mysql mysql:latest
$ docker run -d -n service-postgres postgres:latest
```
This will create two service containers (MySQL and PostgreSQL).

1. Create a build container and execute script in its context:
```
$ cat build_script | docker run -n build -i -l mysql:service-mysql -l postgres:service-postgres ruby:2.1 /bin/bash
```
This will create build container that has two service containers linked.
The build_script is piped using STDIN to bash interpreter which executes the build script in container. 

1. At the end remove all containers:
```
docker rm -f -v build service-mysql service-postgres
```
This will forcefully (the `-f` switch) remove build container and service containers 
and all volumes (the `-v` switch) that were created with the container creation.
