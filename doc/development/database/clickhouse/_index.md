---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Introduction to ClickHouse use and table design
---

## How it differs from PostgreSQL

The [intro](https://clickhouse.com/docs/en/intro) page is quite good to give an overview of ClickHouse.

ClickHouse has a lot of differences from traditional OLTP (online transaction processing) databases like PostgreSQL. The underlying architecture is a bit different, and the processing is a lot more CPU-bound than in traditional databases.
ClickHouse is a log-centric database where immutability is a key component. The advantages of such approaches are well documented [[1]](https://www.odbms.org/2015/10/the-rise-of-immutable-data-stores/) however it also makes updates much harder. See ClickHouse [documentation](https://clickhouse.com/docs/en/guides/developer/mutations) for operations that provide UPDATE/DELETE support. It is noticeable that these operations are supposed to be non-frequent.

This distinction is important while designing tables. Either:

- The updates are not required (best case)
- If they are needed, they aren't to be run during query execution.

## ACID compatibility

ClickHouse has a slightly different overview of Transactional support, where the guarantees are applicable only up to a block of inserted data to a specific table. See [the Transactional (ACID) support](https://clickhouse.com/docs/en/guides/developer/transactional) documentation for details.

Multiple insertions in a single write should be avoided as transactional support across multiple tables is only covered in materialized views.

ClickHouse is heavily geared towards providing the best-in-class support for analytical queries. Operations like aggregation are very fast and there are several features to augment these capabilities.
ClickHouse has some good blog posts covering [details of aggregations](https://altinity.com/blog/clickhouse-aggregation-fun-part-1-internals-and-handy-tools).

## Primary indexes, sorting index and dictionaries

It is highly recommended to read ["A practical introduction to primary indexes in ClickHouse""](https://clickhouse.com/docs/en/guides/improving-query-performance/sparse-primary-indexes/sparse-primary-indexes-intro) to get an understanding of indexes in ClickHouse.

Particularly how database index design in ClickHouse [differs](https://clickhouse.com/docs/en/guides/improving-query-performance/sparse-primary-indexes/sparse-primary-indexes-design#an-index-design-for-massive-data-scales) from those in transactional databases like PostgreSQL.

Primary index design plays a very important role in query performance and should be stated carefully. Almost all of the queries should rely on the primary index as full data scans are bound to take longer.

Read the documentation for [primary keys and indexes in queries](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#primary-keys-and-indexes-in-queries) to learn how indexes can affect query performance in MergeTree Table engines (default table engine in ClickHouse).

Secondary indexes in ClickHouse are different from what is available in other systems. They are also called data-skipping indexes as they are used to skip over a block of data. See the documentation for [data-skipping indexes](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#table_engine-mergetree-data_skipping-indexes).

ClickHouse also offers ["Dictionaries"](https://clickhouse.com/docs/en/sql-reference/dictionaries/external-dictionaries/external-dicts) which can be used as external indexes. Dictionaries are loaded from memory and can be used to look up values on query runtime.

## Data types & Partitioning

ClickHouse offers SQL-compatible [data types](https://clickhouse.com/docs/en/sql-reference/data-types) and few specialized data types like:

- [`LowCardinality`](https://clickhouse.com/docs/en/sql-reference/data-types/lowcardinality)
- [UUID](https://clickhouse.com/docs/en/sql-reference/data-types/uuid)
- [Maps](https://clickhouse.com/docs/en/sql-reference/data-types/map)
- [Nested](https://clickhouse.com/docs/en/sql-reference/data-types/nested-data-structures/nested) which is interesting, because it simulates a table inside a column.

One key design aspect that comes up front while designing a table is the partitioning key. Partitions can be any arbitrary expression but usually, these are time duration like months, days, or weeks. ClickHouse takes a best-effort approach to minimize the data read by using the smallest set of partitions.

Suggested reads:

- [Choose a low cardinality partitioning key](https://clickhouse.com/docs/en/optimize/partitioning-key)
- [Custom partitioning key](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/custom-partitioning-key).

## Sharding and replication

Sharding is a feature that allows splitting the data into multiple ClickHouse nodes to increase throughput and decrease latency. The sharding feature uses a distributed engine that is backed by local tables. The distributed engine is a "virtual" table that does not store any data. It is used as an interface to insert and query data.

See [the ClickHouse documentation](https://clickhouse.com/docs/en/engines/table-engines/special/distributed) and this section on [replication and sharding](https://clickhouse.com/docs/en/architecture/replication#replication-and-sharding-configuration). ClickHouse can use either Zookeeper or its own compatible API via a component called [ClickHouse Keeper](https://clickhouse.com/docs/en/operations/clickhouse-keeper) to maintain consensus.

After nodes are set up, they can become invisible from the Clients and both write and read queries can be issued to any node.

In most cases, clusters usually start with a fixed number of nodes(~ shards). [Rebalancing shards](https://clickhouse.com/docs/en/guides/sre/scaling-clusters) is operationally heavy and requires rigorous testing.

Replication is supported by MergeTree Table engine, see the [replication section](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replication) in documentation for details on how to define them.
ClickHouse relies on a distributed coordination component (either Zookeeper or ClickHouse Keeper) to track the participating nodes in the quorum. Replication is asynchronous and multi-leader. Inserts can be issued to any node and they can appear on other nodes with some latency. If desired, stickiness to a specific node can be used to make sure that reads observe the latest written data.

## Materialized views

One of the defining features of ClickHouse is materialized views. Functionally they resemble insert triggers for ClickHouse.

We recommended reading the [views](https://clickhouse.com/docs/en/sql-reference/statements/create/view#materialized-view) section from the official documentation to get a better understanding of how they work.

Quoting the [documentation](https://clickhouse.com/docs/en/sql-reference/statements/create/view#materialized-view):

> Materialized views in ClickHouse are implemented more like insert triggers.
> If there's some aggregation in the view query, it's applied only to the batch
> of freshly inserted data. Any changes to existing data of the source table
> (like update, delete, drop a partition, etc.) do not change the materialized view.

## Secure and sensible defaults

ClickHouse instances should follow these security recommendations:

### Users

Files: `users.xml` and `config.xml`.

| Topic | Security Requirement | Reason |
| ----- | -------------------- | ------ |
| [`user_name/password`](https://clickhouse.com/docs/en/operations/settings/settings-users#user-namepassword) | Usernames **must not** be blank. Passwords **must** use `password_sha256_hex` and **must not** be blank. | `plaintext` and `password_double_sha1_hex` are insecure. If username isn't specified, [`default` is used with no password](https://clickhouse.com/docs/en/operations/settings/settings-users). |
| [`access_management`](https://clickhouse.com/docs/en/operations/settings/settings-users#access_management-user-setting) | Use Server [configuration files](https://clickhouse.com/docs/en/operations/configuration-files) `users.xml` and `config.xml`. Avoid SQL-driven workflow. | SQL-driven workflow implies that at least one user has `access_management` which can be avoided via configuration files. These files are easier to audit and monitor too, considering that ["You can't manage the same access entity by both configuration methods simultaneously."](https://clickhouse.com/docs/en/operations/access-rights#access-control). |
| [`user_name/networks`](https://clickhouse.com/docs/en/operations/settings/settings-users#user-namenetworks) | At least one of `<ip>`, `<host>`, `<host_regexp>` **must** be set. Do not use `<ip>::/0</ip>` to open access for any network. | Network controls. ([Trust cautiously](https://handbook.gitlab.com/handbook/security/architecture/#trust-cautiously) principle) |
| [`user_name/profile`](https://clickhouse.com/docs/en/operations/settings/settings-users#user-nameprofile) | Use profiles to set similar properties across multiple users and set limits (from the user interface). | [Least privilege](https://handbook.gitlab.com/handbook/security/architecture/#assign-the-least-privilege-possible) principle and limits. |
| [`user_name/quota`](https://clickhouse.com/docs/en/operations/settings/settings-users#user-namequota) | Set quotas for users whenever possible. | Limit resource usage over a period of time or track the use of resources. |
| [`user_name/databases`](https://clickhouse.com/docs/en/operations/settings/settings-users#user-namedatabases) | Restrict access to data, and avoid users with full access. | [Least privilege](https://handbook.gitlab.com/handbook/security/architecture/#assign-the-least-privilege-possible) principle. |

### Network

Files: `config.xml`

| Topic | Security Requirement | Reason |
| ----- | -------------------- | ------ |
| [`mysql_port`](https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings#server_configuration_parameters-mysql_port) | Disable MySQL access unless strictly necessary:<br/> `<!-- <mysql_port>9004</mysql_port> -->`. | Close unnecessary ports and features exposure. ([Defense in depth](https://handbook.gitlab.com/handbook/security/architecture/#implement-defense-in-depth) principle) |
| [`postgresql_port`](https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings#server_configuration_parameters-postgresql_port) | Disable PostgreSQL access unless strictly necessary:<br/> `<!-- <mysql_port>9005</mysql_port> -->` | Close unnecessary ports and features exposure. ([Defense in depth](https://handbook.gitlab.com/handbook/security/architecture/#implement-defense-in-depth) principle) |
| [`http_port/https_port`](https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings#http-porthttps-port) & [`tcp_port/tcp_port_secure`](https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings#http-porthttps-port) | Configure [SSL-TLS](https://clickhouse.com/docs/en/guides/sre/configuring-ssl), and disable non SSL ports:<br/>`<!-- <http_port>8123</http_port> -->`<br/>`<!-- <tcp_port>9000</tcp_port> -->`<br/>and enable secure ports:<br/>`<https_port>8443</https_port>`<br/>`<tcp_port_secure>9440</tcp_port_secure>` | Encrypt data in transit. ([Defense in depth](https://handbook.gitlab.com/handbook/security/architecture/#implement-defense-in-depth) principle) |
| [`interserver_http_host`](https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings#interserver-http-host) | Disable `interserver_http_host` in favor of `interserver_https_host` (`<interserver_https_port>9010</interserver_https_port>`) if ClickHouse is configured as a cluster. | Encrypt data in transit. ([Defense in depth](https://handbook.gitlab.com/handbook/security/architecture/#implement-defense-in-depth) principle) |

### Storage

| Topic | Security Requirement | Reason |
| ----- | -------------------- | ------ |
| Permissions | ClickHouse runs by default with the `clickhouse` user. Running as `root` is never needed. Use the principle of least privileges for the folders: `/etc/clickhouse-server`, `/var/lib/clickhouse`, `/var/log/clickhouse-server`. These folders must belong to the `clickhouse` user and group, and no other system user must have access to them. | Default passwords, ports and rules are "open doors". ([Fail securely & use secure defaults](https://handbook.gitlab.com/handbook/security/architecture/#fail-securely--use-secure-defaults) principle) |
| Encryption | Use an encrypted storage for logs and data if RED data is processed. On Kubernetes, the [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) used must be encrypted. [GKE](https://cloud.google.com/blog/products/containers-kubernetes/exploring-container-security-use-your-own-keys-to-protect-your-data-on-gke) and [EKS](https://aws.github.io/aws-eks-best-practices/security/docs/data/) encrypt all data at rest already. In this case, using your own key is best but not required. | Encrypt data at rest. ([Defense in depth](https://handbook.gitlab.com/handbook/security/architecture/#implement-defense-in-depth)) |

### Logging

| Topic | Security Requirement | Reason |
| ----- | -------------------- | ------ |
| `logger` | `Log` and `errorlog` **must** be defined and writable by `clickhouse`. | Make sure logs are stored. |
| SIEM  | If hosted on GitLab.com, the ClickHouse instance or cluster **must** report [logs to our SIEM](https://internal.gitlab.com/handbook/security/security_operations/security_logging/tooling/devo/) (internal link). | [GitLab logs critical information system activity](https://handbook.gitlab.com/handbook/security/audit-logging-policy/). |
| Log sensitive data | Query masking rules **must** be used if sensitive data can be logged. See [example masking rules](#example-masking-rules). | [Column level encryption](https://clickhouse.com/docs/en/sql-reference/functions/encryption-functions) can be used and leak sensitive data (keys) in logs. |

#### Example masking rules

```xml
<query_masking_rules>
    <rule>
        <name>hide SSN</name>
        <regexp>(^|\D)\d{3}-\d{2}-\d{4}($|\D)</regexp>
        <replace>000-00-0000</replace>
    </rule>
    <rule>
        <name>hide encrypt/decrypt arguments</name>
        <regexp>
           ((?:aes_)?(?:encrypt|decrypt)(?:_mysql)?)\s*\(\s*(?:'(?:\\'|.)+'|.*?)\s*\)
        </regexp>
        <replace>\1(???)</replace>
    </rule>
</query_masking_rules>
```
