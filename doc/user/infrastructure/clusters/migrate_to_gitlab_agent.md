---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrate to the GitLab Agent for Kubernetes **(FREE)**

The first integration between GitLab and Kubernetes used cluster certificates
to connect the cluster to GitLab.
This method was [deprecated](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)
in GitLab 14.5 in favor of the [GitLab Agent for Kubernetes](../../clusters/agent/index.md).

To make sure your clusters connected to GitLab do not break in the future,
we recommend you migrate to the GitLab Agent as soon as possible by following
the processes described in this document.

The certificate-based integration was used for some popular GitLab features such as,
GitLab Managed Apps, GitLab-managed clusters, and Auto DevOps.

As a general rule, migrating clusters that rely on GitLab CI/CD can be
achieved using the [CI/CD Tunnel](../../clusters/agent/ci_cd_tunnel.md)
provided by the Agent.

NOTE:
The GitLab Agent for Kubernetes does not intend to provide feature parity with the
certificate-based cluster integrations. As a result, the Agent doesn't support
all the features available to clusters connected through certificates.

## Migrate cluster application deployments

### Migrate from GitLab-managed clusters

With GitLab-managed clusters, GitLab creates separate service accounts and namespaces
for every branch and deploys using these resources.

To achieve a similar result with the GitLab Agent, you can use [impersonation](../../clusters/agent/repository.md#use-impersonation-to-restrict-project-and-group-access)
strategies to deploy to your cluster with restricted account access. To do so:

1. Choose the impersonation strategy that suits your needs.
1. Use Kubernetes RBAC rules to manage impersonated account permissions in Kubernetes.
1. Use the `access_as` attribute in your Agent’s configuration file to define the impersonation.

### Migrate from Auto DevOps

To configure your Auto DevOps project to use the GitLab Agent:

1. Follow the steps to [install an agent](../../clusters/agent/install/index.md) on your cluster.
1. Go to the project in which you use Auto DevOps.
1. From the sidebar, select **Settings > CI/CD** and expand **Variables**.
1. Select **Add new variable**.
1. Add `KUBE_CONTEXT` as the key, `path/to/agent/project:agent-name` as the value, and select the environment scope of your choice.
1. Select **Add variable**.
1. Repeat the process to add another variable, `KUBE_NAMESPACE`, setting the value for the Kubernetes namespace you want your deployments to target, and set the same environment scope from the previous step.
1. From the sidebar, select **Infrastructure > Kubernetes clusters**.
1. From the certificate-based clusters section, open the cluster that serves the same environment scope.
1. Select the **Details** tab and disable the cluster.
1. To activate the changes, from the project's sidebar, select **CI/CD > Variables > Run pipeline**.

### Migrate generic deployments

When you use Kubernetes contexts to reach the cluster from GitLab, you can use the [CI/CD Tunnel](../../clusters/agent/ci_cd_tunnel.md)
directly. It injects the available contexts into your CI environment automatically:

1. Follow the steps to [install an agent](../../clusters/agent/install/index.md) on your cluster.
1. Go to the project in which you use Auto DevOps.
1. From the sidebar, select **Settings > CI/CD** and expand **Variables**.
1. Select **Add new variable**.
1. Add `KUBE_CONTEXT` as the key, `path/to/agent-configuration-project:your-agent-name` as the value, and select the environment scope of your choice.
1. Edit your `.gitlab-ci.yml` file and set the Kubernetes context to the `KUBE_CONTEXT` you defined in the previous step:

   ```yaml
   <your job name>:
     script:
     - kubectl config use-context $KUBE_CONTEXT
   ```

## Migrate from GitLab Managed Applications

Follow the process to [migrate from GitLab Managed Apps to the Cluster Management Project](../../clusters/migrating_from_gma_to_project_template.md).

## Migrating a Cluster Management project

See [how to use a cluster management project with the GitLab Agent](../../clusters/management_project_template.md#use-the-agent-with-the-cluster-management-project-template).

## Migrate cluster monitoring features

Cluster monitoring features are not supported by the GitLab Agent for Kubernetes yet.
