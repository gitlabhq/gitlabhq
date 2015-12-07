# Using Redis

As many applications depend on Redis as their key-value store, you will
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use Redis with Docker executor

If you are using our Docker integration you basically have everything set up
already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - redis:latest
```

Then you need to configure your application to use the Redis database, for
example:

```bash
Host: redis
```

And that's it. Redis will now be available to be used within your testing
framework.

If you want to use any other version of Redis, check the available versions
on [Docker Hub](https://hub.docker.com/_/redis/).

## Use Redis with Shell executor

Redis can also be used on manually configured servers that are using GitLab
Runner with the Shell executor.

In your build machine install the Redis server:

```bash
sudo apt-get install redis-server
```

Verify that you can connect to the server with the `gitlab-runner` user:

```bash
# Try connecting the the Redis server
sudo -u gitlab-runner -H redis-cli

# Quit the session
127.0.0.1:6379> quit
```

Finally, configure your application to use the database, for example:

```bash
Host: localhost
```

## Example project

We have set up an [Example Redis Project][redis-example-repo] for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push  your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[redis-example-repo]: https://gitlab.com/gitlab-examples/redis
