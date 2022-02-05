---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Connecting a Kubernetes cluster with GitLab

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223061) in GitLab 13.4.
> - Support for `grpcs` [introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/7) in GitLab 13.6.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300960) in GitLab 13.10, KAS became available on GitLab.com under `wss://kas.gitlab.com` through an Early Adopter Program.
> - Introduced in GitLab 13.11, the GitLab Agent became available to every project on GitLab.com.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Renamed](https://gitlab.com/groups/gitlab-org/-/epics/7167) from "GitLab Kubernetes Agent" to "GitLab Agent for Kubernetes" in GitLab 14.6.

The [GitLab Agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) ("Agent", for short)
is an active in-cluster component for connecting Kubernetes clusters to GitLab safely to support cloud-native deployment, management, and monitoring.

The Agent is installed into the cluster through code, providing you with a fast, safe, stable, and scalable solution.

With GitOps, you can manage containerized clusters and applications from a Git repository that:

- Is the single source of truth of your system.
- Is the single place where you operate your system.
- Is a single resource to monitor your system.

By combining GitLab, Kubernetes, and GitOps, it results in a robust infrastructure:

- GitLab as the GitOps operator.
- Kubernetes as the automation and convergence system.
- GitLab CI/CD as the Continuous Integration and Continuous Deployment engine.

Beyond that, you can use all the features offered by GitLab as
the all-in-one DevOps platform for your product and your team.

## Supported cluster versions

GitLab is committed to support at least two production-ready Kubernetes minor
versions at any given time. We regularly review the versions we support, and
provide a three-month deprecation period before we remove support of a specific
version. The range of supported versions is based on the evaluation of:

- The versions supported by major managed Kubernetes providers.
- The versions [supported by the Kubernetes community](https://kubernetes.io/releases/version-skew-policy/#supported-versions).

GitLab supports the following Kubernetes versions, and you can upgrade your
Kubernetes version to any supported version at any time:

- 1.20 (support ends on July 22, 2022)
- 1.19 (support ends on February 22, 2022)
- 1.18 (support ends on November 22, 2021)
- 1.17 (support ends on September 22, 2021)

[Adding support to other versions of Kubernetes is managed under this epic](https://gitlab.com/groups/gitlab-org/-/epics/4827).

Some GitLab features may support versions outside the range provided here.

## Agent's features

By using the Agent, you can:

- Connect GitLab with a Kubernetes cluster behind a firewall or a
Network Address Translation (NAT).
- Have real-time access to API endpoints in your cluster from GitLab CI/CD.
- Use GitOps to configure your cluster through the [Agent's repository](repository.md).
- Perform pull-based or push-based GitOps deployments.
- Configure [Network Security Alerts](#kubernetes-network-security-alerts)
based on [Container Network Policies](../../application_security/policies/index.md#container-network-policy).
- Track objects applied to your cluster through [inventory objects](../../infrastructure/clusters/deploy/inventory_object.md).
- Use the [CI/CD Tunnel](ci_cd_tunnel.md) to access Kubernetes clusters
from GitLab CI/CD jobs while keeping the cluster's APIs safe and unexposed
to the internet.
- [Deploy the GitLab Runner in a Kubernetes cluster](https://docs.gitlab.com/runner/install/kubernetes-agent.html).

See the [Agent roadmap](https://gitlab.com/groups/gitlab-org/-/epics/3329) to track its development.

To contribute to the Agent, see the [Agent's development documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc).

## Agent's GitOps workflow **(PREMIUM)**

The Agent uses multiple GitLab projects to provide a flexible workflow
that can suit various needs. This diagram shows these repositories and the main
actors involved in a deployment:

```mermaid
sequenceDiagram
  participant D as Developer
  participant A as Application code repository
  participant M as Manifest repository
  participant K as GitLab Agent
  participant C as Agent configuration repository
  loop Regularly
    K-->>C: Grab the configuration
  end
  D->>+A: Pushing code changes
  A->>M: Updating manifest
  loop Regularly
    K-->>M: Watching changes
    M-->>K: Pulling and applying changes
  end
```

For more details, refer to our [architecture documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md#high-level-architecture) in the Agent project.

## Install the Agent in your cluster

To connect your cluster to GitLab, [install the Agent on your cluster](install/index.md).

## GitOps deployments **(PREMIUM)**

To perform GitOps deployments with the Agent, you need:

- A properly-configured Kubernetes cluster where the Agent is running.
- A [configuration repository](repository.md) that contains a
`config.yaml` file, which tells the Agent the repositories to synchronize
with the cluster.
- A manifest repository that contains manifest files. Any changes to manifest files are applied to the cluster.

You can use a single GitLab project or different projects for the Agent
configuration and manifest files, as follows:

- Single GitLab project (recommended): When you use a single repository to hold
  both the manifest and the configuration files, these projects can be either
  private or public.
- Two GitLab projects: When you use two different GitLab projects (one for
  manifest files and another for configuration files), the manifests project must
  be public, while the configuration project can be either private or public.

Support for separated private manifest and configuration repositories is tracked in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/220912).

## Kubernetes Network Security Alerts **(ULTIMATE)**

The GitLab Agent also provides an integration with Cilium. This integration provides a simple way to
generate network policy-related alerts and to surface those alerts in GitLab.

There are several components that work in concert for the Agent to generate the alerts:

- A working Kubernetes cluster.
- Cilium integration through either of these options:
  - Installation through [cluster management template](../../project/clusters/protect/container_network_security/quick_start_guide.md#use-the-cluster-management-template-to-install-cilium).
  - Enablement of [hubble-relay](https://docs.cilium.io/en/v1.8/concepts/overview/#hubble) on an
    existing installation.
- One or more network policies through any of these options:
  - Use the [Container Network Policy editor](../../application_security/policies/index.md#container-network-policy-editor) to create and manage policies.
  - Use an [AutoDevOps](../../application_security/policies/index.md#container-network-policy) configuration.
  - Add the required labels and annotations to existing network policies.
- A configuration repository with [Cilium configured in `config.yaml`](repository.md#surface-network-security-alerts-from-cluster-to-gitlab)

The setup process follows the same [Agent's installation steps](install/index.md),
with the following differences:

- When you define a configuration repository, you must do so with [Cilium settings](repository.md#surface-network-security-alerts-from-cluster-to-gitlab).
- You do not need to specify the `gitops` configuration section.

## Remove an agent

You can remove an agent using the [GitLab UI](#remove-an-agent-through-the-gitlab-ui) or through the [GraphQL API](#remove-an-agent-with-the-gitlab-graphql-api).

### Remove an agent through the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323055) in GitLab 14.7.

To remove an agent from the UI:

1. Go to your agent's configuration repository.
1. From your project's sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select your agent from the table, and then in the **Options** column, click the vertical ellipsis
(**{ellipsis_v}**) button and select **Delete agent**.

### Remove an agent with the GitLab GraphQL API

1. Get the `<cluster-agent-token-id>` from a query in the interactive GraphQL explorer.
For GitLab.com, go to <https://gitlab.com/-/graphql-explorer> to open GraphQL Explorer.
For self-managed GitLab instances, go to `https://gitlab.example.com/-/graphql-explorer`, replacing `gitlab.example.com` with your own instance's URL.

   ```graphql
   query{
     project(fullPath: "<full-path-to-agent-configuration-project>") {
       clusterAgent(name: "<agent-name>") {
         id
         tokens {
           edges {
             node {
               id
             }
           }
         }
       }
     }
   }
   ```

1. Remove an agent record with GraphQL by deleting the `clusterAgentToken`.

   ```graphql
   mutation deleteAgent {
     clusterAgentDelete(input: { id: "<cluster-agent-id>" } ) {
       errors
     }
   }

   mutation deleteToken {
     clusterAgentTokenDelete(input: { id: "<cluster-agent-token-id>" }) {
       errors
     }
   }
   ```

1. Verify whether the removal occurred successfully. If the output in the Pod logs includes `unauthenticated`, it means that the agent was successfully removed:

   ```json
   {
       "level": "warn",
       "time": "2021-04-29T23:44:07.598Z",
       "msg": "GetConfiguration.Recv failed",
       "error": "rpc error: code = Unauthenticated desc = unauthenticated"
   }
   ```

1. Delete the Agent in your cluster:

   ```shell
   kubectl delete -n gitlab-kubernetes-agent -f ./resources.yml
   ```

## Migrating to the GitLab Agent from the legacy certificate-based integration

Find out how to [migrate to the GitLab Agent for Kubernetes](../../infrastructure/clusters/migrate_to_gitlab_agent.md) from the certificate-based integration depending on the features you use.

## Related topics

- [Troubleshooting](troubleshooting.md)
