# Updating the Geo nodes

Depending on which version of Geo you are updating to/from, there may be
different steps.

## General update steps

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

    1. **[secondary]** Make sure all services are up:

        ```
        sudo gitlab-ctl start
        ```

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

    1. **[secondary]** Create the `replica.sh` script as described in the
       [database configuration document](database.md#step-3-initiate-the-replication-process).

    1. **[secondary]** Run the recovery script using the credentials from the
       previous step:

        ```
        sudo bash /tmp/replica.sh
        ```

    1. **[secondary]** Reconfigure GitLab:

        ```
        sudo gitlab-ctl reconfigure
        ```

    1. **[secondary]** Start all services:

        ```
        sudo gitlab-ctl start
        ```

    1. **[secondary]** Repeat the steps for the rest of the secondaries.

1. **[primary]** After all secondaries are updated, start all services in
   primary:

    ```
    sudo gitlab-ctl start
    ```

## Check status after updating

Now that the update process is complete, you may want to check whether
everything is working correctly:

1. Run the Geo raketask on all nodes, everything should be green:

    ```
    sudo gitlab-rake gitlab:geo:check
    ```

1. Check the primary's Geo dashboard for any errors
1. Test the data replication by pushing code to the primary and see if it
   is received by the secondaries

## Enable tracking database

NOTE: This step is required only if you want to enable the new Disaster
Recovery feature in Alpha shipped in GitLab 9.0.

Geo secondary nodes now can keep track of replication status and recover
automatically from some replication issues. To get this feature enabled,
you need to activate the Tracking Database.

> **IMPORTANT:** For this feature to work correctly, all nodes must be
with their clocks synchronized. It is not required for all nodes to be set to
the same time zone, but when the respective times are converted to UTC time,
the clocks must be synchronized to within 60 seconds of each other.

1. Setup clock synchronization service in your Linux distro.
   This can easily be done via any NTP-compatible daemon. For example,
   here are [instructions for setting up NTP with Ubuntu](https://help.ubuntu.com/lts/serverguide/NTP.html).

1. Edit `/etc/gitlab/gitlab.rb`:

    ```
    geo_postgresql['enable'] = true
    ```

1. Create `database_geo.yml` with the information of your secondary PostgreSQL
   database.  Note that GitLab will set up another database instance separate
   from the primary, since this is where the secondary will track its internal
   state:

    ```
    sudo cp /opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml.postgresql /opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml
    ```

1. Edit the content of `database_geo.yml` in `production:` like the example below:
    
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
     port: 5431
    
   ```

1. Reconfigure GitLab:

    ```
    sudo gitlab-ctl start
    sudo gitlab-ctl reconfigure
    ```

1. Set up the Geo tracking database:

    ```
    sudo gitlab-rake geo:db:migrate
    ```

[update]: ../update/README.md
