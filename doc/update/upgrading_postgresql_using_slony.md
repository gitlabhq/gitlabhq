---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Upgrading PostgreSQL Using Slony **(FREE SELF)**

This guide describes the steps one can take to upgrade their PostgreSQL database
to the latest version without the need for hours of downtime. This guide assumes
you have two database servers: one database server running an older version of
PostgreSQL (e.g. 9.2.18) and one server running a newer version (e.g. 9.6.0).

For this process we use a PostgreSQL replication tool called
["Slony"](https://www.slony.info/). Slony allows replication between different
PostgreSQL versions and as such can be used to upgrade a cluster with a minimal
amount of downtime.

In various places we refer to the user `gitlab-psql`. This user should be the
user used to run the various PostgreSQL OS processes. If you're using a
different user (e.g. `postgres`) you should replace `gitlab-psql` with the name
of said user. This guide also assumes your database is called
`gitlabhq_production`. If you happen to use a different database name you should
change this accordingly.

## Database Dumps

Slony only replicates data and not any schema changes. As a result we must
ensure that all databases have the same database structure.

To do so, generate a dump of the current database. This dump only
contains the structure, not any data. To generate this dump run the following
command on your active database server:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_dump -h /var/opt/gitlab/postgresql -p 5432 -U gitlab-psql -s -f /tmp/structure.sql gitlabhq_production
```

If you're not using the Omnibus GitLab package you may have to adjust the paths to
`pg_dump` and the PostgreSQL installation directory to match the paths of your
configuration.

After the structure dump is generated we also need to generate a dump for the
`schema_migrations` table. This table doesn't have any primary keys and as such
can't be replicated easily by Slony. To generate this dump run the following
command on your active database server:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_dump -h /var/opt/gitlab/postgresql/ -p 5432 -U gitlab-psql -a -t schema_migrations -f /tmp/migrations.sql gitlabhq_production
```

Next, move these files somewhere accessible by the new database
server. The easiest way is to download these files to your local system:

```shell
scp your-user@production-database-host:/tmp/*.sql /tmp
```

This copies all the SQL files located in `/tmp` to your local system's
`/tmp` directory. Once copied you can safely remove the files from the database
server.

## Installing Slony

Use Slony to upgrade the database without requiring a long downtime.
Slony can be downloaded from <https://www.slony.info/>. If you have installed
PostgreSQL using your operating system's package manager you may also be able to
install Slony using said package manager.

When compiling Slony from source you *must* use the following commands to do so:

```shell
./configure --prefix=/path/to/installation/directory --with-perltools --with-pgconfigdir=/path/to/directory/containing/pg_config/bin
make
make install
```

Omnibus users can use the following commands:

```shell
./configure --prefix=/opt/gitlab/embedded --with-perltools --with-pgconfigdir=/opt/gitlab/embedded/bin
make
make install
```

This assumes you have installed GitLab into `/opt/gitlab`.

To test if Slony is installed properly, run the following commands:

```shell
test -f /opt/gitlab/embedded/bin/slonik && echo 'Slony installed' || echo 'Slony not installed'
test -f /opt/gitlab/embedded/bin/slonik_init_cluster && echo 'Slony Perl tools are available' || echo 'Slony Perl tools are not available'
/opt/gitlab/embedded/bin/slonik -v
```

This assumes Slony was installed to `/opt/gitlab/embedded`. If Slony was
installed properly the output of these commands is (the mentioned `slonik`
version may be different):

```plaintext
Slony installed
Slony Perl tools are available
slonik version 2.2.5
```

## Slony User

Next we must set up a PostgreSQL user that Slony can use to replicate your
database. To do so, sign in to your production database using `psql` using a
super-user account. After signing in, run the following SQL queries:

```sql
CREATE ROLE slony WITH SUPERUSER LOGIN REPLICATION ENCRYPTED PASSWORD 'password string here';
ALTER ROLE slony SET statement_timeout TO 0;
```

Make sure you replace "password string here" with the actual password for the
user. A password is required. This user must be created on both the old and
new database server using the same password.

After creating the user, be sure to note the password, as the password is needed
later.

## Configuring Slony

We can now start configuring Slony. Slony uses a configuration file for
most of the work so we need to set this one up. This configuration file
specifies where to put log files, how Slony should connect to the databases,
etc.

First, create some required directories and set the correct
permissions. To do so, run the following commands on both the old and new
database server:

```shell
sudo mkdir -p /var/log/gitlab/slony /var/run/slony1 /var/opt/gitlab/postgresql/slony
sudo chown gitlab-psql:root /var/log/gitlab/slony /var/run/slony1 /var/opt/gitlab/postgresql/slony
```

Here `gitlab-psql` is the user used to run the PostgreSQL database processes. If
you're using a different user you should replace this with the name of said
user.

Now that the directories are in place we can create the configuration file. For
this we can use the following template:

```perl
if ($ENV{"SLONYNODES"}) {
    require $ENV{"SLONYNODES"};
} else {
    $CLUSTER_NAME = 'slony_replication';
    $LOGDIR = '/var/log/gitlab/slony';
    $MASTERNODE = 1;
    $DEBUGLEVEL = 2;

    add_node(host => 'OLD_HOST', dbname => 'gitlabhq_production', port =>5432,
        user=>'slony', password=>'SLONY_PASSWORD', node=>1);

    add_node(host => 'NEW_HOST', dbname => 'gitlabhq_production', port =>5432,
        user=>'slony', password=>'SLONY_PASSWORD', node=>2, parent=>1 );
}

$SLONY_SETS = {
    "set1" => {
        "set_id"       => 1,
        "table_id"     => 1,
        "sequence_id"  => 1,
        "pkeyedtables" => [
            TABLES
        ],
    },
};

if ($ENV{"SLONYSET"}) {
    require $ENV{"SLONYSET"};
}

# Please do not add or change anything below this point.
1;
```

In this configuration file you should replace a few placeholders before you can
use it. The following placeholders should be replaced:

- `OLD_HOST`: the address of the old database server.
- `NEW_HOST`: the address of the new database server.
- `SLONY_PASSWORD`: the password of the Slony user created earlier.
- `TABLES`: the tables to replicate.

The list of tables to replicate can be generated by running the following
command on your old PostgreSQL database:

```shell
sudo gitlab-psql gitlabhq_production -c "select concat('\"', schemaname, '.', tablename, '\",') from pg_catalog.pg_tables where schemaname = 'public' and tableowner = 'gitlab' and tablename != 'schema_migrations' order by tablename asc;" -t
```

If you're not using Omnibus you should replace `gitlab-psql` with the
appropriate path to the `psql` executable.

The above command outputs a list of tables in a format that can be copy-pasted
directly into the above configuration file. Make sure to _replace_ `TABLES` with
this output, don't just append it below it. The result looks like this:

```perl
"pkeyedtables" => [
    "public.abuse_reports",
    "public.appearances",
    "public.application_settings",
    ... more rows here ...
]
```

After you have the configuration file generated you must install it on both the
old and new database. To do so, place it in
`/var/opt/gitlab/postgresql/slony/slon_tools.conf` (for which we created the
directory earlier on).

Now that the configuration file is in place we can _finally_ start replicating
our database. First we must set up the schema in our new database. To do so make
sure that the SQL files we generated earlier can be found in the `/tmp`
directory of the new server. After these files are in place start a `psql`
session on this server:

```shell
sudo gitlab-psql gitlabhq_production
```

Now run the following commands:

```plaintext
\i /tmp/structure.sql
\i /tmp/migrations.sql
```

To verify if the structure is in place close the session, start it again, then
run `\d`. If all went well you should see output along the lines of the
following:

```plaintext
                               List of relations
 Schema |                    Name                     |   Type   |    Owner
--------+---------------------------------------------+----------+-------------
 public | abuse_reports                               | table    | gitlab
 public | abuse_reports_id_seq                        | sequence | gitlab
 public | appearances                                 | table    | gitlab
 public | appearances_id_seq                          | sequence | gitlab
 public | application_settings                        | table    | gitlab
 public | application_settings_id_seq                 | sequence | gitlab
 public | approvals                                   | table    | gitlab
 ... more rows here ...
```

Now we can initialize the required tables and what not that Slony uses for
its replication process. To do so, run the following on the old database:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/slonik_init_cluster --conf /var/opt/gitlab/postgresql/slony/slon_tools.conf | /opt/gitlab/embedded/bin/slonik
```

If all went well this produces something along the lines of:

```plaintext
<stdin>:10: Set up replication nodes
<stdin>:13: Next: configure paths for each node/origin
<stdin>:16: Replication nodes prepared
<stdin>:17: Please start a slon replication daemon for each node
```

Next we need to start a replication node on every server. To do so, run the
following on the old database:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/slon_start 1 --conf /var/opt/gitlab/postgresql/slony/slon_tools.conf
```

If all went well this produces output such as:

```plaintext
Invoke slon for node 1 - /opt/gitlab/embedded/bin/slon -p /var/run/slony1/slony_replication_node1.pid -s 1000 -d2  slony_replication 'host=192.168.0.7 dbname=gitlabhq_production user=slony port=5432 password=hieng8ezohHuCeiqu0leeghai4aeyahp' > /var/log/gitlab/slony/node1/gitlabhq_production-2016-10-06.log 2>&1 &
Slon successfully started for cluster slony_replication, node node1
PID [26740]
Start the watchdog process as well...
```

Next we need to run the following command on the _new_ database server:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/slon_start 2 --conf /var/opt/gitlab/postgresql/slony/slon_tools.conf
```

This produces similar output if all went well.

Next we need to tell the new database server what it should replicate. This can
be done by running the following command on the _new_ database server:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/slonik_create_set 1 --conf /var/opt/gitlab/postgresql/slony/slon_tools.conf | /opt/gitlab/embedded/bin/slonik
```

This should produce output along the lines of the following:

```plaintext
<stdin>:11: Subscription set 1 (set1) created
<stdin>:12: Adding tables to the subscription set
<stdin>:16: Add primary keyed table public.abuse_reports
<stdin>:20: Add primary keyed table public.appearances
<stdin>:24: Add primary keyed table public.application_settings
... more rows here ...
<stdin>:327: Adding sequences to the subscription set
<stdin>:328: All tables added
```

Finally we can start the replication process by running the following on the
_new_ database server:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/slonik_subscribe_set 1 2 --conf /var/opt/gitlab/postgresql/slony/slon_tools.conf | /opt/gitlab/embedded/bin/slonik
```

This should produce the following output:

```plaintext
<stdin>:6: Subscribed nodes to set 1
```

At this point the new database server starts replicating the data of the old
database server. This process can take anywhere from a few minutes to hours, if
not days. Unfortunately Slony itself doesn't really provide a way of knowing
when the two databases are in sync. To get an estimate of the progress you can
use the following shell script:

```shell
#!/usr/bin/env bash

set -e

user='slony'
pass='SLONY_PASSWORD'

function main {
    while :
    do
        local source
        local target

        source=$(PGUSER="${user}" PGPASSWORD="${pass}" /opt/gitlab/embedded/bin/psql -h OLD_HOST gitlabhq_production -c "select pg_size_pretty(pg_database_size('gitlabhq_production'));" -t -A)
        target=$(PGUSER="${user}" PGPASSWORD="${pass}" /opt/gitlab/embedded/bin/psql -h NEW_HOST gitlabhq_production -c "select pg_size_pretty(pg_database_size('gitlabhq_production'));" -t -A)

        echo "$(date): ${target} of ${source}" >> progress.log
        echo "$(date): ${target} of ${source}"

        sleep 60
    done
}

main
```

This script compares the sizes of the old and new database every minute and
print the result to STDOUT as well as logging it to a file. Make sure to replace
`SLONY_PASSWORD`, `OLD_HOST`, and `NEW_HOST` with the correct values.

## Stopping Replication

At some point, the two databases are in sync. If this is the case, you must plan
for a few minutes of downtime. This small downtime window is used to stop the
replication process, remove any Slony data from both databases, and restart
GitLab so it can use the new database.

First, let's stop all of GitLab. Omnibus users can do so by running the
following on their GitLab servers:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop mailroom
```

If you have any other processes that use PostgreSQL, you should also stop those.

After everything has been stopped, be sure to update any configuration settings
and DNS records so they all point to the new database.

When the settings have been taken care of, we need to stop the replication
process. It's crucial that no new data is written to the databases at this point,
as this data is discarded.

To stop replication, run the following on both database servers:

```shell
sudo -u gitlab-psql /opt/gitlab/embedded/bin/slon_kill --conf /var/opt/gitlab/postgresql/slony/slon_tools.conf
```

This stops all the Slony processes on the host the command was executed on.

## Resetting Sequences

The above setup does not replicate database sequences, as such these must be
reset manually in the target database. You can use the following script for
this:

```shell
#!/usr/bin/env bash
set -e

function main {
    local fix_sequences
    local fix_owners

    fix_sequences='/tmp/fix_sequences.sql'
    fix_owners='/tmp/fix_owners.sql'

    # The SQL queries were taken from
    # https://wiki.postgresql.org/wiki/Fixing_Sequences
    sudo gitlab-psql gitlabhq_production -t -c "
    SELECT 'ALTER SEQUENCE '|| quote_ident(MIN(schema_name)) ||'.'|| quote_ident(MIN(seq_name))
           ||' OWNED BY '|| quote_ident(MIN(TABLE_NAME)) ||'.'|| quote_ident(MIN(column_name)) ||';'
    FROM (
        SELECT
            n.nspname AS schema_name,
            c.relname AS TABLE_NAME,
            a.attname AS column_name,
            SUBSTRING(d.adsrc FROM E'^nextval\\(''([^'']*)''(?:::text|::regclass)?\\)') AS seq_name
        FROM pg_class c
        JOIN pg_attribute a ON (c.oid=a.attrelid)
        JOIN pg_attrdef d ON (a.attrelid=d.adrelid AND a.attnum=d.adnum)
        JOIN pg_namespace n ON (c.relnamespace=n.oid)
        WHERE has_schema_privilege(n.oid,'USAGE')
          AND n.nspname NOT LIKE 'pg!_%' escape '!'
          AND has_table_privilege(c.oid,'SELECT')
          AND (NOT a.attisdropped)
          AND d.adsrc ~ '^nextval'
    ) seq
    GROUP BY seq_name HAVING COUNT(*)=1;
    " > "${fix_owners}"

    sudo gitlab-psql gitlabhq_production -t -c "
    SELECT 'SELECT SETVAL(' ||
           quote_literal(quote_ident(PGT.schemaname) || '.' || quote_ident(S.relname)) ||
           ', COALESCE(MAX(' ||quote_ident(C.attname)|| '), 1) ) FROM ' ||
           quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ';'
    FROM pg_class AS S,
         pg_depend AS D,
         pg_class AS T,
         pg_attribute AS C,
         pg_tables AS PGT
    WHERE S.relkind = 'S'
        AND S.oid = D.objid
        AND D.refobjid = T.oid
        AND D.refobjid = C.attrelid
        AND D.refobjsubid = C.attnum
        AND T.relname = PGT.tablename
    ORDER BY S.relname;
    " > "${fix_sequences}"

    sudo gitlab-psql gitlabhq_production -f "${fix_owners}"
    sudo gitlab-psql gitlabhq_production -f "${fix_sequences}"

    rm "${fix_owners}" "${fix_sequences}"
}

main
```

Upload this script to the _target_ server and execute it as follows:

```shell
bash path/to/the/script/above.sh
```

This corrects the ownership of sequences and reset the next value for the
`id` column to the next available value.

## Removing Slony

Next we need to remove all Slony related data. To do so, run the following
command on the _target_ server:

```shell
sudo gitlab-psql gitlabhq_production -c "DROP SCHEMA _slony_replication CASCADE;"
```

Once done you can safely remove any Slony related files (e.g. the log
directory), and uninstall Slony if desired. At this point you can start your
GitLab instance again and if all went well it should be using your new database
server.
