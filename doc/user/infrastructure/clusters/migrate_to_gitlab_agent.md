---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate to the GitLab agent for Kubernetes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To connect your Kubernetes cluster with GitLab, you can use:

- [A GitOps workflow](../../clusters/agent/gitops.md).
- [A GitLab CI/CD workflow](../../clusters/agent/ci_cd_workflow.md).
- [A certificate-based integration](_index.md).

The certificate-based integration is
[**deprecated**](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)
in GitLab 14.5. The sunsetting plans are described:

- for [GitLab.com customers](../../../update/deprecations.md#gitlabcom-certificate-based-integration-with-kubernetes).
- for [GitLab Self-Managed customers](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes).

If you are using the certificate-based integration, you should move to another workflow as soon as possible.

As a general rule, to migrate clusters that rely on GitLab CI/CD,
you can use the [CI/CD workflow](../../clusters/agent/ci_cd_workflow.md).
This workflow uses an agent to connect to your cluster. The agent:

- Is not exposed to the internet.
- Does not require full [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) access to GitLab.

{{< alert type="note" >}}

The certificate-based integration was used for popular GitLab features like
GitLab-managed Apps, GitLab-managed clusters, and Auto DevOps.

{{< /alert >}}

## Find certificate-based clusters

You can find all the certificate-based clusters within a GitLab instance or group, including subgroups and projects, using [a dedicated API](../../../api/cluster_discovery.md#discover-certificate-based-clusters). Querying the API with a group ID returns all the certificate-based clusters defined at or below the provided group.

Clusters defined in parent groups are not returned in this case. This behavior helps group Owners find all the clusters they need to migrate.

Disabled clusters are returned as well to avoid accidentally leaving clusters behind.

{{< alert type="note" >}}

The cluster discovery API does not work for personal namespaces.

{{< /alert >}}

## Migrate generic deployments

To migrate generic deployments:

1. Install the [GitLab agent for Kubernetes](../../clusters/agent/install/_index.md).
1. Follow the CI/CD workflow to [authorize the agent to access](../../clusters/agent/ci_cd_workflow.md#authorize-the-agent) groups and projects, or to [secure access with impersonation].(../../clusters/agent/ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation).
1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. From the certificate-based clusters section, open the cluster that serves the same environment scope.
1. Select the **Details** tab and turn off the cluster.

## Migrate from GitLab-managed clusters to Kubernetes resources

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

With GitLab-managed clusters, GitLab creates separate service accounts and namespaces for every branch and deploys by using these resources.

Now, you can use [GitLab-managed Kubernetes resources](../../clusters/agent/managed_kubernetes_resources.md) to self-serve resources with enhanced security controls.

With GitLab-managed Kubernetes resources, you can:

- Set up environments securely without manual intervention.
- Control resource creation and access without giving developers administrative cluster permissions.
- Provide self-service capabilities for [developers](https://handbook.gitlab.com/handbook/product/personas/#sasha-software-developer) when they create a new project or environment.
- Allow developers to deploy testing and development versions in dedicated or shared namespaces.

Prerequisites:

- Install the [GitLab agent for Kubernetes](../../clusters/agent/install/_index.md).
- [Authorize the agent](../../clusters/agent/ci_cd_workflow.md#authorize-the-agent) to access relevant projects or groups.
- Check the status of the **Namespace per environment** checkbox in your certificate-based cluster integration page.

To migrate from GitLab-managed clusters to GitLab-managed Kubernetes resources:

1. If you're migrating an existing environment, configure an agent for the environment either through the [dashboard for Kubernetes](../../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard) or the [Environments API](../../../api/environments.md).
1. Configure the agent to turn on resource management in your agent configuration file:

   ```yaml
   ci_access:
      projects:
        - id: <your_group/your_project>
          access_as:
            ci_job: {}
          resource_management:
            enabled: true
      groups:
        - id: <your_other_group>
          access_as:
            ci_job: {}
          resource_management:
            enabled: true
   ```

1. Create an environment template under `.gitlab/agents/<agent-name>/environment_templates/default.yaml`. Check the status of the **Namespace per environment** checkbox in your certificate-based cluster integration page.

   If **Namespace per environment** was checked, use the following template:

   ```yaml
   objects:
     - apiVersion: v1
       kind: Namespace
       metadata:
         name: {{ .project.slug }}-{{ .project.id }}-{{ .environment.slug }}
     - apiVersion: rbac.authorization.k8s.io/v1
       kind: RoleBinding
       metadata:
         name: bind-{{ .agent.id }}-{{ .project.id }}-{{ .environment.slug }}
         namespace: {{ .project.slug }}-{{ .project.id }}-{{ .environment.slug }}
       subjects:
         - kind: Group
           apiGroup: rbac.authorization.k8s.io
           name: gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}
       roleRef:
         apiGroup: rbac.authorization.k8s.io
         kind: ClusterRole
         name: admin
   ```

   If **Namespace per environment** was unchecked, use the following template:

   ```yaml
   objects:
     - apiVersion: v1
       kind: Namespace
       metadata:
         name: {{ .project.slug }}-{{ .project.id }}
     - apiVersion: rbac.authorization.k8s.io/v1
       kind: RoleBinding
       metadata:
         name: bind-{{ .agent.id }}-{{ .project.id }}-{{ .environment.slug }}
         namespace: {{ .project.slug }}-{{ .project.id }}
       subjects:
         - kind: Group
           apiGroup: rbac.authorization.k8s.io
           name: gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}
       roleRef:
         apiGroup: rbac.authorization.k8s.io
         kind: ClusterRole
         name: admin
   ```

1. In your CI/CD configuration, use the agent with the `environment.kubernetes.agent: <path/to/agent/project:agent-name>` syntax.
1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. From the certificate-based clusters section, open the cluster that serves the same environment scope.
1. Select the **Details** tab and turn off the cluster.

## Migrate from Auto DevOps

In your Auto DevOps project, you can use the GitLab agent to connect with your Kubernetes cluster.

Prerequisites

- Install the [GitLab agent for Kubernetes](../../clusters/agent/install/_index.md).
- [Authorize the agent](../../clusters/agent/ci_cd_workflow.md#authorize-the-agent) to access relevant projects or groups.

To migrate from Auto DevOps:

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

## Migrate from GitLab-managed applications

GitLab-managed Apps (GMA) were deprecated in GitLab 14.0, and removed in GitLab 15.0.
The agent for Kubernetes does not support them. To migrate from GMA to the
agent, go through the following steps:

1. [Migrate from GitLab-managed Apps to a cluster management project](../../clusters/migrating_from_gma_to_project_template.md).
1. [Migrate the cluster management project to use the agent](../../clusters/management_project_template.md).

## Migrate a cluster management project

See [how to use a cluster management project with the GitLab agent](../../clusters/management_project_template.md).

## Migrate cluster monitoring features

Once you connect a Kubernetes cluster to GitLab using the agent for Kubernetes, you can use [the dashboard for Kubernetes](../../../ci/environments/kubernetes_dashboard.md) after enabling [user access](../../clusters/agent/user_access.md).
