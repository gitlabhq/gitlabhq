# Using PostgreSQL

As many applications depend on PostgreSQL as their database, you will
eventually need it in order for your tests to run. Below you are guided how to
do this with the Docker and Shell executors of GitLab Runner.

## Use PostgreSQL with the Docker executor

If you are using [GitLab Runner](../runners/README.md) with the Docker executor
you basically have everything set up already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - postgres:latest

variables:
  POSTGRES_DB: nice_marmot
  POSTGRES_USER: runner
  POSTGRES_PASSWORD: ""
```

And then configure your application to use the database, for example:

```yaml
Host: postgres
User: runner
Password:
Database: nice_marmot
```

If you are wondering why we used `postgres` for the `Host`, read more at
[How is service linked to the build](../docker/using_docker_images.md#how-is-service-linked-to-the-build).

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

The next step is to create a user, so login to PostgreSQL:

```bash
sudo -u postgres psql -d template1
```

Then create a user (in our case `runner`) which will be used by your
application. Change `$password` in the command below to a real strong password.

*__Note:__ Do not type `template1=#`, this is part of the PostgreSQL prompt.*

```bash
template1=# CREATE USER runner WITH PASSWORD '$password' CREATEDB;
```

*__Note:__ Notice that we created the user with the privilege to be able to
create databases (`CREATEDB`). In the following steps we will create a database 
explicitly for that user but having that privilege can be useful if in your
testing framework you have tools that drop and create databases.*

Create the database and grant all privileges on it for the user `runner`:

```bash
template1=# CREATE DATABASE nice_marmot OWNER runner;
```

If all went well you can now quit the database session:

```bash
template1=# \q
```

Now, try to connect to the newly created database with the user `runner` to
check that everything is in place.

```bash
psql -U runner -h localhost -d nice_marmot -W
```

*__Note:__ We are explicitly telling `psql` to connect to localhost in order
to use the md5 authentication. If you omit this step you will be denied access.*

Finally, configure your application to use the database, for example:

```yaml
Host: localhost
User: runner
Password: $password
Database: nice_marmot
```

## Example project

We have set up an [Example PostgreSQL Project][postgres-example-repo] for your
convenience that runs on [GitLab.com](https://gitlab.com) using our publicly
available [shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push  your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[hub-pg]: https://hub.docker.com/r/_/postgres/
[postgres-example-repo]: https://gitlab.com/gitlab-examples/postgres
