---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Package defaults **(FREE SELF)**

Unless configuration is specified in the `/etc/gitlab/gitlab.rb` file,
the package will assume the defaults as noted below.

## Ports

See the table below for the list of ports that the Omnibus GitLab assigns
by default:

| Component                                              | On by default  | Communicates via | Alternative | Connection port                            |
| :----------------------------------------------------: | :------------: | :--------------: | :---------: | :------------------------------------:     |
| <a name="gitlab-rails"></a>        GitLab Rails        | Yes            | Port             | X           | 80 or 443                                  |
| <a name="gitlab-shell"></a>        GitLab Shell        | Yes            | Port             | X           | 22                                         |
| <a name="postgresql"></a>          PostgreSQL          | Yes            | Socket           | Port (5432) | X                                          |
| <a name="redis"></a>               Redis               | Yes            | Socket           | Port (6379) | X                                          |
| <a name="puma"></a>                Puma                | Yes            | Socket           | Port (8080) | X                                          |
| <a name="gitlab-workhorse"></a>    GitLab Workhorse    | Yes            | Socket           | Port (8181) | X                                          |
| <a name="nginx-status"></a>        NGINX status        | Yes            | Port             | X           | 8060                                       |
| <a name="prometheus"></a>          Prometheus          | Yes            | Port             | X           | 9090                                       |
| <a name="node-exporter"></a>       Node exporter       | Yes            | Port             | X           | 9100                                       |
| <a name="redis-exporter"></a>      Redis exporter      | Yes            | Port             | X           | 9121                                       |
| <a name="postgres-exporter"></a>   PostgreSQL exporter | Yes            | Port             | X           | 9187                                       |
| <a name="pgbouncer-exporter"></a>  PgBouncer exporter  | No             | Port             | X           | 9188                                       |
| <a name="gitlab-exporter"></a>     GitLab Exporter     | Yes            | Port             | X           | 9168                                       |
| <a name="sidekiq-exporter"></a>    Sidekiq exporter    | Yes            | Port             | X           | 8082                                       |
| <a name="puma-exporter"></a>       Puma exporter       | No             | Port             | X           | 8083                                       |
| <a name="geo-postgresql"></a>      Geo PostgreSQL      | No             | Socket           | Port (5431) | X                                          |
| <a name="redis-sentinel"></a>      Redis Sentinel      | No             | Port             | X           | 26379                                      |
| <a name="incoming-email"></a>      Incoming email      | No             | Port             | X           | 143                                        |
| <a name="elasticsearch"></a>       Elastic search      | No             | Port             | X           | 9200                                       |
| <a name="gitlab-pages"></a>        GitLab Pages        | No             | Port             | X           | 80 or 443                                  |
| <a name="gitlab-registry-web"></a> GitLab Registry     | No*            | Port             | X           | 80, 443 or 5050                            |
| <a name="gitlab-registry"></a>     GitLab Registry     | No             | Port             | X           | 5000                                       |
| <a name="ldap"></a>                LDAP                | No             | Port             | X           | Depends on the component configuration     |
| <a name="kerberos"></a>            Kerberos            | No             | Port             | X           | 8443 or 8088                               |
| <a name="omniauth"></a>            OmniAuth            | Yes            | Port             | X           | Depends on the component configuration     |
| <a name="smtp"></a>                SMTP                | No             | Port             | X           | 465                                        |
| <a name="remote-syslog"></a>       Remote syslog       | No             | Port             | X           | 514                                        |
| <a name="mattermost"></a>          Mattermost          | No             | Port             | X           | 8065                                       |
| <a name="mattermost-web"></a>      Mattermost          | No             | Port             | X           | 80 or 443                                  |
| <a name="pgbouncer"></a>           PgBouncer           | No             | Port             | X           | 6432                                       |
| <a name="consul"></a>              Consul              | No             | Port             | X           | 8300, 8301(UDP), 8500, 8600[^Consul-notes] |
| <a name="patroni"></a>             Patroni             | No             | Port             | X           | 8008                                       |
| <a name="gitlab-kas"></a>          GitLab KAS          | No             | Port             | X           | 8150                                       |
| <a name="gitaly"></a>              Gitaly              | No             | Port             | X           | 8075                                       |

Legend:

- `Component` - Name of the component.
- `On by default` - Is the component running by default.
- `Communicates via` - How the component talks with the other components.
- `Alternative` - If it is possible to configure the component to use different type of communication. The type is listed with default port used in that case.
- `Connection port` - Port on which the component communicates.

GitLab also expects a file system to be ready for the storage of Git repositories
and various other files.

Note that if you are using NFS (Network File System), files will be carried
over a network which will require, based on implementation, ports `111` and
`2049` to be open.

NOTE:
In some cases, the GitLab Registry will be automatically enabled by default. Please see [our documentation](../packages/container_registry.md) for more details

 [^Consul-notes]: If using additional Consul functionality, more ports may need to be opened. See the [official documentation](https://www.consul.io/docs/install/ports#ports-table) for the list.
