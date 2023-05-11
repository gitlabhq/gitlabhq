---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Geo with external PostgreSQL instances **(PREMIUM SELF)**

This document is relevant if you are using a PostgreSQL instance that is *not
managed by Omnibus*. This includes cloud-managed instances like Amazon RDS, or
manually installed and configured PostgreSQL instances.

Ensure that you are using one of the PostgreSQL versions that
[Omnibus ships with](../../package_information/postgresql_versions.md)
to [avoid version mismatches](../index.md#requirements-for-running-geo)
in case a Geo site has to be rebuilt.

NOTE:
We strongly recommend running Omnibus-managed instances as they are actively
developed and tested. We aim to be compatible with most external
(not managed by Omnibus) databases but we do not guarantee compatibility.

## **Primary** site

1. SSH into a **Rails node on your primary** site and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   ##
   ## Geo Primary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_primary_role']

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/user/admin_area/geo_nodes.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Reconfigure the **Rails node** for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Execute the command below on the **Rails node** to define the site as **primary** site:

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   This command uses your defined `external_url` in `/etc/gitlab/gitlab.rb`.

### Configure the external database to be replicated

To set up an external database, you can either:

- Set up [streaming replication](https://www.postgresql.org/docs/12/warm-standby.html#STREAMING-REPLICATION-SLOTS) yourself (for example Amazon RDS, or bare metal not managed by Omnibus).
- Perform the Omnibus configuration manually as follows.

#### Leverage your cloud provider's tools to replicate the primary database

Given you have a primary site set up on AWS EC2 that uses RDS.
You can now just create a read-only replica in a different region and the
replication process is managed by AWS. Make sure you've set Network ACL (Access Control List), Subnet, and Security Group according to your needs, so the secondary Rails nodes can access the database.

The following instructions detail how to create a read-only replica for common
cloud providers:

- Amazon RDS - [Creating a Read Replica](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure Database for PostgreSQL - [Create and manage read replicas in Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)
- Google Cloud SQL - [Creating read replicas](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

When your read-only replica is set up, you can skip to [configure your secondary site](#configure-secondary-site-to-use-the-external-read-replica)

#### Manually configure the primary database for replication

The [`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)
configures the **primary** node's database to be replicated by making changes to
`pg_hba.conf` and `postgresql.conf`. Make the following configuration changes
manually to your external database configuration and ensure that you restart PostgreSQL
afterwards for the changes to take effect:

```plaintext
##
## Geo Primary Role
## - pg_hba.conf
##
host    all         all               <trusted primary IP>/32       md5
host    replication gitlab_replicator <trusted primary IP>/32       md5
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
```

```plaintext
##
## Geo Primary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 50
max_replication_slots = 1 # number of secondary instances
hot_standby = on
```

## **Secondary** sites

### Manually configure the replica database

Make the following configuration changes manually to your `pg_hba.conf` and `postgresql.conf`
of your external replica database and ensure that you restart PostgreSQL afterwards
for the changes to take effect:

```plaintext
##
## Geo Secondary Role
## - pg_hba.conf
##
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
host    all         all               <trusted primary IP>/24       md5
```

```plaintext
##
## Geo Secondary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 10
hot_standby = on
```

### Configure **secondary** site to use the external read-replica

With Omnibus, the
[`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)
has three main functions:

1. Configure the replica database.
1. Configure the tracking database.
1. Enable the [Geo Log Cursor](../index.md#geo-log-cursor) (not covered in this section).

To configure the connection to the external read-replica database and enable Log Cursor:

1. SSH into each **Rails, Sidekiq and Geo Log Cursor** node on your **secondary** site and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_secondary_role']

   # note this is shared between both databases,
   # make sure you define the same password in both
   gitlab_rails['db_password'] = '<your_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL, since we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)

### Configure the tracking database

**Secondary** sites use a separate PostgreSQL installation as a tracking
database to keep track of replication status and automatically recover from
potential replication issues. Omnibus automatically configures a tracking database
when `roles ['geo_secondary_role']` is set.
If you want to run this database external to Omnibus GitLab, use the following instructions.

If you are using a cloud-managed service for the tracking database, you may need
to grant additional roles to your tracking database user (by default, this is
`gitlab_geo`):

- Amazon RDS requires the [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) role.
- Azure Database for PostgreSQL requires the [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql) role.
- Google Cloud SQL requires the [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users) role.

This is for the installation of extensions during installation and upgrades. As an alternative,
[ensure the extensions are installed manually, and read about the problems that may arise during future GitLab upgrades](../../../install/postgresql_extensions.md).

To setup an external tracking database, follow the instructions below:

NOTE:
If you want to use Amazon RDS as a tracking database, make sure it has access to
the secondary database. Unfortunately, just assigning the same security group is not enough as
outbound rules do not apply to RDS PostgreSQL databases. Therefore, you need to explicitly add an inbound
rule to the read-replica's security group allowing any TCP traffic from
the tracking database on port 5432.

1. Set up PostgreSQL according to the
   [database requirements document](../../../install/requirements.md#database).
1. Set up a `gitlab_geo` user with a password of your choice, create the `gitlabhq_geo_production` database, and make the user an owner of the database. You can see an example of this setup in the [installation from source documentation](../../../install/installation.md#7-database).
1. If you are **not** using a cloud-managed PostgreSQL database, ensure that your secondary
   site can communicate with your tracking database by manually changing the
   `pg_hba.conf` that is associated with your tracking database.
   Remember to restart PostgreSQL afterwards for the changes to take effect:

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   ```

1. SSH into a GitLab **secondary** server and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` with the connection parameters and credentials for
   the machine with the PostgreSQL instance:

   ```ruby
   geo_secondary['db_username'] = 'gitlab_geo'
   geo_secondary['db_password'] = '<your_password_here>'

   geo_secondary['db_host'] = '<tracking_database_host>'
   geo_secondary['db_port'] = <tracking_database_port>      # change to the correct port
   geo_postgresql['enable'] = false     # don't use internal managed instance
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)

1. The reconfigure should automatically create the database. If needed, you can perform this task manually. This task (whether run by itself or during reconfigure) requires the database user to be a superuser.

   ```shell
   gitlab-rake db:create:geo
   ```

1. The reconfigure should automatically migrate the database. You can migrate the database manually if needed, for example if `geo_secondary['auto_migrate'] = false`:

   ```shell
   gitlab-rake db:migrate:geo
   ```
