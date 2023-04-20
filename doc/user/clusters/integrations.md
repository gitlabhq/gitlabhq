---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Cluster integrations (deprecated) **(FREE)**

> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
> - [Disabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) in GitLab 15.0.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `certificate_based_clusters`.

GitLab provides several ways to integrate applications to your
Kubernetes cluster.

To enable cluster integrations, first add a Kubernetes cluster to a GitLab
[project](../project/clusters/index.md) or
[group](../group/clusters/index.md) or
[instance](../instance/clusters/index.md).

You can install your applications manually as shown in the following sections, or use the
[Cluster management project template](management_project_template.md) that automates the
installation.

Although, the [Cluster management project template](management_project_template.md) still
requires that you manually do the last steps of this section,
[Enable Prometheus integration for your cluster](#enable-prometheus-integration-for-your-cluster). [An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/326565)
to automate this step.

Prometheus cluster integrations can only be enabled for clusters [connected through cluster certificates](../project/clusters/add_existing_cluster.md).

To enable Prometheus for your cluster connected through the [GitLab agent](agent/index.md), you can [integrate it manually](../project/integrations/prometheus.md#manual-configuration-of-prometheus).

There is no option to enable Elastic Stack for your cluster if it is connected with the GitLab agent.
Follow this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/300230) for updates.

## Prometheus cluster integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55244) in GitLab 13.11.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5. However, you can **still use** Prometheus
for Kubernetes clusters connected to GitLab through the
[agent](agent/index.md) by [enabling Prometheus manually](../project/integrations/prometheus.md#manual-configuration-of-prometheus).

You can integrate your Kubernetes cluster with
[Prometheus](https://prometheus.io/) for monitoring key metrics of your
apps directly from the GitLab UI.

Once enabled, you can see metrics from services available in the
[metrics library](../project/integrations/prometheus_library/index.md).

### Prometheus Prerequisites

To use this integration:

1. Prometheus must be installed in your cluster in the `gitlab-managed-apps` namespace.
1. The `Service` resource for Prometheus must be named `prometheus-prometheus-server`.

You can manage your Prometheus however you like, but as an example, you can set
it up using [Helm](https://helm.sh/) as follows:

```shell
# Create the required Kubernetes namespace
kubectl create ns gitlab-managed-apps

# Download Helm chart values that is compatible with the requirements above.
# These are included in the Cluster Management project template.
wget https://gitlab.com/gitlab-org/project-templates/cluster-management/-/raw/master/applications/prometheus/values.yaml

# Add the Prometheus community Helm chart repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Install Prometheus
helm install prometheus prometheus-community/prometheus -n gitlab-managed-apps --values values.yaml
```

Alternatively, you can use your preferred installation method to install
Prometheus as long as you meet the requirements above.

### Enable Prometheus integration for your cluster

To enable the Prometheus integration for your cluster:

1. Go to the cluster's page:
      - For a [project-level cluster](../project/clusters/index.md), go to your project's
      **Infrastructure > Kubernetes clusters**.
      - For a [group-level cluster](../group/clusters/index.md), go to your group's
      **Kubernetes** page.
      - For an [instance-level cluster](../instance/clusters/index.md), go to your instance's
      **Kubernetes** page.
1. Select the **Integrations** tab.
1. Check the **Enable Prometheus integration** checkbox.
1. Select **Save changes**.
1. Go to the **Health** tab to see your cluster's metrics.
