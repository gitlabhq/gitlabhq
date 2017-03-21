# Updating the Geo nodes

In order to update the GitLab Geo nodes when a new GitLab version is released,
all you need to do is update GitLab itself:

1. Log into each node (primary and secondaries)
1. [Update GitLab][update]
1. Test primary and secondary nodes, and check version in each.

## Special update notes for 9.0.x

> **IMPORTANT**:
With GitLab 9.0, the PostgreSQL version is upgraded to 9.6 and manual steps are
required in order to update the secondary nodes and keep the Streaming
Replication working. Downtime is required, so plan ahead.

The following steps apply only if you upgrade from a 8.17 GitLab version to
9.0+. For previous versions, update to GitLab 8.17 first before attempting to
upgrade to 9.0+.

---

Make sure to follow the steps in the exact order as they appear below and pay
extra attention in what node (primary/secondary) you execute them! Each step
is prepended with the relevant node for better clarity:

1. **[secondary]** Login to **all** your secondary nodes and stop all services:

    ```ruby
    sudo gitlab-ctl stop
    ```

1. **[secondary]** Make a backup of the `recovery.conf` file on **all**
   secondary nodes to preserve PostgreSQL's credentials:

    ```
    sudo cp /var/opt/gitlab/postgresql/data/recovery.conf /var/opt/gitlab/
    ```

1. **[primary]** Update the primary node to GitLab 9.0 following the
   [regular update docs][update]. At the end of the update, the primary node
   will be running with PostgreSQL 9.6.

1. **[primary]** To prevent a de-synchronization of the repository replication,
   stop all services except `postgresql` as we will use it to re-initialize the
   secondary node's database:

    ```
    sudo gitlab-ctl stop
    sudo gitlab-ctl start postgresql
    ```

1. **[secondary]** Run the following steps on each of the secondaries:

    1. **[secondary]** Create the `replica.sh` script as described in the
       [database configuration document](database.md#step-3-initiate-the-replication-process).

    1. **[secondary]**  Stop all services:

        ```
        sudo gitlab-ctl stop
        ```

    1. **[secondary]** Prevent running database migrations:

        ```
        sudo touch /etc/gitlab/skip-auto-migrations
        ```

    1. **[secondary]** Move the old database to another directory:

        ```
        sudo mv /var/opt/gitlab/postgresql{,.bak}
        ```

    1. **[secondary]** Update to GitLab 9.0 following the [regular update docs][update].
       At the end of the update, the node will be running with PostgreSQL 9.6.

    1. **[secondary]** Reconfigure GitLab:

        ```
        sudo gitlab-ctl reconfigure
        ```

    1. **[secondary]** Run the PostgreSQL upgrade command:

          ```
          sudo gitlab-ctl pg-upgrade
          ```

    1. **[secondary]** See the stored credentials for the database that you will
       need to re-initialize the replication:

        ```
        sudo grep -s primary_conninfo /var/opt/gitlab/recovery.conf
        ```

    1. **[secondary]** Run the recovery script using the credentials from the
       previous step:

        ```
        sudo bash /tmp/replica.sh
        ```

    1. **[secondary]** Start all services:

        ```
        sudo gitlab-ctl start
        ```

    1. **[secondary]** Repeat the steps for the rest of the secondaries.

[update]: ../update/README.md
