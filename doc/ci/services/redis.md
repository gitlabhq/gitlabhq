# Using Redis

As many applications depend on Redis as their key-value store, you will
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use Redis with the Docker executor

If you are using [GitLab Runner](../runners/README.md) with the Docker executor
you basically have everything set up already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - redis:latest
```

Then you need to configure your application to use the Redis database, for
example:

```yaml
Host: redis
```

And that's it. Redis will now be available to be used within your testing
framework.

You can also use any other docker image available on [Docker Hub][hub-redis].
For example, to use Redis 2.8 the service becomes `redis:2.8`.

## Use Redis with the Shell executor

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

```yaml
Host: localhost
```

## Example project

We have set up an [Example Redis Project][redis-example-repo] for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push  your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[hub-redis]: https://hub.docker.com/r/_/redis/
[redis-example-repo]: https://gitlab.com/gitlab-examples/redis
