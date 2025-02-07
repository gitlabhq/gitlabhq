---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using PostgreSQL
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

As many applications depend on PostgreSQL as their database, you
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use PostgreSQL with the Docker executor

To pass variables set in the GitLab UI to service containers, you must [define the variables](../variables/_index.md#define-a-cicd-variable-in-the-ui).
You must define your variables as either Group or Project, then call the variables in your job as shown in the following workaround.

In Postgres 15.4 and later, Postgres does not substitute a schema or owner name into an extension script if the name contains a quote, backslash, or dollar sign.
If the CI variables are not configured, the value uses the environment variable name as a string instead. For example, `POSTGRES_USER: $USER` results in the
`POSTGRES_USER` variable being set to '$USER', which causes Postgres to show the following error:

```shell
Fatal: invalid character in extension
```

The workaround is to set your variables in [GitLab CI/CD variables](../variables/_index.md) or set variables in string form:

1. [Set Postgres variables in GitLab](../variables/_index.md#for-a-project). Variables set in the GitLab UI are not passed down to the service containers.

1. In the `.gitlab-ci.yml` file, specify a Postgres image:

   ```yaml
   default:
      services:
        - postgres
   ```

1. In the `.gitlab-ci.yml` file, add your defined variables:

   ```yaml
   variables:
     POSTGRES_DB: $POSTGRES_DB
     POSTGRES_USER: $POSTGRES_USER
     POSTGRES_PASSWORD: $POSTGRES_PASSWORD
     POSTGRES_HOST_AUTH_METHOD: trust
   ```

   For more information about using `postgres` for the `Host`, see [How services are linked to the job](../services/_index.md#how-services-are-linked-to-the-job).

1. Configure your application to use the database, for example:

   ```yaml
   Host: postgres
   User: $POSTGRES_USER
   Password: $POSTGRES_PASSWORD
   Database: $POSTGRES_DB
   ```

Alternatively, you can set variables as a string in the `.gitlab-ci.yml` file:

```yaml
variables:
  POSTGRES_DB: DB_name
  POSTGRES_USER: username
  POSTGRES_PASSWORD: password
  POSTGRES_HOST_AUTH_METHOD: trust
```

You can use any other Docker image available on [Docker Hub](https://hub.docker.com/_/postgres).
For example, to use PostgreSQL 14.3, the service becomes `postgres:14.3`.

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
available [instance runners](../runners/_index.md).

Want to hack on it? Fork it, commit, and push your changes. Within a few
moments the changes are picked by a public runner and the job begins.
