---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Using PostgreSQL

As many applications depend on PostgreSQL as their database, you
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use PostgreSQL with the Docker executor

If you're using [GitLab Runner](../runners/index.md) with the Docker executor,
you basically have everything set up already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - postgres:12.2-alpine

variables:
  POSTGRES_DB: nice_marmot
  POSTGRES_USER: runner
  POSTGRES_PASSWORD: ""
  POSTGRES_HOST_AUTH_METHOD: trust
```

To set values for the `POSTGRES_DB`, `POSTGRES_USER`,
`POSTGRES_PASSWORD` and `POSTGRES_HOST_AUTH_METHOD`,
[assign them to a CI/CD variable in the user interface](../variables/index.md#custom-cicd-variables),
then assign that variable to the corresponding variable in your
`.gitlab-ci.yml` file.

And then configure your application to use the database, for example:

```yaml
Host: postgres
User: runner
Password: ''
Database: nice_marmot
```

If you're wondering why we used `postgres` for the `Host`, read more at
[How services are linked to the job](../services/index.md#how-services-are-linked-to-the-job).

You can also use any other Docker image available on [Docker Hub](https://hub.docker.com/_/postgres).
For example, to use PostgreSQL 9.3, the service becomes `postgres:9.3`.

The `postgres` image can accept some environment variables. For more details,
see the documentation on [Docker Hub](https://hub.docker.com/_/postgres).

## Use PostgreSQL with the Shell executor

You can also use PostgreSQL on manually configured servers that are using
GitLab Runner with the Shell executor.

First install the PostgreSQL server:

```shell
sudo apt-get install -y postgresql postgresql-client libpq-dev
```

The next step is to create a user, so sign in to PostgreSQL:

```shell
sudo -u postgres psql -d template1
```

Then create a user (in our case `runner`) which is used by your
application. Change `$password` in the command below to a real strong password.

NOTE:
Be sure to not enter `template1=#` in the following commands, as that's part of
the PostgreSQL prompt.

```shell
template1=# CREATE USER runner WITH PASSWORD '$password' CREATEDB;
```

The created user has the privilege to create databases (`CREATEDB`). The
following steps describe how to create a database explicitly for that user, but
having that privilege can be useful if in your testing framework you have tools
that drop and create databases.

Create the database and grant all privileges to it for the user `runner`:

```shell
template1=# CREATE DATABASE nice_marmot OWNER runner;
```

If all went well, you can now quit the database session:

```shell
template1=# \q
```

Now, try to connect to the newly created database with the user `runner` to
check that everything is in place.

```shell
psql -U runner -h localhost -d nice_marmot -W
```

This command explicitly directs `psql` to connect to localhost to use the md5
authentication. If you omit this step, you are denied access.

Finally, configure your application to use the database, for example:

```yaml
Host: localhost
User: runner
Password: $password
Database: nice_marmot
```

## Example project

We have set up an [Example PostgreSQL Project](https://gitlab.com/gitlab-examples/postgres) for your
convenience that runs on [GitLab.com](https://gitlab.com) using our publicly
available [shared runners](../runners/index.md).

Want to hack on it? Fork it, commit, and push your changes. Within a few
moments the changes are picked by a public runner and the job begins.
