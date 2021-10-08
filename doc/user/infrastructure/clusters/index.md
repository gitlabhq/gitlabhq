---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Kubernetes clusters **(FREE)**

> - Project-level clusters [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/35954) in GitLab 10.1.
> - Group-level clusters [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34758) in GitLab 11.6.
> - Instance-level clusters [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/39840) in GitLab 11.11.

Kubernetes is a container orchestration platform to deploy applications
in a cluster without downtime and that scales as you need.

With the GitLab integration with Kubernetes, you can:

1. [Connect your cluster](#connect-your-cluster-to-gitlab).
1. [Manage your cluster](#manage-your-cluster).
1. [Deploy your cluster](#deploy-to-your-cluster).

See the [Kubernetes clusters versions supported by GitLab](connect/index.md#supported-cluster-versions).

## Connect your cluster to GitLab

Learn how to [create new and connect existing clusters to GitLab](connect/index.md).

## Manage your cluster

- [Cluster Management Project](../../clusters/management_project.md):
create a project to manage your cluster's shared resources requiring
`cluster-admin` privileges such as an Ingress controller.
  - [Cluster Management Project Template](../../clusters/management_project_template.md): start a cluster management project directly from a template.
  - [Migrate to Cluster Management Project](../../clusters/migrating_from_gma_to_project_template.md): migrate from the deprecated GitLab Managed Apps to Cluster Management Projects.
  - [GitLab Managed Apps](../../clusters/applications.md) (deprecated in favor of Cluster Management Projects): configure applications in your cluster directly from GitLab.
- [Cluster integrations](../../clusters/integrations.md): install
third-party applications into your cluster and manage them from GitLab.
- [GitLab-managed clusters](../../project/clusters/gitlab_managed_clusters.md):
enable GitLab to automatically create resources for your clusters.
- [Cost management](../../clusters/cost_management.md): see insights into your cluster's resource usage.
- [Crossplane integration](../../clusters/crossplane.md): manage your cluster's resources and cloud infrastructure with Crossplane.

### Monitor your cluster

- [Prometheus monitoring](../../project/integrations/prometheus_library/kubernetes.md): detect and monitor Kubernetes metrics with Prometheus.
- [NGINX monitoring](../../project/integrations/prometheus_library/nginx.md): automatically monitor NGINX Ingress.
- [Clusters health](manage/clusters_health.md): monitor your cluster's health, such as CPU and memory usage.

### Secure your cluster

- [Container Host Security](../../project/clusters/protect/container_host_security/index.md): monitor and block activity inside a container and enforce security policies across the cluster.
- [Container Network security](../../project/clusters/protect/container_network_security/index.md): filter traffic going in and out of the cluster and traffic between pods through a firewall with Cilium NetworkPolicies.

## Deploy to your cluster

- [CI/CD Tunnel](../../clusters/agent/ci_cd_tunnel.md): use the CI/CD Tunnel to run Kubernetes commands from different projects.
- [Inventory object](deploy/inventory_object.md): track objects applied to a cluster configured with the Kubernetes Agent.
- [Auto DevOps](../../../topics/autodevops/index.md): enable Auto DevOps
to allow GitLab automatically detect, build, test, and deploy applications.
- [Cluster environments](../../clusters/environments.md): view CI/CD environments deployed to Kubernetes clusters.
- [Canary Deployments](../../project/canary_deployments.md): deploy app updates to a small portion of the fleet with this Continuous Delivery strategy.
- [Deploy to your cluster](../../project/clusters/deploy_to_cluster.md):
deploy applications into your cluster using cluster certificates.
- [Deploy Boards](../../project/deploy_boards.md): view the current health and status of each CI/CD environment running on your cluster, and the status of deployment pods.
- [Pod logs](../../project/clusters/kubernetes_pod_logs.md): view the logs of your cluster's running pods.
- [Serverless](../../project/clusters/serverless/index.md) (deprecated): deploy Serverless applications in Kubernetes environments and cloud Function as a Service (FaaS) environments.
