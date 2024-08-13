---
stage: Secure
group: Composition analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Operational container scanning

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/368828) the starboard directive in GitLab 15.4. The starboard directive is scheduled for removal in GitLab 16.0.

## Supported architectures

In GitLab agent for Kubernetes 16.10.0 and later and GitLab agent Helm Chart 1.25.0 and later, operational container scanning (OCS) is supported for `linux/arm64` and `linux/amd64`. For earlier versions, only `linux/amd64` is supported.

## Enable operational container scanning

You can use OCS to scan container images in your cluster for security vulnerabilities.
In GitLab agent 16.9 and later, OCS uses a [wrapper image](https://gitlab.com/gitlab-org/security-products/analyzers/trivy-k8s-wrapper) around [Trivy](https://github.com/aquasecurity/trivy) to scan images for vulnerabilities.
Before GitLab 16.9, OCS directly used the [Trivy](https://github.com/aquasecurity/trivy) image.

OCS can be configured to run on a cadence by using `agent config` or a project's scan execution policy.

NOTE:
If both `agent config` and `scan execution policies` are configured, the configuration from `scan execution policy` takes precedence.

### Enable via agent configuration

To enable scanning of images within your Kubernetes cluster via the agent configuration, add a `container_scanning` configuration block to your agent
configuration with a `cadence` field containing a [CRON expression](https://en.wikipedia.org/wiki/Cron) for when the scans are run.

```yaml
container_scanning:
  cadence: '0 0 * * *' # Daily at 00:00 (Kubernetes cluster time)
```

The `cadence` field is required. GitLab supports the following types of CRON syntax for the cadence field:

- A daily cadence of once per hour at a specified hour, for example: `0 18 * * *`
- A weekly cadence of once per week on a specified day and at a specified hour, for example: `0 13 * * 0`

NOTE:
Other elements of the [CRON syntax](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) may work in the cadence field if supported by the [cron](https://github.com/robfig/cron) we are using in our implementation, however, GitLab does not officially test or support them.

NOTE:
The CRON expression is evaluated in [UTC](https://www.timeanddate.com/worldclock/timezone/utc) using the system-time of the Kubernetes-agent pod.

By default, operational container scanning does not scan any workloads for vulnerabilities.
You can set the `vulnerability_report` block with the `namespaces`
field which can be used to select which namespaces are scanned. For example,
if you would like to scan only the `default`, `kube-system` namespaces, you can use this configuration:

```yaml
container_scanning:
  cadence: '0 0 * * *'
  vulnerability_report:
    namespaces:
      - default
      - kube-system
```

For every target namespace, all images in the following workload resources are scanned:

- Pod
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- Job

### Enable via scan execution policies

To enable scanning of all images within your Kubernetes cluster via scan execution policies, we can use the
[scan execution policy editor](../../application_security/policies/scan_execution_policies.md#scan-execution-policy-editor)
To create a new schedule rule.

NOTE:
The Kubernetes agent must be running in your cluster to scan running container images

NOTE:
Operational Container Scanning operates independently of GitLab pipelines. It is fully automated and managed by the Kubernetes Agent, which initiates new scans at the scheduled time configured in the Scan Execution Policy. The agent creates a dedicated Job within your cluster to perform the scan and report findings back to GitLab.

Here is an example of a policy which enables operational container scanning within the cluster the Kubernetes agent is attached to:

```yaml
- name: Enforce Container Scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

The keys for a schedule rule are:

- `cadence` (required): a [CRON expression](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) for when the scans are run
- `agents:<agent-name>` (required): The name of the agent to use for scanning
- `agents:<agent-name>:namespaces` (optional): The Kubernetes namespaces to scan. If omitted, all namespaces are scanned

NOTE:
Other elements of the [CRON syntax](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) may work in the cadence field if supported by the [cron](https://github.com/robfig/cron) we are using in our implementation, however, GitLab does not officially test or support them.

NOTE:
The CRON expression is evaluated in [UTC](https://www.timeanddate.com/worldclock/timezone/utc) using the system-time of the Kubernetes-agent pod.

You can view the complete schema within the [scan execution policy documentation](../../application_security/policies/scan_execution_policies.md#scan-execution-policies-schema).

## Configure scanner resource requirements

By default the scanner pod's default resource requirements are:

```yaml
requests:
  cpu: 100m
  memory: 100Mi
limits:
  cpu: 500m
  memory: 500Mi
```

You can customize it with a `resource_requirements` field.

```yaml
container_scanning:
  resource_requirements:
    requests:
      cpu: '0.2'
      memory: 200Mi
    limits:
      cpu: '0.7'
      memory: 700Mi
```

When using a fractional value for CPU, format the value as a string.

NOTE:
Resource requirements can only be set up using the agent configuration. If you enabled `Operational Container Scanning` through `scan execution policies`, you would need to define the resource requirements within the agent configuration file.

## View cluster vulnerabilities

To view vulnerability information in GitLab:

1. On the left sidebar, select **Search or go to** and find the project that contains the agent configuration file.
1. Select **Operate > Kubernetes clusters**.
1. Select the **Agent** tab.
1. Select an agent to view the cluster vulnerabilities.

![Cluster agent security tab UI](../img/cluster_agent_security_tab_v14_8.png)

This information can also be found under [operational vulnerabilities](../../../user/application_security/vulnerability_report/index.md#operational-vulnerabilities).

NOTE:
You must have at least the Developer role.

## Scanning private images

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415451) in GitLab 16.4.

To scan private images, the scanner relies on the image pull secrets (direct references and from the service account) to pull the image.

## Limitations

In GitLab agent 16.9 and later, operational container scanning:

- handles Trivy reports of up to 100MB. For previous releases this limit is 10MB.
- is [disabled](../../../development/fips_compliance.md#unsupported-features-in-fips-mode) when the GitLab agent runs in `fips` mode.

## Troubleshooting

### `Error running Trivy scan. Container terminated reason: OOMKilled`

OCS might fail with an OOM error if there are too many resources to be scanned or if the images being scanned are large.
To resolve this, [configure the resource requirement](#configure-scanner-resource-requirements) to increase the amount of memory available.
