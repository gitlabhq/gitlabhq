---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: tutorial
---

# Testing PHP projects **(FREE)**

This guide covers basic building instructions for PHP projects.

Two testing scenarios are covered: using the Docker executor and
using the Shell executor.

## Test PHP projects using the Docker executor

While it is possible to test PHP apps on any system, this would require manual
configuration from the developer. To overcome this we use the
official [PHP Docker image](https://hub.docker.com/_/php) that can be found in Docker Hub.

This allows us to test PHP projects against different versions of PHP.
However, not everything is plug 'n' play, you still need to configure some
things manually.

As with every job, you need to create a valid `.gitlab-ci.yml` describing the
build environment.

Let's first specify the PHP image that is used for the job process.
(You can read more about what an image means in the runner's lingo reading
about [Using Docker images](../docker/using_docker_images.md#what-is-an-image).)

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

```shell
#!/bin/bash

# We need to install dependencies only for Docker
[[ ! -e /.dockerenv ]] && exit 0

set -xe

# Install git (the php image doesn't have it) which is required by composer
apt-get update -yqq
apt-get install git -yqq

# Install phpunit, the tool that we will use for testing
curl --location --output /usr/local/bin/phpunit "https://phar.phpunit.de/phpunit.phar"
chmod +x /usr/local/bin/phpunit

# Install mysql driver
# Here you can install any other extension that you need
docker-php-ext-install pdo_mysql
```

You might wonder what `docker-php-ext-install` is. In short, it is a script
provided by the official PHP Docker image that you can use to easily install
extensions. For more information read [the documentation](https://hub.docker.com/_/php).

Now that we created the script that contains all prerequisites for our build
environment, let's add it in `.gitlab-ci.yml`:

```yaml
before_script:
  - bash ci/docker_install.sh > /dev/null
```

Last step, run the actual tests using `phpunit`:

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

Finally, commit your files and push them to GitLab to see your build succeeding
(or failing).

The final `.gitlab-ci.yml` should look similar to this:

```yaml
# Select image from https://hub.docker.com/_/php
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
with a different Docker image version and the runner does the rest:

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

There are times where you need to customise your PHP environment by
putting your `.ini` file into `/usr/local/etc/php/conf.d/`. For that purpose
add a `before_script` action:

```yaml
before_script:
  - cp my_php.ini /usr/local/etc/php/conf.d/test.ini
```

Of course, `my_php.ini` must be present in the root directory of your repository.

## Test PHP projects using the Shell executor

The shell executor runs your job in a terminal session on your server. To test
your projects, you must first ensure that all dependencies are installed.

For example, in a VM running Debian 8, first update the cache, and then install
`phpunit` and `php5-mysql`:

```shell
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

The [phpenv](https://github.com/phpenv/phpenv) project allows you to easily manage different versions of PHP
each with its own configuration. This is especially useful when testing PHP projects
with the Shell executor.

You have to install it on your build machine under the `gitlab-runner`
user following [the upstream installation guide](https://github.com/phpenv/phpenv#installation).

Using phpenv also allows to easily configure the PHP environment with:

```shell
phpenv config-add my_config.ini
```

*__Important note:__ It seems `phpenv/phpenv`
 [is abandoned](https://github.com/phpenv/phpenv/issues/57). There is a fork
 at [`madumlao/phpenv`](https://github.com/madumlao/phpenv) that tries to bring
 the project back to life. [`CHH/phpenv`](https://github.com/CHH/phpenv) also
 seems like a good alternative. Picking any of the mentioned tools works
 with the basic phpenv commands. Guiding you to choose the right phpenv is out
 of the scope of this tutorial.*

### Install custom extensions

Since this is a pretty bare installation of the PHP environment, you may need
some extensions that are not currently present on the build machine.

To install additional extensions simply execute:

```shell
pecl install <extension>
```

It's not advised to add this to `.gitlab-ci.yml`. You should execute this
command once, only to set up the build environment.

## Extend your tests

### Using `atoum`

Instead of PHPUnit, you can use any other tool to run unit tests. For example
you can use [`atoum`](https://github.com/atoum/atoum):

```yaml
before_script:
  - wget http://downloads.atoum.org/nightly/mageekguy.atoum.phar

test:atoum:
  script:
    - php mageekguy.atoum.phar
```

### Using Composer

The majority of the PHP projects use Composer for managing their PHP packages.
To execute Composer before running your tests, add the following to your
`.gitlab-ci.yml`:

```yaml
# Composer stores all downloaded packages in the vendor/ directory.
# Do not use the following if the vendor/ directory is committed to
# your git repository.
cache:
  paths:
    - vendor/

before_script:
  # Install composer dependencies
  - wget https://composer.github.io/installer.sig -O - -q | tr -d '\n' > installer.sig
  - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  - php -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  - php composer-setup.php
  - php -r "unlink('composer-setup.php'); unlink('installer.sig');"
  - php composer.phar install
```

## Access private packages or dependencies

If your test suite needs to access a private repository, you need to configure
the [SSH keys](../ssh_keys/index.md) to be able to clone it.

## Use databases or other services

Most of the time, you need a running database for your tests to be able to
run. If you're using the Docker executor, you can leverage Docker's ability to
link to other containers. With GitLab Runner, this can be achieved by defining
a `service`.

This functionality is covered in [the CI services](../services/index.md)
documentation.

## Testing things locally

With GitLab Runner 1.0 you can also test any changes locally. From your
terminal execute:

```shell
# Check using docker executor
gitlab-runner exec docker test:app

# Check using shell executor
gitlab-runner exec shell test:app
```

## Example project

We have set up an [Example PHP Project](https://gitlab.com/gitlab-examples/php) for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[shared runners](../runners/index.md).

Want to hack on it? Simply fork it, commit, and push your changes. Within a few
moments the changes are picked by a public runner and the job begins.
