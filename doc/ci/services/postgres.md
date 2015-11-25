## Using PostgreSQL

It's possible to use PostgreSQL database test your apps during builds.

### Use PostgreSQL with Docker executor

If you are using our Docker integration you basically have everything already.

1. Add this to your `.gitlab-ci.yml`:

		services:
		- postgres

		variables:
		  # Configure postgres service (https://hub.docker.com/_/postgres/)
		  POSTGRES_DB: hello_world_test
		  POSTGRES_USER: postgres
		  POSTGRES_PASSWORD: ""

2. Configure your application to use the database:

		Host: postgres
		User: postgres
		Password: postgres
		Database: hello_world_test

3. You can also use any other available on [DockerHub](https://hub.docker.com/_/postgres/). For example: `postgres:9.3`.

Example: https://gitlab.com/gitlab-examples/postgres/blob/master/.gitlab-ci.yml

### Use PostgreSQL with Shell executor

It's possible to use PostgreSQL on manually configured servers that are using GitLab Runner with Shell executor.

1. First install the PostgreSQL server:

		sudo apt-get install -y postgresql postgresql-client libpq-dev

2. Create an user:

		# Install the database packages
		sudo apt-get install -y postgresql postgresql-client libpq-dev

		# Login to PostgreSQL
		sudo -u postgres psql -d template1

		# Create a user for runner
		# Do not type the 'template1=#', this is part of the prompt
		template1=# CREATE USER runner CREATEDB;

		# Create the database & grant all privileges on database
		template1=# CREATE DATABASE hello_world_test OWNER runner;

		# Quit the database session
		template1=# \q

3. Try to connect to database:

		# Try connecting to the new database with the new user
		sudo -u gitlab-runner -H psql -d hello_world_test

		# Quit the database session
		hello_world_test> \q

4. Configure your application to use the database:

		Host: localhost
		User: runner
		Password:
		Database: hello_world_test
