---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster integrations **(FREE)**

GitLab provides several ways to integrate applications to your
Kubernetes cluster.

To enable cluster integrations, first add a Kubernetes cluster to a GitLab
[project](../project/clusters/add_remove_clusters.md) or
[group](../group/clusters/index.md#group-level-kubernetes-clusters) or
[instance](../instance/clusters/index.md).

You can install your applications manually as shown in the following sections, or use the
[Cluster management project template](management_project_template.md) that automates the
installation.

Although, the [Cluster management project template](management_project_template.md) still
requires that you manually do the last steps of these sections,
[Enable Prometheus integration for your cluster](#enable-prometheus-integration-for-your-cluster)
or [Enable Elastic Stack integration for your cluster](#enable-elastic-stack-integration-for-your-cluster)
depending on which application you are installing. We plan to also automate this step in the future,
see the [opened issue](https://gitlab.com/gitlab-org/gitlab/-/issues/326565).

## Prometheus cluster integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55244) in GitLab 13.11.

You can integrate your Kubernetes cluster with
[Prometheus](https://prometheus.io/) for monitoring key metrics of your
apps directly from the GitLab UI.

[Alerts](../../operations/metrics/alerts.md) can be configured the same way as
for [external Prometheus instances](../../operations/metrics/alerts.md#external-prometheus-instances).

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
      - For a [project-level cluster](../project/clusters/index.md), navigate to your project's
      **Infrastructure > Kubernetes clusters**.
      - For a [group-level cluster](../group/clusters/index.md), navigate to your group's
      **Kubernetes** page.
      - For an [instance-level cluster](../instance/clusters/index.md), navigate to your instance's
      **Kubernetes** page.
1. Select the **Integrations** tab.
1. Check the **Enable Prometheus integration** checkbox.
1. Click **Save changes**.
1. Go to the **Health** tab to see your cluster's metrics.

## Elastic Stack cluster integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61077) in GitLab 13.12.

You can integrate your cluster with [Elastic
Stack](https://www.elastic.co/elastic-stack/) to index and [query your pod
logs](../project/clusters/kubernetes_pod_logs.md).

### Elastic Stack Prerequisites

To use this integration:

1. Elasticsearch 7.x or must be installed in your cluster in the
   `gitlab-managed-apps` namespace.
1. The `Service` resource must be called `elastic-stack-elasticsearch-master`
   and expose the Elasticsearch API on port `9200`.
1. The logs are expected to be [Filebeat container logs](https://www.elastic.co/guide/en/beats/filebeat/7.x/filebeat-input-container.html)
   following the [7.x log structure](https://www.elastic.co/guide/en/beats/filebeat/7.x/exported-fields-log.html)
   and include [Kubernetes metadata](https://www.elastic.co/guide/en/beats/filebeat/7.x/add-kubernetes-metadata.html).

You can manage your Elastic Stack however you like, but as an example, you can
use [this Elastic Stack chart](https://gitlab.com/gitlab-org/charts/elastic-stack) to get up and
running:

```shell
# Create the required Kubernetes namespace
kubectl create namespace gitlab-managed-apps

# Download Helm chart values that is compatible with the requirements above.
# These are included in the Cluster Management project template.
wget https://gitlab.com/gitlab-org/project-templates/cluster-management/-/raw/master/applications/elastic-stack/values.yaml

# Add the GitLab Helm chart repository
helm repo add gitlab https://charts.gitlab.io

# Install Elastic Stack
helm install prometheus gitlab/elastic-stack -n gitlab-managed-apps --values values.yaml
```

### Enable Elastic Stack integration for your cluster

To enable the Elastic Stack integration for your cluster:

1. Go to the cluster's page:
      - For a [project-level cluster](../project/clusters/index.md), navigate to your project's
      **Infrastructure > Kubernetes clusters**.
      - For a [group-level cluster](../group/clusters/index.md), navigate to your group's
      **Kubernetes** page.
      - For an [instance-level cluster](../instance/clusters/index.md), navigate to your instance's
      **Kubernetes** page.
1. Select the **Integrations** tab.
1. Check the **Enable Prometheus integration** checkbox.
1. Click **Save changes**.
1. Go to the **Health** tab to see your cluster's metrics.
