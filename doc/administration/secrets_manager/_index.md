---
stage: Sec
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secrets Manager (OpenBao)
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/16319) in GitLab 18.8 as an experiment, made available to some initial testers in a closed [beta](../../policy/development_stages_support.md#beta) in GitLab 18.8.

{{< /history >}}

The [GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md) uses [OpenBao](https://openbao.org/),
an open-source secrets management solution. OpenBao provides secure storage, access control, and lifecycle management
for secrets used in your GitLab instance.

GitLab CI/CD jobs using secrets from the GitLab Secrets Manager must use
[GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions) 18.6 or later.

## OpenBao architecture

OpenBao integrates with GitLab as an optional component that runs in parallel to existing GitLab services.

- The Rails backend and runners connect to the OpenBao API through a load balancer.
- OpenBao stores data in PostgreSQL.
  The Helm chart configures OpenBao to use a separate logical database on the same PostgreSQL instance.
  Configure the connection using `global.openbao.psql` in the Helm chart.
- OpenBao gets the unseal key from a secret store.
- OpenBao reads the unseal key from a Kubernetes secret mounted by the Helm chart.
- OpenBao posts audit logs to the Rails backend when audit logs are enabled.

```mermaid
flowchart TB
    SecretStore[Secret store]
    PostgreSQL[PostgreSQL]
    LB[Load balancer]
    OpenBao[OpenBao active node]
    Rails[Rails backend]
    Runner[GitLab Runner]
    Workhorse[Workhorse]

    Rails-- Write secrets and permissions -->LB
    Runner-- Get pipeline secrets -->LB
    LB-->OpenBao
    OpenBao-- Get unseal key -->SecretStore
    OpenBao-- Store -->PostgreSQL
    OpenBao-- Audit logs -->Workhorse
    Workhorse-->Rails
```

OpenBao runs with a single active node that handles all requests,
and optionally multiple standby nodes that take over if the active node fails.

## Install OpenBao

Prerequisites:

- Administrator access.
- GitLab 18.8 or later.
- For installing OpenBao alongside a Linux package instance, GitLab 19.0 or later.
- A Kubernetes cluster.
- For Cloud Native GitLab deployments, an external (non-Omnibus) PostgreSQL instance.
  The external PostgreSQL instance is required by the GitLab Helm chart for Cloud Native deployments,
  not by OpenBao specifically. OpenBao uses a separate logical database on that instance.

Choose the installation method based on your GitLab deployment:

- **Cloud Native GitLab**: Use this if you deploy GitLab to Kubernetes.
  For more information, see [OpenBao Helm chart documentation](https://docs.gitlab.com/charts/charts/openbao/).
- **Linux package**: Use this if you deploy GitLab with the Linux package, on a single node or
  across multiple nodes. For more information, see
  [install OpenBao for a Linux package instance](linux_package_integration.md).

After installation, verify that OpenBao is working by following the
[GitLab Secrets Manager user documentation](../../ci/secrets/secrets_manager/_index.md).

## Sizing recommendations

OpenBao resource requirements depend on your GitLab instance size and secret usage patterns.

These recommendations are validated starting points. Monitor your deployment and adjust
resources based on actual usage patterns. Your requirements will differ based on
the number of CI/CD jobs that fetch secrets, and the number of
groups and projects with Secrets Manager enabled.

### Pod resources

OpenBao runs with a single active node that handles all requests.
Additional replicas provide high-availability failover only.
Standby nodes do not serve read traffic because OpenBao does not support
Horizontal Read Scalability (HRS) when connected to a PostgreSQL database.

| Secret fetches/s | CPU request | Memory request | Replicas |
|------------------|-------------|----------------|----------|
| Up to 3          | 500m        | 2 GB           | 2        |
| Up to 6          | 500m        | 3 GB           | 2        |
| Up to 12         | 500m        | 4 GB           | 2        |
| Up to 30         | 500m        | 9 GB           | 2        |
| Up to 60         | 1,000m      | 16 GB          | 2        |
| Up to 150        | 2,000m      | 31 GB          | 2        |

#### Estimate your secret fetch rate

To determine which row applies, estimate your secret fetches per second:

```plaintext
fetches/s = Git Pull RPS × adoption rate × 3
```

Where:

- `Git Pull RPS` is the peak Git pull throughput of your GitLab instance.
  You can measure this from your existing environment monitoring,
  see
  [Extract peak traffic metrics](../reference_architectures/sizing.md#extract-peak-traffic-metrics).
- `adoption rate` is the fraction of CI/CD jobs that use Secrets Manager
  (for example, 0.05 for 5%, 0.20 for 20%, or 0.50 for 50%).
- `3` is the assumed average number of secrets fetched per job that uses the Secrets Manager.

Select the row where **Secret fetches/s** meets or just exceeds your result.
For example, a deployment with a measured 20 Git pull RPS at 20% adoption:
`20 × 0.20 × 3 = 12 fetches/s`. Use at least the **Up to 12** row.

After deployment, verify your estimates against actual usage.
Use the [monitoring queries](#monitor-your-openbao-deployment) to measure resource usage
and scale up to the next row when thresholds are exceeded.

### How resources are calculated

**CPU** is driven by how frequently CI/CD jobs fetch secrets.
Secret write operations (creating or updating secrets) are infrequent relative to pipeline
volume and contribute negligibly to CPU load.
The table uses Git clone rate (Git Pull RPS) as a proxy for CI job rate,
because each CI/CD job begins with a Git clone.
For the formula, see [Estimate your secret fetch rate](#estimate-your-secret-fetch-rate).
Set the CPU limit to twice the CPU request. This provides burst headroom for startup
and provisioning spikes without over-reserving on the node during steady state.

**Memory** is driven by the number of OpenBao namespaces, which corresponds to
the number of GitLab groups and projects with Secrets Manager enabled.
Allocate approximately 5 MB per namespace, plus a 1 GB safety margin,
with a minimum of 2 GB.
Set the memory limit equal to the memory request (Guaranteed QoS class).
OpenBao crashes immediately when it exceeds its memory limit with no graceful degradation.

**Replicas** provide high-availability failover only. Use 2 replicas for all deployments.
OpenBao does not support Horizontal Read Scalability (HRS) with the PostgreSQL storage backend,
so additional replicas provide no throughput benefit.

### Database resources

OpenBao stores its data in a separate PostgreSQL database.
You can colocate it on the same PostgreSQL server as the GitLab databases.
No additional database compute capacity beyond the
[reference architecture PostgreSQL recommendations](../reference_architectures/_index.md)
is required.

#### Database connection pool

The OpenBao Helm chart configures these PostgreSQL connection pool defaults:

| Setting                                              | Default value |
|------------------------------------------------------|---------------|
| `config.storage.postgresql.maxParallel`              | 5             |
| `config.storage.postgresql.maxIdleConnections`       | 2             |

Do not increase these values unless you observe database connection wait time in your monitoring.

#### Database storage

Database storage requirements depend primarily on the total number of secrets.
Each secret, including its metadata and stored versions, requires approximately 13 KB of storage.

| Total secrets  | Estimated storage |
|----------------|-------------------|
| 10,000         | ~130 MB           |
| 50,000         | ~650 MB           |
| 100,000        | ~1.3 GB           |
| 200,000        | ~2.6 GB           |

Storage growth is negligible for all reference architecture tiers.
Allocating 5 to 10 GB of database storage provides ample headroom.

## Monitor your OpenBao deployment

Use the following queries to verify that your deployment is correctly sized and to
detect when scaling is needed.

### CPU utilization

To measure OpenBao CPU usage:

```prometheus
sum(rate(container_cpu_usage_seconds_total{container="openbao-server"}[5m]))
```

The result is in CPU cores. Multiply by 1,000 to convert to millicores for comparison
with the CPU request values in the sizing table.
If CPU utilization consistently exceeds 50% of the CPU request, consider
scaling up to the next row in the sizing table.

### Memory utilization

To measure OpenBao memory usage:

```prometheus
sum(container_memory_working_set_bytes{container="openbao-server"})
```

The result is in bytes. Memory grows as groups and projects enable Secrets Manager, at approximately
5 MB per namespace. After a restart, memory stabilizes as OpenBao loads namespace metadata
from the database.

To calculate the correct memory request, count the groups and projects with Secrets Manager
enabled and multiply by 5 MB, then add 1 GB. Update your pod resources if the result exceeds
your current memory request. If memory shows a sustained upward trend with no active
provisioning, investigate for potential issues.

### CPU throttling

To detect CPU throttling that may affect latency:

```prometheus
sum(rate(container_cpu_cfs_throttled_periods_total{container="openbao-server"}[5m]))
/
sum(rate(container_cpu_cfs_periods_total{container="openbao-server"}[5m]))
```

A throttle ratio above 0.25 (25%) indicates the CPU limit is too low for the current workload.
When OpenBao is throttled, goroutines waiting for CPU time cause increased secret fetch latency.

### Health check endpoints

OpenBao provides health check endpoints for monitoring:

- `<your-openbao-url>/v1/sys/health`: Returns the health status of OpenBao
- `<your-openbao-url>/v1/sys/seal-status`: Returns the seal status

You can integrate these endpoints with your monitoring system.

## Backup and restore

OpenBao stores data in a separate logical database on PostgreSQL. Back up this database alongside your
regular GitLab backup to ensure secrets can be restored after a failure.

For detailed backup and restore procedures specific to OpenBao, see the [OpenBao backup documentation](https://docs.gitlab.com/charts/charts/openbao/#back-up-openbao).

## Recovery key management

For information about managing the OpenBao recovery key, including storing, viewing, and using it
to generate a root token, see [recovery key management](recovery_key.md).

## High availability

OpenBao uses a single active node architecture. One node handles all requests,
and standby nodes provide automatic failover if the active node fails.

### Failover

Standby nodes load all namespace metadata at startup, so promotion to active
requires no additional initialization. The number of namespaces does not affect failover time.

For production deployments:

- Run at least two OpenBao replicas for redundancy.
- Use a highly available PostgreSQL backend.
- Implement monitoring and alerting using the [monitoring queries](#monitor-your-openbao-deployment).

### Upgrade downtime

OpenBao does not support zero-downtime upgrades. During an upgrade, OpenBao
initializes each namespace sequentially on startup. Every group or project with Secrets Manager enabled
counts as one namespace.

To upgrade, it takes approximately 11 seconds per 1,000 namespaces, plus a 5 second baseline.

When OpenBao implements on-demand namespace loading, upgrade downtime will be significantly reduced.
For more information, see
[issue 595721](https://gitlab.com/gitlab-org/gitlab/-/work_items/595721).

## Geo deployment

OpenBao supports [Geo](../geo/_index.md) deployments. OpenBao is deployed on both the primary and
secondary Geo sites, but only the primary site runs an active OpenBao node.

### OpenBao behavior in Geo

On the primary site, OpenBao runs as an active
node connected to a writable PostgreSQL database. On the secondary site, OpenBao runs in standby mode,
connected to a PostgreSQL read replica.

PostgreSQL streaming replication carries all OpenBao data (secrets, policies, authentication
configuration) from the primary to the secondary site automatically.

Both GitLab instances (primary and secondary) connect to the primary OpenBao URL. The secondary
OpenBao deployment remains in standby, and is promoted to active when the secondary
PostgreSQL database becomes writable during a
[Geo failover](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster).

On the secondary site, OpenBao logs `failed to acquire lock` and
`cannot execute INSERT in a read-only transaction` errors. These errors are expected. OpenBao cannot
acquire the HA leader lock on a read-only database.

### Install OpenBao on a secondary site

Prerequisites:

- Geo must be configured. For more information, see [Set up Geo](../geo/setup/_index.md).
- OpenBao must be installed and working on the primary site before you deploy it on the secondary.
  For more information, see [Install OpenBao](#install-openbao).

1. The secondary OpenBao must use the same unseal key as the primary to decrypt replicated data.
   Copy the `gitlab-openbao-unseal` Kubernetes secret from the primary cluster to the secondary
   cluster:

   ```shell
   kubectl --namespace gitlab get secret gitlab-openbao-unseal -o yaml
   ```

   Apply the exported secret to the secondary cluster. For more information, see
   [Back up the secrets](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets).

1. If you plan to update the DNS record of the primary domain to point to the secondary site during failover,
   you might want to configure OpenBao accordingly ahead of time.
   Configure the Helm chart and set the `url` and `jwt_audience` to the primary OpenBao URL:

   ```yaml
   global:
     openbao:
       enabled: true
       url: https://openbao.<primary-domain>
       jwt_audience: https://openbao.<primary-domain>
   ```

   For more information on chart configuration options,
   see [Geo configuration](https://docs.gitlab.com/charts/charts/openbao/#geo-configuration).

1. Deploy the GitLab Helm chart on the secondary site. OpenBao pods start and remain in standby
   mode. This is expected.

1. On the secondary cluster, check that OpenBao pods are running:

   ```shell
   kubectl --namespace gitlab get pods -l app=openbao
   ```

   All pods should be in `Running` state. Secondary pods do not have the `openbao-active: "true"`
   label. This is expected.

1. Confirm that the active service has no endpoints on the secondary cluster:

   ```shell
   kubectl --namespace gitlab get endpoints gitlab-openbao-active
   ```

   Zero endpoints on the secondary is expected.

1. Test the Secrets Manager by running a CI pipeline that uses a
   [Secrets Manager variable](../../ci/secrets/secrets_manager/_index.md) on the secondary site.

## Troubleshooting

When working with the Secrets Manager, you might encounter the following issues.

### Troubleshoot Geo deployments

| Symptom | Cause | Resolution |
|---------|-------|------------|
| `cipher: message authentication failed` or `unknown key ID` in secondary OpenBao logs | Unseal key mismatch between primary and secondary | Copy `gitlab-openbao-unseal` from the primary cluster to the secondary cluster and restart OpenBao pods. |
| `failed to acquire lock` in secondary OpenBao logs | OpenBao standby on read-only database | Expected behavior. No action required. |
| `cannot execute INSERT in a read-only transaction` in secondary OpenBao logs | OpenBao attempting leader election on read replica | Expected behavior. No action required. |
| JWT authentication fails after Geo failover | `jwt_audience` does not match `boundAudiences` in OpenBao | Set `jwt_audience` to the primary OpenBao URL on both sites. |

### Diagnose slow secret operations

Use this section when CI/CD jobs are slow to fetch secrets or secret operations time out.

#### Confirm latency is elevated

Use the following query to measure average request latency in milliseconds.
The query works at any traffic level, including low-traffic deployments:

```prometheus
rate(openbao_core_handle_request_sum[5m])
/
rate(openbao_core_handle_request_count[5m])
```

Under normal load, average latency across all request types is typically 3–7 ms.
Investigate if average latency consistently exceeds 20 ms.

When OpenBao is actively processing requests, use the following query for P99 latency:

```prometheus
openbao_core_handle_request{quantile="0.99"}
```

Normal P99 is below 10 ms. This query returns `NaN` when OpenBao is idle because
the summary window has no recent observations. Use the rate-based query in that case.

#### Identify potential issues

| Potential issue             | What to check                   | Query                                                                       | Threshold           | Action                                                             |
|-----------------------------|---------------------------------|-----------------------------------------------------------------------------|---------------------|--------------------------------------------------------------------|
| CPU limit too low           | CFS throttle ratio              | [CPU throttling query](#cpu-throttling)                                     | > 25%               | Increase CPU limit                                                 |
| Demand exceeds CPU capacity | CPU utilization                 | [CPU utilization query](#cpu-utilization)                                   | > 50% of request    | Scale to the next row in the [sizing table](#pod-resources)        |
| Request surge               | In-flight requests              | `openbao_core_in_flight_requests`                                           | Sustained above 5   | Transient. Monitor for recurrence.                                 |
| PostgreSQL bottleneck       | Average PostgreSQL read latency | `rate(openbao_postgres_get_sum[5m]) / rate(openbao_postgres_get_count[5m])` | > 5 ms              | Check PostgreSQL resources and connection pool                     |
| Memory pressure             | Memory utilization              | [Memory utilization query](#memory-utilization)                             | Near memory request | Increase memory using the [namespace formula](#memory-utilization) |

If PostgreSQL latency is elevated, check whether the connection pool is saturated.
If all connections are busy, additional requests queue and cause latency.
For connection pool configuration, see [Database resources](#database-resources).
Verify connection count in your PostgreSQL monitoring or in the OpenBao logs.
