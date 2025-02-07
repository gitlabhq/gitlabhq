---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using Redis
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

As many applications depend on Redis as their key-value store, you
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use Redis with the Docker executor

If you are using [GitLab Runner](../runners/_index.md) with the Docker executor
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

And that's it. Redis is now available to be used within your testing
framework.

You can also use any other Docker image available on [Docker Hub](https://hub.docker.com/_/redis).
For example, to use Redis 6.0 the service becomes `redis:6.0`.

## Use Redis with the Shell executor

Redis can also be used on manually configured servers that are using GitLab
Runner with the Shell executor.

In your build machine install the Redis server:

```shell
sudo apt-get install redis-server
```

Verify that you can connect to the server with the `gitlab-runner` user:

```shell
# Try connecting the Redis server
sudo -u gitlab-runner -H redis-cli

# Quit the session
127.0.0.1:6379> quit
```

Finally, configure your application to use the database, for example:

```yaml
Host: localhost
```

## Example project

We have set up an [Example Redis Project](https://gitlab.com/gitlab-examples/redis) for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[instance runners](../runners/_index.md).

Want to hack on it? Fork it, commit and push your changes. Within a few
moments the changes are picked by a public runner and the job begins.
