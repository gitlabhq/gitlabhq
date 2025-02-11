---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes clusters
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To connect clusters to GitLab, use the [GitLab agent](../../clusters/agent/_index.md).

## Certificate-based Kubernetes integration (deprecated)

WARNING:
In GitLab 14.5, the certificate-based method to connect Kubernetes clusters
to GitLab was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8),
as well as its related [features](#deprecated-features). In GitLab Self-Managed 17.0 and later,
this feature is disabled by default. For GitLab SaaS users, this feature is available until
GitLab 15.9 for users who have at least one certificate-based cluster enabled in their namespace hierarchy.
For GitLab SaaS users that never used this feature previously, it is no longer available.

The certificate-based Kubernetes integration with GitLab is deprecated.
It had the following issues:

- There were security issues as it required direct access to the Kubernetes API by GitLab.
- The configuration options weren't flexible.
- The integration was flaky.
- Users were constantly reporting issues with features based on this model.

For this reason, we started to build features based on a new model, the
[GitLab agent](../../clusters/agent/_index.md).
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
the GitLab agent model on the [agent's design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/gitlab_to_kubernetes_communication/).

If you need more time to migrate to GitLab agent, you can [enable the feature flag](../../../administration/feature_flags.md)
named `certificate_based_clusters`, which was [introduced in GitLab 15.0](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes).
This feature flag re-enables the certificate-based Kubernetes integration.

## Deprecated features

- [Connect an existing cluster through cluster certificates](../../project/clusters/add_existing_cluster.md)
- [Access controls](../../project/clusters/cluster_access.md)
- [GitLab-managed clusters](../../project/clusters/gitlab_managed_clusters.md)
- [Deploy applications through certificate-based connection](../../project/clusters/deploy_to_cluster.md)
- [Cluster Management Project](../../clusters/management_project.md)
- [Cluster environments](../../clusters/environments.md)
- [Show Canary Ingress deployments on deploy boards](../../project/canary_deployments.md#show-canary-ingress-deployments-on-deploy-boards-deprecated)
- [Deploy Boards](../../project/deploy_boards.md)
- [Web terminals](../../../administration/integration/terminal.md)

### Cluster levels

The concept of [project-level](../../project/clusters/_index.md),
[group-level](../../group/clusters/_index.md), and
[instance-level](../../instance/clusters/_index.md) clusters becomes
extinct in the new model, although the functionality remains to some extent.

The agent is always configured in a single GitLab project and you can expose the cluster connection to other projects and groups to [access it from GitLab CI/CD](../../clusters/agent/ci_cd_workflow.md).
By doing so, you are granting these projects and groups access to the same cluster, which is similar to group-level clusters' use case.
