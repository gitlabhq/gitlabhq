---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab architecture overview

## Software delivery

There are two software distributions of GitLab:

- The open source [Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/) (CE).
- The open core [Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/) (EE).

GitLab is available under [different subscriptions](https://about.gitlab.com/pricing/).

New versions of GitLab are released from stable branches, and the `main` branch is used for
bleeding-edge development.

For more information, visit the [GitLab Release Process](https://about.gitlab.com/handbook/engineering/releases/).

Both distributions require additional components. These components are described in the
[Component details](#components) section, and all have their own repositories.
New versions of each dependent component are usually tags, but staying on the `main` branch of the
GitLab codebase gives you the latest stable version of those components. New versions are
generally released around the same time as GitLab releases, with the exception of informal security
updates deemed critical.

## Components

A typical install of GitLab is on GNU/Linux, but growing number of deployments also use the
Kubernetes platform. The largest known GitLab instance is on GitLab.com, which is deployed using our
[official GitLab Helm chart](https://docs.gitlab.com/charts/) and the [official Linux package](https://about.gitlab.com/install/).

A typical installation uses NGINX or Apache as a web server to proxy through
[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) and into the [Puma](https://puma.io)
application server. GitLab serves web pages and the [GitLab API](../api/index.md) using the Puma
application server. It uses Sidekiq as a job queue which, in turn, uses Redis as a non-persistent
database backend for job information, metadata, and incoming jobs.

By default, communication between Puma and Workhorse is via a Unix domain socket, but forwarding
requests via TCP is also supported. Workhorse accesses the `gitlab/public` directory, bypassing the
Puma application server to serve static pages, uploads (for example, avatar images or attachments),
and pre-compiled assets.

The GitLab application uses PostgreSQL for persistent database information (for example, users,
permissions, issues, or other metadata). GitLab stores the bare Git repositories in the location
defined in [the configuration file, `repositories:` section](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).
It also keeps default branch and hook information with the bare repository.

When serving repositories over HTTP/HTTPS GitLab uses the GitLab API to resolve authorization and
access and to serve Git objects.

The add-on component GitLab Shell serves repositories over SSH. It manages the SSH keys within the
location defined in [the configuration file, `GitLab Shell` section](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).
The file in that location should never be manually edited. GitLab Shell accesses the bare
repositories through Gitaly to serve Git objects, and communicates with Redis to submit jobs to
Sidekiq for GitLab to process. GitLab Shell queries the GitLab API to determine authorization and access.

Gitaly executes Git operations from GitLab Shell and the GitLab web app, and provides an API to the
GitLab web app to get attributes from Git (for example, title, branches, tags, or other metadata),
and to get blobs (for example, diffs, commits, or files).

You may also be interested in the [production architecture of GitLab.com](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/).

## Adapting existing and introducing new components

There are fundamental differences in how the application behaves when it is installed on a
traditional Linux machine compared to a containerized platform, such as Kubernetes.

Compared to [our official installation methods](https://about.gitlab.com/install/), some of the
notable differences are:

- Official Linux packages can access files on the same file system with different services.
  [Shared files](shared_files.md) are not an option for the application running on the Kubernetes
  platform.
- Official Linux packages by default have services that have access to the shared configuration and
  network. This is not the case for services running in Kubernetes, where services might be running
  in complete isolation, or only accessible through specific ports.

In other words, the shared state between services needs to be carefully considered when
architecting new features and adding new components. Services that need to have access to the same
files, need to be able to exchange information through the appropriate APIs. Whenever possible,
this should not be done with files.

Since components written with the API-first philosophy in mind are compatible with both methods, all
new features and services must be written to consider Kubernetes compatibility **first**.

The simplest way to ensure this, is to add support for your feature or service to
[the official GitLab Helm chart](https://docs.gitlab.com/charts/) or reach out to
[the Distribution team](https://about.gitlab.com/handbook/engineering/development/enablement/distribution/#how-to-work-with-distribution).

Refer to the [process for adding new service components](adding_service_component.md) for more details.

### Simplified component overview

This is a simplified architecture diagram that can be used to
understand the GitLab architecture.

A complete architecture diagram is available in our
[component diagram](#component-diagram) below.

![Simplified Component Overview](img/architecture_simplified.png)

<!--
To update this diagram, GitLab team members can edit this source file:
https://docs.google.com/drawings/d/1fBzAyklyveF-i-2q-OHUIqDkYfjjxC4mq5shwKSZHLs/edit.
 -->

### Component diagram

```mermaid
graph LR
  %% Anchor items in the appropriate subgraph.
  %% Link them where the destination* is.

  subgraph Clients
    Browser((Browser))
    Git((Git))
  end

  %% External Components / Applications
  Geo{{GitLab Geo}} -- TCP 80, 443 --> HTTP
  Geo -- TCP 22 --> SSH
  Geo -- TCP 5432 --> PostgreSQL
  Runner{{GitLab Runner}} -- TCP 443 --> HTTP
  K8sAgent{{GitLab Kubernetes Agent}} -- TCP 443 --> HTTP

  %% GitLab Application Suite
  subgraph GitLab
    subgraph Ingress
        HTTP[[HTTP/HTTPS]]
        SSH[[SSH]]
        NGINX[NGINX]
        GitLabShell[GitLab Shell]

        %% inbound/internal
        Browser -- TCP 80,443 --> HTTP
        Git -- TCP 80,443 --> HTTP
        Git -- TCP 22 --> SSH
        HTTP -- TCP 80, 443 --> NGINX
        SSH -- TCP 22 --> GitLabShell
    end

    subgraph GitLab Services
        %% inbound from NGINX
        NGINX --> GitLabWorkhorse
        NGINX -- TCP 8090 --> GitLabPages
        NGINX -- TCP 8150 --> GitLabKas
        NGINX --> Registry
        %% inbound from GitLabShell
        GitLabShell --TCP 8080 -->Puma

        %% services
        Puma["Puma (GitLab Rails)"]
        Puma <--> Registry
        GitLabWorkhorse[GitLab Workhorse] <--> Puma
        GitLabKas[GitLab Kubernetes Agent Server] --> GitLabWorkhorse
        GitLabPages[GitLab Pages] --> GitLabWorkhorse
        Mailroom
        Sidekiq
    end

    subgraph Integrated Services
        %% Mattermost
        Mattermost
        Mattermost ---> GitLabWorkhorse
        NGINX --> Mattermost

        %% Grafana
        Grafana
        NGINX --> Grafana
    end

    subgraph Metadata
        %% PostgreSQL
        PostgreSQL
        PostgreSQL --> Consul

        %% Consul and inbound
        Consul
        Puma ---> Consul
        Sidekiq ---> Consul
        Migrations --> PostgreSQL

        %% PgBouncer and inbound
        PgBouncer
        PgBouncer --> Consul
        PgBouncer --> PostgreSQL
        Sidekiq --> PgBouncer
        Puma --> PgBouncer
    end

    subgraph State
        %% Redis and inbound
        Redis
        Puma --> Redis
        Sidekiq --> Redis
        GitLabWorkhorse --> Redis
        Mailroom --> Redis
        GitLabKas --> Redis

        %% Sentinel and inbound
        Sentinel <--> Redis
        Puma --> Sentinel
        Sidekiq --> Sentinel
        GitLabWorkhorse --> Sentinel
        Mailroom --> Sentinel
        GitLabKas --> Sentinel
    end

    subgraph Git Repositories
        %% Gitaly / Praefect
        Praefect --> Gitaly
        GitLabKas --> Praefect
        GitLabShell --> Praefect
        GitLabWorkhorse --> Praefect
        Puma --> Praefect
        Sidekiq --> Praefect
        Praefect <--> PraefectPGSQL[PostgreSQL]
        %% Gitaly makes API calls
        %% Ordered here to ensure placement.
        Gitaly --> GitLabWorkhorse
    end

    subgraph Storage
        %% ObjectStorage and inbound traffic
        ObjectStorage["Object Storage"]
        Puma -- TCP 443 --> ObjectStorage
        Sidekiq -- TCP 443 --> ObjectStorage
        GitLabWorkhorse -- TCP 443 --> ObjectStorage
        Registry -- TCP 443 --> ObjectStorage
        GitLabPages -- TCP 443 --> ObjectStorage
    end

    subgraph Monitoring
        %% Prometheus
        Grafana -- TCP 9090 --> Prometheus[Prometheus]
        Prometheus -- TCP 80, 443 --> Puma
        RedisExporter[Redis Exporter] --> Redis
        Prometheus -- TCP 9121 --> RedisExporter
        PostgreSQLExporter[PostgreSQL Exporter] --> PostgreSQL
        PgBouncerExporter[PgBouncer Exporter] --> PgBouncer
        Prometheus -- TCP 9187 --> PostgreSQLExporter
        Prometheus -- TCP 9100 --> NodeExporter[Node Exporter]
        Prometheus -- TCP 9168 --> GitLabExporter[GitLab Exporter]
        Prometheus -- TCP 9127 --> PgBouncerExporter
        Prometheus --> Alertmanager
        GitLabExporter --> PostgreSQL
        GitLabExporter --> GitLabShell
        GitLabExporter --> Sidekiq

        %% Alertmanager
        Alertmanager -- TCP 25 --> SMTP
    end
  %% end subgraph GitLab
  end

  subgraph External
    subgraph External Services
        SMTP[SMTP Gateway]
        LDAP

        %% Outbound SMTP
        Sidekiq -- TCP 25 --> SMTP
        Puma -- TCP 25 --> SMTP
        Mailroom -- TCP 25 --> SMTP

        %% Outbound LDAP
        Puma -- TCP 369 --> LDAP
        Sidekiq -- TCP 369 --> LDAP

        %% Elasticsearch
        Elasticsearch
        Puma -- TCP 9200 --> Elasticsearch
        Sidekiq -- TCP 9200 --> Elasticsearch
    end
    subgraph External Monitoring
        %% Sentry
        Sidekiq -- TCP 80, 443 --> Sentry
        Puma -- TCP 80, 443 --> Sentry

        %% Jaeger
        Jaeger
        Sidekiq -- UDP 6831 --> Jaeger
        Puma -- UDP 6831 --> Jaeger
        Gitaly -- UDP 6831 --> Jaeger
        GitLabShell -- UDP 6831 --> Jaeger
        GitLabWorkhorse -- UDP 6831 --> Jaeger
    end
  %% end subgraph External
  end

click Alertmanager "./architecture.html#alertmanager"
click Praefect "./architecture.html#praefect"
click Geo "./architecture.html#gitlab-geo"
click NGINX "./architecture.html#nginx"
click Runner "./architecture.html#gitlab-runner"
click Registry "./architecture.html#registry"
click ObjectStorage "./architecture.html#minio"
click Mattermost "./architecture.html#mattermost"
click Gitaly "./architecture.html#gitaly"
click Jaeger "./architecture.html#jaeger"
click GitLabWorkhorse "./architecture.html#gitlab-workhorse"
click LDAP "./architecture.html#ldap-authentication"
click Puma "./architecture.html#puma"
click GitLabShell "./architecture.html#gitlab-shell"
click SSH "./architecture.html#ssh-request-22"
click Sidekiq "./architecture.html#sidekiq"
click Sentry "./architecture.html#sentry"
click GitLabExporter "./architecture.html#gitlab-exporter"
click Elasticsearch "./architecture.html#elasticsearch"
click Migrations "./architecture.html#database-migrations"
click PostgreSQL "./architecture.html#postgresql"
click Consul "./architecture.html#consul"
click PgBouncer "./architecture.html#pgbouncer"
click PgBouncerExporter "./architecture.html#pgbouncer-exporter"
click RedisExporter "./architecture.html#redis-exporter"
click Redis "./architecture.html#redis"
click Prometheus "./architecture.html#prometheus"
click Grafana "./architecture.html#grafana"
click GitLabPages "./architecture.html#gitlab-pages"
click PostgreSQLExporter "./architecture.html#postgresql-exporter"
click SMTP "./architecture.html#outbound-email"
click NodeExporter "./architecture.html#node-exporter"
```

### Component legend

- ✅ - Installed by default
- ⚙ - Requires additional configuration
- ⤓ - Manual installation required
- ❌ - Not supported or no instructions available
- N/A - Not applicable

Component statuses are linked to configuration documentation for each component.

### Component list

| Component                                             | Description                                                          | [Omnibus GitLab](https://docs.gitlab.com/omnibus/) | [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit) | [GitLab chart](https://docs.gitlab.com/charts/) | [Minikube Minimal](https://docs.gitlab.com/charts/development/minikube/#deploying-gitlab-with-minimal-settings) | [GitLab.com](https://gitlab.com) | [Source](../install/installation.md) | [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit) |  [CE/EE](https://about.gitlab.com/install/ce-or-ee/)  |
|-------------------------------------------------------|----------------------------------------------------------------------|:--------------:|:--------------:|:------------:|:----------------:|:----------:|:------:|:---:|:-------:|
| [Certificate Management](#certificate-management)     | TLS Settings, Let's Encrypt                                          |       ✅       |       ✅        |      ✅       |        ⚙         |     ✅      |   ⚙    |  ⚙  | CE & EE |
| [Consul](#consul)                                     | Database node discovery, failover                                    |       ⚙       |       ✅         |      ❌       |        ❌         |     ✅      |   ❌    |  ❌  | EE Only |
| [Database Migrations](#database-migrations)           | Database migrations                                                  |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⚙    |  ✅  | CE & EE |
| [Elasticsearch](#elasticsearch)                       | Improved search within GitLab                                        |       ⤓        |       ⚙        |      ⤓       |        ⤓         |     ✅      |   ⤓    |  ⤓  | EE Only |
| [Gitaly](#gitaly)                                     | Git RPC service for handling all Git calls made by GitLab            |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⚙    |  ✅  | CE & EE |
| [GitLab Exporter](#gitlab-exporter)                   | Generates a variety of GitLab metrics                                |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ❌    |  ❌  | CE & EE |
| [GitLab Geo Node](#gitlab-geo)                        | Geographically distributed GitLab nodes                              |       ⚙        |       ⚙      |        ❌      |        ❌         |     ✅      |   ❌    |  ⚙  | EE Only |
| [GitLab Kubernetes Agent](#gitlab-kubernetes-agent)   | Integrate Kubernetes clusters in a cloud-native way                  |       ⚙       |       ⚙        |      ⚙       |        ❌         |     ❌      |   ⤓    |  ⚙   | EE Only |
| [GitLab Pages](#gitlab-pages)                         | Hosts static websites                                                |       ⚙       |       ⚙        |      ❌       |        ❌         |     ✅      |   ⚙    |  ⚙  | CE & EE |
| [GitLab Kubernetes Agent](#gitlab-kubernetes-agent)   | Integrate Kubernetes clusters in a cloud-native way                  |       ⚙       |       ⚙        |      ⚙       |        ❌         |     ❌      |   ⤓    |  ⚙   | EE Only |
| [GitLab self-monitoring: Alertmanager](#alertmanager) | Deduplicates, groups, and routes alerts from Prometheus              |       ⚙       |       ⚙        |      ✅       |        ⚙         |     ✅      |   ❌    |  ❌  | CE & EE |
| [GitLab self-monitoring: Grafana](#grafana)           | Metrics dashboard                                                    |       ✅       |       ✅        |      ⚙       |        ⤓         |     ✅      |   ❌    |  ❌  | CE & EE |
| [GitLab self-monitoring: Jaeger](#jaeger)             | View traces generated by the GitLab instance                         |       ❌       |       ⚙        |      ⚙       |        ❌         |     ❌      |   ⤓    |  ⚙  | CE & EE |
| [GitLab self-monitoring: Prometheus](#prometheus)     | Time-series database, metrics collection, and query service          |       ✅       |       ✅        |      ✅       |        ⚙         |     ✅      |   ❌    |  ❌  | CE & EE |
| [GitLab self-monitoring: Sentry](#sentry)             | Track errors generated by the GitLab instance                        |       ⤓        |       ⤓        |      ⤓       |        ❌         |     ✅      |   ⤓    |  ⤓  | CE & EE |
| [GitLab Shell](#gitlab-shell)                         | Handles `git` over SSH sessions                                      |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⚙    |  ✅  | CE & EE |
| [GitLab Workhorse](#gitlab-workhorse)                 | Smart reverse proxy, handles large HTTP requests                     |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⚙    |  ✅  | CE & EE |
| [Inbound email (SMTP)](#inbound-email)                | Receive messages to update issues                                    |       ⤓        |       ⤓        |      ⚙       |        ⤓         |     ✅      |   ⤓    |  ⤓  | CE & EE |
| [Jaeger integration](#jaeger)                         | Distributed tracing for deployed apps                                |       ⤓        |       ⤓        |      ⤓       |        ⤓         |     ⤓      |   ⤓    |  ⤓  | EE Only |
| [LDAP Authentication](#ldap-authentication)           | Authenticate users against centralized LDAP directory                |       ⤓        |       ⤓        |      ⤓       |        ⤓         |     ❌      |   ⤓    |  ⤓  | CE & EE |
| [Mattermost](#mattermost)                             | Open-source Slack alternative                                        |       ⚙       |       ⚙        |      ⤓       |        ⤓         |     ⤓      |   ❌    |  ❌  | CE & EE |
| [MinIO](#minio)                                       | Object storage service                                               |       ⤓        |       ⤓        |      ✅       |        ✅         |     ✅      |   ❌    |  ⚙  | CE & EE |
| [NGINX](#nginx)                                       | Routes requests to appropriate components, terminates SSL            |       ✅       |       ✅        |      ✅       |        ⚙         |     ✅      |   ⤓    |  ❌  | CE & EE |
| [Node Exporter](#node-exporter)                       | Prometheus endpoint with system metrics                              |       ✅       |       ✅        |     N/A      |       N/A        |     ✅      |   ❌    |  ❌  | CE & EE |
| [Outbound email (SMTP)](#outbound-email)              | Send email messages to users                                         |       ⤓        |       ⤓        |      ⚙       |        ⤓         |     ✅      |   ⤓    |  ⤓  | CE & EE |
| [Patroni](#patroni)                                   | Manage PostgreSQL HA cluster leader selection and replication        |       ⚙       |       ✅        |      ❌       |        ❌         |     ✅      |   ❌    |  ❌  | EE Only |
| [PgBouncer Exporter](#pgbouncer-exporter)             | Prometheus endpoint with PgBouncer metrics                           |       ⚙       |       ✅        |      ❌       |        ❌         |     ✅      |   ❌    |  ❌  | CE & EE |
| [PgBouncer](#pgbouncer)                               | Database connection pooling, failover                                |       ⚙       |       ✅        |      ❌       |        ❌         |     ✅      |   ❌    |  ❌  | EE Only |
| [PostgreSQL Exporter](#postgresql-exporter)           | Prometheus endpoint with PostgreSQL metrics                          |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ❌    |  ❌  | CE & EE |
| [PostgreSQL](#postgresql)                             | Database                                                             |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⤓    |  ✅  | CE & EE |
| [Praefect](#praefect)                                 | A transparent proxy between any Git client and Gitaly storage nodes. |       ✅       |       ✅        |      ⚙       |        ❌         |     ✅      |   ⚙    |  ✅  | CE & EE |
| [Puma (GitLab Rails)](#puma)                          | Handles requests for the web interface and API                       |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⚙    |  ✅  | CE & EE |
| [Redis Exporter](#redis-exporter)                     | Prometheus endpoint with Redis metrics                               |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ❌    |  ❌  | CE & EE |
| [Redis](#redis)                                       | Caching service                                                      |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ⤓    |  ✅  | CE & EE |
| [Registry](#registry)                                 | Container registry, allows pushing and pulling of images             |       ⚙       |       ⚙        |      ✅       |        ✅         |     ✅      |   ⤓    |  ⚙  | CE & EE |
| [Runner](#gitlab-runner)                              | Executes GitLab CI/CD jobs                                           |       ⤓        |       ⤓        |      ✅       |        ⚙         |     ✅      |   ⚙    |  ⚙  | CE & EE |
| [Sentry integration](#sentry)                         | Error tracking for deployed apps                                     |       ⤓        |       ⤓        |      ⤓       |        ⤓         |     ⤓      |   ⤓    |  ⤓  | CE & EE |
| [Sidekiq](#sidekiq)                                   | Background jobs processor                                            |       ✅       |       ✅        |      ✅       |        ✅         |     ✅      |   ✅    |  ✅  | CE & EE |

### Component details

This document is designed to be consumed by systems administrators and GitLab Support Engineers who want to understand more about the internals of GitLab and how they work together.

When deployed, GitLab should be considered the amalgamation of the below processes. When troubleshooting or debugging, be as specific as possible as to which component you are referencing. That should increase clarity and reduce confusion.

**Layers**

GitLab can be considered to have two layers from a process perspective:

- **Monitoring**: Anything from this layer is not required to deliver GitLab the application, but allows administrators more insight into their infrastructure and what the service as a whole is doing.
- **Core**: Any process that is vital for the delivery of GitLab as a platform. If any of these processes halt, a GitLab outage results. For the Core layer, you can further divide into:
  - **Processors**: These processes are responsible for actually performing operations and presenting the service.
  - **Data**: These services store/expose structured data for the GitLab service.

#### Alertmanager

- [Project page](https://github.com/prometheus/alertmanager/blob/master/README.md)
- Configuration:
  - [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
  - [Charts](https://github.com/helm/charts/tree/master/stable/prometheus)
- Layer: Monitoring
- Process: `alertmanager`
- GitLab.com: [Monitoring of GitLab.com](https://about.gitlab.com/handbook/engineering/monitoring/)

[Alert manager](https://prometheus.io/docs/alerting/latest/alertmanager/) is a tool provided by Prometheus that _"handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integration such as email, PagerDuty, or Opsgenie. It also takes care of silencing and inhibition of alerts."_ You can read more in [issue #45740](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45740) about what we alert on.

#### Certificate management

- Project page:
  - [Omnibus](https://github.com/certbot/certbot/blob/master/README.rst)
  - [Charts](https://github.com/jetstack/cert-manager/blob/master/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/ssl.html)
  - [Charts](https://docs.gitlab.com/charts/installation/tls.html)
  - [Source](../install/installation.md#using-https)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/https.md)
- Layer: Core Service (Processor)
- GitLab.com: [Secrets Management](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#secrets-management)

#### Consul

- [Project page](https://github.com/hashicorp/consul/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/consul.md)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#postgresql)
- Layer: Core Service (Data)
- GitLab.com: [Consul](../user/gitlab_com/index.md#consul)

Consul is a tool for service discovery and configuration. Consul is distributed, highly available, and extremely scalable.

#### Database migrations

- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/database.html#disabling-automatic-database-migration)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/migrations/)
  - [Source](../update/upgrading_from_source.md#10-install-libraries-migrations-etc)
- Layer: Core Service (Data)

#### Elasticsearch

- [Project page](https://github.com/elastic/elasticsearch/)
- Configuration:
  - [Omnibus](../integration/elasticsearch.md)
  - [Charts](../integration/elasticsearch.md)
  - [Source](../integration/elasticsearch.md)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/elasticsearch.md)
- Layer: Core Service (Data)
- GitLab.com: [Get Advanced Search working on GitLab.com (Closed)](https://gitlab.com/groups/gitlab-org/-/epics/153) epic.

Elasticsearch is a distributed RESTful search engine built for the cloud.

#### Gitaly

- [Project page](https://gitlab.com/gitlab-org/gitaly/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/gitaly/index.md)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/gitaly/)
  - [Source](../install/installation.md#install-gitaly)
- Layer: Core Service (Data)
- Process: `gitaly`
- GitLab.com: [Service Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#service-architecture)

Gitaly is a service designed by GitLab to remove our need for NFS for Git storage in distributed deployments of GitLab (think GitLab.com or High Availability Deployments). As of 11.3.0, this service handles all Git level access in GitLab. You can read more about the project [in the project's README](https://gitlab.com/gitlab-org/gitaly).

#### Praefect

- [Project page](https://gitlab.com/gitlab-org/gitaly/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/gitaly/index.md)
  - [Source](../install/installation.md#install-gitaly)
- Layer: Core Service (Data)
- Process: `praefect`
- GitLab.com: [Service Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#service-architecture)

Praefect is a transparent proxy between each Git client and the Gitaly coordinating the replication of
repository updates to secondary nodes.

#### GitLab Geo

- Configuration:
  - [Omnibus](../administration/geo/setup/index.md)
  - [Charts](https://docs.gitlab.com/charts/advanced/geo/)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md)
- Layer: Core Service (Processor)

Geo is a premium feature built to help speed up the development of distributed teams by providing one or more read-only mirrors of a primary GitLab instance. This mirror (a Geo secondary site) reduces the time to clone or fetch large repositories and projects, or can be part of a Disaster Recovery solution.

#### GitLab Exporter

- [Project page](https://gitlab.com/gitlab-org/gitlab-exporter)
- Configuration:
  - [Omnibus](../administration/monitoring/prometheus/gitlab_exporter.md)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/gitlab-exporter/index.html)
- Layer: Monitoring
- Process: `gitlab-exporter`
- GitLab.com: [Monitoring of GitLab.com](https://about.gitlab.com/handbook/engineering/monitoring/)

GitLab Exporter is a process designed in house that allows us to export metrics about GitLab application internals to Prometheus. You can read more [in the project's README](https://gitlab.com/gitlab-org/gitlab-exporter).

#### GitLab Kubernetes Agent

- [Project page](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)
- Configuration:
  - [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/kas/index.html)

[GitLab Kubernetes Agent](../user/clusters/agent/index.md) is an active in-cluster
component for solving GitLab and Kubernetes integration tasks in a secure and
cloud-native way.

You can use it to sync deployments onto your Kubernetes cluster.

#### GitLab Pages

- Configuration:
  - [Omnibus](../administration/pages/index.md)
  - [Charts](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/37)
  - [Source](../install/installation.md#install-gitlab-pages)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/pages.md)
- Layer: Core Service (Processor)
- GitLab.com: [GitLab Pages](../user/gitlab_com/index.md#gitlab-pages)

GitLab Pages is a feature that allows you to publish static websites directly from a repository in GitLab.

You can use it either for personal or business websites, such as portfolios, documentation, manifestos, and business presentations. You can also attribute any license to your content.

#### GitLab Runner

- [Project page](https://gitlab.com/gitlab-org/gitlab-runner/blob/master/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/runner/)
  - [Charts](https://docs.gitlab.com/runner/install/kubernetes.html)
  - [Source](https://docs.gitlab.com/runner/)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md)
- Layer: Core Service (Processor)
- GitLab.com: [Runner](../user/gitlab_com/index.md#shared-runners)

GitLab Runner runs jobs and sends the results to GitLab.

GitLab CI/CD is the open-source continuous integration service included with GitLab that coordinates the testing. The old name of this project was `GitLab CI Multi Runner` but please use `GitLab Runner` (without CI) from now on.

#### GitLab Shell

- [Project page](https://gitlab.com/gitlab-org/gitlab-shell/-/blob/main/README.md)
- Configuration:
  - [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/)
  - [Source](../install/installation.md#install-gitlab-shell)
  - [GDK](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
- Layer: Core Service (Processor)
- GitLab.com: [Service Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#service-architecture)

[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) is a program designed at GitLab to handle SSH-based `git` sessions, and modifies the list of authorized keys. GitLab Shell is not a Unix shell nor a replacement for Bash or Zsh.

#### GitLab Workhorse

- [Project page](https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/README.md)
- Configuration:
  - [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/webservice/)
  - [Source](../install/installation.md#install-gitlab-workhorse)
- Layer: Core Service (Processor)
- Process: `gitlab-workhorse`
- GitLab.com: [Service Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#service-architecture)

[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) is a program designed at GitLab to help alleviate pressure from Puma. You can read more about the [historical reasons for developing](https://about.gitlab.com/blog/2016/04/12/a-brief-history-of-gitlab-workhorse/). It's designed to act as a smart reverse proxy to help speed up GitLab as a whole.

#### Grafana

- [Project page](https://github.com/grafana/grafana/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/monitoring/performance/grafana_configuration.md)
  - [Charts](https://docs.gitlab.com/charts/charts/globals#configure-grafana-integration)
- Layer: Monitoring
- GitLab.com: [GitLab triage Grafana dashboard](https://dashboards.gitlab.com/d/RZmbBr7mk/gitlab-triage?refresh=30s)

Grafana is an open source, feature rich metrics dashboard and graph editor for Graphite, Elasticsearch, OpenTSDB, Prometheus, and InfluxDB.

#### Jaeger

- [Project page](https://github.com/jaegertracing/jaeger/blob/master/README.md)
- Configuration:
  - [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4104)
  - [Charts](https://docs.gitlab.com/charts/charts/globals#tracing)
  - [Source](../development/distributed_tracing.md#enabling-distributed-tracing)
  - [GDK](../development/distributed_tracing.md#using-jaeger-in-the-gitlab-development-kit)
- Layer: Monitoring
- GitLab.com: [Configuration to enable Tracing for a GitLab instance](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4104) issue.

Jaeger, inspired by Dapper and OpenZipkin, is a distributed tracing system.
It can be used for monitoring microservices-based distributed systems.

For monitoring deployed apps, see [Jaeger tracing documentation](../operations/tracing.md)

#### Logrotate

- [Project page](https://github.com/logrotate/logrotate/blob/master/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/logs.html#logrotate)
- Layer: Core Service
- Process: `logrotate`

GitLab is comprised of a large number of services that all log. We started bundling our own Logrotate
as of GitLab 7.4 to make sure we were logging responsibly. This is just a packaged version of the common open source offering.

#### Mattermost

- [Project page](https://github.com/mattermost/mattermost-server/blob/master/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/gitlab-mattermost/)
  - [Charts](https://docs.mattermost.com/install/install-mmte-helm-gitlab-helm.html)
- Layer: Core Service (Processor)
- GitLab.com: [Mattermost](../user/project/integrations/mattermost.md)

Mattermost is an open source, private cloud, Slack-alternative from <https://mattermost.com>.

#### MinIO

- [Project page](https://github.com/minio/minio/blob/master/README.md)
- Configuration:
  - [Omnibus](https://min.io/download)
  - [Charts](https://docs.gitlab.com/charts/charts/minio/)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/object_storage.md)
- Layer: Core Service (Data)
- GitLab.com: [Storage Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#storage-architecture)

MinIO is an object storage server released under Apache License v2.0. It is compatible with Amazon S3 cloud storage service. It is best suited for storing unstructured data such as photos, videos, log files, backups, and container / VM images. Size of an object can range from a few KBs to a maximum of 5TB.

#### NGINX

- Project page:
  - [Omnibus](https://github.com/nginx/nginx)
  - [Charts](https://github.com/kubernetes/ingress-nginx/blob/master/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/)
  - [Charts](https://docs.gitlab.com/charts/charts/nginx/)
  - [Source](../install/installation.md#9-nginx)
- Layer: Core Service (Processor)
- Process: `nginx`
- GitLab.com: [Service Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#service-architecture)

NGINX has an Ingress port for all HTTP requests and routes them to the appropriate sub-systems within GitLab. We are bundling an unmodified version of the popular open source webserver.

#### Node Exporter

- [Project page](https://github.com/prometheus/node_exporter/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/monitoring/prometheus/node_exporter.md)
  - [Charts](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1332)
- Layer: Monitoring
- Process: `node-exporter`
- GitLab.com: [Monitoring of GitLab.com](https://about.gitlab.com/handbook/engineering/monitoring/)

[Node Exporter](https://github.com/prometheus/node_exporter) is a Prometheus tool that gives us metrics on the underlying machine (think CPU/Disk/Load). It's just a packaged version of the common open source offering from the Prometheus project.

#### Patroni

- [Project Page](https://github.com/zalando/patroni)
- Configuration:
  - [Omnibus](../administration/postgresql/replication_and_failover.md#patroni)
- Layer: Core Service (Data)
- Process: `patroni`
- GitLab.com: [Database Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#database-architecture)

#### PgBouncer

- [Project page](https://github.com/pgbouncer/pgbouncer/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/postgresql/pgbouncer.md)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#postgresql)
- Layer: Core Service (Data)
- GitLab.com: [Database Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#database-architecture)

Lightweight connection pooler for PostgreSQL.

#### PgBouncer Exporter

- [Project page](https://github.com/prometheus-community/pgbouncer_exporter/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/monitoring/prometheus/pgbouncer_exporter.md)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#postgresql)
- Layer: Monitoring
- GitLab.com: [Monitoring of GitLab.com](https://about.gitlab.com/handbook/engineering/monitoring/)

Prometheus exporter for PgBouncer. Exports metrics at 9127/metrics.

#### PostgreSQL

- [Project page](https://github.com/postgres/postgres/blob/master/README)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/database.html)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#postgresql)
  - [Source](../install/installation.md#6-database)
- Layer: Core Service (Data)
- Process: `postgresql`
- GitLab.com: [PostgreSQL](../user/gitlab_com/index.md#postgresql)

GitLab packages the popular Database to provide storage for Application meta data and user information.

#### PostgreSQL Exporter

- [Project page](https://github.com/wrouesnel/postgres_exporter/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/monitoring/prometheus/postgres_exporter.md)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#postgresql)
- Layer: Monitoring
- Process: `postgres-exporter`
- GitLab.com: [Monitoring of GitLab.com](https://about.gitlab.com/handbook/engineering/monitoring/)

[`postgres_exporter`](https://github.com/wrouesnel/postgres_exporter) is the community provided Prometheus exporter that delivers data about PostgreSQL to Prometheus for use in Grafana Dashboards.

#### Prometheus

- [Project page](https://github.com/prometheus/prometheus/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/monitoring/prometheus/index.md)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#prometheus)
- Layer: Monitoring
- Process: `prometheus`
- GitLab.com: [Prometheus](../user/gitlab_com/index.md#prometheus)

Prometheus is a time-series tool that helps GitLab administrators expose metrics about the individual processes used to provide GitLab the service.

#### Redis

- [Project page](https://github.com/antirez/redis/blob/unstable/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/redis.html)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#redis)
  - [Source](../install/installation.md#7-redis)
- Layer: Core Service (Data)
- Process: `redis`
- GitLab.com: [Service Architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/#service-architecture)

Redis is packaged to provide a place to store:

- session data
- temporary cache information
- background job queues

See our [Redis guidelines](redis.md) for more information about how GitLab uses Redis.

#### Redis Exporter

- [Project page](https://github.com/oliver006/redis_exporter/blob/master/README.md)
- Configuration:
  - [Omnibus](../administration/monitoring/prometheus/redis_exporter.md)
  - [Charts](https://docs.gitlab.com/charts/installation/deployment.html#redis)
- Layer: Monitoring
- Process: `redis-exporter`
- GitLab.com: [Monitoring of GitLab.com](https://about.gitlab.com/handbook/engineering/monitoring/)

[Redis Exporter](https://github.com/oliver006/redis_exporter) is designed to give specific metrics about the Redis process to Prometheus so that we can graph these metrics in Grafana.

#### Registry

- [Project page](https://github.com/docker/distribution/blob/master/README.md)
- Configuration:
  - [Omnibus](../update/upgrading_from_source.md#10-install-libraries-migrations-etc)
  - [Charts](https://docs.gitlab.com/charts/charts/registry/)
  - [Source](../administration/packages/container_registry.md#enable-the-container-registry)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/registry.md)
- Layer: Core Service (Processor)
- GitLab.com: [GitLab Container Registry](../user/packages/container_registry/index.md#build-and-push-by-using-gitlab-cicd)

The registry is what users use to store their own Docker images. The bundled
registry uses NGINX as a load balancer and GitLab as an authentication manager.
Whenever a client requests to pull or push an image from the registry, it
returns a `401` response along with a header detailing where to get an
authentication token, in this case the GitLab instance. The client then
requests a pull or push auth token from GitLab and retries the original request
to the registry. Learn more about [token authentication](https://docs.docker.com/registry/spec/auth/token/).

An external registry can also be configured to use GitLab as an auth endpoint.

#### Sentry

- [Project page](https://github.com/getsentry/sentry/)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/configuration.html#error-reporting-and-logging-with-sentry)
  - [Charts](https://docs.gitlab.com/charts/charts/globals#sentry-settings)
  - [Source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
  - [GDK](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
- Layer: Monitoring
- GitLab.com: [Searching Sentry](https://about.gitlab.com/handbook/support/workflows/500_errors.html#searching-sentry)

Sentry fundamentally is a service that helps you monitor and fix crashes in real time.
The server is in Python, but it contains a full API for sending events from any language, in any application.

For monitoring deployed apps, see the [Sentry integration docs](../operations/error_tracking.md)

#### Sidekiq

- [Project page](https://github.com/mperham/sidekiq/blob/master/README.md)
- Configuration:
  - [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)
  - [Minikube Minimal](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/index.html)
  - [Source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
  - [GDK](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
- Layer: Core Service (Processor)
- Process: `sidekiq`
- GitLab.com: [Sidekiq](../user/gitlab_com/index.md#sidekiq)

Sidekiq is a Ruby background job processor that pulls jobs from the Redis queue and processes them. Background jobs allow GitLab to provide a faster request/response cycle by moving work into the background.

#### Puma

Starting with GitLab 13.0, Puma is the default web server.

- [Project page](https://gitlab.com/gitlab-org/gitlab/-/blob/master/README.md)
- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/puma.html)
  - [Charts](https://docs.gitlab.com/charts/charts/gitlab/webservice/)
  - [Source](../install/installation.md#configure-it)
  - [GDK](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
- Layer: Core Service (Processor)
- Process: `puma`
- GitLab.com: [Puma](../user/gitlab_com/index.md#puma)

[Puma](https://puma.io/) is a Ruby application server that is used to run the core Rails Application that provides the user facing features in GitLab. Often this displays in process output as `bundle` or `config.ru` depending on the GitLab version.

#### LDAP Authentication

- Configuration:
  - [Omnibus](../administration/auth/ldap/index.md)
  - [Charts](https://docs.gitlab.com/charts/charts/globals.html#ldap)
  - [Source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
  - [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/ldap.md)
- Layer: Core Service (Processor)
- GitLab.com: [Product Tiers](https://about.gitlab.com/pricing/#gitlab-com)

#### Outbound Email

- Configuration:
  - [Omnibus](https://docs.gitlab.com/omnibus/settings/smtp.html)
  - [Charts](https://docs.gitlab.com/charts/installation/command-line-options.html#outgoing-email-configuration)
  - [Source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
  - [GDK](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
- Layer: Core Service (Processor)
- GitLab.com: [Mail configuration](../user/gitlab_com/index.md#mail-configuration)

#### Inbound Email

- Configuration:
  - [Omnibus](../administration/incoming_email.md)
  - [Charts](https://docs.gitlab.com/charts/installation/command-line-options.html#incoming-email-configuration)
  - [Source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
  - [GDK](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
- Layer: Core Service (Processor)
- GitLab.com: [Mail configuration](../user/gitlab_com/index.md#mail-configuration)

## GitLab by request type

GitLab provides two "interfaces" for end users to access the service:

- Web HTTP Requests (Viewing the UI/API)
- Git HTTP/SSH Requests (Pushing/Pulling Git Data)

It's important to understand the distinction as some processes are used in both and others are exclusive to a specific request type.

### GitLab Web HTTP request cycle

When making a request to an HTTP Endpoint (think `/users/sign_in`) the request takes the following path through the GitLab Service:

- NGINX - Acts as our first line reverse proxy.
- GitLab Workhorse - This determines if it needs to go to the Rails application or somewhere else to reduce load on Puma.
- Puma - Since this is a web request, and it needs to access the application, it routes to Puma.
- PostgreSQL/Gitaly/Redis - Depending on the type of request, it may hit these services to store or retrieve data.

### GitLab Git request cycle

Below we describe the different paths that HTTP vs. SSH Git requests take. There is some overlap with the Web Request Cycle but also some differences.

### Web request (80/443)

Git operations over HTTP use the stateless "smart" protocol described in the
[Git documentation](https://git-scm.com/docs/http-protocol), but responsibility
for handling these operations is split across several GitLab components.

Here is a sequence diagram for `git fetch`. Note that all requests pass through
NGINX as well as any other HTTP load balancers, but are not transformed in any
way by them. All paths are presented relative to a `/namespace/project.git` URL.

```mermaid
sequenceDiagram
    participant Git on client
    participant NGINX
    participant Workhorse
    participant Rails
    participant Gitaly
    participant Git on server

    Note left of Git on client: git fetch<br/>info-refs
    Git on client->>+Workhorse: GET /info/refs?service=git-upload-pack
    Workhorse->>+Rails: GET /info/refs?service=git-upload-pack
    Note right of Rails: Auth check
    Rails-->>-Workhorse: Gitlab::Workhorse.git_http_ok
    Workhorse->>+Gitaly: SmartHTTPService.InfoRefsUploadPack request
    Gitaly->>+Git on server: git upload-pack --stateless-rpc --advertise-refs
    Git on server-->>-Gitaly: git upload-pack response
    Gitaly-->>-Workhorse: SmartHTTPService.InfoRefsUploadPack response
    Workhorse-->>-Git on client: 200 OK

    Note left of Git on client: git fetch<br/>fetch-pack
    Git on client->>+Workhorse: POST /git-upload-pack
    Workhorse->>+Rails: POST /git-upload-pack
    Note right of Rails: Auth check
    Rails-->>-Workhorse: Gitlab::Workhorse.git_http_ok
    Workhorse->>+Gitaly: SmartHTTPService.PostUploadPack request
    Gitaly->>+Git on server: git upload-pack --stateless-rpc
    Git on server-->>-Gitaly: git upload-pack response
    Gitaly-->>-Workhorse: SmartHTTPService.PostUploadPack response
    Workhorse-->>-Git on client: 200 OK
```

The sequence is similar for `git push`, except `git-receive-pack` is used
instead of `git-upload-pack`.

### SSH request (22)

Git operations over SSH can use the stateful protocol described in the
[Git documentation](https://git-scm.com/docs/pack-protocol#_ssh_transport), but
responsibility for handling them is split across several GitLab components.

No GitLab components speak SSH directly - all SSH connections are made between
Git on the client machine and the SSH server, which terminates the connection.
To the SSH server, all connections are authenticated as the `git` user; GitLab
users are differentiated by the SSH key presented by the client.

Here is a sequence diagram for `git fetch`, assuming [Fast SSH key lookup](../administration/operations/fast_ssh_key_lookup.md)
is enabled. Note that `AuthorizedKeysCommand` is an executable provided by
[GitLab Shell](#gitlab-shell):

```mermaid
sequenceDiagram
    participant Git on client
    participant SSH server
    participant AuthorizedKeysCommand
    participant GitLab Shell
    participant Rails
    participant Gitaly
    participant Git on server

    Note left of Git on client: git fetch
    Git on client->>+SSH server: ssh git fetch-pack request
    SSH server->>+AuthorizedKeysCommand: gitlab-shell-authorized-keys-check git AAAA...
    AuthorizedKeysCommand->>+Rails: GET /internal/api/authorized_keys?key=AAAA...
    Note right of Rails: Lookup key ID
    Rails-->>-AuthorizedKeysCommand: 200 OK, command="gitlab-shell upload-pack key_id=1"
    AuthorizedKeysCommand-->>-SSH server: command="gitlab-shell upload-pack key_id=1"
    SSH server->>+GitLab Shell: gitlab-shell upload-pack key_id=1
    GitLab Shell->>+Rails: GET /internal/api/allowed?action=upload_pack&key_id=1
    Note right of Rails: Auth check
    Rails-->>-GitLab Shell: 200 OK, { gitaly: ... }
    GitLab Shell->>+Gitaly: SSHService.SSHUploadPack request
    Gitaly->>+Git on server: git upload-pack request
    Note over Git on client,Git on server: Bidirectional communication between Git client and server
    Git on server-->>-Gitaly: git upload-pack response
    Gitaly -->>-GitLab Shell: SSHService.SSHUploadPack response
    GitLab Shell-->>-SSH server: gitlab-shell upload-pack response
    SSH server-->>-Git on client: ssh git fetch-pack response
```

The `git push` operation is very similar, except `git receive-pack` is used
instead of `git upload-pack`.

If fast SSH key lookups are not enabled, the SSH server reads from the
`~git/.ssh/authorized_keys` file to determine what command to run for a given
SSH session. This is kept up to date by an [`AuthorizedKeysWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/authorized_keys_worker.rb)
in Rails, scheduled to run whenever an SSH key is modified by a user.

[SSH certificates](../administration/operations/ssh_certificates.md) may be used
instead of keys. In this case, `AuthorizedKeysCommand` is replaced with an
`AuthorizedPrincipalsCommand`. This extracts a username from the certificate
without using the Rails internal API, which is used instead of `key_id` in the
[`/api/internal/allowed`](internal_api.md) call later.

GitLab Shell also has a few operations that do not involve Gitaly, such as
resetting two-factor authentication codes. These are handled in the same way,
except there is no round-trip into Gitaly - Rails performs the action as part
of the [internal API](internal_api.md) call, and GitLab Shell streams the
response back to the user directly.

## System layout

When referring to `~git` in the pictures it means the home directory of the Git user which is typically `/home/git`.

GitLab is primarily installed within the `/home/git` user home directory as `git` user. Within the home directory is where the GitLab server software resides as well as the repositories (though the repository location is configurable).

The bare repositories are located in `/home/git/repositories`. GitLab is a Ruby on rails application so the particulars of the inner workings can be learned by studying how a Ruby on rails application works.

To serve repositories over SSH there's an add-on application called GitLab Shell which is installed in `/home/git/gitlab-shell`.

### Installation folder summary

To summarize here's the [directory structure of the `git` user home directory](../install/installation.md#gitlab-directory-structure).

### Processes

```shell
ps aux | grep '^git'
```

GitLab has several components to operate. It requires a persistent database
(PostgreSQL) and Redis database, and uses Apache `httpd` or NGINX to `proxypass`
Puma. All these components should run as different system users to GitLab
(for example, `postgres`, `redis`, and `www-data`, instead of `git`).

As the `git` user it starts Sidekiq and Puma (a simple Ruby HTTP server
running on port `8080` by default). Under the GitLab user there are normally 4
processes: `puma master` (1 process), `puma cluster worker`
(2 processes), `sidekiq` (1 process).

### Repository access

Repositories get accessed via HTTP or SSH. HTTP cloning/push/pull uses the GitLab API and SSH cloning is handled by GitLab Shell (previously explained).

## Troubleshooting

See the README for more information.

### Init scripts of the services

The GitLab init script starts and stops Puma and Sidekiq:

```plaintext
/etc/init.d/gitlab
Usage: service gitlab {start|stop|restart|reload|status}
```

Redis (key-value store/non-persistent database):

```plaintext
/etc/init.d/redis
Usage: /etc/init.d/redis {start|stop|status|restart|condrestart|try-restart}
```

SSH daemon:

```plaintext
/etc/init.d/sshd
Usage: /etc/init.d/sshd {start|stop|restart|reload|force-reload|condrestart|try-restart|status}
```

Web server (one of the following):

```plaintext
/etc/init.d/httpd
Usage: httpd {start|stop|restart|condrestart|try-restart|force-reload|reload|status|fullstatus|graceful|help|configtest}

$ /etc/init.d/nginx
Usage: nginx {start|stop|restart|reload|force-reload|status|configtest}
```

Persistent database:

```plaintext
$ /etc/init.d/postgresql
Usage: /etc/init.d/postgresql {start|stop|restart|reload|force-reload|status} [version ..]
```

### Log locations of the services

GitLab (includes Puma and Sidekiq logs):

- `/home/git/gitlab/log/` contains `application.log`, `production.log`, `sidekiq.log`, `puma.stdout.log`, `git_json.log` and `puma.stderr.log` normally.

GitLab Shell:

- `/home/git/gitlab-shell/gitlab-shell.log`

SSH:

- `/var/log/auth.log` auth log (on Ubuntu).
- `/var/log/secure` auth log (on RHEL).

NGINX:

- `/var/log/nginx/` contains error and access logs.

Apache `httpd`:

- [Explanation of Apache logs](https://httpd.apache.org/docs/2.2/logs.html).
- `/var/log/apache2/` contains error and output logs (on Ubuntu).
- `/var/log/httpd/` contains error and output logs (on RHEL).

Redis:

- `/var/log/redis/redis.log` there are also log-rotated logs there.

PostgreSQL:

- `/var/log/postgresql/*`

### GitLab specific configuration files

GitLab has configuration files located in `/home/git/gitlab/config/*`. Commonly referenced
configuration files include:

- `gitlab.yml`: GitLab configuration
- `puma.rb`: Puma web server settings
- `database.yml`: Database connection settings

GitLab Shell has a configuration file at `/home/git/gitlab-shell/config.yml`.

### Maintenance tasks

[GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master) provides Rake tasks with which you see version information and run a quick check on your configuration to ensure it is configured properly within the application. See [maintenance Rake tasks](../administration/raketasks/maintenance.md).
In a nutshell, do the following:

```shell
sudo -i -u git
cd gitlab
bundle exec rake gitlab:env:info RAILS_ENV=production
bundle exec rake gitlab:check RAILS_ENV=production
```

It's recommended to sign in to the `git` user using either `sudo -i -u git` or
`sudo su - git`. Although the `sudo` commands provided by GitLab work in Ubuntu,
they don't always work in RHEL.

## GitLab.com

The [GitLab.com architecture](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/)
is detailed for your reference, but this architecture is only useful if you have
millions of users.
