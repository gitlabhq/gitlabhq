---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrate to the GitLab agent for Kubernetes **(FREE)**

To connect your Kubernetes cluster with GitLab, you can use:

- [A GitOps workflow](../../clusters/agent/gitops.md).
- [A GitLab CI/CD workflow](../../clusters/agent/ci_cd_tunnel.md).
- [A certificate-based integration](index.md).

The certificate-based integration is
[**deprecated**](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)
in GitLab 14.5. It is expected to be
[turned off by default in 15.0](../../../update/deprecations.md#certificate-based-integration-with-kubernetes)
and removed in GitLab 15.6.

If you are using the certificate-based integration, you should move to another workflow as soon as possible. 

As a general rule, to migrate clusters that rely on GitLab CI/CD,
you can use the [CI/CD workflow](../../clusters/agent/ci_cd_tunnel.md).
This workflow uses an agent to connect to your cluster. The agent:

- Is not exposed to the internet.
- Does not require full cluster-admin access to GitLab.

NOTE:
The certificate-based integration was used for popular GitLab features like
GitLab Managed Apps, GitLab-managed clusters, and Auto DevOps.
Some features are currently available only when using certificate-based integration.

## Migrate cluster application deployments

### Migrate from GitLab-managed clusters

With GitLab-managed clusters, GitLab creates separate service accounts and namespaces
for every branch and deploys by using these resources.

The GitLab agent uses [impersonation](../../clusters/agent/ci_cd_tunnel.md#use-impersonation-to-restrict-project-and-group-access)
strategies to deploy to your cluster with restricted account access. To do so:

1. Choose the impersonation strategy that suits your needs.
1. Use Kubernetes RBAC rules to manage impersonated account permissions in Kubernetes.
1. Use the `access_as` attribute in your agent configuration file to define the impersonation.

### Migrate from Auto DevOps

To configure your Auto DevOps project to use the GitLab agent:

1. Follow the steps to [install an agent](../../clusters/agent/install/index.md) in your cluster.
1. Go to the project where you use Auto DevOps.
1. On the left sidebar, select **Settings > CI/CD** and expand **Variables**.
1. Select **Add new variable**.
1. Add `KUBE_CONTEXT` as the key, `path/to/agent/project:agent-name` as the value, and select the environment scope of your choice.
1. Select **Add variable**.
1. Repeat the process to add another variable, `KUBE_NAMESPACE`, setting the value for the Kubernetes namespace you want your deployments to target, and set the same environment scope from the previous step.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. From the certificate-based clusters section, open the cluster that serves the same environment scope.
1. Select the **Details** tab and disable the cluster.
1. To activate the changes, on the left sidebar, select **CI/CD > Variables > Run pipeline**.

For an example, [view this project](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service).

### Migrate generic deployments

Follow the process for the [CI/CD workflow](../../clusters/agent/ci_cd_tunnel.md).

## Migrate from GitLab Managed applications

Follow the process to [migrate from GitLab Managed Apps to the cluster management project](../../clusters/migrating_from_gma_to_project_template.md).

## Migrate a cluster management project

See [how to use a cluster management project with the GitLab agent](../../clusters/management_project_template.md).

## Migrate cluster monitoring features

Cluster monitoring features are not yet supported by the GitLab agent for Kubernetes.
