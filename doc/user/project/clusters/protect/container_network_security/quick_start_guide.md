---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Getting started with Container Network Security **(FREE)**

The following steps are recommended for installing Container Network Security.

## Installation steps

The following steps are recommended to install and use Container Network Security through GitLab:

1. [Install at least one runner and connect it to GitLab](https://docs.gitlab.com/runner/).
1. [Create a group](../../../../group/#create-a-group).
1. [Connect a Kubernetes cluster to the group](../../add_remove_clusters.md).
1. [Create a cluster management project and associate it with the Kubernetes cluster](../../../../clusters/management_project.md).

1. Install and configure an Ingress node:

   - [Install the Ingress node via CI/CD (Cluster Management Project)](../../../../clusters/applications.md#install-ingress-using-gitlab-cicd).
   - Navigate to the Kubernetes page and enter the [DNS address for the external endpoint](../../gitlab_managed_clusters.md#base-domain)
     into the **Base domain** field on the **Details** tab. Save the changes to the Kubernetes
     cluster.

1. [Install and configure Cilium](#use-the-cluster-management-template-to-install-cilium).
1. Be sure to restart all pods that were running before Cilium was installed by running this command
   in your cluster:

   `kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod`

   You can skip this step if `nodeinit.restartPods` is set to `true` on your Helm chart.

It's possible to install and manage Cilium in other ways. For example, you could use the GitLab Helm
chart to install Cilium manually in a Kubernetes cluster, and then connect it back to GitLab.
However, such methods aren't documented or officially supported by GitLab.

### Use the Cluster Management template to install Cilium

[Cilium](https://cilium.io/) is a networking plug-in for Kubernetes that you can use to implement
support for [`NetworkPolicy`](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
resources. For more information, see [Network Policies](../../../../../topics/autodevops/stages.md#network-policy).

You can use the [Cluster Management Project Template](../../../../clusters/management_project_template.md)
to install Cilium in your Kubernetes cluster.

1. In your cluster management project, go to `helmfile.yaml` and uncomment `- path: applications/cilium/helmfile.yaml`.
1. In `applications/cilium/helmfile.yaml`, set `clusterType` to either `gke` or `eks` based on which Kubernetes provider your are using.

    ```yaml
    environments:
      default:
        values:
        # Set to "gke" or "eks" based on your cluster type
        - clusterType: ""
    ```

1. Merge or push these changes to the default branch of your cluster management project,
and [GitLab CI/CD](../../../../../ci/README.md) will automatically install Cilium.

WARNING:
Installation and removal of the Cilium requires a **manual**
[restart](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-helm/#restart-unmanaged-pods)
of all affected pods in all namespaces to ensure that they are
[managed](https://docs.cilium.io/en/stable/operations/troubleshooting/#ensure-managed-pod)
by the correct networking plug-in. When Hubble is enabled, its related pod might require a
restart depending on whether it started prior to Cilium. For more information, see
[Failed Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment)
in the Kubernetes docs.

NOTE:
Major upgrades might require additional setup steps. For more information, see
the official [upgrade guide](https://docs.cilium.io/en/stable/operations/upgrade/).

Support for installing the Cilium application is provided by the
GitLab Container Security group. If you run into unknown issues,
[open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new), and ping at
least 2 people from the
[Container Security group](https://about.gitlab.com/handbook/product/categories/#container-security-group).

### Configure the Cilium Helm chart

You can customize Cilium's Helm variables by editing the `applications/cilium/values.yaml`
file in your cluster management project. Refer to the [Cilium Helm reference](https://docs.cilium.io/en/stable/helm-reference/)
for the available configuration options.

By default, Cilium's
[audit mode](https://docs.cilium.io/en/stable/gettingstarted/policy-creation/#enable-policy-audit-mode)
is enabled. In audit mode, Cilium doesn't drop disallowed packets. You
can use `policy-verdict` log to observe policy-related decisions. You
can disable audit mode by setting `policyAuditMode: false` in
`applications/cilium/values.yaml`.

The Cilium monitor log for traffic is logged out by the
`cilium-monitor` sidecar container. You can check these logs with the following command:

```shell
kubectl -n gitlab-managed-apps logs -l k8s-app=cilium -c cilium-monitor
```

You can disable the monitor log in `application/cilium/values.yaml`:

```yaml
monitor:
  enabled: false
```

The [Hubble](https://github.com/cilium/hubble) monitoring daemon is enabled by default
and it's set to collect per namespace flow metrics. This metrics are accessible on the
[Threat Monitoring](../../../../application_security/threat_monitoring/index.md)
dashboard. You can disable Hubble by adding the following to
`applications/cilium/values.yaml`:

```yaml
hubble:
  enabled: false
```

You can also adjust Helm values for Hubble by using
`applications/cilium/values.yaml`:

```yaml
hubble:
  enabled: true
  metrics:
    enabled:
    - 'flow:sourceContext=namespace;destinationContext=namespace'
```

## Managing Network Policies

Managing NetworkPolicies through GitLab is advantageous over managing the policies in Kubernetes
directly. Kubernetes doesn't provide a GUI editor, a change control process, or a revision history.
Network Policies can be managed through GitLab in one of two ways:

- Management through a YAML file in each application's project (for projects using Auto DevOps). For
  more information, see the [Network Policy documentation](../../../../../topics/autodevops/stages.md#network-policy).
- Management through the GitLab Policy management UI (for projects not using Auto DevOps). For more
  information, see the [Container Network Policy documentation](../../../../application_security/threat_monitoring/index.md#container-network-policy-management) (Ultimate only).

Each method has benefits and drawbacks:

|  | YAML method | UI method (Ultimate only) |
|--|:------------|:-------------------------------|
| **Benefits** | A change control process is possible by requiring [MR Approvals](../../../merge_requests/approvals/index.md). All changes are fully tracked and audited in the same way that Git tracks the history of any file in its repository. | The UI provides a simple rules editor for users who are less familiar with the YAML syntax of NetworkPolicies. This view is a live representation of the policies currently deployed in the Kubernetes cluster. The UI also allows for multiple network policies to be created per environment. |
| **Drawbacks** | Only one network policy can be deployed per environment (although that policy can be as detailed as needed). Also, if changes were made in Kubernetes directly rather than through the `auto-deploy-values.yaml` file, the YAML file's contents don't represent the actual state of policies deployed in Kubernetes. | Policy changes aren't audited and a change control process isn't available. |

Users are encouraged to choose one of the two methods to manage their policies. If users attempt to
use both methods simultaneously, when the application project pipeline runs the contents of the
NetworkPolicy in the `auto-deploy-values.yaml` file may override policies configured in the UI
editor.

## Monitoring throughput **(ULTIMATE)**

To view statistics for Container Network Security, you must follow the installation steps above and
configure GitLab integration with Prometheus. Also, if you use custom Helm values for Cilium, you
must enable Hubble with flow metrics for each namespace by adding the following lines to
your [Cilium values](#use-the-cluster-management-template-to-install-cilium):

```yaml
hubble:
  enabled: true
  metrics:
    enabled:
      - 'flow:sourceContext=namespace;destinationContext=namespace'
```

Additional information about the statistics page is available in the
[documentation that describes the Threat Management UI](../../../../application_security/threat_monitoring/index.md#container-network-policy).

## Forwarding logs to a SIEM

Cilium logs can be forwarded to a SIEM or an external logging system through syslog protocol by
installing and configuring Fluentd. Fluentd can be installed through the GitLab
[Cluster Management Project](../../../../clusters/applications.md#install-fluentd-using-gitlab-cicd).

## Viewing the logs

Cilium logs can be viewed by running the following command in your Kubernetes cluster:

```shell
kubectl -n gitlab-managed-apps logs -l k8s-app=cilium -c cilium-monitor
```

## Troubleshooting

### Traffic is not being blocked as expected

By default, Cilium is installed in Audit mode only, meaning that NetworkPolicies log policy
violations but don't block any traffic. To set Cilium to Blocking mode, you must add the following
lines to the `applications/cilium/values.yaml` file in your cluster management project:

```yaml
config:
  policyAuditMode: false

monitor:
  eventTypes: ["drop"]
```

### Traffic is not being allowed as expected

Keep in mind that when Cilium is set to blocking mode (rather than Audit mode), NetworkPolicies
operate on an allow-list basis. If one or more NetworkPolicies apply to a node, then all traffic
that doesn't match at least one Policy is blocked. To resolve, add NetworkPolicies defining the
traffic that you want to allow in the node.

### Trouble connecting to the cluster

Occasionally, your CI/CD pipeline may fail or have trouble connecting to the cluster. Here are some
initial troubleshooting steps that resolve the most common problems:

1. [Clear the cluster cache](../../gitlab_managed_clusters.md#clearing-the-cluster-cache).
1. If things still aren't working, a more assertive set of actions may help get things back into a
   good state:

   - Stop and [delete the problematic environment](../../../../../ci/environments/index.md#delete-a-stopped-environment) in GitLab.
   - Delete the relevant namespace in Kubernetes by running `kubectl delete namespaces <insert-some-namespace-name>` in your Kubernetes cluster.
   - Rerun the application project pipeline to redeploy the application.

**Related documentation links:**

- [Cluster Management Project](../../../../clusters/management_project.md)
