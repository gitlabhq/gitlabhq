## Testing PHP projects

This guide covers basic of building PHP projects.

Is it possible to test PHP apps on any system.
However, it will require manual configuration.
The simplest is to use Docker executor as described below.

### PHP projects on Docker executor
It's possible to official [PHP](https://hub.docker.com/_/php/) repositories on Docker Hub.
They allow to test PHP projects against different versions of the runtime.
However, they require additional configuration.

To build PHP project you need to create valid `.gitlab-ci.yml` describing the build environment:
1. First you need to specify PHP image as described here: http://doc.gitlab.com/ce/ci/docker/using_docker_images.html#what-is-image. To your `.gitlab-ci.yml` add:

		image: php:5.6

2. The official images are great, but they are lacking a few useful tools for testing. We need to install them first in build environment. Create `ci/docker_install.sh` file with following content:

		#!/bin/bash

		# We need to install dependencies only for Docker
		[[ ! -e /.dockerinit ]] && exit 0

		set -xe

		# Install git (the php image doesn't have it) which is required by composer
		apt-get update -yqq
		apt-get install git -yqq

		# Install phpunit, the tool that we will use for testing
		curl -o /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar
		chmod +x /usr/local/bin/phpunit

		# Install mysql driver
		# Here you can install any other extension that you need
		docker-php-ext-install pdo_mysql

3. From your `.gitlab-ci.yml` run the created script:

		before_script:
		- bash ci/docker_install.sh > /dev/null

4. Now you can run your tests. Usually it will be `phpunit` with arguments:

		test:app:
		  script:
		  - phpunit --configuration phpunit_myapp.xml --coverage-text

5. Commit your files, and push them to GitLab to see if it works. With GitLab Runner 1.0 you can also test the changes locally. From your terminal execute:

		# Check using docker executor
		gitlab-runner exec docker test:app

		# Check using shell executor
		gitlab-runner exec shell test:app

The final `.gitlab-ci.yml` should look similar to this:

		# Select image from https://hub.docker.com/_/php/
		image: php:5.6

		before_script:
		# Install dependencies
		- ci/docker_install.sh > /dev/null

		test:app:
		  script:
		  - phpunit --configuration phpunit_myapp.xml --coverage-text

#### Test against different PHP versions in Docker builds

You can also test against multiple version of PHP runtime:

		before_script:
		# Install dependencies
		- ci/docker_install.sh > /dev/null

		# We test PHP5.6
		test:5.6:
		  image: php:5.6
		  script:
		  - phpunit --configuration phpunit_myapp.xml --coverage-text

		# We test PHP7.0
		test:7.0:
		  image: php:7.0
		  script:
		  - phpunit --configuration phpunit_myapp.xml --coverage-text

#### Custom PHP configuration in Docker builds

You can customise your PHP environment by putting your .ini file into `/usr/local/etc/php/conf.d/`:

		before_script:
		- cp my_php.ini /usr/local/etc/php/conf.d/test.ini

### Test PHP projects using Shell

Shell executor runs your builds in terminal session of your server. Thus in order to test your projects you need to have all dependencies installed as root.

1. Install PHP dependencies:

		sudo apt-get update -qy
		sudo apt-get install phpunit php5-mysql -y

	This will install the PHP version available for your distribution.

2. Now you can run your tests. Usually it will be `phpunit` with arguments:

		test:app:
		  script:
		  - phpunit --configuration phpunit_myapp.xml --coverage-text

#### Test against different PHP versions in Shell builds

The [phpenv](https://github.com/phpenv/phpenv) allows you to easily manage different PHP with they own configs.
This is specially usefull when testing PHP project with Shell executor.

Login as `gitlab-runner` user and follow [the installation guide](https://github.com/phpenv/phpenv#installation).

Using phpenv also allows to easily configure PHP environment with: `phpenv config-add my_config.ini`.

#### Install custom extensions

Since we have pretty bare installation of our PHP environment you may need some extensions that are not present on your installation.

To install additional extensions simply execute.:

		pecl install <extension>

	It's not advised to add this to the `.gitlab-ci.yml`.
	You should execute this command once, only to setup the build environment.

### Extend your tests

#### Using atoum

Instead of PHPUnit, you can use any other tool to run unit tests. For example [atoum](https://github.com/atoum/atoum):

		before_script:
		- wget http://downloads.atoum.org/nightly/mageekguy.atoum.phar

		test:atoum:
		  script:
		  - php mageekguy.atoum.phar

#### Using Composer

Majority of the PHP projects use Composer for managing the packages.
It's very simple to execute the Composer before running your tests.
To your `.gitlab-ci.yml` add:

		# The composer stores all downloaded packages in vendor/
		# Remove it if you committed the vendor/ directory
		cache:
		  paths:
		  - vendor/

		before_script:
		# Install composer dependencies
		- curl -sS https://getcomposer.org/installer | php
		- php composer.phar install

### Access private packages / dependencies

You need to configure [the SSH keys](../ssh_keys/README.md) in order to checkout the repositories.

### Use databases or other services

Please checkout the docs about configuring [the CI services](../services/README.md).

### Example project

You maybe interested in our [Example Project](https://gitlab.com/gitlab-examples/php) that runs on [GitLab.com](https://gitlab.com) using our publically available shared runners.

Want to hack it? Simply fork it, commit and push changes. Within a few moments the changes will be picked and rebuilt by public runners.
