# Setup Database

GitLab supports the following databases:

* PostgreSQL (preferred)
* [MySQL](doc/install/database_mysql.md)

## PostgreSQL

    # Install the database packages
    sudo apt-get install -y postgresql-9.1 postgresql-client libpq-dev

    # Login to PostgreSQL
    sudo -u postgres psql -d template1

    # Create a user for GitLab.
    template1=# CREATE USER git;

    # Create the GitLab production database & grant all privileges on database
    template1=# CREATE DATABASE gitlabhq_production OWNER git;

    # Quit the database session
    template1=# \q

    # Try connecting to the new database with the new user
    sudo -u git -H psql -d gitlabhq_production

