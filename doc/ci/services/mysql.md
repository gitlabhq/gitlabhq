# Using MySQL

As many applications depend on MySQL as their database, you will eventually
need it in order for your tests to run. Below you are guided how to do this
with the Docker and Shell executors of GitLab Runner.

## Use MySQL with the Docker executor

If you are using [GitLab Runner](../runners/README.md) with the Docker executor
you basically have everything set up already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - mysql:latest

variables:
  # Configure mysql environment variables (https://hub.docker.com/r/_/mysql/)
  MYSQL_DATABASE: el_duderino
  MYSQL_ROOT_PASSWORD: mysql_strong_password
```

And then configure your application to use the database, for example:

```yaml
Host: mysql
User: root
Password: mysql_strong_password
Database: el_duderino
```

If you are wondering why we used `mysql` for the `Host`, read more at
[How is service linked to the build](../docker/using_docker_images.md#how-is-service-linked-to-the-build).

You can also use any other docker image available on [Docker Hub][hub-mysql].
For example, to use MySQL 5.5 the service becomes `mysql:5.5`.

The `mysql` image can accept some environment variables. For more details
check the documentation on [Docker Hub][hub-mysql].

## Use MySQL with the Shell executor

You can also use MySQL on manually configured servers that are using
GitLab Runner with the Shell executor.

First install the MySQL server:

```bash
sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
```

Pick a MySQL root password (can be anything), and type it twice when asked.

*Note: As a security measure you can run `mysql_secure_installation` to
remove anonymous users, drop the test database and disable remote logins with
the root user.*

The next step is to create a user, so login to MySQL as root:

```bash
mysql -u root -p
```

Then create a user (in our case `runner`) which will be used by your
application. Change `$password` in the command below to a real strong password.

*Note: Do not type `mysql>`, this is part of the MySQL prompt.*

```bash
mysql> CREATE USER 'runner'@'localhost' IDENTIFIED BY '$password';
```

Create the database:

```bash
mysql> CREATE DATABASE IF NOT EXISTS `el_duderino` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
```

Grant the necessary permissions on the database:

```bash
mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `el_duderino`.* TO 'runner'@'localhost';
```

If all went well you can now quit the database session:

```bash
mysql> \q
```

Now, try to connect to the newly created database to check that everything is
in place:

```bash
mysql -u runner -p -D el_duderino
```

As a final step, configure your application to use the database, for example:

```bash
Host: localhost
User: runner
Password: $password
Database: el_duderino
```

## Example project

We have set up an [Example MySQL Project][mysql-example-repo] for your
convenience that runs on [GitLab.com](https://gitlab.com) using our publicly
available [shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push  your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[hub-mysql]: https://hub.docker.com/r/_/mysql/
[mysql-example-repo]: https://gitlab.com/gitlab-examples/mysql
