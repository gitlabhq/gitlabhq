# Setup Database

GitLab supports the following databases:

* MySQL (preferred)
* PostgreSQL


## MySQL

    # Install the database packages
    sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

    # Login to MySQL
    $ mysql -u root -p

    # Create a user for GitLab. (change $password to a real password)
    mysql> CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '$password';

    # Create the GitLab production database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

    # Grant the GitLab user necessary permissopns on the table.
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'localhost';

    # Quit the database session
    mysql> \q

    # Try connecting to the new database with the new user
    sudo -u gitlab -H mysql -u gitlab -p -D gitlabhq_production

## PostgreSQL

    # Install the database packages
    sudo apt-get install -y postgresql-9.1 libpq-dev

    # Login to PostgreSQL
    sudo -u postgres psql -d template1

    # Create a user for GitLab. (change $password to a real password)
    template1=# CREATE USER gitlab WITH PASSWORD '$password';

    # Create the GitLab production database & grant all privileges on database
    template1=# CREATE DATABASE gitlabhq_production OWNER gitlab;

    # Quit the database session
    template1=# \q

    # Try connecting to the new database with the new user
    sudo -u gitlab -H psql -d gitlabhq_production

