## Using Redis

It's possible to use Redis database test your apps during builds.

### Use Redis with Docker executor

If you are using our Docker integration you basically have everything already.

1. Add this to your `.gitlab-ci.yml`:

		services:
		- redis

2. Configure your application to use the database:

		Host: redis

3. You can also use any other available on [DockerHub](https://hub.docker.com/_/redis/). For example: `redis:2.6`.

Example: https://gitlab.com/gitlab-examples/redis/blob/master/.gitlab-ci.yml

### Use Redis with Shell executor

It's possible to use Redis on manually configured servers that are using GitLab Runner with Shell executor.

1. First install the Redis server:

		sudo apt-get install redis-server

2. Try to connect to the server:

		# Try connecting the the Redis server
		sudo -u gitlab-runner -H redis-cli

		# Quit the session
		127.0.0.1:6379> quit

4. Configure your application to use the database:

		Host: localhost
