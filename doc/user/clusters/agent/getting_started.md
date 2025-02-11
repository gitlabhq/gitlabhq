---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started connecting a Kubernetes cluster to GitLab

This page guides you through setting up a basic Kubernetes integration in a single project. If you're new to the GitLab agent for Kubernetes, pull-based deployment, or Flux, you should start here.

When you finish, you will be able to:

- View the status of your Kubernetes cluster with a real-time Kubernetes dashboard.
- Deploy updates to your cluster with Flux.
- Deploy updates to your cluster with GitLab CI/CD.

## Before you begin

Make sure you have the following before you complete this tutorial:

- A Kubernetes cluster that you can access locally with `kubectl`.
  To see what versions of Kubernetes GitLab supports, see [Supported Kubernetes versions for GitLab features](_index.md#supported-kubernetes-versions-for-gitlab-features).

  You can check that everything is properly configured by running:

  ```shell
  kubectl cluster-info
  ```

## Install and configure Flux

[Flux](https://fluxcd.io/flux/) is the recommended tool for GitOps deployments (also called pull-based deployments). Flux is a matured CNCF project.

To install Flux:

- Complete the steps in [Install the Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli) in the Flux documentation.

Check that the Flux CLI is properly installed by running:

```shell
flux -v
```

### Create a personal access token

To authenticate with the Flux CLI, create a personal access token with
the `api` scope:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Enter a name and optional expiry date for the token.
1. Select the `api` scope.
1. Select **Create personal access token**.

You can also use a [project](../../../user/project/settings/project_access_tokens.md) or [group access token](../../../user/group/settings/group_access_tokens.md) with the `api` scope and the `developer` role.

### Bootstrap Flux

In this section, you'll bootstrap Flux into an empty GitLab repository with the
[`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/) command.

To bootstrap a Flux installation:

- Run the `flux bootstrap gitlab` command. For example:

  ```shell
  flux bootstrap gitlab \
  --hostname=gitlab.example.org \
  --owner=my-group/optional-subgroup \
  --repository=my-repository \
  --branch=main \
  --path=clusters/testing \
  --deploy-token-auth
  ```

The arguments of `bootstrap` are:

| Argument | Description |
|--------------|-------------|
|`hostname` | Hostname of your GitLab instance. |
|`owner` | GitLab group containing the Flux repository. |
|`repository` | GitLab project containing the Flux repository. |
|`branch` | Git branch the changes are committed to. |
|`path` | File path to a folder where the Flux configuration is stored. |

The bootstrap script does the following:

1. Creates a deploy token and saves it as a Kubernetes `secret`.
1. Creates an empty GitLab project, if the project specified by the `--repository` argument doesn't exist.
1. Generates Flux definition files for your project in a folder specified by the `--path` argument.
1. Commits the definition files to the branch specified by the `--branch` argument.
1. Applies the definition files to your cluster.

After you run the script, Flux will be ready to manage itself and any other resources
you add to the GitLab project and path.

The rest of this tutorial assumes your path is `clusters/testing`, and your project is under `my-group/optional-subgroup/my-repository`.

## Set up the agent connection

To connect your clusters, you need to install the GitLab agent for Kubernetes.
You can do this by bootstrapping the agent with the GitLab CLI (`glab`).

1. [Install the GitLab CLI](https://gitlab.com/gitlab-org/cli/#installation).

   To check that the GitLab CLI is available, run

   ```shell
   glab version
   ```

1. [Authenticate `glab`](https://gitlab.com/gitlab-org/cli/#installation) to your GitLab instance.

1. In the repository where you bootstrapped Flux, run the `glab cluster agent bootstrap` command:

   ```shell
   glab cluster agent bootstrap --manifest-path clusters/testing testing 
   ```

By default, the command:

1. Registers the agent with `testing` as the name.
1. Configures the agent.
1. Configures an environment called `testing` with a dashboard for the agent.
1. Creates an agent token.
1. In the cluster, creates a Kubernetes secret with the agent token.
1. Commits the Flux Helm resources to the Git repository.
1. Triggers a Flux reconciliation.

For more information about configuring the agent, see [Installing the agent for Kubernetes](install/_index.md).

## Check out the dashboard for Kubernetes

The `glab cluster agent bootstrap` created an environment within GitLab and [configured a dashboard](../../../ci/environments/kubernetes_dashboard.md).

To view your dashboard:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Environments**.
1. Select your environment. For example, `flux-system/gitlab-agent`.
1. Select the **Kubernetes overview** tab.

## Secure the deployment

DETAILS:
**Tier:** Premium, Ultimate

So far, we've deployed an agent using the `.gitlab/agents/testing/config.yaml` file.
This configuration enables user access using the service account configured for the agent deployment. User access is used by the dashboard for Kubernetes, and for local access.

To keep your deployments secure, you should change this setup to impersonate a GitLab user.
In this case, you can manage your access to cluster resources through regular Kubernetes role-based access control (RBAC).

To enable user impersonation:

1. In your `.gitlab/agents/testing/config.yaml` file, replace `user_access.access_as.agent: {}` with `user_access.access_as.user: {}`.
1. Go to the configured dashboard for Kubernetes. If access is restricted, the dashboard displays an error message.
1. Add the following code to `clusters/testing/gitlab-user-read.yaml`:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
      name: gitlab-user-view
   roleRef:
      name: view
      kind: ClusterRole
      apiGroup: rbac.authorization.k8s.io
   subjects:
      - name: gitlab:user
        kind: Group
   ```

1. Wait a few seconds to allow Flux to apply the added manifest, then check the dashboard for Kubernetes again. The dashboard should be back to normal, thanks to the deployed cluster role binding that grants read access to all GitLab users.

For more information about user access, see [Grant users Kubernetes access](user_access.md).

## Keep everything up to date

You might need to upgrade Flux and `agentk` after installation.

To do this:

- Rerun the `flux bootstrap gitlab` and `glab cluster agent bootstrap` commands.

## Next steps

You can deploy directly to your cluster from the project where you registered the agent and stored your Flux manifests. The agent is designed to support multi-tenancy, and you can scale your configuration to other projects and groups with the configured agent and Flux installation.

Consider working through the follow-up tutorial, [Get started deploying to Kubernetes](getting_started_deployments.md). To learn more about using Kubernetes with GitLab, see:

- [Best practices for using the GitLab integration with Kubernetes](enterprise_considerations.md)
- Using the agent for [operational container scanning](vulnerabilities.md)
- Providing [remote workspaces](../../workspace/_index.md) for your engineers
