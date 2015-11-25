## Using MySQL

It's possible to use MySQL database test your apps during builds.

### Use MySQL with Docker executor

If you are using our Docker integration you basically have everything already.

1. Add this to your `.gitlab-ci.yml`:

		services:
		- mysql

		variables:
		  # Configure mysql service (https://hub.docker.com/_/mysql/)
		  MYSQL_DATABASE: hello_world_test
		  MYSQL_ROOT_PASSWORD: mysql

2. Configure your application to use the database:

		Host: mysql
		User: root
		Password: mysql
		Database: hello_world_test

3. You can also use any other available on [DockerHub](https://hub.docker.com/_/mysql/). For example: `mysql:5.5`. 

Example: https://gitlab.com/gitlab-examples/mysql/blob/master/.gitlab-ci.yml

### Use MySQL with Shell executor

It's possible to use MySQL on manually configured servers that are using GitLab Runner with Shell executor.

1. First install the MySQL server:
	
		sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

		# Pick a MySQL root password (can be anything), type it and press enter
		# Retype the MySQL root password and press enter

2. Create an user:

		mysql -u root -p

		# Create a user which will be used by your apps
		# do not type the 'mysql>', this is part of the prompt
		# change $password in the command below to a real password you pick
		mysql> CREATE USER 'runner'@'localhost' IDENTIFIED BY '$password';

		# Ensure you can use the InnoDB engine which is necessary to support long indexes
		# If this fails, check your MySQL config files (e.g. `/etc/mysql/*.cnf`, `/etc/mysql/conf.d/*`) for the setting "innodb = off"
		mysql> SET storage_engine=INNODB;

		# Create the database
		mysql> CREATE DATABASE IF NOT EXISTS `hello_world_test` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

		# Grant necessary permissions on the database
		mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `hello_world_test`.* TO 'runner'@'localhost';

		# Quit the database session
		mysql> \q

3. Try to connect to database:

		sudo -u gitlab-runner -H mysql -u runner -p -D hello_world_test

4. Configure your application to use the database:

		Host: localhost
		User: runner
		Password: $password
		Database: hello_world_test
