---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Working with the agent for Kubernetes **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259669) in GitLab 13.7.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3834) in GitLab 13.11, the GitLab agent became available on GitLab.com.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) the `ci_access` attribute in GitLab 14.3.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332227) in GitLab 14.0, the `resource_inclusions` and `resource_exclusions` attributes were removed and `reconcile_timeout`, `dry_run_strategy`, `prune`, `prune_timeout`, `prune_propagation_policy`, and `inventory_policy` attributes were added.

## View your agents

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340882) in GitLab 14.8, the installed `agentk` version is displayed on the **Agent** tab.

Prerequisite:

- You must have at least the Developer role.

To view the list of agents:

1. On the top bar, select **Menu > Projects** and find the project that contains your agent configuration file.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select **Agent** tab to view clusters connected to GitLab through the agent.

On this page, you can view:

- All the registered agents for the current project.
- The connection status.
- The version of `agentk` installed on your cluster.
- The path to each agent configuration file.

## View an agent's activity information

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/277323) in GitLab 14.6.

The activity logs help you to identify problems and get the information
you need for troubleshooting. You can see events from a week before the
current date. To view an agent's activity:

1. On the top bar, select **Menu > Projects** and find the project that contains your agent configuration file.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select the agent you want to see activity for.

The activity list includes:

- Agent registration events: When a new token is **created**.
- Connection events: When an agent is successfully **connected** to a cluster.

The connection status is logged when you connect an agent for
the first time or after more than an hour of inactivity.

View and provide feedback about the UI in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/4739).

## Debug the agent

To debug the cluster-side component (`agentk`) of the agent, set the log
level according to the available options:

- `off`
- `warning`
- `error`
- `info`
- `debug`

The log level defaults to `info`. You can change it by using a top-level `observability`
section in the configuration file, for example:

```yaml
observability:
  logging:
    level: debug
```

## Remove an agent

You can remove an agent by using the [GitLab UI](#remove-an-agent-through-the-gitlab-ui) or the [GraphQL API](#remove-an-agent-with-the-gitlab-graphql-api).

### Remove an agent through the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323055) in GitLab 14.7.

To remove an agent from the UI:

1. On the top bar, select **Menu > Projects** and find the project that contains the agent configuration file.
1. From the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. In the table, in the row for your agent, in the **Options** column, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Delete agent**.

### Remove an agent with the GitLab GraphQL API

1. Get the `<cluster-agent-token-id>` from a query in the interactive GraphQL explorer.
   - For GitLab.com, go to <https://gitlab.com/-/graphql-explorer> to open GraphQL Explorer.
   - For self-managed GitLab, go to `https://gitlab.example.com/-/graphql-explorer`, replacing `gitlab.example.com` with your instance's URL.

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

1. Delete the agent in your cluster:

   ```shell
   kubectl delete -n gitlab-kubernetes-agent -f ./resources.yml
   ```

## Surface network security alerts from cluster to GitLab **(ULTIMATE)**

> [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/7476) in GitLab 14.8, and planned for [removal](https://gitlab.com/groups/gitlab-org/-/epics/7477) in GitLab 15.0.

WARNING:
Cilium integration is in its end-of-life process. It's [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/7476)
for use in GitLab 14.8, and planned for [removal](https://gitlab.com/groups/gitlab-org/-/epics/7477)
in GitLab 15.0.

The agent for Kubernetes also provides an integration with Cilium. This integration provides a simple way to
generate network policy-related alerts and to surface those alerts in GitLab.

Several components work in concert for the agent to generate the alerts:

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

The setup process follows the same [agent's installation steps](install/index.md),
with the following differences:

- When you define a configuration repository, you must do so with [Cilium settings](repository.md#surface-network-security-alerts-from-cluster-to-gitlab).
- You do not need to specify the `gitops` configuration section.

To integrate, add a top-level `cilium` section to your `config.yml` file. Currently, the
only configuration option is the Hubble relay address:

```yaml
cilium:
  hubble_relay_address: "<hubble-relay-host>:<hubble-relay-port>"
```

If your Cilium integration was performed through [GitLab Managed Apps](../applications.md#install-cilium-using-gitlab-cicd) or the
[cluster management template](../../project/clusters/protect/container_network_security/quick_start_guide.md#use-the-cluster-management-template-to-install-cilium),
you can use `hubble-relay.gitlab-managed-apps.svc.cluster.local:80` as the address:

```yaml
cilium:
  hubble_relay_address: "hubble-relay.gitlab-managed-apps.svc.cluster.local:80"
```
