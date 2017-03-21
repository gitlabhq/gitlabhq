# Updating the Geo nodes

In order to update the GitLab Geo nodes when a new GitLab version is released,
all you need to do is update GitLab itself:

1. Log into each node (primary and secondaries)
1. Upgrade GitLab
1. Test primary and secondary nodes, and check version in each.

---

For Omnibus GitLab installations it's a matter of updating the package:

```
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install gitlab-ee

# Centos/RHEL
sudo yum install gitlab-ee
```

For installations from source, [follow the instructions for your GitLab version]
(https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc/update).

# Upgrade to 9.0.x

> **IMPORTANT**: 9.0 requires manual steps in the secondary node,
because we are upgrading PostgreSQL to 9.6 on the primary and Postgres
doesn't support upgrading secondary nodes while keeping the
Streaming Replication working.

Before starting the upgrade to 9.0 on both **primary** and **secondary** nodes,
stop all service in the secondary node: `gitlab-ctl stop` and make a backup of the `recovery.conf`
located at: `/var/opt/gitlab/postgresql/data/recovery.conf`

Follow regular upgrade instruction for 9.0 on the primary node.

At the end of the upgrade procedures your primary node will be running with
PostgreSQL on 9.6.x branch. To prevent a desynchronization of the repository
replication, stop all services but the `postgresql` as we will use it to
re-initialize the secondary node's database:


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

sudo cp /var/opt/gitlab/postgresql/data/recovery.conf ~/

# prevent running database migrations on the secondary node:
touch /etc/gitlab/skip-automigrations

# we need to remove the old database:
rm -rf /var/opt/gitlab/postgresql

gitlab-ctl reconfigure
gitlab-ctl pg-upgrade

# see the stored credentials for the database, that you will need to re-initialize replication:
grep -s primary_conninfo ~/recovery.conf

# run the recovery script with the credentials above
bash /tmp/replica.sh
```

