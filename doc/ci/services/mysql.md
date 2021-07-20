---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Using MySQL

Many applications depend on MySQL as their database, and you may
need it for your tests to run.

## Use MySQL with the Docker executor

If you want to use a MySQL container, you can use [GitLab Runner](../runners/index.md) with the Docker executor.

This example shows you how to set a username and password that GitLab uses to access the MySQL container. If you do not set a username and password, you must use `root`.

1. [Create CI/CD variables](../variables/index.md#custom-cicd-variables) for your
   MySQL database and password by going to **Settings > CI/CD**, expanding **Variables**,
   and clicking **Add Variable**.

   This example uses `$MYSQL_DB` and `$MYSQL_PASS` as the keys.

1. To specify a MySQL image, add the following to your `.gitlab-ci.yml` file:

   ```yaml
   services:
     - mysql:latest
   ```

   - You can use any Docker image available on [Docker Hub](https://hub.docker.com/_/mysql/).
     For example, to use MySQL 5.5, use `mysql:5.5`.
   - The `mysql` image can accept environment variables. For more information, view
     the [Docker Hub documentation](https://hub.docker.com/_/mysql/).

1. To include the database name and password, add the following to your `.gitlab-ci.yml` file:

   ```yaml
   variables:
     # Configure mysql environment variables (https://hub.docker.com/_/mysql/)
     MYSQL_DATABASE: $MYSQL_DB
     MYSQL_ROOT_PASSWORD: $MYSQL_PASS
   ```

   The MySQL container uses `MYSQL_DATABASE` and `MYSQL_ROOT_PASSWORD` to connect to the database.
   Pass these values by using variables (`$MYSQL_DB` and `$MYSQL_PASS`),
   [rather than calling them directly](https://gitlab.com/gitlab-org/gitlab/-/issues/30178).

1. Configure your application to use the database, for example:

   ```yaml
   Host: mysql
   User: runner
   Password: <your_mysql_password>
   Database: <your_mysql_database>
   ```

   In this example, the user is `runner`. You should use a user that has permission to
   access your database.

## Use MySQL with the Shell executor

You can also use MySQL on manually-configured servers that use
GitLab Runner with the Shell executor.

1. Install the MySQL server:

   ```shell
   sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
   ```

1. Choose a MySQL root password and type it twice when asked.

   NOTE:
   As a security measure, you can run `mysql_secure_installation` to
   remove anonymous users, drop the test database, and disable remote logins by
   the root user.

1. Create a user by logging in to MySQL as root:

   ```shell
   mysql -u root -p
   ```

1. Create a user (in this case, `runner`) that is used by your
   application. Change `$password` in the command to a strong password.

   At the `mysql>` prompt, type:

   ```sql
   CREATE USER 'runner'@'localhost' IDENTIFIED BY '$password';
   ```

1. Create the database:

   ```sql
   CREATE DATABASE IF NOT EXISTS `<your_mysql_database>` DEFAULT CHARACTER SET `utf8` \
   COLLATE `utf8_unicode_ci`;
   ```

1. Grant the necessary permissions on the database:

   ```sql
   GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `<your_mysql_database>`.* TO 'runner'@'localhost';
   ```

1. If all went well, you can quit the database session:

   ```shell
   \q
   ```

1. Connect to the newly-created database to check that everything is
   in place:

   ```shell
   mysql -u runner -p -D <your_mysql_database>
   ```

1. Configure your application to use the database, for example:

   ```shell
   Host: localhost
   User: runner
   Password: $password
   Database: <your_mysql_database>
   ```

## Example project

To view a MySQL example, create a fork of this [sample project](https://gitlab.com/gitlab-examples/mysql).
This project uses publicly-available [shared runners](../runners/index.md) on [GitLab.com](https://gitlab.com).
Update the README.md file, commit your changes, and view the CI/CD pipeline to see it in action.
