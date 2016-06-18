# InfluxDB Configuration

The default settings provided by [InfluxDB] are not sufficient for a high traffic
GitLab environment. The settings discussed in this document are based on the
settings GitLab uses for GitLab.com, depending on your own needs you may need to
further adjust them.

If you are intending to run InfluxDB on the same server as GitLab, make sure
you have plenty of RAM since InfluxDB can use quite a bit depending on traffic.

Unless you are going with a budget setup, it's advised to run it separately.

## Requirements

- InfluxDB 0.9.5 or newer
- A fairly modern version of Linux
- At least 4GB of RAM
- At least 10GB of storage for InfluxDB data

Note that the RAM and storage requirements can differ greatly depending on the
amount of data received/stored. To limit the amount of stored data users can
look into [InfluxDB Retention Policies][influxdb-retention].

## Installation

Installing InfluxDB is out of the scope of this document. Please refer to the
[InfluxDB documentation].

## InfluxDB Server Settings

Since InfluxDB has many settings that users may wish to customize themselves
(e.g. what port to run InfluxDB on), we'll only cover the essentials.

The configuration file in question is usually located at
`/etc/influxdb/influxdb.conf`. Whenever you make a change in this file,
InfluxDB needs to be restarted.

### Storage Engine

InfluxDB comes with different storage engines and as of InfluxDB 0.9.5 a new
storage engine is available, called [TSM Tree]. All users **must** use the new
`tsm1` storage engine as this [will be the default engine][tsm1-commit] in
upcoming InfluxDB releases.

Make sure you have the following in your configuration file:

```
[data]
  dir = "/var/lib/influxdb/data"
  engine = "tsm1"
```

### Admin Panel

Production environments should have the InfluxDB admin panel **disabled**. This
feature can be disabled by adding the following to your InfluxDB configuration
file:

```
[admin]
  enabled = false
```

### HTTP

HTTP is required when using the [InfluxDB CLI] or other tools such as Grafana,
thus it should be enabled. When enabling make sure to _also_ enable
authentication:

```
[http]
  enabled = true
  auth-enabled = true
```

_**Note:** Before you enable authentication, you might want to [create an
admin user](#create-a-new-admin-user)._

### UDP

GitLab writes data to InfluxDB via UDP and thus this must be enabled. Enabling
UDP can be done using the following settings:

```
[[udp]]
  enabled = true
  bind-address = ":8089"
  database = "gitlab"
  batch-size = 1000
  batch-pending = 5
  batch-timeout = "1s"
  read-buffer = 209715200
```

This does the following:

1. Enable UDP and bind it to port 8089 for all addresses.
2. Store any data received in the "gitlab" database.
3. Define a batch of points to be 1000 points in size and allow a maximum of
   5 batches _or_ flush them automatically after 1 second.
4. Define a UDP read buffer size of 200 MB.

One of the most important settings here is the UDP read buffer size as if this
value is set too low, packets will be dropped. You must also make sure the OS
buffer size is set to the same value, the default value is almost never enough.

To set the OS buffer size to 200 MB, on Linux you can run the following command:

```bash
sysctl -w net.core.rmem_max=209715200
```

To make this permanent, add the following to `/etc/sysctl.conf` and restart the
server:

```bash
net.core.rmem_max=209715200
```

It is **very important** to make sure the buffer sizes are large enough to
handle all data sent to InfluxDB as otherwise you _will_ lose data. The above
buffer sizes are based on the traffic for GitLab.com. Depending on the amount of
traffic, users may be able to use a smaller buffer size, but we highly recommend
using _at least_ 100 MB.

When enabling UDP, users should take care to not expose the port to the public,
as doing so will allow anybody to write data into your InfluxDB database (as
[InfluxDB's UDP protocol][udp] doesn't support authentication). We recommend either
whitelisting the allowed IP addresses/ranges, or setting up a VLAN and only
allowing traffic from members of said VLAN.

## Create a new admin user

If you want to [enable authentication](#http), you might want to [create an
admin user][influx-admin]:

```
influx -execute "CREATE USER jeff WITH PASSWORD '1234' WITH ALL PRIVILEGES"
```

## Create the `gitlab` database

Once you get InfluxDB up and running, you need to create a database for GitLab.
Make sure you have changed the [storage engine](#storage-engine) to `tsm1`
before creating a database.

_**Note:** If you [created an admin user](#create-a-new-admin-user) and enabled
[HTTP authentication](#http), remember to append the username (`-username <username>`)
and password (`-password <password>`)  you set earlier to the commands below._

Run the following command to create a database named `gitlab`:

```bash
influx -execute 'CREATE DATABASE gitlab'
```

The name **must** be `gitlab`, do not use any other name.

Next, make sure that the database was successfully created:

```bash
influx -execute 'SHOW DATABASES'
```

The output should be similar to:

```
name: databases
---------------
name
_internal
gitlab
```

That's it! Now your GitLab instance should send data to InfluxDB.

---

Read more on:

- [Introduction to GitLab Performance Monitoring](introduction.md)
- [GitLab Configuration](gitlab_configuration.md)
- [InfluxDB Schema](influxdb_schema.md)
- [Grafana Install/Configuration](grafana_configuration.md)

[influxdb-retention]: https://docs.influxdata.com/influxdb/v0.9/query_language/database_management/#retention-policy-management
[influxdb documentation]: https://docs.influxdata.com/influxdb/v0.9/
[influxdb cli]: https://docs.influxdata.com/influxdb/v0.9/tools/shell/
[udp]: https://docs.influxdata.com/influxdb/v0.9/write_protocols/udp/
[influxdb]: https://influxdata.com/time-series-platform/influxdb/
[tsm tree]: https://influxdata.com/blog/new-storage-engine-time-structured-merge-tree/
[tsm1-commit]: https://github.com/influxdata/influxdb/commit/15d723dc77651bac83e09e2b1c94be480966cb0d
[influx-admin]: https://docs.influxdata.com/influxdb/v0.9/administration/authentication_and_authorization/#create-a-new-admin-user
