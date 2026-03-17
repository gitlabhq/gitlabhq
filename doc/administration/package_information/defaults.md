---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Package defaults
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Unless configuration is specified in the `/etc/gitlab/gitlab.rb` file,
the package assumes the defaults as noted below.

## Ports

See the table below for the list of ports that the Linux package assigns by default:

| Component                 | On by default | Communicates via | Alternative   | Connection port |
|:-------------------------:|:-------------:|:----------------:|:-------------:|:----------------|
| GitLab Rails              | Yes           | Port             |               | `80` or `443`   |
| GitLab Shell              | Yes           | Port             |               | `22`            |
| PostgreSQL                | Yes           | Socket           | Port (`5432`) |                 |
| Redis                     | Yes           | Socket           | Port (`6379`) |                 |
| Puma                      | Yes           | Socket           | Port (`8080`) |                 |
| GitLab Workhorse          | Yes           | Socket           | Port (`8181`) |                 |
| NGINX status              | Yes           | Port             |               | `8060`          |
| Prometheus                | Yes           | Port             |               | `9090`          |
| Node exporter             | Yes           | Port             |               | `9100`          |
| Redis exporter            | Yes           | Port             |               | `9121`          |
| PostgreSQL exporter       | Yes           | Port             |               | `9187`          |
| PgBouncer exporter        | No            | Port             |               | `9188`          |
| GitLab Exporter           | Yes           | Port             |               | `9168`          |
| Sidekiq exporter          | Yes           | Port             |               | `8082`          |
| Sidekiq health check      | Yes           | Port             |               | `8092` <sup>1</sup> |
| Web exporter              | No            | Port             |               | `8083`          |
| Geo PostgreSQL            | No            | Socket           | Port (`5431`) |                 |
| Redis Sentinel            | No            | Port             |               | `26379`         |
| Incoming email            | No            | Port             |               | `143`           |
| Elastic search            | No            | Port             |               | `9200`          |
| GitLab Pages              | No            | Port             |               | `80` or `443`   |
| GitLab Registry           | No*           | Port             |               | `80`, `443` or `5050` |
| GitLab Registry           | No            | Port             |               | `5000`          |
| LDAP                      | No            | Port             |               | Depends on the component configuration |
| Kerberos                  | No            | Port             |               | `8443` or `8088` |
| OmniAuth                  | Yes           | Port             |               | Depends on the component configuration |
| SMTP                      | No            | Port             |               | `465`           |
| Remote syslog             | No            | Port             |               | `514`           |
| Mattermost                | No            | Port             |               | `8065`          |
| Mattermost                | No            | Port             |               | `80` or `443`   |
| PgBouncer                 | No            | Port             |               | `6432`          |
| Consul                    | No            | Port             |               | `8300`, `8301`(TCP and UDP), `8500`, `8600` <sup>2</sup> |
| Patroni                   | No            | Port             |               | `8008`          |
| GitLab KAS                | Yes           | Port             |               | `8150`          |
| Gitaly                    | Yes           | Socket           | Port (`8075`) | `8075` or `9999` (TLS) |
| Gitaly exporter           | Yes           | Port             |               | `9236`          |
| Praefect                  | No            | Port             |               | `2305` or `3305` (TLS) |
| GitLab Workhorse exporter | Yes           | Port             |               | `9229`          |
| Registry exporter         | No            | Port             |               | `5001`          |

**Footnotes**:

1. If Sidekiq health check settings are not set, they default to the Sidekiq metrics exporter settings.
   This default is deprecated and is set to be removed in [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/347509).
1. If using additional Consul functionality, more ports may need to be opened. See the
   [official documentation](https://developer.hashicorp.com/consul/docs/install/ports#ports-table) for the list.

Legend:

- `Component` - Name of the component.
- `On by default` - Is the component running by default.
- `Communicates via` - How the component talks with the other components.
- `Alternative` - If it is possible to configure the component to use different type of communication. The type is listed with default port used in that case.
- `Connection port` - Port on which the component communicates.

GitLab also expects a file system to be ready for the storage of Git repositories
and various other files.

If you are using NFS (Network File System), files are carried
over a network which requires, based on implementation, ports `111` and
`2049` to be open.

> [!note]
> In some cases, the GitLab Registry is automatically enabled by default. For more information, see [GitLab container registry administration](../packages/container_registry.md).
