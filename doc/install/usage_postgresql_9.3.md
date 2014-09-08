# Usage of PostgreSQL 9.3

## Note

We do not recommend using PostgreSQL in version 9.3.
These steps are for Debian Wheezy (stable).

## PostgreSQL 9.3

    # Install the [official PostgreSQL Debian/Ubuntu repository](https://wiki.postgresql.org/wiki/Apt)
    cat >> /etc/apt/sources.list.d/pgdg.list << EOF
    deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
    EOF

    # Install the repository signing key
    sudo apt-get install wget ca-certificates
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

    # Update your apt lists
    sudo apt-get update

    # Upgrade your installed packages
    sudo apt-get upgrade

## Intregation in the manual installation process

    # If you arrive the point 4 in the manual [4. Database](https://github.com/gitlabhq/gitlabhq/blob/7-2-stable/doc/install/installation.md#4-database), replace the first step with the following command:

    sudo apt-get install -y postgresql-9.3 postgresql-client-9.3 libpq-dev

    # After that follow the normal manual instructions...


## Upgrade from PostgreSQL version 9.1 to 9.3

    # Stop your Gitlab service
    service gitlab stop

    # Install all PostgreSQL packages for your environment after you integrate the Debian/Ubuntu repository
    sudo apt-get install -y postgresql-9.3 postgresql-server-dev-9.3 postgresql-contrib-9.3 postgresql-client-9.3 libpq-dev

    # Extend your PostgreSQL 9.3. server with your extensions
    sudo su - postgres -c "psql template1 -p 5433 -c 'CREATE EXTENSION IF NOT EXISTS hstore;'"
    sudo su - postgres -c "psql template1 -p 5433 -c 'CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";'"

    # Stop your PostgreSQL server daemons (both!)
    sudo service postgresql stop

    # Make the migration from 9.1 to 9.3
    sudo su - postgres -c '/usr/lib/postgresql/9.3/bin/pg_upgrade -b /usr/lib/postgresql/9.1/bin -B /usr/lib/postgresql/9.3/bin -d /var/lib/postgresql/9.1/main/ -D /var/lib/postgresql/9.3/main/ -O " -c config_file=/etc/postgresql/9.3/main/postgresql.conf" -o " -c config_file=/etc/postgresql/9.1/main/postgresql.conf"'

    # Remove your old PostgreSQL version, if you have no issues.
    sudo apt-get remove -y postgresql-9.1

    # Change the listen port of your PostgreSQL 9.3 server
    sudo sed -i "s:5433:5432:g" /etc/postgresql/9.3/main/postgresql.conf

    # Start your PostgreSQL service
    sudo service postgresql start

    # Start your Gitlab service
    service gitlab start

    # Done!
