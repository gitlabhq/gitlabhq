# Databases:

GitLab use mysql as default database but you are free to use PostgreSQL or SQLite.


## SQLite

    sudo apt-get install -y sqlite3 libsqlite3-dev 

## MySQL

    sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

    # Login to MySQL
    $ mysql -u root -p

    # Create the GitLab production database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

    # Create the MySQL User change $password to a real password
    mysql> CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '$password';

    # Grant proper permissions to the MySQL User
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'localhost';


## PostgreSQL

    sudo apt-get install -y postgresql-9.2 postgresql-server-dev-9.2

    # Connect to database server
    sudo -u postgres psql -d template1

    # Add a user called gitlab. Change $password to a real password
    template1=# CREATE USER gitlab WITH PASSWORD '$password';

    # Create the GitLab production database
    template1=# CREATE DATABASE IF NOT EXISTS gitlabhq_production;

    # Grant all privileges on database
    template1=# GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production to gitlab;

    # Quit from PostgreSQL server
    template1=# \q

    # Try connect to new database
    $ su - gitlab
    $ psql -d gitlabhq_production -U gitlab



#### Select the database you want to use

    # SQLite
    sudo -u gitlab cp config/database.yml.sqlite config/database.yml

    # Mysql
    sudo -u gitlab cp config/database.yml.mysql config/database.yml

    # PostgreSQL
    sudo -u gitlab cp config/database.yml.postgresql config/database.yml

    # make sure to update username/password in config/database.yml

#### Install gems 

    # mysql
    sudo -u gitlab -H bundle install --without development test sqlite postgres  --deployment

    # or postgres
    sudo -u gitlab -H bundle install --without development test sqlite mysql --deployment

    # or sqlite
    sudo -u gitlab -H bundle install --without development test mysql postgres  --deployment

