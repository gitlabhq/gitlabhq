---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Managing the agent for Kubernetes instances
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the following tasks when you work with the agent for Kubernetes.

## View your agents

The installed `agentk` version is displayed on the **Agent** tab.

Prerequisites:

- You must have at least the Developer role.

To view the list of agents:

1. On the left sidebar, select **Search or go to** and find the project that contains your agent configuration file.
   You cannot view registered agents from a project that does not contain the agent configuration file.
1. Select **Operate > Kubernetes clusters**.
1. Select **Agent** tab to view clusters connected to GitLab through the agent.

On this page, you can view:

- All the registered agents for the current project.
- The connection status.
- The version of `agentk` installed on your cluster.
- The path to each agent configuration file.

### Configure your agent

To configure your agent:

- Add content to the `config.yaml` file optionally created [during installation](install/_index.md#create-an-agent-configuration-file).

You can quickly locate an agent configuration file from the list of agents.
The **Configuration** column indicates the location of the `config.yaml` file,
or shows how to create one.

The agent configuration file manages the various agent features:

- For a GitLab CI/CD workflow. You must [authorize the agent to access your projects](ci_cd_workflow.md#authorize-the-agent), and then
  [add `kubectl` commands to your `.gitlab-ci.yml` file](ci_cd_workflow.md#update-your-gitlab-ciyml-file-to-run-kubectl-commands).
- For [user access](user_access.md) to the cluster from the GitLab UI or from the local terminal.
- For configuring [operational container scanning](vulnerabilities.md).
- For configuring [remote workspaces](../../workspace/gitlab_agent_configuration.md).

## View shared agents

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/395498) in GitLab 16.1.

In addition to the agents owned by your project, you can also view agents shared with the
[`ci_access`](ci_cd_workflow.md) and [`user_access`](user_access.md) keywords. Once an agent
is shared with a project, it automatically appears in the project agent tab.

To view the list of shared agents:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Kubernetes clusters**.
1. Select the **Agent** tab.

The list of shared agents and their clusters are displayed.

## View an agent's activity information

The activity logs help you to identify problems and get the information
you need for troubleshooting. You can see events from a week before the
current date. To view an agent's activity:

1. On the left sidebar, select **Search or go to** and find the project that contains your agent configuration file.
1. Select **Operate > Kubernetes clusters**.
1. Select the agent you want to see activity for.

The activity list includes:

- Agent registration events: When a new token is **created**.
- Connection events: When an agent is successfully **connected** to a cluster.

The connection status is logged when you connect an agent for
the first time or after more than an hour of inactivity.

View and provide feedback about the UI in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/4739).

## Debug the agent

> - The `grpc_level` was [introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/669) in GitLab 15.1.

To debug the cluster-side component (`agentk`) of the agent, set the log
level according to the available options:

- `error`
- `info`
- `debug`

The agent has two loggers:

- A general purpose logger, which defaults to `info`.
- A gRPC logger, which defaults to `error`.

You can change your log levels by using a top-level `observability` section in the [agent configuration file](#configure-your-agent), for example setting the levels to `debug` and `warn`:

```yaml
observability:
  logging:
    level: debug
    grpc_level: warn
```

When `grpc_level` is set to `info` or below, there are a lot of gRPC logs.

Commit the configuration changes and inspect the agent service logs:

```shell
kubectl logs -f -l=app=gitlab-agent -n gitlab-agent
```

For more information about debugging, see [troubleshooting documentation](troubleshooting.md).

## Reset the agent token

> - Two-token limit [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361030/) in GitLab 16.1 with a [flag](../../../administration/feature_flags.md) named `cluster_agents_limit_tokens_created`.
> - Two-token limit [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/412399) in GitLab 16.2. Feature flag `cluster_agents_limit_tokens_created` removed.

An agent can have only two active tokens at one time.

To reset the agent token without downtime:

1. Create a new token:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Operate > Kubernetes clusters**.
   1. Select the agent you want to create a token for.
   1. On the **Access tokens** tab, select **Create token**.
   1. Enter token's name and description (optional) and select **Create token**.
1. Securely store the generated token.
1. Use the token to [install the agent in your cluster](install/_index.md#install-the-agent-in-the-cluster) and to [update the agent](install/_index.md#update-the-agent-version) to another version.
1. To delete the token you're no longer using, return to the token list and select **Revoke** (**{remove}**).

## Remove an agent

You can remove an agent by using the [GitLab UI](#remove-an-agent-through-the-gitlab-ui) or the
[GraphQL API](#remove-an-agent-with-the-gitlab-graphql-api). The agent and any associated tokens
are removed from GitLab, but no changes are made in your Kubernetes cluster. You must
clean up those resources manually.

### Remove an agent through the GitLab UI

To remove an agent from the UI:

1. On the left sidebar, select **Search or go to** and find the project that contains the agent configuration file.
1. Select **Operate > Kubernetes clusters**.
1. In the table, in the row for your agent, in the **Options** column, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Delete agent**.

### Remove an agent with the GitLab GraphQL API

1. Get the `<cluster-agent-token-id>` from a query in the interactive GraphQL explorer.
   - For GitLab.com, go to <https://gitlab.com/-/graphql-explorer> to open GraphQL Explorer.
   - For GitLab Self-Managed, go to `https://gitlab.example.com/-/graphql-explorer`, replacing `gitlab.example.com` with your instance's URL.

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

## Related topics

- [Manage an agent's workspaces](../../workspace/_index.md#manage-workspaces-at-the-agent-level)
