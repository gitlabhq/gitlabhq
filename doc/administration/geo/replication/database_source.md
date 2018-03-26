# Geo database replication (source)

NOTE: **Note:**
This is the documentation for installations from source. For installations
using the Omnibus GitLab packages, follow the
[**database replication for Omnibus GitLab**][database] guide.

NOTE: **Note:**
The stages of the setup process must be completed in the documented order.
Before attempting the steps in this stage, [complete all prior stages][toc].

This document describes the minimal steps you have to take in order to
replicate your primary GitLab database to a secondary node's database. You may
have to change some values according to your database setup, how big it is, etc.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

## PostgreSQL replication

The GitLab primary node where the write operations happen will connect to
primary database server, and the secondary ones which are read-only will
connect to secondary database servers (which are read-only too).

NOTE: **Note:**
In many databases documentation you will see "primary" being referenced as "master"
and "secondary" as either "slave" or "standby" server (read-only).

We recommend using [PostgreSQL replication slots][replication-slots-article]
to ensure the primary retains all the data necessary for the secondaries to
recover. See below for more details.

The following guide assumes that:

- You are using PostgreSQL 9.6 or later which includes the
  [`pg_basebackup` tool][pgback] and improved [Foreign Data Wrapper][FDW] support.
- You have a primary node already set up (the GitLab server you are
  replicating from), running PostgreSQL 9.6 or later, and
  you have a new secondary server set up with the same versions of the OS,
  PostgreSQL, and GitLab on all nodes.
- The IP of the primary server for our examples will be `1.2.3.4`, whereas the
  secondary's IP will be `5.6.7.8`. Note that the primary and secondary servers
  **must** be able to communicate over these addresses. These IP addresses can either
  be public or private.

### Step 1. Configure the primary server

1. SSH into your GitLab **primary** server and login as root:

    ```bash
    sudo -i
    ```

1. Add this node as the Geo primary by running:

    ```bash
    bundle exec rake geo:set_primary_node
    ```

1. Create a [replication user] named `gitlab_replicator`:

    ```sql
    --- Create a new user 'replicator'
    CREATE USER gitlab_replicator;
    
    --- Set/change a password and grants replication privilege 
    ALTER USER gitlab_replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicationpasswordhere';
    ```
    
1. Make sure your the `gitlab` database user has a password defined

    ```bash
    sudo -u postgres psql -d template1 -c "ALTER USER gitlab WITH ENCRYPTED PASSWORD 'mydatabasepassword';"
    ```
    
1. Edit the content of `database.yml` in `production:` and add the password like the exemple below:

    ```yaml
    #
    # PRODUCTION
    #
    production:
      adapter: postgresql
      encoding: unicode
      database: gitlabhq_production
      pool: 10
      username: gitlab
      password: mydatabasepassword
      host: /var/opt/gitlab/geo-postgresql
    ```

1. Set up TLS support for the PostgreSQL primary server

    CAUTION: **Warning**: 
    Only skip this step if you **know** that PostgreSQL traffic
    between the primary and secondary will be secured through some other
    means, e.g., a known-safe physical network path or a site-to-site VPN that
    you have configured.

    If you are replicating your database across the open Internet, it is
    **essential** that the connection is TLS-secured. Correctly configured, this
    provides protection against both passive eavesdroppers and active
    "man-in-the-middle" attackers.

    To generate a self-signed certificate and key, run this command:

    ```bash
    openssl req -nodes -batch -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 3650
    ```

    This will create two files - `server.key` and `server.crt` - that you can
    use for authentication.

    Copy them to the correct location for your PostgreSQL installation:

    ```bash
    # Copying a self-signed certificate and key
    install -o postgres -g postgres -m 0400 -T server.crt ~postgres/9.x/main/data/server.crt
    install -o postgres -g postgres -m 0400 -T server.key ~postgres/9.x/main/data/server.key
    ```

    Add this configuration to `postgresql.conf`, removing any existing
    configuration for `ssl_cert_file` or `ssl_key_file`:

    ```
    ssl = on
    ssl_cert_file='server.crt'
    ssl_key_file='server.key'
    ```

1. Edit `postgresql.conf` to configure the primary server for streaming replication
   (for Debian/Ubuntu that would be `/etc/postgresql/9.x/main/postgresql.conf`):

    ```
    listen_address = '1.2.3.4'
    wal_level = hot_standby
    max_wal_senders = 5
    min_wal_size = 80MB
    max_wal_size = 1GB
    max_replicaton_slots = 1 # Number of Geo secondary nodes
    wal_keep_segments = 10
    hot_standby = on
    ```

    NOTE: **Note**:
    Be sure to set `max_replication_slots` to the number of Geo secondary
    nodes that you may potentially have (at least 1).

    For security reasons, PostgreSQL by default only listens on the local
    interface (e.g. 127.0.0.1). However, Geo needs to communicate
    between the primary and secondary nodes over a common network, such as a
    corporate LAN or the public Internet. For this reason, we need to
    configure PostgreSQL to listen on more interfaces.

    The `listen_address` option opens PostgreSQL up to external connections
    with the interface corresponding to the given IP. See [the PostgreSQL
    documentation][pg-docs-runtime-conn] for more details.

    You may also want to edit the `wal_keep_segments` and `max_wal_senders` to
    match your database replication requirements. Consult the 
    [PostgreSQL - Replication documentation][pg-docs-runtime-replication] for more information.

