---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Cilium with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

[Cilium](https://cilium.io/) is a networking plugin for Kubernetes that you can use to implement
support for [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
resources. For more information, see [Network Policies](../../../../../topics/autodevops/stages.md#network-policy).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see the
[Container Network Security Demo for GitLab 12.8](https://www.youtube.com/watch?v=pgUEdhdhoUI).

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install cilium you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/cilium/helmfile.yaml
```

and update the `applications/cilium/values.yaml` to set the `clusterType`:

```yaml
# possible values are gke or eks
clusterType: gke
```

The `clusterType` variable enables the recommended Helm variables for a corresponding cluster type.
You can check the recommended variables for each cluster type in the official documentation:

- [Google GKE](https://docs.cilium.io/en/v1.8/gettingstarted/k8s-install-gke/#deploy-cilium)
- [AWS EKS](https://docs.cilium.io/en/v1.8/gettingstarted/k8s-install-eks/#deploy-cilium)

Do not use `clusterType` for sandbox environments like [Minikube](https://minikube.sigs.k8s.io/docs/).

You can customize Cilium's Helm variables by defining the
`applications/cilium/values.yaml` file in your cluster
management project. Refer to the
[Cilium chart](https://github.com/cilium/cilium/tree/master/install/kubernetes/cilium)
for the available configuration options.

You can check Cilium's installation status on the cluster management page:

- [Project-level cluster](../../../../project/clusters/index.md): Navigate to your project's
  **Infrastructure > Kubernetes clusters** page.
- [Group-level cluster](../../../../group/clusters/index.md): Navigate to your group's
  **Kubernetes** page.

WARNING:
Installation and removal of the Cilium requires a **manual**
[restart](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-helm/#restart-unmanaged-pods)
of all affected pods in all namespaces to ensure that they are
[managed](https://docs.cilium.io/en/v1.8/operations/troubleshooting/#ensure-managed-pod)
by the correct networking plugin. Whenever Hubble is enabled, its related pod might require a
restart depending on whether it started prior to Cilium. For more information, see
[Failed Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment)
in the Kubernetes docs.

NOTE:
Major upgrades might require additional setup steps. For more information, see
the official [upgrade guide](https://docs.cilium.io/en/v1.8/operations/upgrade/).

By default, Cilium's
[audit mode](https://docs.cilium.io/en/v1.8/gettingstarted/policy-creation/#enable-policy-audit-mode)
is enabled. In audit mode, Cilium doesn't drop disallowed packets. You
can use `policy-verdict` log to observe policy-related decisions. You
can disable audit mode by adding the following to
`applications/cilium/values.yaml`:

```yaml
config:
  policyAuditMode: false

agent:
  monitor:
    eventTypes: ["drop"]
```

The Cilium monitor log for traffic is logged out by the
`cilium-monitor` sidecar container. You can check these logs with the following command:

```shell
kubectl -n gitlab-managed-apps logs -l k8s-app=cilium -c cilium-monitor
```

You can disable the monitor log in `.gitlab/managed-apps/cilium/values.yaml`:

```yaml
agent:
  monitor:
    enabled: false
```

The [Hubble](https://github.com/cilium/hubble) monitoring daemon is enabled by default
and it's set to collect per namespace flow metrics. This metrics are accessible on the
[Threat Monitoring](../../../../application_security/threat_monitoring/index.md)
dashboard. You can disable Hubble by adding the following to
`applications/cilium/values.yaml`:

```yaml
global:
  hubble:
    enabled: false
```

You can also adjust Helm values for Hubble by using
`applications/cilium/values.yaml`:

```yaml
global:
  hubble:
    enabled: true
    metrics:
      enabled:
      - 'flow:sourceContext=namespace;destinationContext=namespace'
```

Support for installing the Cilium managed application is provided by the
GitLab Container Security group. If you run into unknown issues,
[open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new), and ping at
least 2 people from the
[Container Security group](https://about.gitlab.com/handbook/product/categories/#container-security-group).
