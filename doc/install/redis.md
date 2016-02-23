# Install Redis on old distributions

GitLab requires at least Redis 2.8. The following guide is for Debian 7 and
Ubuntu 12.04. If you are using Debian 8 or Ubuntu 14.04 and up, follow the
[installation guide](installation.md).

## Install Redis 2.8 in Debian 7

Redis 2.8 is included in the Debian Wheezy [backports] repository.

1. Edit `/etc/apt/sources.list` and add the following line:

    ```
    deb http://http.debian.net/debian wheezy-backports main
    ```

1. Update the repositories:

    ```
    sudo apt-get update
    ```

1. Install `redis-server`:

    ```
    sudo apt-get -t wheezy-backports install redis-server
    ```

1. Follow the rest of the [installation guide](installation.md).

## Install Redis 2.8 in Ubuntu 12.04

We will [use a PPA](https://launchpad.net/~chris-lea/+archive/ubuntu/redis-server)
to install a recent version of Redis.

1. Install the PPA repository:

    ```
    sudo add-apt-repository ppa:chris-lea/redis-server
    ```

    Your system will now fetch the PPA's key. This enables your Ubuntu system to
    verify that the packages in the PPA have not been interfered with since they
    were built.

1. Update the repositories:

    ```
    sudo apt-get update
    ```

1. Install `redis-server`:

    ```
    sudo apt-get install redis-server
    ```

1. Follow the rest of the [installation guide](installation.md).

[backports]: http://backports.debian.org/Instructions/ "Debian backports website"
