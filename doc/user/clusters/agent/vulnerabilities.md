---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Container vulnerability scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6346) in GitLab 14.8.

To view cluster vulnerabilities, you can view the [vulnerability report](../../application_security/vulnerabilities/index.md).
You can also configure your agent so the vulnerabilities are displayed with other agent information in GitLab.

## View cluster vulnerabilities

Prerequisite:

- You must have at least the Developer role.
- [Cluster image scanning](../../application_security/cluster_image_scanning/index.md)
  must be part of your build process.

To view vulnerability information in GitLab:

1. On the top bar, select **Menu > Projects** and find the project that contains the agent configuration file.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select the **Agent** tab.
1. Select the agent you want to see the vulnerabilities for.

![Cluster agent security tab UI](../img/cluster_agent_security_tab_v14_8.png)

## Enable cluster vulnerability scanning **(ULTIMATE)**

You can use [cluster image scanning](../../application_security/cluster_image_scanning/index.md)
to scan container images in your cluster for security vulnerabilities.

To begin scanning all resources in your cluster, add a `starboard`
configuration block to your agent configuration file with no `filters`:

```yaml
starboard:
  vulnerability_report:
    filters: []
```

The namespaces that are able to be scanned depend on the [Starboard Operator install mode](https://aquasecurity.github.io/starboard/latest/operator/configuration/#install-modes).
By default, the Starboard Operator only scans resources in the `default` namespace. To change this
behavior, edit the `STARBOARD_OPERATOR` environment variable in the `starboard-operator` deployment
definition.

By adding filters, you can limit scans by:

- Resource name
- Kind
- Container name
- Namespace

```yaml
starboard:
  vulnerability_report:
    filters:
      - namespaces:
        - staging
        - production
        kinds:
        - Deployment
        - DaemonSet
        containers:
        - ruby
        - postgres
        - nginx
        resources:
        - my-app-name
        - postgres
        - ingress-nginx
```

A resource is scanned if the resource matches any of the given names and all of the given filter
types (`namespaces`, `kinds`, `containers`, `resources`). If a filter type is omitted, then all
names are scanned. In this example, a resource isn't scanned unless it has a container named `ruby`,
`postgres`, or `nginx`, and it's a `Deployment`:

```yaml
starboard:
  vulnerability_report:
    filters:
      - kinds:
        - Deployment
        containers:
        - ruby
        - postgres
        - nginx
```

There is also a global `namespaces` field that applies to all filters:

```yaml
starboard:
  vulnerability_report:
    namespaces:
    - production
    filters:
    - kinds:
      - Deployment
    - kinds:
      - DaemonSet
      resources:
      - log-collector
```

In this example, the following resources are scanned:

- All deployments (`Deployment`) in the `production` namespace.
- All daemon sets (`DaemonSet`) named `log-collector` in the `production` namespace.
