# GitLab Geo database replication

This document describes the minimal steps you have to take in order to
replicate your GitLab database into another server. You may have to change
some values according to your database setup, how big it is, etc.

The GitLab primary node where the write operations happen will act as `master`,
and the secondary ones which are read-only will act as `slaves`.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [GitLab Geo PostgreSQL replication](#gitlab-geo-postgresql-replication)
    - [PostgreSQL - Configure the master server](#postgresql-configure-the-master-server)
    - [PostgreSQL - Configure the slave server](#postgresql-configure-the-slave-server)
    - [PostgreSQL - Initiate the replication process](#postgresql-initiate-the-replication-process)
- [GitLab Geo MySQL replication](#gitlab-geo-mysql-replication)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## GitLab Geo PostgreSQL replication

The following guide assumes that:

- You are using PostgreSQL 9.1 or later which includes the
  [`pg_basebackup` tool][pgback]. As of this writing, the latest Omnibus
  packages (8.5) have version 9.2.
- You have a master server already set up, running PostgreSQL 9.2.x, and you
  have a new slave server set up on the same OS and PostgreSQL version.
- The IP of master server for our examples will be `1.2.3.4`, whereas the
  slave's IP will be `5.6.7.8`.

[pgback]: http://www.postgresql.org/docs/9.2/static/app-pgbasebackup.html

### PostgreSQL - Configure the master server

**For installations from source**

1. Create a replication user:

    ```bash
    sudo -u postgres psql -c "CREATE USER gitlab_replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'thepassword';"
    ```

1. Edit `postgresql.conf` to configure the master for streaming replication
   (for Ubuntu that would be `/etc/postgresql/9.2/main/postgresql.conf`):

    ```bash
    listen_address = 'localhost,1.2.3.4'
    wal_level = hot_standby
    max_wal_senders = 5
    checkpoint_segments = 10
    wal_keep_segments = 10
    hot_standby = on
    ```

    Edit these values as you see fit.

1. Edit the access control on the master to allow the connection from the slave
   in `pg_hba.conf` (for Ubuntu that would be `/etc/postgresql/9.2/main/pg_hba.conf`):

    ```bash
    host    replication     gitlab_replicator        5.6.7.8/32      md5
    ```

    Note that `5.6.7.8` is the IP of the slave.

1. Restart PostgreSQL

**For Omnibus installations**

Edit `/etc/gitla/gitlab.rb` and add the following:

```ruby
postgresql['listen_address'] = "localhost,1.2.3.4"
postgresql['md5_auth_cidr_addresses'] = ['5.6.7.8/32']
postgresql['sql_replication_user'] = "gitlab_replicator"
postgresql['wal_level'] = "hot_standby"
postgresql['max_wal_senders'] = 10
postgresql['wal_keep_segments'] = 10
postgresql['hot_standby'] = "on"
```

### PostgreSQL - Configure the slave server

**For installations from source**

1. Edit `postgresql.conf`
1. Restart postgres

### PostgreSQL - Initiate the replication process

```bash
psql -c "select pg_start_backup('initial_backup');"
rsync -cva --inplace --exclude=*pg_xlog* /var/lib/postgresql/9.5/main/ slave_IP_address:/var/lib/postgresql/9.5/main/
psql -c "select pg_stop_backup();"
```

```bash
psql -c "select pg_start_backup('initial_backup');"
rsync -cva --inplace --exclude=*pg_xlog* /var/opt/gitlab/postgresql/data/ slave_IP_address:/var/opt/gitlab/postgresql/data/
psql -c "select pg_stop_backup();"
```

## GitLab Geo MySQL replication

TODO

## Acknowledgments


