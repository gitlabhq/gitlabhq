---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Tiered Storages in ClickHouse
---

NOTE:
The MergeTree table engine in ClickHouse supports tiered storage.
See the documentation for [Using Multiple Block Devices for Data Storage](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#table_engine-mergetree-multiple-volumes)
for details on setup and further explanation.

Quoting from the [MergeTree documentation](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#table_engine-mergetree-multiple-volumes):

<!-- vale gitlab_base.Simplicity = NO -->

> MergeTree family table engines can store data on multiple block devices. For example,
> it can be useful when the data of a certain table are implicitly split into "hot" and "cold".
> The most recent data is regularly requested but requires only a small amount of space.
> On the contrary, the fat-tailed historical data is requested rarely.

<!-- vale gitlab_base.Simplicity = YES -->

When used with remote storage backends such as
[Amazon S3](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#table_engine-mergetree-s3),
this makes a very efficient storage scheme. It allows for storage policies, which
allows data to be on local disks for a period of time and then move it to object storage.

An [example configuration](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#table_engine-mergetree-multiple-volumes_configure) can look like this:

```xml
<storage_configuration>
    <disks>
        <fast_ssd>
            <path>/mnt/fast_ssd/clickhouse/</path>
        </fast_ssd>
        <gcs>
            <support_batch_delete>false</support_batch_delete>
            <type>s3</type>
            <endpoint>https://storage.googleapis.com/${BUCKET_NAME}/${ROOT_FOLDER}/</endpoint>
            <access_key_id>${SERVICE_ACCOUNT_HMAC_KEY}</access_key_id>
            <secret_access_key>${SERVICE_ACCOUNT_HMAC_SECRET}</secret_access_key>
            <metadata_path>/var/lib/clickhouse/disks/gcs/</metadata_path>
        </gcs>
     ...
    </disks>
    ...
    <policies>

        <move_from_local_disks_to_gcs> <!-- policy name -->
            <volumes>
                <hot> <!-- volume name -->
                    <disk>fast_ssd</disk>  <!-- disk name -->
                </hot>
                <cold>
                    <disk>gcs</disk>
                </cold>
            </volumes>
            <move_factor>0.2</move_factor>
            <!-- The move factor determines when to move data from hot volume to cold.
                 See ClickHouse docs for more details. -->
        </moving_from_ssd_to_hdd>
    ....
</storage_configuration>
```

In this storage policy, two volumes are defined `hot` and `cold`. After the `hot` volume is filled with occupancy of `disk_size * move_factor`, the data is being moved to Google Cloud Storage (GCS).

If this storage policy is not the default, create tables by attaching the storage policies. For example:

```sql
CREATE TABLE key_value_table (
    event_date Date,
    key String,
    value String,
) ENGINE = MergeTree
ORDER BY (key)
PARTITION BY toYYYYMM(event_date)
SETTINGS storage_policy = 'move_from_local_disks_to_gcs'
```

NOTE:
In this storage policy, the move happens implicitly. It is also possible to keep
_hot_ data on local disks for a fixed period of time and then move them as _cold_.

This approach is possible with
[Table TTLs](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#mergetree-table-ttl),
which are also available with MergeTree table engine.

The ClickHouse documentation shows this feature in detail, in the example of
[implementing a hot - warm - cold architecture](https://clickhouse.com/docs/en/guides/developer/ttl#implementing-a-hotwarmcold-architecture).

You can take a similar approach for the example shown above. First, adjust the storage policy:

```xml
<storage_configuration>
    ...
    <policies>
        <local_disk_and_gcs> <!-- policy name -->
            <volumes>
                <hot> <!-- volume name -->
                    <disk>fast_ssd</disk>  <!-- disk name -->
                </hot>
                <cold>
                    <disk>gcs</disk>
                </cold>
            </volumes>
        </local_disk_and_gcs>
    ....
</storage_configuration>
```

Then create the table as:

```sql
CREATE TABLE another_key_value_table (
    event_date Date,
    key String,
    value String,
) ENGINE = MergeTree
ORDER BY (key)
PARTITION BY toYYYYMM(event_date)
TTL
    event_date TO VOLUME 'hot',
    event_date + INTERVAL 1 YEAR TO VOLUME 'cold'
SETTINGS storage_policy = 'local_disk_and_gcs';
```

This creates the table so that data older than 1 year (evaluated against the
`event_date` column) is moved to GCS. Such a storage policy can be helpful for append-only
tables (like audit events) where only the most recent data is accessed frequently.
You can drop the data altogether, which can be a regulatory requirement.

We don't mention modifying TTLs in this guide, but that is possible as well.
See ClickHouse documentation for
[modifying TTL](https://clickhouse.com/docs/en/sql-reference/statements/alter/ttl#modify-ttl)
for details.
