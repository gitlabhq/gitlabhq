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
  The Helm chart configures OpenBao to store data in the main GitLab database by default.
- OpenBao gets the unseal key from a secret store.
- OpenBao reads the unseal key from a Kubernetes secret mounted by the Helm chart.
- OpenBao posts audit logs to the Rails backend when audit logs are enabled.

```mermaid
flowchart TB
    SecretStore[Secret store]
    PostgreSQL[PostgreSQL]
    LB[Load balancer]
    OpenBao[OpenBao active node]

    Rails-- Write secrets and permissions -->LB
    Runner-- Get pipeline secrets -->LB
    LB-->OpenBao
    OpenBao-- Get unseal key -->SecretStore
    OpenBao-- Store -->PostgreSQL
```

OpenBao runs with a single active node that handles all requests,
and optionally multiple standby nodes that take over if the active node fails.

## Install OpenBao

Prerequisites:

- You must have administrator access to the instance.
- You must be running GitLab 18.8 or later.
- You must have a Kubernetes cluster.

To install OpenBao, use the [OpenBao Helm chart for Kubernetes deployments](https://docs.gitlab.com/charts/charts/openbao/).

After installation, verify that OpenBao is working by following the [GitLab Secrets Manager user documentation](../../ci/secrets/secrets_manager/_index.md)
to test secret operations.

OpenBao resource requirements depend on your GitLab instance size and secret usage patterns.

Monitor your deployment and adjust resources as needed based on actual usage patterns.

### CPU requirements

OpenBao CPU usage is primarily driven by:

- How often CI/CD jobs fetch secrets.
- How often the Secrets Manager is accessed through the GitLab UI.

Recommended number of CPU cores:

| Deployment Size | Fetch frequency       | CPU Cores |
|-----------------|-----------------------|-----------|
| Small           | Less than 100 ops/sec | 1 core    |
| Medium          | 100 to 200 ops/sec    | 1-2 cores |
| Large           | More than 200 ops/sec | 2+ cores  |

For example, testing a deployment with 100,000 secrets corresponded to 139 fetch operations per second.
This assumes each secret is fetched by a CI/CD job approximately every 12 minutes,
and OpenBao makes full use of its memory cache.

### Memory requirements

OpenBao memory usage primarily depends on the number of projects
where GitLab Secrets Manager is enabled.
You should allocate at least 1 GB of memory per 200 projects,
plus a safety margin of 1 GB.

Recommended memory allocation:

| Deployment Size | Number of Projects | Memory |
|-----------------|--------------------|--------|
| Small           | Less than 200      | 2 GB   |
| Medium          | 400 to 800         | 5 GB   |
| Large           | More than 1,000    | 6+ GB  |

#### Storage requirements

Storage requirements for the PostgreSQL database depends primarily on the number of secrets.
It takes about 13 KB to store a single version of a secret and the corresponding metadata.

Usage example:

- 100,000 secrets = ~1.5 GB
- 200,000 secrets = ~3 GB

## Backup and restore

OpenBao data is stored in PostgreSQL and should be included in your regular GitLab backup procedures.

For detailed backup and restore procedures specific to OpenBao, see the [OpenBao backup documentation](https://docs.gitlab.com/charts/charts/openbao/#back-up-openbao).

## High availability

For production deployments, consider:

- Running multiple OpenBao replicas for redundancy
- Using a highly available PostgreSQL backend
- Implementing proper monitoring and alerting

## Health check and monitoring

OpenBao provides health check endpoints for monitoring:

- `openbao.example.com/v1/sys/health`: Returns the health status of OpenBao
- `openbao.example.com/v1/sys/seal-status`: Returns the seal status

You can integrate these endpoints with your monitoring system.

## Performance issues

If you experience slow secret operations:

- Check OpenBao resource usage (CPU, memory)
- Verify PostgreSQL backend performance
- Check network latency between OpenBao and its PostgreSQL backend

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
