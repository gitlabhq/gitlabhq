# GitLab Geo database replication for Source installations

This document describes the minimal steps you have to take in order to
replicate your GitLab database into another server. You may have to change
some values according to your database setup, how big it is, etc.

The GitLab primary node where the write operations happen will connect to the
`primary` database server, and the secondary ones which are read-only will
connect to `secondary` database servers (which are read-only too).

>**Note:**
In many databases documentation you will see `primary` being references as `master`
and `secondary` as either `slave` or `standby` server (read-only).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [PostgreSQL replication](#postgresql-replication)
    - [PostgreSQL - Configure the primary server](#postgresql-configure-the-primary-server)
    - [PostgreSQL - Configure the secondary server](#postgresql-configure-the-secondary-server)
    - [PostgreSQL - Initiate the replication process](#postgresql-initiate-the-replication-process)
- [MySQL replication](#mysql-replication)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## PostgreSQL replication

The following guide assumes that:

- You are using PostgreSQL 9.1 or later which includes the
  [`pg_basebackup` tool][pgback]. As of this writing, the latest Omnibus
  packages (8.5) have version 9.2.
- You have a primary server already set up, running PostgreSQL 9.2.x, and you
  have a new secondary server set up on the same OS and PostgreSQL version.
- The IP of the primary server for our examples will be `1.2.3.4`, whereas the
  secondary's IP will be `5.6.7.8`.

[pgback]: http://www.postgresql.org/docs/9.2/static/app-pgbasebackup.html

### PostgreSQL - Configure the primary server

1. Login as root and create a replication user:

    ```bash
    sudo -u postgres psql -c "CREATE USER gitlab_replicator REPLICATION ENCRYPTED PASSWORD 'thepassword';"
    ```

1. Edit `postgresql.conf` to configure the primary server for streaming replication
   (for Debian/Ubuntu that would be `/etc/postgresql/9.2/main/postgresql.conf`):

    ```bash
    listen_address = '1.2.3.4'
    wal_level = hot_standby
    max_wal_senders = 5
    checkpoint_segments = 10
    wal_keep_segments = 10
    hot_standby = on
    ```

    Edit the `wal` values as you see fit.

1. Set the access control on the primary to allow TCP connections using the
   server's public IP and set the connection from the secondary to require a
   password.  Edit `pg_hba.conf` (for Debian/Ubuntu that would be
   `/etc/postgresql/9.2/main/pg_hba.conf`):

    ```bash
    host    all             all                      127.0.0.1/32    trust
    host    all             all                      1.2.3.4/32      trust
    host    replication     gitlab_replicator        5.6.7.8/32      md5
    ```

    Where `1.2.3.4` is the public IP address of the primary server, and `5.6.7.8`
    the public IP address of the secondary one.

1. Restart PostgreSQL for the changes to take effect

---

Now that the PostgreSQL server is set up to accept remote connections, run
`netstat -plnt` to make sure that PostgreSQL is listening to the server's
public IP.

Test that the remote connection works by going to the secondary server and
running:

```
sudo -u postgres psql -h 1.2.3.4 -U gitlab_replicator -d gitlabhq_production -W
```

When prompted enter the password you set in the first step for the
`gitlab_replicator` user. If all worked correctly, you should see the database
prompt. Run `\q` to exit.

### PostgreSQL - Configure the secondary server

**For installations from source**

1. Edit `postgresql.conf` to configure the secondary for streaming replication
   (for Debian/Ubuntu that would be `/etc/postgresql/9.2/main/postgresql.conf`):

    ```bash
    wal_level = hot_standby
    max_wal_senders = 5
    checkpoint_segments = 10
    wal_keep_segments = 10
    hot_standby = on
    ```

1. Restart PostgreSQL for the changes to take effect

---

### PostgreSQL - Initiate the replication process

Below we provide a script that connects to the primary server, replicates the
database and creates the needed files for replication.

The directories used are the defaults that are set up in Omnibus. Configure it
as you see fit replacing the directories and paths.

>**Warning:**
Make sure to run this on the _**secondary**_ server as it removes all PostgreSQL's
data before running `pg_basebackup`.

```bash
#!/bin/bash

PORT="5432"
USER="gitlab_replicator"
echo Enter ip of primary postgresql server
read HOST
echo Enter password for $USER@$HOST
read -s PASSWORD

echo Stopping PostgreSQL
gitlab-ctl stop

echo Backup postgresql.conf
sudo -u gitlab-psql mv /var/opt/gitlab/postgresql/data/postgresql.conf /var/opt/gitlab/postgresql/

echo Cleaning up old cluster directory
sudo -u gitlab-psql rm -rf /var/opt/gitlab/postgresql/data
rm -f /tmp/postgresql.trigger

echo Starting base backup as replicator
echo Enter password for $USER@$HOST
sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_basebackup -h $HOST -D /var/opt/gitlab/postgresql/data -U gitlab_replicator -v -x -P

echo Writing recovery.conf file
sudo -u gitlab-psql bash -c "cat > /var/opt/gitlab/postgresql/data/recovery.conf <<- _EOF1_
  standby_mode = 'on'
  primary_conninfo = 'host=$HOST port=$PORT user=$USER password=$PASSWORD'
  trigger_file = '/tmp/postgresql.trigger'
_EOF1_
"

echo Restore postgresql.conf
sudo -u gitlab-psql mv /var/opt/gitlab/postgresql/postgresql.conf /var/opt/gitlab/postgresql/data/

echo Starting PostgreSQL
gitlab-ctl start
```

When prompted, enter the password you set up for the `gitlab_replicator` user.

## MySQL replication

We don't support MySQL replication for GitLab Geo.
