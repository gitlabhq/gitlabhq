# Database MySQL

>**Note:**
- We do not recommend using MySQL due to various issues. For example, case
[(in)sensitivity](https://dev.mysql.com/doc/refman/5.0/en/case-sensitivity.html)
and [problems](https://bugs.mysql.com/bug.php?id=65830) that
[suggested](https://bugs.mysql.com/bug.php?id=50909)
[fixes](https://bugs.mysql.com/bug.php?id=65830) [have](https://bugs.mysql.com/bug.php?id=63164).

## Initial database setup

```
# Install the database packages
sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

# Ensure you have MySQL version 5.6 or later
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

# If you have MySQL < 5.7.7 and want to enable utf8mb4 character set support with your GitLab install, you must set the following NOW:
mysql> SET GLOBAL innodb_file_per_table=1, innodb_file_format=Barracuda, innodb_large_prefix=1;

# If you use MySQL with replication, or just have MySQL configured with binary logging, you need to run the following to allow the use of `TRIGGER`:
mysql> SET GLOBAL log_bin_trust_function_creators = 1;

# Create the GitLab production database
mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_general_ci`;

# Grant the GitLab user necessary permissions on the database
mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES, REFERENCES, TRIGGER ON `gitlabhq_production`.* TO 'git'@'localhost';

# Quit the database session
mysql> \q

# Try connecting to the new database with the new user
sudo -u git -H mysql -u git -p -D gitlabhq_production

# Type the password you replaced $password with earlier

# You should now see a 'mysql>' prompt

# Quit the database session
mysql> \q
```

You are done installing the database for now and can go back to the rest of the installation.
Please proceed to the rest of the installation **before** running through the steps below.

### `log_bin_trust_function_creators`

If you use MySQL with replication, or just have MySQL configured with binary logging, all of your MySQL servers will need to have `log_bin_trust_function_creators` enabled to allow the use of `TRIGGER` in migrations. You have already set this global variable in the steps above, but to make it persistent, add the following to your `my.cnf` file:

```
log_bin_trust_function_creators=1
```

### MySQL utf8mb4 support

After installation or upgrade, remember to [convert any new tables](#tables-and-data-conversion-to-utf8mb4) to `utf8mb4`/`utf8mb4_general_ci`.

---

GitLab 8.14 has introduced [a feature](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7420) requiring `utf8mb4` encoding to be supported in your GitLab MySQL Database, which is not the case if you have setup your database before GitLab 8.16.

Follow the below instructions to ensure you use the most up to date requirements for your GitLab MySQL Database.

**We are about to do the following:**
- Ensure you can enable `utf8mb4` encoding and `utf8mb4_general_ci` collation for your GitLab DB, tables and data.
- Convert your GitLab tables and data from `utf8`/`utf8_general_ci` to `utf8mb4`/`utf8mb4_general_ci`

### Check for utf8mb4 support

#### Check for InnoDB File-Per-Table Tablespaces

We need to check, enable and maybe convert your existing GitLab DB tables to the [InnoDB File-Per-Table Tablespaces](http://dev.mysql.com/doc/refman/5.7/en/innodb-multiple-tablespaces.html) as a prerequise for supporting **utfb8mb4 with long indexes** required by recent GitLab databases.

    # Login to MySQL
    mysql -u root -p

    # Type the MySQL root password
    mysql > use gitlabhq_production;

    # Check your MySQL version is >= 5.5.3 (GitLab requires 5.5.14+)
    mysql > SHOW VARIABLES LIKE 'version';
    +---------------+-----------------+
    | Variable_name | Value           |
    +---------------+-----------------+
    | version       | 5.5.53-0+deb8u1 |
    +---------------+-----------------+

    # Note where is your MySQL data dir for later:
    mysql > select @@datadir;
    +----------------+
    | @@datadir      |
    +----------------+
    | /var/lib/mysql |
    +----------------+

    # Note whether your MySQL server runs with innodb_file_per_table ON or OFF:
    mysql> SELECT @@innodb_file_per_table;
    +-------------------------+
    | @@innodb_file_per_table |
    +-------------------------+
    |                       1 |
    +-------------------------+

    # You can now quit the database session
    mysql> \q

> You need **MySQL 5.5.3 or later** to perform this update.

Whatever the results of your checks above, we now need to check if your GitLab database has been created using [InnoDB File-Per-Table Tablespaces](http://dev.mysql.com/doc/refman/5.7/en/innodb-multiple-tablespaces.html) (i.e. `innodb_file_per_table` was set to **1** at initial setup time).

> Note: This setting is [enabled by default](http://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_file_per_table) since MySQL 5.6.6.

    # Run this command with root privileges, replace the data dir if different:
    sudo ls -lh /var/lib/mysql/gitlabhq_production/*.ibd | wc -l

    # Run this command with root privileges, replace the data dir if different:
    sudo ls -lh /var/lib/mysql/gitlabhq_production/*.frm | wc -l


- **Case 1: a result > 0 for both commands**

Congrats, your GitLab database uses the right InnoDB tablespace format.

However, you must still ensure that any **future tables** created by GitLab will still use the right format:

- If `SELECT @@innodb_file_per_table` returned **1** previously, your server is running correctly.
> It's however a requirement to check *now* that this setting is indeed persisted in your [my.cnf](https://dev.mysql.com/doc/refman/5.7/en/tablespace-enabling.html) file!

- If `SELECT @@innodb_file_per_table` returned **0** previously, your server is not running correctly.
> [Enable innodb_file_per_table](https://dev.mysql.com/doc/refman/5.7/en/tablespace-enabling.html) by running in a MySQL session as root the command `SET GLOBAL innodb_file_per_table=1, innodb_file_format=Barracuda;` and persist the two settings in your [my.cnf](https://dev.mysql.com/doc/refman/5.7/en/tablespace-enabling.html) file

Now, if you have a **different result** returned by the 2 commands above, it means you have a **mix of tables format** uses in your GitLab database. This can happen if your MySQL server had different values for `innodb_file_per_table` in its life and you updated GitLab at different moments with those inconsistent values. So keep reading.

- **Case 2: a result equals to "0" OR not the same result for both commands**

Unfortunately, none or only some of your GitLab database tables use the GitLab requirement of [InnoDB File-Per-Table Tablespaces](http://dev.mysql.com/doc/refman/5.7/en/innodb-multiple-tablespaces.html).

Let's enable what we need on the running server:

    # Login to MySQL
    mysql -u root -p

    # Type the MySQL root password

    # Enable innodb_file_per_table and set innodb_file_format on the running server:
    mysql > SET GLOBAL innodb_file_per_table=1, innodb_file_format=Barracuda;

    # You can now quit the database session
    mysql> \q

> Now, **persist** [innodb_file_per_table](https://dev.mysql.com/doc/refman/5.6/en/tablespace-enabling.html) and [innodb_file_format](https://dev.mysql.com/doc/refman/5.6/en/innodb-file-format-enabling.html) in your `my.cnf` file.

Ensure at this stage that your GitLab instance is indeed **stopped**.

Now, let's convert all the GitLab database tables to the new tablespace format:

    # Login to MySQL
    mysql -u root -p

    # Type the MySQL root password
    mysql > use gitlabhq_production;

    # Safety check: you should still have those values set as follow:
    mysql> SELECT @@innodb_file_per_table, @@innodb_file_format;
    +-------------------------+----------------------+
    | @@innodb_file_per_table | @@innodb_file_format |
    +-------------------------+----------------------+
    |                       1 | Barracuda            |
    +-------------------------+----------------------+

    mysql > SELECT CONCAT('ALTER TABLE `', TABLE_NAME,'` ENGINE=InnoDB;') AS 'Copy & run these SQL statements:' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA="gitlabhq_production" AND TABLE_TYPE="BASE TABLE";

    # If previous query returned results, copy & run all shown SQL statements

    # You can now quit the database session
    mysql> \q

---

#### Check for proper InnoDB File Format, Row Format, Large Prefix and tables conversion

We need to check, enable and probably convert your existing GitLab DB tables to use the [Barracuda InnoDB file format](https://dev.mysql.com/doc/refman/5.6/en/innodb-file-format.html), the [DYNAMIC row format](https://dev.mysql.com/doc/refman/5.6/en/glossary.html#glos_dynamic_row_format) and [innodb_large_prefix](http://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_large_prefix) as a second prerequisite for supporting **utfb8mb4 with long indexes** used by recent GitLab databases.

    # Login to MySQL
    mysql -u root -p

    # Type the MySQL root password
    mysql > use gitlabhq_production;

    # Set innodb_file_format and innodb_large_prefix on the running server:
    # Note: These are the default settings only for MySQL 5.7.7 and later.

    mysql > SET GLOBAL innodb_file_format=Barracuda, innodb_large_prefix=1;

    # Your DB must be (still) using utf8/utf8_general_ci as default encoding and collation.
    # We will NOT change the default encoding and collation on the DB in order to support future GitLab migrations creating tables
    # that require "long indexes support" on installations using MySQL <= 5.7.9.
    # However, when such migrations occur, you will have to follow this guide again to convert the newly created tables to the proper encoding/collation.

    # This should return the following:
    mysql> SELECT @@character_set_database, @@collation_database;
    +--------------------------+----------------------+
    | @@character_set_database | @@collation_database |
    +--------------------------+----------------------+
    | utf8                     | utf8_general_ci      |
    +--------------------------+----------------------+

> Now, ensure that [innodb_file_format](https://dev.mysql.com/doc/refman/5.6/en/tablespace-enabling.html) and [innodb_large_prefix](http://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_large_prefix) are **persisted** in your `my.cnf` file.

#### Tables and data conversion to utf8mb4

Now that you have a persistent MySQL setup, you can safely upgrade tables after setup or upgrade time:

    # Convert tables not using ROW_FORMAT DYNAMIC:

    mysql> SELECT CONCAT('ALTER TABLE `', TABLE_NAME,'` ROW_FORMAT=DYNAMIC;') AS 'Copy & run these SQL statements:' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA="gitlabhq_production" AND TABLE_TYPE="BASE TABLE" AND ROW_FORMAT!="Dynamic";

    # !! If previous query returned results, copy & run all shown SQL statements

    # Convert tables/columns not using utf8mb4/utf8mb4_general_ci as encoding/collation:

    mysql > SET foreign_key_checks = 0;

    mysql > SELECT CONCAT('ALTER TABLE `', TABLE_NAME,'` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;') AS 'Copy & run these SQL statements:' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA="gitlabhq_production" AND TABLE_COLLATION != "utf8mb4_general_ci" AND TABLE_TYPE="BASE TABLE";

    # !! If previous query returned results, copy & run all shown SQL statements

    # Turn foreign key checks back on
    mysql > SET foreign_key_checks = 1;

    # You can now quit the database session
    mysql> \q

Ensure your GitLab database configuration file uses a proper connection encoding and collation:

```sudo -u git -H editor config/database.yml```

    production:
      adapter: mysql2
      encoding: utf8mb4
      collation: utf8mb4_general_ci

[Restart your GitLab instance](../administration/restart_gitlab.md).


## MySQL strings limits

After installation or upgrade, remember to run the `add_limits_mysql` Rake task:

**Omnibus GitLab installations**
```
sudo gitlab-rake add_limits_mysql
```

**Installations from source**

```
bundle exec rake add_limits_mysql RAILS_ENV=production
```

The `text` type in MySQL has a different size limit than the `text` type in
PostgreSQL. In MySQL `text` columns are limited to ~65kB, whereas in PostgreSQL
`text` columns are limited up to ~1GB!

The `add_limits_mysql` Rake task converts some important `text` columns in the
GitLab database to `longtext` columns, which can persist values of up to 4GB
(sometimes less if the value contains multibyte characters).

Details can be found in the [PostgreSQL][postgres-text-type] and
[MySQL][mysql-text-types] manuals.

[postgres-text-type]: http://www.postgresql.org/docs/9.2/static/datatype-character.html
[mysql-text-types]: http://dev.mysql.com/doc/refman/5.7/en/string-type-overview.html
[ce-38152]: https://gitlab.com/gitlab-org/gitlab-ce/issues/38152
