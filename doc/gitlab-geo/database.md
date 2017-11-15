# GitLab Geo database replication

>**Note:**
This is the documentation for the Omnibus GitLab packages. For installations
from source, follow the
[**database replication for installations from source**](database_source.md) guide.

>**Note:**
Stages of the setup process must be completed in the documented order.
Before attempting the steps in this stage, complete all prior stages.

1. [Install GitLab Enterprise Edition][install-ee] on the server that will serve
   as the **secondary** Geo node. Do not login or set up anything else in the
   secondary node for the moment.
1. [Upload the GitLab License](../user/admin_area/license.md) to the **primary** Geo Node to unlock GitLab Geo.
1. **Setup the database replication** (`primary (read-write) <-> secondary (read-only)` topology).
1. [Configure SSH authorizations to use the database](ssh.md)
1. [Configure GitLab](configuration.md) to set the primary and secondary nodes.
1. Optional: [Configure a secondary LDAP server](../administration/auth/ldap.md) for the secondary. See [notes on LDAP](#ldap).
1. [Follow the after setup steps](after_setup.md).

[install-ee]: https://about.gitlab.com/downloads-ee/ "GitLab Enterprise Edition Omnibus packages downloads page"

This document describes the minimal steps you have to take in order to
replicate your GitLab database into another server. You may have to change
some values according to your database setup, how big it is, etc.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

## PostgreSQL replication

The GitLab primary node where the write operations happen will connect to
primary database server, and the secondary ones which are read-only will
connect to secondary database servers (which are read-only too).

>**Note:**
In many databases documentation you will see "primary" being referenced as "master"
and "secondary" as either "slave" or "standby" server (read-only).

Since GitLab 9.4: We recommend using [PostgreSQL replication
slots](https://medium.com/@tk512/replication-slots-in-postgresql-b4b03d277c75)
to ensure the primary retains all the data necessary for the secondaries to
recover. See below for more details.

### Prerequisites

The following guide assumes that:

- You are using PostgreSQL 9.6 or later which includes the
  [`pg_basebackup` tool][pgback]. If you are using Omnibus it includes the required
  PostgreSQL version for Geo.
- You have a primary server already set up (the GitLab server you are
  replicating from), running Omnibus' PostgreSQL (or equivalent version), and you
  have a new secondary server set up on the same OS and PostgreSQL version. Also
  make sure the GitLab version is the same on all nodes.
- The IP of the primary server for our examples will be `1.2.3.4`, whereas the
  secondary's IP will be `5.6.7.8`. Note that the primary and secondary servers
  **must** be able to communicate over these addresses (using HTTPS & SSH).
  These IP addresses can either be public or private.

### Step 1. Configure the primary server

1. SSH into your GitLab **primary** server and login as root:

    ```
    sudo -i
    ```

1. Execute the command below to define the node as primary Geo node:

    ```
    gitlab-ctl set-geo-primary-node
    ```

    This command will use your defined `external_url` in `/etc/gitlab/gitlab.rb`.

1. Omnibus GitLab has already a replication user called `gitlab_replicator`.
   You must set its password manually. You will be prompted to enter a
   password:

    ```bash
      gitlab-ctl set-replication-password
    ```

   This command will also read `postgresql['sql_replication_user']` Omnibus
   setting in case you have changed `gitlab_replicator` username to something
   else.

1. Set up TLS support for the PostgreSQL primary server
    > **Warning**: Only skip this step if you **know** that PostgreSQL traffic
    > between the primary and secondary will be secured through some other
    > means, e.g., a known-safe physical network path or a site-to-site VPN that
    > you have configured.

    If you are replicating your database across the open Internet, it is
    **essential** that the connection is TLS-secured. Correctly configured, this
    provides protection against both passive eavesdroppers and active
    "man-in-the-middle" attackers.

    To do this, PostgreSQL needs to be provided with a key and certificate to
    use. You can re-use the same files you're using for your main GitLab
    instance, or generate a self-signed certificate just for PostgreSQL's use.

    Prefer the first option if you already have a long-lived certificate. Prefer
    the second if your certificates expire regularly (e.g. LetsEncrypt), or if
    PostgreSQL is running on a different server to the main GitLab services
    (this may be the case in a HA configuration, for instance).

    To generate a self-signed certificate and key, run this command:

    ```bash
    openssl req -nodes -batch -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 3650
    ```

    This will create two files - `server.key` and `server.crt` - that you can
    use for authentication.

    PostgreSQL's permission requirements are very strict, so whether you're
    re-using your certificates or just generated new ones, **copy** the files
    to the correct location.

    If you're re-using certificates already in GitLab, they are likely to be in
    the `/etc/gitlab/ssl` directory. If your domain is `primary.geo.example.com`,
    the commands would be:

    ```bash
    # Copying a certificate and key currently used by GitLab
    install -o gitlab-psql -g gitlab-psql -m 0400 -T /etc/gitlab/ssl/primary.geo.example.com.crt ~gitlab-psql/data/server.crt
    install -o gitlab-psql -g gitlab-psql -m 0400 -T /etc/gitlab/ssl/primary.geo.example.com.key ~gitlab-psql/data/server.key
    ```

    If you just generated a self-signed certificate and key, the files will be
    in your current working directory, so run:

    ```bash
    # Copying a self-signed certificate and key
    install -o gitlab-psql -g gitlab-psql -m 0400 -T server.crt ~gitlab-psql/data/server.crt
    install -o gitlab-psql -g gitlab-psql -m 0400 -T server.key ~gitlab-psql/data/server.key
    ```

    Add this configuration to `/etc/gitlab/gitlab.rb`. Additional options are
    documented [here](http://docs.gitlab.com/omnibus/settings/database.html#enabling-ssl).

    ```ruby
    postgresql['ssl'] = 'on'
    ```

1. Configure PostgreSQL to listen on an external network interface

    Edit `/etc/gitlab/gitlab.rb` and add the following. Note that GitLab 9.1 added
    the `geo_primary_role` configuration variable:

    ```ruby
    geo_primary_role['enable'] = true
    postgresql['listen_address'] = "1.2.3.4"
    postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/32','1.2.3.4/32']
    postgresql['md5_auth_cidr_addresses'] = ['5.6.7.8/32']
    # New for 9.4: Set this to be the number of Geo secondary nodes you have
    postgresql['max_replication_slots'] = 1
    # postgresql['max_wal_senders'] = 10
    # postgresql['wal_keep_segments'] = 10
    ```

    Where `1.2.3.4` is the IP address of the primary server, and `5.6.7.8`
    is the IP address of the secondary one.

    For security reasons, PostgreSQL by default only listens on the local
    interface (e.g. 127.0.0.1). However, GitLab Geo needs to communicate
    between the primary and secondary nodes over a common network, such as a
    corporate LAN or the public Internet. For this reason, we need to
    configure PostgreSQL to listen on more interfaces.

    The `listen_address` option opens PostgreSQL up to external connections
    with the interface corresponding to the given IP. See [the PostgreSQL
    documentation](https://www.postgresql.org/docs/9.6/static/runtime-config-connection.html)
    for more details.

    Note that if you are running GitLab Geo with a cloud provider (e.g. Amazon
    Web Services), the internal interface IP (as provided by `ifconfig`) may
    be different from the public IP address. For example, suppose you have a
    nodes with the following configuration:

    |Node Type|Internal IP|External IP|
    |---------|-----------|-----------|
    |Primary|10.1.5.3|54.193.124.100|
    |Secondary|10.1.10.5|54.193.100.155|

    If you are running two nodes in different cloud availability zones, you
    may need to double check that the nodes can communicate over the internal
    IP addresses. For example, servers on Amazon Web Services in the same
    [Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/) can do
    this. Google Compute Engine also offers an [internal network]
    (https://cloud.google.com/compute/docs/networking) that supports
    cross-availability zone networking.

    For the above example, the following configuration uses the internal IPs
    to replicate the database from the primary to the secondary:

    ```ruby
    # Example configuration using internal IPs for a cloud configuration
    geo_primary_role['enable'] = true
    postgresql['listen_address'] = "10.1.5.3"
    postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/32','10.1.5.3/32']
    postgresql['md5_auth_cidr_addresses'] = ['10.1.10.5/32']
    postgresql['max_replication_slots'] = 1 # Number of Geo secondary nodes
    # postgresql['max_wal_senders'] = 10
    # postgresql['wal_keep_segments'] = 10
    ```

    If you prefer that your nodes communicate over the public Internet, you
    may choose the IP addresses from the "External IP" column above.

1.  Optional: If you want to add another secondary, the relevant setting would look like:

    ```ruby
    postgresql['md5_auth_cidr_addresses'] = ['5.6.7.8/32','11.22.33.44/32']
    ```

    You may also want to edit the `wal_keep_segments` and `max_wal_senders` to
    match your database replication requirements. Consult the [PostgreSQL - Replication documentation](https://www.postgresql.org/docs/9.6/static/runtime-config-replication.html)
    for more information.

1. Check to make sure your firewall rules are set so that the secondary nodes
   can access port 5432 on the primary node.
1. Save the file and [reconfigure GitLab][] for the DB listen changes to take effect.
   This will fail and is expected.
1. You will need to manually restart postgres `gitlab-ctl restart postgresql` until [Omnibus#2797](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2797) gets fixed.
1. You should now reconfigure again, and it should complete cleanly.
1. New for 9.4: Restart your primary PostgreSQL server to ensure the replication slot changes
   take effect (`sudo gitlab-ctl restart postgresql` for Omnibus-provided PostgreSQL).
1. Now that the PostgreSQL server is set up to accept remote connections, run
   `netstat -plnt` to make sure that PostgreSQL is listening to the server's
   public IP.

### Step 2. Add the secondary GitLab node

To prevent the secondary geo node trying to act as the primary once the
database is replicated, the secondary geo node must be configured on the
primary before the database is replicated.

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes**
   (`/admin/geo_nodes`) in your browser.
1. Add the secondary node by providing its full URL. **Do NOT** check the box
   'This is a primary node'.
1. Added in GitLab 9.5: Choose which namespaces should be replicated by the
   secondary node. Leave blank to replicate all. Read more in
   [selective replication](#selective-replication).
1. Click the **Add node** button.

### Step 3. Configure the secondary server

1. SSH into your GitLab **secondary** server and login as root:

    ```
    sudo -i
    ```

1. Set up PostgreSQL TLS verification on the secondary
    If you configured PostgreSQL to accept TLS connections in
    [Step 1](#step-1-configure-the-primary-server), then you need to provide a
    list of "known-good" certificates to the secondary. It uses this list to
    keep the connection secure against an active "man-in-the-middle" attack.

    If you reused your existing certificates on the primary, you can use the
    list of valid root certificates provided with omnibus:

    ```bash
    mkdir -p ~gitlab-psql/.postgresql
    ln -s /opt/gitlab/embedded/ssl/certs/cacert.pem ~gitlab-psql/.postgresql/root.crt
    ```

    If you generated a self-signed certificate, that won't work. Copy the
    generated `server.crt` file onto the secondary server from the primary, then
    install it in the right place:

    ```bash
    install -o gitlab-psql -g gitlab-psql -m 0400 -T server.crt ~gitlab-psql/.postgresql/root.crt
    ```

    PostgreSQL will now only recognize that exact certificate when verifying TLS
    connections.


1. Test that the remote connection to the primary server works.

    If you're using a CA-issued certificate and connecting by FQDN:

     ```
     sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h primary.geo.example.com -U gitlab_replicator -d "dbname=gitlabhq_production sslmode=verify-ca" -W
     ```

     If you're using a self-signed certificate or connecting by IP address:

     ```
     sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h 1.2.3.4 -U gitlab_replicator -d "dbname=gitlabhq_production sslmode=verify-full" -W
     ```

    When prompted enter the password you set in the first step for the
    `gitlab_replicator` user. If all worked correctly, you should see the
    database prompt.

1. Exit the PostgreSQL console:

    ```
    \q
    ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    geo_secondary_role['enable'] = true
    ```

1. [Reconfigure GitLab][] for the changes to take effect.

1. Setup clock synchronization service in your Linux distro.
   This can easily be done via any NTP-compatible daemon. For example,
   here are [instructions for setting up NTP with Ubuntu](https://help.ubuntu.com/lts/serverguide/NTP.html).

    **IMPORTANT:** For Geo to work correctly, all nodes must be with their
    clocks synchronized. It is not required for all nodes to be set to the
    same time zone, but when the respective times are converted to UTC time,
    the clocks must be synchronized to within 60 seconds of each other.

### Step 4. Initiate the replication process

Below we provide a script that connects to the primary server, replicates the
database and creates the needed files for replication.

The directories used are the defaults that are set up in Omnibus. If you have
changed any defaults or are using a source installation, configure it as you
see fit replacing the directories and paths.

>**Warning:**
Make sure to run this on the **secondary** server as it removes all PostgreSQL's
data before running `pg_basebackup`.

1. SSH into your GitLab **secondary** server and login as root:

    ```
    sudo -i
    ```

1. New for 9.4: Choose a database-friendly name to use for your secondary to use as the
   replication slot name. For example, if your domain is
   `geo-secondary.mydomain.com`, you may use `geo_secondary_my_domain_com` as
   the slot name.

1. Execute the command below to start a backup/restore and begin the replication:

    ```
    gitlab-ctl replicate-geo-database --host=geo.primary.my.domain.com --slot-name=geo_secondary_my_domain_com
    ```

    If PostgreSQL is listening on a non-standard port, add `--port=` as well.

    If you have to connect to a specific IP address, rather than the FQDN of the
    primary, to reach your PostgreSQL server, then you should pass
    `--sslmode=verify-ca` as well. This should **only** be the case if you have
    also used a self-signed certificate. `verify-ca` is **not** safe if you are
    connecting to an IP address and re-using an existing TLS certificate!

    Pass `--sslmode=prefer` if you are happy to skip PostgreSQL TLS
    authentication altogether (e.g., you know the network path is secure, or you
    are using a site-to-site VPN).

    You can read more details about each `sslmode` in the
    [PostgreSQL documentation](https://www.postgresql.org/docs/9.6/static/libpq-ssl.html#LIBPQ-SSL-PROTECTION);
    the instructions above are carefully written to ensure protection against
    both passive eavesdroppers and active "man-in-the-middle" attackers.

    When prompted, enter the password you set up for the `gitlab_replicator`
    user in the first step.

    New for 9.4: Change the `--slot-name` to the name of the replication slot
    to be used on the primary database. The script will attempt to create the
    replication slot automatically if it does not exist.

    This command also takes a number of additional options. You can use `--help`
    to list them all, but here are a couple of tips:

    If you're setting up replication on a brand-new secondary that has no data,
    you may want to pass `--no-wait --skip-backup` to speed up the process - but
    be **certain** that you're running it against the right GitLab installation
    first! It **will** cause data loss otherwise.

    If you're repurposing an old server into a Geo secondary, you'll need to
    add `--force` to the command line.

The replication process is now over.

### Next steps

Now that the database replication is done, the next step is to configure GitLab.

[➤ GitLab Geo configuration](configuration.md)

## MySQL replication

We don't support MySQL replication for GitLab Geo.

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).

[pgback]: http://www.postgresql.org/docs/9.2/static/app-pgbasebackup.html
[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
