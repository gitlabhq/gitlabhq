---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate to the GitLab agent for Kubernetes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To connect your Kubernetes cluster with GitLab, you can use:

- [A GitOps workflow](../../clusters/agent/gitops.md).
- [A GitLab CI/CD workflow](../../clusters/agent/ci_cd_workflow.md).
- [A certificate-based integration](_index.md).

The certificate-based integration is
[**deprecated**](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)
in GitLab 14.5. The sunsetting plans are described:

- for [GitLab.com customers](../../../update/deprecations.md#gitlabcom-certificate-based-integration-with-kubernetes).
- for [Self-managed customers](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes).

If you are using the certificate-based integration, you should move to another workflow as soon as possible.

As a general rule, to migrate clusters that rely on GitLab CI/CD,
you can use the [CI/CD workflow](../../clusters/agent/ci_cd_workflow.md).
This workflow uses an agent to connect to your cluster. The agent:

- Is not exposed to the internet.
- Does not require full [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) access to GitLab.

NOTE:
The certificate-based integration was used for popular GitLab features like
GitLab Managed Apps, GitLab-managed clusters, and Auto DevOps.
Some features are currently available only when using certificate-based integration.

## Migrate cluster application deployments

### Migrate from GitLab-managed clusters

With GitLab-managed clusters, GitLab creates separate service accounts and namespaces
for every branch and deploys by using these resources.

The GitLab agent uses [impersonation](../../clusters/agent/ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation)
strategies to deploy to your cluster with restricted account access. To do so:

1. Choose the impersonation strategy that suits your needs.
1. Use Kubernetes RBAC rules to manage impersonated account permissions in Kubernetes.
1. Use the `access_as` attribute in your agent configuration file to define the impersonation.

### Migrate from Auto DevOps

In your Auto DevOps project, you can use the GitLab agent to connect with your Kubernetes cluster.

1. [Install an agent](../../clusters/agent/install/_index.md) in your cluster.
1. In GitLab, go to the project where you use Auto DevOps.
1. Add three variables. On the left sidebar, select **Settings > CI/CD** and expand **Variables**.
   - Add a key called `KUBE_INGRESS_BASE_DOMAIN` with the application deployment domain as the value.
   - Add a key called `KUBE_CONTEXT` with a value like `path/to/agent/project:agent-name`.
     Select the environment scope of your choice.
     If you are not sure what your agent's context is, edit your `.gitlab-ci.yml` file and add a job to see the available contexts:

     ```yaml
      deploy:
       image:
         name: bitnami/kubectl:latest
         entrypoint: [""]
       script:
       - kubectl config get-contexts
      ```

   - Add a key called `KUBE_NAMESPACE` with a value of the Kubernetes namespace for your deployments to target. Set the same environment scope.
1. Select **Add variable**.
1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. From the certificate-based clusters section, open the cluster that serves the same environment scope.
1. Select the **Details** tab and disable the cluster.
1. Edit your `.gitlab-ci.yml` file and ensure it's using the Auto DevOps template. For example:

   ```yaml
   include:
     template: Auto-DevOps.gitlab-ci.yml

   variables:
     KUBE_INGRESS_BASE_DOMAIN: 74.220.23.215.nip.io
     KUBE_CONTEXT: "gitlab-examples/ops/gitops-demo/k8s-agents:demo-agent"
     KUBE_NAMESPACE: "demo-agent"
   ```

1. To test your pipeline, on the left sidebar, select **Build > Pipelines** and then **New pipeline**.

For an example, [view this project](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service).

### Migrate generic deployments

Follow the process for the [CI/CD workflow](../../clusters/agent/ci_cd_workflow.md).

## Migrate from GitLab Managed applications

GitLab Managed Apps (GMA) were deprecated in GitLab 14.0, and removed in GitLab 15.0.
The agent for Kubernetes does not support them. To migrate from GMA to the
agent, go through the following steps:

1. [Migrate from GitLab Managed Apps to a cluster management project](../../clusters/migrating_from_gma_to_project_template.md).
1. [Migrate the cluster management project to use the agent](../../clusters/management_project_template.md).

## Migrate a cluster management project

See [how to use a cluster management project with the GitLab agent](../../clusters/management_project_template.md).

## Migrate cluster monitoring features

Cluster monitoring features are not yet supported by the GitLab agent for Kubernetes.