1. Set the access control on the primary to allow TCP connections using the
   server's public IP and set the connection from the secondary to require a
   password.  Edit `pg_hba.conf` (for Debian/Ubuntu that would be
   `/etc/postgresql/9.x/main/pg_hba.conf`):

    ```bash
    host    all             all                      1.2.3.4/32      md5
    host    replication     gitlab_replicator        5.6.7.8/32      md5
    ```

    Where `1.2.3.4` is the public IP address of the primary server, and `5.6.7.8`
    the public IP address of the secondary one. If you want to add another
    secondary, add one more row like the replication one and change the IP
    address:

    ```bash
    host    all             all                      1.2.3.4/32      md5
    host    replication     gitlab_replicator        5.6.7.8/32      md5
    host    replication     gitlab_replicator        11.22.33.44/32  md5
    ```

1. Restart PostgreSQL for the changes to take effect.

1. Choose a database-friendly name to use for your secondary to use as the
   replication slot name. For example, if your domain is
   `secondary.geo.example.com`, you may use `secondary_example` as the slot
   name.

1. Create the replication slot on the primary:

    ```bash
    $ sudo -u postgres psql -c "SELECT * FROM pg_create_physical_replication_slot('secondary_example');"
      slot_name         | xlog_position
      ------------------+---------------
      secondary_example |
      (1 row)
    ```

1. Now that the PostgreSQL server is set up to accept remote connections, run
   `netstat -plnt` to make sure that PostgreSQL is listening to the server's
   public IP.

### Step 2. Configure the secondary server

Follow the first steps in ["configure the secondary server"][database-replication],
but note that since you are installing from source, the username and
group listed as `gitlab-psql` in those steps should be replaced by `postgres`
instead. After completing the "Test that the `gitlab-psql` user can connect to
the primary's database" step, continue here:

1. Edit `postgresql.conf` to configure the secondary for streaming replication
   (for Debian/Ubuntu that would be `/etc/postgresql/9.*/main/postgresql.conf`):

    ```bash
    wal_level = hot_standby
    max_wal_senders = 5
    checkpoint_segments = 10
    wal_keep_segments = 10
    hot_standby = on
    ```

1. Restart PostgreSQL for the changes to take effect.

#### Enable tracking database on the secondary server

Geo secondary nodes use a tracking database to keep track of replication status
and recover automatically from some replication issues. Follow the steps below to create
the tracking database.

1. On the secondary node, run the following command to create `database_geo.yml` with the
information of your secondary PostgreSQL instance:

    ```bash
    sudo cp /home/git/gitlab/config/database_geo.yml.postgresql /home/git/gitlab/config/database_geo.yml
    ```

1. Edit the content of `database_geo.yml` in `production:` as in the example below:

    ```yaml
    #
    # PRODUCTION
    #
    production:
      adapter: postgresql
      encoding: unicode
      database: gitlabhq_geo_production
      pool: 10
      username: gitlab_geo
      # password:
      host: /var/opt/gitlab/geo-postgresql
    ```

1. Create the database `gitlabhq_geo_production` on the PostgreSQL instance of the secondary
node.

1. Set up the Geo tracking database:

    ```bash
    bundle exec rake geo:db:migrate
    ```

1. Configure the [PostgreSQL FDW][FDW] connection and credentials:

    Save the script below in a file, ex. `/tmp/geo_fdw.sh` and modify the connection
    params to match your environment. Execute it to setup the FDW connection.
    
    ```bash
    #!/bin/bash
 
    # Secondary Database connection params:
    DB_HOST="/var/opt/gitlab/postgresql" # change to the public IP or VPC private IP if its an external server
    DB_NAME="gitlabhq_production"
    DB_USER="gitlab"
    DB_PORT="5432"
    
    # Tracking Database connection params:
    GEO_DB_HOST="/var/opt/gitlab/geo-postgresql" # change to the public IP or VPC private IP if its an external server
    GEO_DB_NAME="gitlabhq_geo_production"
    GEO_DB_USER="gitlab_geo"
    GEO_DB_PORT="5432"
 
    query_exec () {
      gitlab-psql -h $GEO_DB_HOST -d $GEO_DB_NAME -p $GEO_DB_PORT -c "${1}"
    }
 
    query_exec "CREATE EXTENSION postgres_fdw;"
    query_exec "CREATE SERVER gitlab_secondary FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '${DB_HOST}', dbname '${DB_NAME}', port '${DB_PORT}');"
    query_exec "CREATE USER MAPPING FOR ${GEO_DB_USER} SERVER gitlab_secondary OPTIONS (user '${DB_USER}');"
    query_exec "CREATE SCHEMA gitlab_secondary;"
    query_exec "GRANT USAGE ON FOREIGN SERVER gitlab_secondary TO ${GEO_DB_USER};"
    ```

    And edit the content of `database_geo.yml` and to add `fdw: true` to
    the  `production:` block.

