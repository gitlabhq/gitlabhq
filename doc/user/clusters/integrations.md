---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster integrations **(FREE)**

GitLab provides several ways to integrate applications to your
Kubernetes cluster.

To enable cluster integrations, first add a Kubernetes cluster to a GitLab
[project](../project/clusters/add_remove_clusters.md) or [group](../group/clusters/index.md#group-level-kubernetes-clusters).

## Prometheus cluster integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55244) in GitLab 13.11.

You can integrate your Kubernetes cluster with
[Prometheus](https://prometheus.io/) for monitoring key metrics of your
apps directly from the GitLab UI.

Once enabled, you will see metrics from services available in the
[metrics library](../project/integrations/prometheus_library/index.md).

Prerequisites:

To benefit from this integration, you must have Prometheus
installed in your cluster with the following requirements:

1. Prometheus must be installed inside the `gitlab-managed-apps` namespace.
1. The `Service` resource for Prometheus must be named `prometheus-prometheus-server`.

You can use the following commands to install Prometheus to meet the requirements for cluster integrations:

```shell
# Create the require Kubernetes namespace
kubectl create ns gitlab-managed-apps

# Download Helm chart values that is compatible with the requirements above.
# You should substitute the tag that corresponds to the GitLab version in the url
# - https://gitlab.com/gitlab-org/gitlab/-/raw/<tag>/vendor/prometheus/values.yaml
#
wget https://gitlab.com/gitlab-org/gitlab/-/raw/v13.9.0-ee/vendor/prometheus/values.yaml

# Add the Prometheus community helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Install Prometheus
helm install prometheus prometheus-community/prometheus -n gitlab-managed-apps --values values.yaml
```

Alternatively, you can use your preferred installation method to install
Prometheus as long as you meet the requirements above.

### Enable Prometheus integration for your cluster

To enable the Prometheus integration for your cluster:

1. Go to the cluster's page:
      - For a [project-level cluster](../project/clusters/index.md), navigate to your project's
      **Operations > Kubernetes**.
      - For a [group-level cluster](../group/clusters/index.md), navigate to your group's
      **Kubernetes** page.
1. Select the **Integrations** tab.
1. Check the **Enable Prometheus integration** checkbox.
1. Click **Save changes**.
1. Go to the **Health** tab to see your cluster's metrics.
