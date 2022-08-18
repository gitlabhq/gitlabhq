---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Operational Container Scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6346) in GitLab 14.8.

To view cluster vulnerabilities, you can view the [vulnerability report](../../application_security/vulnerabilities/index.md).
You can also configure your agent so the vulnerabilities are displayed with other agent information in GitLab.

## Enable operational container scanning **(ULTIMATE)**

You can use operational container scanning
to scan container images in your cluster for security vulnerabilities.

NOTE:
In GitLab 15.0 and later, you do not need to install Starboard operator in the Kubernetes cluster.

To begin scanning all resources in your cluster, add a `starboard`
configuration block to your agent configuration with a `cadence` field
containing a CRON expression for when the scans will be run.

```yaml
starboard:
  cadence: '0 0 * * *' # Daily at 00:00 (Kubernetes cluster time)
```

The `cadence` field is required. GitLab supports the following types of CRON syntax for the cadence field:

- A daily cadence of once per hour at a specified hour, for example: `0 18 * * *`
- A weekly cadence of once per week on a specified day and at a specified hour, for example: `0 13 * * 0`

It is possible that other elements of the CRON syntax will work in the cadence field, however, GitLab does not officially test or support them.

By default, operational container scanning will attempt to scan the workloads in all
namespaces for vulnerabilities. The `vulnerability_report` block has a `namespaces`
field which can be used to restrict which namespaces are scanned. For example,
if you would like to scan only the `development`, `staging`, and `production`
namespaces, you can use this configuration:

```yaml
starboard:
  cadence: '0 0 * * *'
  vulnerability_report:
    namespaces:
      - development
      - staging
      - production
```

## View cluster vulnerabilities

Prerequisite:

- You must have at least the Developer role.

To view vulnerability information in GitLab:

1. On the top bar, select **Menu > Projects** and find the project that contains the agent configuration file.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select the **Agent** tab.
1. Select an agent to view the cluster vulnerabilities.

![Cluster agent security tab UI](../img/cluster_agent_security_tab_v14_8.png)

This information can also be found under [operational vulnerabilities](../../../user/application_security/vulnerability_report/index.md#operational-vulnerabilities).
