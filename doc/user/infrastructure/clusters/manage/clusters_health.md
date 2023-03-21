---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Clusters health (deprecated) **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4701) in GitLab 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/208224) from GitLab Ultimate to GitLab Free in 13.2.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5. However, you can **still use** Prometheus
for Kubernetes clusters connected to GitLab by [enabling Prometheus manually](../../../project/integrations/prometheus.md#manual-configuration-of-prometheus).

When [the Prometheus cluster integration is enabled](../../../clusters/integrations.md#prometheus-cluster-integration), GitLab monitors the cluster's health. At the top of the cluster settings page, CPU and Memory utilization is displayed, along with the total amount available. Keeping an eye on cluster resources can be important, if the cluster runs out of memory pods may be shutdown or fail to start.

![Cluster Monitoring](img/k8s_cluster_monitoring.png)
