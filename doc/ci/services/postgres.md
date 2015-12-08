# Using PostgreSQL

As many applications depend on PostgreSQL as their database, you will
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use PostgreSQL with the Docker executor

If you are using GitLab's Runner with the Docker executor you basically have
everything set up already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - postgres

variables:
  POSTGRES_DB: nice_marmot
  POSTGRES_USER: gitlab_runner
  POSTGRES_PASSWORD: ""
```

And then configure your application to use PostgreSQL, for example:

```yaml
Host: localhost
User: gitlab_runner
Password:
Database: nice_marmot
```

You can also use any other docker image available on [Docker Hub][hub-pg].
For example, to use PostgreSQL 9.3 the service becomes `postgres:9.3`.

The `postgres` image can accept some environment variables. For more details
check the documentation on [Docker Hub][hub-pg].

## Use PostgreSQL with the Shell executor

You can also use PostgreSQL on manually configured servers that are using
GitLab Runner with the Shell executor.

First install the PostgreSQL server:

```bash
sudo apt-get install -y postgresql postgresql-client libpq-dev
```

Then create a user:

```bash
# Login to PostgreSQL
sudo -u postgres psql -d template1

# Create a user for GitLab Runner that can create databases
# Do not type the 'template1=#', this is part of the prompt
template1=# CREATE USER gitlab_runner CREATEDB;

# Create the database & grant all privileges on database
template1=# CREATE DATABASE nice_marmot OWNER gitlab_runner;

# Quit the database session
template1=# \q
```

Try to connect to database:

```bash
# Try connecting to the new database with the new user
sudo -u gitlab_runner -H psql -d nice_marmot

# Quit the database session
nice_marmot> \q
```

Finally, configure your application to use the database:

```bash
Host: localhost
User: gitlab_runner
Password:
Database: nice_marmot
```

## Example project

We have set up an [Example PostgreSQL Project][postgres-example-repo] for your
convenience that runs on [GitLab.com](https://gitlab.com) using our publicly
available [shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push  your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[hub-pg]: https://hub.docker.com/_/postgres/
[postgres-example-repo]: https://gitlab.com/gitlab-examples/postgres
