# Testing PHP projects

This guide covers basic building instructions for PHP projects.

There are covered two cases: testing using the Docker executor and testing
using the Shell executor.

## Test PHP projects using the Docker executor

While it is possible to test PHP apps on any system, this would require manual
configuration from the developer. To overcome this we will be using the
official [PHP docker image][php-hub] that can be found in Docker Hub.

This will allow us to test PHP projects against different versions of PHP.
However, not everything is plug 'n' play, you still need to configure some
things manually.

As with every build, you need to create a valid `.gitlab-ci.yml` describing the
build environment.

Let's first specify the PHP image that will be used for the build process
(you can read more about what an image means in the Runner's lingo reading
about [Using Docker images](../docker/using_docker_images.md#what-is-image)).

Start by adding the image to your `.gitlab-ci.yml`:

```yaml
image: php:5.6
```

The official images are great, but they lack a few useful tools for testing.
We need to first prepare the build environment. A way to overcome this is to
create a script which installs all prerequisites prior the actual testing is
done.

Let's create a `ci/docker_install.sh` file in the root directory of our
repository with the following content:

```bash
#!/bin/bash

# We need to install dependencies only for Docker
[[ ! -e /.dockerenv ]] && [[ ! -e /.dockerinit ]] && exit 0

set -xe

# Install git (the php image doesn't have it) which is required by composer
apt-get update -yqq
apt-get install git -yqq

# Install phpunit, the tool that we will use for testing
curl --location --output /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar
chmod +x /usr/local/bin/phpunit

# Install mysql driver
# Here you can install any other extension that you need
docker-php-ext-install pdo_mysql
```

You might wonder what `docker-php-ext-install` is. In short, it is a script
provided by the official php docker image that you can use to easilly install
extensions. For more information read the the documentation at
<https://hub.docker.com/r/_/php/>.

Now that we created the script that contains all prerequisites for our build
environment, let's add it in `.gitlab-ci.yml`:

```yaml
...

before_script:
- bash ci/docker_install.sh > /dev/null

...
```

Last step, run the actual tests using `phpunit`:

```yaml
...

test:app:
  script:
  - phpunit --configuration phpunit_myapp.xml

...
```

Finally, commit your files and push them to GitLab to see your build succeeding
(or failing).

The final `.gitlab-ci.yml` should look similar to this:

```yaml
# Select image from https://hub.docker.com/r/_/php/
image: php:5.6

before_script:
# Install dependencies
- bash ci/docker_install.sh > /dev/null

test:app:
  script:
  - phpunit --configuration phpunit_myapp.xml
```

### Test against different PHP versions in Docker builds

Testing against multiple versions of PHP is super easy. Just add another job
with a different docker image version and the runner will do the rest:

```yaml
before_script:
# Install dependencies
- bash ci/docker_install.sh > /dev/null

# We test PHP5.6
test:5.6:
  image: php:5.6
  script:
  - phpunit --configuration phpunit_myapp.xml

# We test PHP7.0 (good luck with that)
test:7.0:
  image: php:7.0
  script:
  - phpunit --configuration phpunit_myapp.xml
```

### Custom PHP configuration in Docker builds

There are times where you will need to customise your PHP environment by
putting your `.ini` file into `/usr/local/etc/php/conf.d/`. For that purpose
add a `before_script` action:

```yaml
before_script:
- cp my_php.ini /usr/local/etc/php/conf.d/test.ini
```

Of course, `my_php.ini` must be present in the root directory of your repository.

## Test PHP projects using the Shell executor

The shell executor runs your builds in a terminal session on your server.
Thus, in order to test your projects you first need to make sure that all
dependencies are installed.

For example, in a VM running Debian 8 we first update the cache, then we
install `phpunit` and `php5-mysql`:

```bash
sudo apt-get update -y
sudo apt-get install -y phpunit php5-mysql
```

Next, add the following snippet to your `.gitlab-ci.yml`:

```yaml
test:app:
  script:
  - phpunit --configuration phpunit_myapp.xml
```

Finally, push to GitLab and let the tests begin!

### Test against different PHP versions in Shell builds

The [phpenv][] project allows you to easily manage different versions of PHP
each with its own config. This is specially usefull when testing PHP projects
with the Shell executor.

You will have to install it on your build machine under the `gitlab-runner`
user following [the upstream installation guide][phpenv-installation].

Using phpenv also allows to easily configure the PHP environment with:

```
phpenv config-add my_config.ini
```

*__Important note:__ It seems `phpenv/phpenv`
 [is abandoned](https://github.com/phpenv/phpenv/issues/57). There is a fork
 at [madumlao/phpenv](https://github.com/madumlao/phpenv) that tries to bring
 the project back to life. [CHH/phpenv](https://github.com/CHH/phpenv) also
 seems like a good alternative. Picking any of the mentioned tools will work
 with the basic phpenv commands. Guiding you to choose the right phpenv is out
 of the scope of this tutorial.*

### Install custom extensions

Since this is a pretty bare installation of the PHP environment, you may need
some extensions that are not currently present on the build machine.

To install additional extensions simply execute:

```bash
pecl install <extension>
```

It's not advised to add this to `.gitlab-ci.yml`. You should execute this
command once, only to setup the build environment.

## Extend your tests

### Using atoum

Instead of PHPUnit, you can use any other tool to run unit tests. For example
you can use [atoum](https://github.com/atoum/atoum):

```yaml
before_script:
- wget http://downloads.atoum.org/nightly/mageekguy.atoum.phar

test:atoum:
  script:
  - php mageekguy.atoum.phar
```

### Using Composer

The majority of the PHP projects use Composer for managing their PHP packages.
In order to execute Composer before running your tests, simply add the
following in your `.gitlab-ci.yml`:

```yaml
...

# Composer stores all downloaded packages in the vendor/ directory.
# Do not use the following if the vendor/ directory is commited to
# your git repository.
cache:
  paths:
  - vendor/

before_script:
# Install composer dependencies
- curl --silent --show-error https://getcomposer.org/installer | php
- php composer.phar install

...
```

## Access private packages / dependencies

If your test suite needs to access a private repository, you need to configure
[the SSH keys](../ssh_keys/README.md) in order to be able to clone it.

## Use databases or other services

Most of the time you will need a running database in order for your tests to
run. If you are using the Docker executor you can leverage Docker's ability to
link to other containers. In GitLab Runner lingo, this can be achieved by
defining a `service`.

This functionality is covered in [the CI services](../services/README.md)
documentation.

## Testing things locally

With GitLab Runner 1.0 you can also test any changes locally. From your
terminal execute:

```bash
# Check using docker executor
gitlab-ci-multi-runner exec docker test:app

# Check using shell executor
gitlab-ci-multi-runner exec shell test:app
```

## Example project

We have set up an [Example PHP Project][php-example-repo] for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push  your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[php-hub]: https://hub.docker.com/r/_/php/
[phpenv]: https://github.com/phpenv/phpenv
[phpenv-installation]: https://github.com/phpenv/phpenv#installation
[php-example-repo]: https://gitlab.com/gitlab-examples/php
