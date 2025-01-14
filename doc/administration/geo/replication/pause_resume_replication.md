---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---


# Pausing and resuming replication

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

WARNING:
Pausing and resuming of replication is only supported for Geo installations using a
Linux package-managed database. External databases are not supported.

In some circumstances, like during [upgrades](upgrading_the_geo_sites.md) or a
[planned failover](../disaster_recovery/planned_failover.md), it is desirable to pause replication between the primary and secondary.

If you plan to allow user activity on your secondary sites during the upgrade,
do not pause replication for a [zero-downtime upgrade](../../../update/zero_downtime.md). While paused, the secondary site gets more and more out-of-date.
One known effect is that more and more Git fetches get redirected or proxied to the primary site. There may be additional unknown effects.

Pausing and resuming replication is done through a command-line tool from a specific node in the secondary site. Depending on your database architecture,
this will target either the `postgresql` or `patroni`service:

- If you are using a single node for all services on your secondary site, you must run the commands on this single node.
- If you have a standalone PostgreSQL node on your secondary site, you must run the commands on this standalone PostgreSQL node.
- If your secondary site is using a Patroni cluster, you must run these commands on the secondary Patroni standby leader node.

If you aren't using a single node for all services on your secondary site, ensure that the `/etc/gitlab/gitlab.rb` on your PostgreSQL or Patroni nodes
contains the configuration line `gitlab_rails['geo_node_name'] = 'node_name'`, where `node_name` is the same as the `geo_node_name` on the application node.

**To Pause: (from secondary site)**

Also, be aware that if PostgreSQL is restarted after pausing replication (either by restarting the VM or restarting the service with `gitlab-ctl restart postgresql`), PostgreSQL automatically resumes replication, which is something you wouldn't want during an upgrade or in a planned failover scenario.

```shell
gitlab-ctl geo-replication-pause
```

**To Resume: (from secondary site)**

```shell
gitlab-ctl geo-replication-resume
```
