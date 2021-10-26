---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Certificate-based cluster connection (DEPRECATED) **(FREE)**

WARNING:
In GitLab 14.5, the certificate-based method to connect Kubernetes clusters
to GitLab was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8),
as well as its related [features](#deprecated-features).

Connecting Kubernetes clusters to GitLab through cluster certificates is deprecated.
This method had the following issues:

- There were security issues as it required direct access to the Kube API by GitLab.
- The configuration options weren't flexible.
- The integration was flaky.
- Users were constantly reporting issues with features based on this model.

For this reason, we started to build features based on a new model, the
[GitLab Kubernetes Agent](../../clusters/agent/index.md).
Maintaining both methods in parallel caused a lot of confusion
and significantly increased the complexity to use, develop, maintain, and
document them. For this reason, we decided to deprecate them to focus on the
new model.

Certificate-based features will continue to receive security and critical
fixes, and features built on top of it will continue to work with the supported
Kubernetes versions. The removal of these features from GitLab is not
scheduled yet.
Follow this [epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
for updates.

You can find technical information about why we moved away from cluster certificates into
the Kubernetes Agent model on the [Agent's blueprint documentation](../../../architecture/blueprints/gitlab_to_kubernetes_communication/index.md).

## Deprecated features

- [Create a new cluster through cluster certificates](../../project/clusters/add_remove_clusters.md)
- [Connect an existing cluster through cluster certificates](../../project/clusters/add_existing_cluster.md)
- [Access controls](../../project/clusters/cluster_access.md)
- [GitLab-managed clusters](../../project/clusters/gitlab_managed_clusters.md)
- [GitLab Managed Apps](../../clusters/applications.md)
- [Deploy applications through certificate-based connection](../../project/clusters/deploy_to_cluster.md)
- [Cluster Management Project](../../clusters/management_project.md)
- [Cluster integrations](../../clusters/integrations.md)
- [Cluster cost management](../../clusters/cost_management.md)
- [Cluster environments](../../clusters/environments.md)
- [Canary Deployments](../../project/canary_deployments.md)
- [Serverless](../../project/clusters/serverless/index.md)
- [Deploy Boards](../../project/deploy_boards.md)
- [Pod logs](../../project/clusters/kubernetes_pod_logs.md)
- [Container Host Security](../../project/clusters/protect/container_host_security/index.md)
- [Clusters health](manage/clusters_health.md)
- [Crossplane integration](../../clusters/crossplane.md)
- [Auto Deploy](../../../topics/autodevops/stages.md#auto-deploy)
- [Web terminals](../../../administration/integration/terminal.md)

### Cluster levels

The concept of [project-level](../../project/clusters/index.md),
[group-level](../../group/clusters/index.md), and
[instance-level](../../instance/clusters/index.md) clusters becomes
extinct in the new model, although the functionality remains to some extent.

The Agent is always configured in a GitLab project, but you can:

- [Grant your cluster's access to GitLab groups through the Agent](../../clusters/agent/repository.md#authorize-groups-to-use-an-agent).
- [Share access to the Agent with other projects and groups through the CI/CD Tunnel](../../clusters/agent/ci_cd_tunnel.md#share-the-cicd-tunnel-provided-by-an-agent-with-other-projects-and-group).
