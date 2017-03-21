# Updating the Geo nodes

In order to update the GitLab Geo nodes when a new GitLab version is released,
all you need to do is update GitLab itself:

1. Log into each node (primary and secondaries)
1. [Update GitLab](../update/README.md)
1. Test primary and secondary nodes, and check version in each.

# Upgrade to 9.0.x

> **IMPORTANT**: 9.0 requires manual steps in the secondary nodes,
because we are upgrading PostgreSQL to 9.6 on the primary and Postgres
doesn't support upgrading secondary nodes while keeping the
Streaming Replication working.

Before starting the upgrade to 9.0 on both **primary** and **secondary** nodes,
stop all service in each secondary nodes: `gitlab-ctl stop` and make a backup of
the `recovery.conf` located at: `/var/opt/gitlab/postgresql/data/recovery.conf`

Follow regular upgrade instruction for 9.0 on the primary node.

At the end of the upgrade procedures your primary node will be running with
PostgreSQL on 9.6.x branch. To prevent a desynchronization of the repository
replication, follow these steps to stop all services but the `postgresql` as
we will use it to re-initialize the secondary node's database:

**Run in the primary node:**

```
sudo gitlab-ctl stop
sudo gitlab-ctl start postgresql
```

**Run in the secondary node:**

Follow the instructions [here](https://docs.gitlab.com/ee/gitlab-geo/database.html#step-3-initiate-the-replication-process)
to Create the `replica.sh` script and execute the instructions below:

```
gitlab-ctl stop

# backup the recovery.conf from postgresql to preserv credentials
sudo cp /var/opt/gitlab/postgresql/data/recovery.conf /var/opt/gitlab

# prevent running database migrations on the secondary node:
touch /etc/gitlab/skip-auto-migrations

# let's disable the old database:
mv /var/opt/gitlab/postgresql{,.bak}

gitlab-ctl reconfigure
gitlab-ctl pg-upgrade

# see the stored credentials for the database, that you will need to re-initialize replication:
grep -s primary_conninfo /var/opt/gitlab/recovery.conf

# run the recovery script with the credentials above
bash /tmp/replica.sh
```

