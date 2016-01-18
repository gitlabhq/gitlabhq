# InfluxDB Configuration

The default settings provided by InfluxDB are not sufficient for a high traffic
GitLab environment. The settings discussed in this document are based on the
settings GitLab uses for GitLab.com, depending on your own needs you may need to
further adjust them.

## Requirements

* InfluxDB 0.9 or newer
* A fairly modern version of Linux
* At least 4GB of RAM
* At least 10GB of storage for InfluxDB data

Note that the RAM and storage requirements can differ greatly depending on the
amount of data received/stored. To limit the amount of stored data users can
look into [InfluxDB Retention Policies][influxdb-retention].

## InfluxDB Server Settings

Since InfluxDB has many settings that users may wish to customize themselves
(e.g. what port to run InfluxDB on) we'll only cover the essentials.

### Storage Engine

InfluxDB comes with different storage engines and as of InfluxDB 0.9 a new
storage engine is available called "tsm1". All users _must_ use the new tsm1
storage engine (this will be the default engine in upcoming InfluxDB engines).

### Admin Panel

Production environments should have the InfluxDB admin panel _disabled_. This
feature can be disabled by adding the following to your InfluxDB configuration
file:

    [admin]
      enabled = false

### HTTP

HTTP is required when using the InfluxDB CLI or other tools such as Grafana,
thus it should be enabled. When enabling make sure to _also_ enable
authentication:

    [http]
      enabled = true
      auth-enabled = true

### UDP

GitLab writes data to InfluxDB via UDP and thus this must be enabled. Enabling
UDP can be done using the following settings:

    [udp]
      enabled = true
      bind-address = ":8089"
      database = "gitlab"
      batch-size = 1000
      batch-pending = 5
      batch-timeout = 1s
      read-buffer = 209715200

This does the following:

1. Enable UDP and bind it to port 8089 for all addresses.
2. Store any data received in the "gitlab" database.
3. Define a batch of points to be 1000 points in size and allow a maximum of
   5 batches _or_ flush them automatically after 1 second.
4. Define a UDP read buffer size of 200 MB.

One of the most important settings here is the UDP read buffer size as if this
value is set too low packets will be dropped. You must also make sure the OS
buffer size is set to the same value, the default value is almost never enough.

To set the OS buffer size to 200 MB on Linux you can run the following command:

    sysctl -w net.core.rmem_max=209715200

To make this permanent, add the following to `/etc/sysctl.conf` and restart the
server:

    net.core.rmem_max=209715200

It is **very important** to make sure the buffer sizes are large enough to
handle all data sent to InfluxDB as otherwise you _will_ lose data. The above
buffer sizes are based on the traffic for GitLab.com. Depending on the amount of
traffic users may be able to use a smaller buffer size, but we highly recommend
using _at least_ 100 MB.

When enabling UDP users should take care to not expose the port to the public as
doing so will allow anybody to write data into your InfluxDB database (as
InfluxDB's UDP protocol doesn't support authentication). We recommend either
whitelisting the allowed IP addresses/ranges, or setting up a VLAN and only
allowing traffic from members of said VLAN.

[influxdb-retention]: https://docs.influxdata.com/influxdb/v0.9/query_language/database_management/#retention-policy-management