### Step 3. Initiate the replication process

Below we provide a script that connects the database on the secondary node to
the database on the primary node, replicates the database, and creates the
needed files for streaming replication.

The directories used are the defaults for Debian/Ubuntu. If you have changed
any defaults, configure it as you see fit replacing the directories and paths.

CAUTION: **Warning:**
Make sure to run this on the **secondary** server as it removes all PostgreSQL's
data before running `pg_basebackup`.

1. SSH into your GitLab **secondary** server and login as root:

    ```bash
    sudo -i
    ```

1. Save the snippet below in a file, let's say `/tmp/replica.sh`. Modify the
   embedded paths if necessary:

    ```
    #!/bin/bash

    PORT="5432"
    USER="gitlab_replicator"
    echo ---------------------------------------------------------------
    echo WARNING: Make sure this script is run from the secondary server
    echo ---------------------------------------------------------------
    echo
    echo Enter the IP or FQDN of the primary PostgreSQL server
    read HOST
    echo Enter the password for $USER@$HOST
    read -s PASSWORD
    echo Enter the required sslmode
    read SSLMODE

    echo Stopping PostgreSQL and all GitLab services
    sudo service gitlab stop
    sudo service postgresql stop

    echo Backing up postgresql.conf
    sudo -u postgres mv /var/opt/gitlab/postgresql/data/postgresql.conf /var/opt/gitlab/postgresql/

    echo Cleaning up old cluster directory
    sudo -u postgres rm -rf /var/opt/gitlab/postgresql/data

    echo Starting base backup as the replicator user
    echo Enter the password for $USER@$HOST
    sudo -u postgres /opt/gitlab/embedded/bin/pg_basebackup -h $HOST -D /var/opt/gitlab/postgresql/data -U gitlab_replicator -v -x -P

    echo Writing recovery.conf file
    sudo -u postgres bash -c "cat > /var/opt/gitlab/postgresql/data/recovery.conf <<- _EOF1_
      standby_mode = 'on'
      primary_conninfo = 'host=$HOST port=$PORT user=$USER password=$PASSWORD sslmode=$SSLMODE'
    _EOF1_
    "

    echo Restoring postgresql.conf
    sudo -u postgres mv /var/opt/gitlab/postgresql/postgresql.conf /var/opt/gitlab/postgresql/data/

    echo Starting PostgreSQL
    sudo service postgresql start
    ```

1. Run it with:

    ```bash
    bash /tmp/replica.sh
    ```

    When prompted, enter the IP/FQDN of the primary, and the password you set up
    for the `gitlab_replicator` user in the first step.

    You should use `verify-ca` for the `sslmode`. You can use `disable` if you
    are happy to skip PostgreSQL TLS authentication altogether (e.g., you know
    the network path is secure, or you are using a site-to-site VPN). This is
    **not** safe over the public Internet!

    You can read more details about each `sslmode` in the
    [PostgreSQL documentation][pg-docs-ssl];
    the instructions above are carefully written to ensure protection against
    both passive eavesdroppers and active "man-in-the-middle" attackers.

The replication process is now over.

## MySQL replication

MySQL replication is not supported for Geo.

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).

[replication-slots-article]: https://medium.com/@tk512/replication-slots-in-postgresql-b4b03d277c75
[pgback]: http://www.postgresql.org/docs/9.6/static/app-pgbasebackup.html
[replication user]:https://wiki.postgresql.org/wiki/Streaming_Replication
[FDW]: https://www.postgresql.org/docs/9.6/static/postgres-fdw.html
[toc]: index.md#using-gitlab-installed-from-source
[database]: database.md
[add-geo-node]: configuration.md#step-3-add-the-secondary-gitlab-node
[database-replication]: database.md#step-2-configure-the-secondary-server
[pg-docs-ssl]: https://www.postgresql.org/docs/9.6/static/libpq-ssl.html#LIBPQ-SSL-PROTECTION
[pg-docs-runtime-conn]: https://www.postgresql.org/docs/9.6/static/runtime-config-connection.html
[pg-docs-runtime-replication]: https://www.postgresql.org/docs/9.6/static/runtime-config-replication.html
