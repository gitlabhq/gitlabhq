# Database MySQL

## Note

We do not recommend using MySQL due to various issues. For example, case [(in)sensitivity](https://dev.mysql.com/doc/refman/5.0/en/case-sensitivity.html) and [problems](https://bugs.mysql.com/bug.php?id=65830) that [suggested](https://bugs.mysql.com/bug.php?id=50909) [fixes](https://bugs.mysql.com/bug.php?id=65830) [have](https://bugs.mysql.com/bug.php?id=63164).

## MySQL

    # Install the database packages
    sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

    # Ensure you have MySQL version 5.5.14 or later
    mysql --version

    # Pick a MySQL root password (can be anything), type it and press enter
    # Retype the MySQL root password and press enter

    # Secure your installation
    sudo mysql_secure_installation

    # Login to MySQL
    mysql -u root -p

    # Type the MySQL root password

    # Create a user for GitLab
    # do not type the 'mysql>', this is part of the prompt
    # change $password in the command below to a real password you pick
    mysql> CREATE USER 'git'@'localhost' IDENTIFIED BY '$password';

    # Ensure you can use the InnoDB engine which is necessary to support long indexes
    # If this fails, check your MySQL config files (e.g. `/etc/mysql/*.cnf`, `/etc/mysql/conf.d/*`) for the setting "innodb = off"
    mysql> SET storage_engine=INNODB;

    # Create the GitLab production database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

    # Grant the GitLab user necessary permissions on the database
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES, REFERENCES ON `gitlabhq_production`.* TO 'git'@'localhost';

    # Quit the database session
    mysql> \q

    # Try connecting to the new database with the new user
    sudo -u git -H mysql -u git -p -D gitlabhq_production

    # Type the password you replaced $password with earlier

    # You should now see a 'mysql>' prompt

    # Quit the database session
    mysql> \q

    # You are done installing the database and can go back to the rest of the installation.

## MySQL strings limits

After installation or upgrade, remember to run the `add_limits_mysql` Rake task:

```
bundle exec rake add_limits_mysql
```

The `text` type in MySQL has a different size limit than the `text` type in
PostgreSQL. In MySQL `text` columns are limited to ~65kB, whereas in PostgreSQL
`text` columns are limited up to ~1GB!

The `add_limits_mysql` Rake task converts some important `text` columns in the
GitLab database to `longtext` columns, which can persist values of up to 4GB
(sometimes less if the value contains multibyte characters).

Details can be found in the [PostgreSQL][postgres-text-type] and
[MySQL][mysql-text-types] manuals.

[postgres-text-type]: http://www.postgresql.org/docs/9.1/static/datatype-character.html
[mysql-text-types]: http://dev.mysql.com/doc/refman/5.7/en/string-type-overview.html
