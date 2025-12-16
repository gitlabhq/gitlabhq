---
stage: Create
group: Remote Development
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Set up local development environment
---

Set up your local development environment to work on the Remote Development Workspaces features.
You can choose between two setup modes depending on your development needs:

- Agent for workspace (`agentw`):

  - Simpler setup.
  - Uses direct agent communication.
  - Recommended for most development scenarios.

- GitLab Workspaces Proxy:

  - More complex setup.
  - Uses proxy for workspace communication.
  - Required for testing proxy-specific features.

## Set up Kubernetes

1. Install [Rancher Desktop 1.20.0](https://github.com/rancher-sandbox/rancher-desktop/releases/tag/v1.20.0).
1. In Rancher Desktop, select the **Preferences** icon.
1. Configure the virtual machine:

   - Go to **Virtual Machine** > **Hardware** and set minimum values of 4 CPUs and 8 GB RAM.
   - For macOS only:

      1. Go to **Virtual Machine** > **Emulation**
      1. Select **VZ** as the Virtual Machine Type.
      1. Select **Enable Rosetta support**.

1. Go to **Container Engine**, select **`containerd`**.
1. Go to **Kubernetes**:

   1. Select Kubernetes version **v1.33.4**.
   1. Clear the **Enable Traefik** checkbox.

## Set up GDK

1. [Install GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main#supported-methods).
1. Set the `GDK_ROOT` environment variable:

   ```shell
   echo 'export GDK_ROOT="/path/to/your/gdk"' >> ~/.zshrc
   ```

   Replace `/path/to/your/gdk` with your actual GDK directory path.

1. [Set up an EE license](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses).
1. Configure GDK to run on a local private IP address by following the [local network binding documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/local_network.md#local-network-binding).

   For this setup, we assume the private IP address is `172.16.123.1`. If you use a different IP address,
   substitute the correct value in later steps.

1. Configure NGINX for GDK:

   1. Add this configuration to your `gdk.yml` file:

      ```yaml
      hostname: gdk.test
      nginx:
        enabled: true
        http:
            enabled: true
      ```

   1. Install NGINX:

      ```shell
      brew install nginx
      ```

1. Optional. Check out the desired branches on GitLab:

   ```shell
   cd "${GDK_ROOT}/gitlab"
   git checkout my_branch
   ```

   To prevent changes from being lost when you run `gdk update`, add this to your `gdk.yml`:

      ```yaml
      gdk:
        auto_rebase_projects: true
      ```

1. Restart your GDK:

   ```shell
   cd "${GDK_ROOT}"
   gdk restart
   ```

## Set up GitLab Agent Server (KAS) in GDK

1. Enable agent for Kubernetes in your GDK by adding this configuration to `gdk.yml`:

   ```yaml
   gitlab_k8s_agent:
    enabled: true
    agent_listen_address: gdk.test:8150
    k8s_api_listen_address: gdk.test:8154
   ```

1. Reconfigure and restart GDK:

   ```shell
    cd "${GDK_ROOT}"
    gdk reconfigure
    gdk restart
   ```

1. Optional. Check out the desired branches on agent for Kubernetes:

   ```shell
         cd "${GDK_ROOT}/gitlab-k8s-agent"
         git checkout my_branch
   ```

1. Optional. To manually run `kas`, for example, to run in a different cloned directory or debug in an IDE:

   - See [running `kas` and `agentk` locally](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/developing.md#running-kas-and-agentk-locally).
   - For debugging with JetBrains GoLand IDE:

      1. Set up a `kas` "Run Configuration" "Run Kind: Directory'
      1. Point to `/path/to/cmd/kas`.
      1. Check `Run after build`.
      1. Pass all the same `ENV` vars and options as you do to Bazel.

### Verify agent for Kubernetes installation

To ensure agent for Kubernetes is properly installed:

1. Install Xcode from the Apple App Store and accept the license:

   ```shell
    sudo xcodebuild -license accept
   ```

1. Clone the agent repository:

   ```shell
    git clone https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent
   ```

1. Test the installation:

   ```shell
    cd gitlab-agent
    make test
   ```

1. If you encounter errors, clean and retry:

   ```shell
    bazel clean --expunge
    make test
   ```

   {{< alert type="note" >}}

   You might also need to do this in the `<GDK_ROOT>/gitlab-k8s-agent`, which is used by the GDK.

   {{< /alert >}}

When `make test` passes, agent for Kubernetes is ready to use.

## Set up agent for Kubernetes (`agentk`) for Workspaces

1. Create an agent configuration file:

   1. Go to `http://gdk.test:3000/gitlab-org`.
   1. Create a private project named `gitlab-agent-configurations` with a README.
   1. In the project, create a file at `.gitlab/agents/remotedev/config.yaml` with your `agentk` configuration.

   {{< alert type="note" >}}

   When you create or change this file, you must start or restart `agentk` described in step 4.

   {{< /alert >}}

1. Register `agentk` with GitLab:

   1. In the `gitlab-agent-configurations` project, go to **Operate** > **Kubernetes clusters**.
   1. Select **Connect a cluster**.
   1. Enter `remotedev` in the input field.
   1. Select **Register**.
   1. Copy and save the generated token. It is required for the `AGENT_TOKEN` environment variable.

1. Map the agent to the `gitlab-org` group:

   1. Go to `http://gdk.test:3000/gitlab-org`.
   1. Go to **Settings** > **Workspaces**.
   1. Select the **All agents** tab.
   1. Find `remotedev` in the list and select **Allow**.
   1. Verify the agent appears in the **Allowed agents** tab.

1. Start the Agent (`agentk`):

   ```shell
    export AGENT_TOKEN='your_copied_token'
    cd "${GDK_ROOT}/gitlab-k8s-agent"
    echo -n "$AGENT_TOKEN" > "$HOME/.gitlab-agentk-token.txt"
    export POD_NAMESPACE=default
    export POD_NAME=remotedev
    bazel run //cmd/agentk -- --kas-address=grpc://gdk.test:8150 --token-file=$HOME/.gitlab-agentk-token.txt
   ```

1. Optional. To manually run `agentk`, for example, to run in a different cloned dir or debug in an IDE:

   - See [running `kas` and `agentk` locally](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/developing.md#running-kas-and-agentk-locally).
   - For debugging with JetBrains GoLand IDE:

      1. Set up a `kas` "Run Configuration" "Run Kind: Directory'
      1. Point to `/path/to/cmd/kas`.
      1. Check `Run after build`.
      1. Pass all the same `ENV` vars and options as you do to Bazel.

Go to **Operate** > **Kubernetes clusters**. The `remotedev` agent should now display as **Connected**.

## Configure Workspaces in GDK

### For agent for workspace mode

Use this configuration in the `.gitlab/agents/remotedev/config.yaml` file:

```yaml
remote_development:
  enabled: true
  network_policy:
    enabled: true
    egress:
    - allow: '0.0.0.0/0'
      except:
      - '10.0.0.0/8'
      - '172.16.0.0/12'
      - '192.168.0.0/16'
    - allow: '172.16.123.1/32'
  gitlab_workspaces_proxy:
    http_enabled: false
    ssh_enabled: false

observability:
  logging:
    level: debug
    grpc_level: warn
```

### For GitLab Workspaces Proxy mode

Use this configuration in the `.gitlab/agents/remotedev/config.yaml` file:

```yaml
remote_development:
  enabled: true
  dns_zone: workspaces.localtest.me
  network_policy:
    enabled: true
    egress:
    - allow: '0.0.0.0/0'
      except:
      - '10.0.0.0/8'
      - '172.16.0.0/12'
      - '192.168.0.0/16'
    - allow: '172.16.123.1/32'

observability:
  logging:
    level: debug
    grpc_level: warn
```

## Set up GitLab Workspaces Proxy (proxy mode only)

If you chose the GitLab Workspaces Proxy mode, complete these additional steps:

1. Create an OAuth application:

   1. Go to `http://gdk.test:3000/admin`.
   1. Go to **Applications** and select **Add new application**.
   1. Set the name to `GitLab Workspaces Proxy`.
   1. Set the redirect URI to `https://workspaces.localtest.me/auth/callback`.
   1. Set the scopes to `api`, `read_user`, `openid`, and `profile`.
   1. Export the client credentials:

      ```shell
      export CLIENT_ID="your_client_id"
      export CLIENT_SECRET="your_client_secret"
      ```

1. Export `GITLAB_URL` to point to your GDK:

   ```shell
    export GITLAB_URL="http://gdk.test:3000"
   ```

1. Set up Ingress Controller and GitLab Workspaces Proxy:

   ```shell
    brew install mkcert
    cd "${GDK_ROOT}/gitlab"
    ./scripts/remote_development/workspaces_kubernetes_setup.sh
   ```

## Create a workspace

1. Optional. Define a devfile for testing:

   1. If you don't need to test specific configurations, skip this step in favor of using the
      default Devfile in the next step.
   1. Go to the `gitlab-org/gitlab-shell` project at `http://gdk.test:3000/gitlab-org/gitlab-shell`.
   1. Create a file at `.devfile.yaml`:

      ```yaml
        schemaVersion: 2.2.0
        components:
          - name: tooling-container
            attributes:
              gl/inject-editor: true
            container:
                image: "registry.gitlab.com/gitlab-org/workspaces/gitlab-workspaces-docs/ubuntu:04@sha256:07590ca30ebde8a5339c3479404953e43ee70e7e9e0c2ede2770684010ddf7fe"
      ```

      {{< alert type="note" >}}

      The SHA256 is required to ensure the pulled container is the AMD64 architecture container.
      The GitLab VS Code fork for Workspaces does not support other architectures yet.
      To track this, see [issue 392693](https://gitlab.com/gitlab-org/gitlab/-/issues/392693).

      {{< /alert >}}

1. Create a new workspace:

   1. Go to **Your Work** > **Workspaces** at `http://gdk.test:3000/-/remote_development/workspaces`.
   1. Select **New Workspace**.
   1. Choose the project with your devfile (or search for `shell` to find GitLab Shell).

      {{< alert type="note" >}}

      If you get an error about a missing agent configuration, check your `agentk` debug logs to ensure
      that your `agentk` successfully connects and reads your agent configuration file.

      {{< /alert >}}

   1. Choose your cluster agent.
   1. If you skipped the devfile step, select **Use GitLab default devfile**.
   1. Select **Create Workspace**.
   1. Wait for the workspace to reach the **Running** state.
   1. Select **Open Workspace**.

1. To enable Extensions Marketplace for Web IDE in a workspace, see [manage extensions](../../user/project/web_ide/_index.md#manage-extensions).

   {{< alert type="note" >}}

   By default, the GitLab VS Code fork for Workspaces server uses [Open VSX](https://open-vsx.org/)
   Extensions Marketplace. These settings are configured during a workspace startup in the `product.json`
   file. This file is located in the `${GL_EDITOR_VOLUME_DIR}/code-server` directory.

   {{< /alert >}}

   To customize the Extensions Marketplace configuration, these are the relevant properties in the
   `product.json` file:

      ```json
      {
          "extensionsGallery": {
              "serviceUrl": "",
              "itemUrl": "",
              "resourceUrlTemplate": ""
          }
      }
      ```

## Optional. Set up AI features

To enable AI features in workspaces:

1. Follow the instructions in [Set up GitLab Team Member License for GDK](../ai_features/ai_development_license.md#set-up-gitlab-team-member-license-for-gdk).

   This page also lists other set up AI features options for local development. To provision a
   GitLab Self-Managed Ultimate Subscription with GitLab Duo Pro add-on license yourself, follow the cloud license
   with CustomersDot approach.

1. Configure your instance to use the staging AI gateway (`https://cloud.staging.gitlab.com/ai`).

For workspaces, you must enable GitLab Duo Chat features. They are only available with a GitLab Duo Enterprise
license. You cannot provision this license for yourself through the staging Customers Portal.
To upgrade your subscription from GitLab Duo Pro to GitLab Duo Enterprise, submit your request in the
`#g_provision` Slack channel.

If configured correctly, in the **Admin** > **GitLab Duo Pro** settings, the message,
**No health problems detected.** is displayed.

{{< alert type="note" >}}

While using GitLab Duo Chat, if you see the `Error code: A9999` response, clear and reset the chat until it succeeds.
It is a common error response from the GitLab Duo API when using the staging gateway.

{{< /alert >}}

## IDE Setup

### RubyMine

{{< alert type="note" >}}

It is planned to move some of the information in this section to the [RubyMine](https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/individual-ides/rubymine/) handbook section, or ideally shared with SCM.

{{< /alert >}}

#### Scopes

Use these scopes to:

- Search code in the scope.
- `Inspect Code` (`cmd-shift-A -> Inspect Code`) to run static analysis on the scope.

##### `remote_dev`

```plaintext
file[gitlab]:ee/lib/remote_development//*||file[gitlab]:ee/spec/factories/remote_development//*||file[gitlab]:ee/app/services/remote_development//*||file[gitlab]:app/models/remote_development//*||file[gitlab]:ee/app/graphql/mutations/remote_development//*||file[gitlab]:ee/app/graphql/resolvers/remote_development//*||file[gitlab]:ee/app/graphql/types/remote_development//*||file[gitlab]:ee/app/models/remote_development//*||file[gitlab]:ee/spec/graphql/types/remote_development//*||file[gitlab]:ee/spec/models/remote_development//*||file[gitlab]:ee/spec/services/remote_development//*||file[gitlab]:ee/app/finders/remote_development//*||file[gitlab]:ee/spec/features/remote_development//*||file[gitlab]:ee/spec/support/shared_contexts/remote_development//*||file[gitlab]:ee/app/graphql/ee/types/user_interface.rb||file[gitlab]:ee/app/graphql/resolvers/concerns/remote_development//*||file[gitlab]:ee/app/graphql/resolvers/projects/workspaces_resolver.rb||file[gitlab]:ee/app/graphql/resolvers/users/workspaces_resolver.rb||file[gitlab]:ee/spec/requests/api/graphql/mutations/remote_development//*||file[gitlab]:ee/spec/requests/api/graphql/remote_development//*||file[gitlab]:ee/spec/finders/remote_development//*||file[gitlab]:ee/app/assets/javascripts/remote_development//*||file[gitlab]:ee/spec/frontend/remote_development//*||file[gitlab]:ee/spec/graphql/api/workspace_spec.rb||file[gitlab]:ee/spec/fixtures/remote_development//*||file[gitlab]:ee/spec/lib/remote_development//*
```

##### `remote_dev services & lib`

Use this scope to set up restricted `YARD` inspections and to have safety warnings for:

- `Editor -> Inspections -> YARD -> Missing @param tag in method signature`, add scope as `Warning`
- `Editor -> Inspections -> YARD -> Missing @return tag in method`, add scope as `Warning`

```plaintext
file[gitlab]:ee/app/services/remote_development//*||file[gitlab]:ee/lib/remote_development//*
```

## Testing

### Run test suite

To run a subset of specs related to the Workspaces feature for a pre-commit "Smoke Test", use the following script:

```shell
scripts/remote_development/run-smoke-test-suite.sh
```

### Run E2E spec locally

- There is an end to end test that verifies the creation of a new running workspace.
- The test works by running UI actions on a running installation of a test GitLab instance, using GDK, KAS, and `agentk`.

{{< alert type="note" >}}

The test does not set up or teardown any of these components as a part of its execution.

At present, the test is tagged with a `quarantine` label so it does not run as a part of CI/CD, because
of complexities in spinning up KAS and `agentk` in the CI/CD environment. It must be run manually.

{{< /alert >}}

To run the test:

1. Ensure that the test GitLab instance is up and running with the default KAS or `agentk` stopped.
1. Ensure KAS with remote development code is up and running.
1. By default, the E2E test assumes the existence of an agent with name `test-agent` under the group
   `gitlab-org` in the GDK GitLab instance:

   1. To work with the defaults, create an agent with the name `test-agent` in a project in `gitlab-org` group.
      The `gitlab-shell` project in the `gitlab-org` group is a candidate for where to create this agent.
   1. Alternatively, to use a custom group/agent, override the group and agent name with the environment
      variables `AGENTK_GROUP` and `AGENTK_NAME`.

1. Change the current working directory to `{GDK_ROOT}/gitlab`.
1. Run the test with `scripts/remote_development/run-e2e-spec.sh`.

   - To override the defaults, use `AGENTK_GROUP=some-org GITLAB_PASSWORD=example scripts/remote_development/run-e2e-spec.sh`

   The complete list of environment variables are in `scripts/remote_development/run-e2e-spec.sh`.

### Verify behavior with example projects

Use the [example projects](https://gitlab.com/gitlab-org/workspaces/examples) to test GitLab Workspaces.
These projects include devfiles and work out-of-the-box.

1. Clone the example projects to your development machine and push them to your local GitLab installation
   as **public** projects under the `gitlab-org` group.
1. The projects appear in the project list when you create a workspace.
1. Follow the `README` file in each project for specific usage instructions.

## Repositories

These repositories are used to develop Workspaces:

| Name                                                                                          | Description                                                               | Language |
|-----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|----------|
| [GitLab](https://gitlab.com/gitlab-org/gitlab)                                                | Main logic                                                                | Ruby on Rails |
| [GitLab Agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) | Logic for creating/report Kubernetes resources                            | Go       |
| [GitLab Workspaces Proxy](https://gitlab.com/gitlab-org/workspaces/gitlab-workspaces-proxy)   | Logic for authentication and authorization of incoming workspaces traffic | Go       |
| [GitLab Build Images](https://gitlab.com/gitlab-org/gitlab-build-images)                      | Logic for workspaces-related container image builds                       | Shell script, Docker |
| [Devfile Gem](https://gitlab.com/gitlab-org/ruby/gems/devfile-gem)                            | Logic for converting Devfile to Kubernetes resources                      | Go, Ruby |

These dependencies are external repositories that Workspaces relies on:

| Name                                                                              | Description                                                     | Language   | Used by |
|-----------------------------------------------------------------------------------|-----------------------------------------------------------------|------------|---------|
| [GitLab VS Code Fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork)   | GitLab fork of upstream VS Code OSS project                     | Script     | GitLab Workspaces Tools |
| [GitLab VS Code Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension) | GitLab VS Code Extension                                        | TypeScript | GitLab Workspaces Tools |
| [Devfile API](https://github.com/devfile/api)                                     | Upstream project defining Devfile Schema                        | Go         | GitLab  |
| [Devfile Library](https://github.com/devfile/library)                             | Upstream project for converting Devfile to Kubernetes resources | Go         | Devfile Gem |

## Debugging

### IDE setup for debugging

For tips on debugging under Ruby Mine, see [Using RubyMine debugger for GitLab running under GDK](https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/individual-ides/rubymine/#using-rubymine-debugger-for-gitlab-running-under-gdk).

KAS and `agentk` debugging also works under GoLand. If you need help to set up Run Configurations,
reach out to one of the developers or engineers.

### Rails

#### `log/remote_development.log`

`log/remote_development.log` contains specific remote development logs in JSON format.
You might need to install `jq`.

```shell
tail -f log/remote_development.log | jq
```

#### `log/development.log`

For other details or exceptions that are not in `log/remote_development.log`, see the standard Rails `log/development.log`:

```shell
tail -f log/development.log
```

#### Delete orphaned workspace in Rails

You might get orphaned workspace records on Rails, or you might want to start with a clean slate.
To do this:

1. Go to the `gitlab` repository in your GDK.
1. Open the Rails console:

   ```shell
   bin/rails c
   ```

1. Delete all the workspace records:

   ```ruby
   RemoteDevelopment::Workspace.delete_all
   ```

### Kubernetes

#### Context and namespace management

| Task                | Command |
|---------------------|---------|
| List all contexts   | `kubectl config get-contexts` |
| Get current context | `kubectl config current-context` |
| Switch context      | `kubectl config use-context CONTEXT_NAME` |
| List namespaces     | `kubectl get namespaces` |
| Switch namespace    | `kubectl config set-context --current --namespace=NAMESPACE` |

#### Resource inspection

| Task                        | Command |
|-----------------------------|---------|
| List pods in all namespaces | `kubectl get pods -A` |
| Get namespace details       | `kubectl get namespace NAMESPACE -o yaml` |
| Get pod details             | `kubectl -n NAMESPACE get pods POD_NAME -o yaml` |
| List API resources          | `kubectl api-resources` |

{{< alert type="note" >}}

If you omit `-n NAMESPACE` from commands, `kubectl` uses the current namespace.

{{< /alert >}}

#### Logs and debugging

Get logs from a pod:

```shell
kubectl -n NAMESPACE logs -f POD_NAME
```

Get logs from a specific container:

```shell
kubectl -n NAMESPACE logs -f POD_NAME -c CONTAINER_NAME
```

#### Workspace-specific commands

Get all workspace objects:

```shell
kubectl get serviceaccount,pvc,networkpolicy,resourcequota,deployment,service,secret,configmap -l "agent.gitlab.com/id"
```

Get the `gitlab-workspaces-proxy-config` secret:

```shell
kubectl -n gitlab-workspaces get secret gitlab-workspaces-proxy-config -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

Enter workspace main container shell:

```shell
PODNAME=$(kubectl get po -o name | cut -d/ -f2) && CONTAINER_NAME=$(kubectl get pod $PODNAME -o jsonpath='{range .spec.containers[*]}{.name}{"\t"}{range .env[*]}{.name}{","}{end}{"\n"}{end}' | grep GL_TOOLS_DIR | cut -f 1) && kubectl exec $PODNAME -c $CONTAINER_NAME -it -- /bin/bash
```

Run commands in the workspace container (example with log tailing):

```shell
PODNAME=$(kubectl get po -o name | cut -d/ -f2) && CONTAINER_NAME=$(kubectl get pod $PODNAME -o jsonpath='{range .spec.containers[*]}{.name}{"\t"}{range .env[*]}{.name}{","}{end}{"\n"}{end}' | grep GL_TOOLS_DIR | cut -f 1) && kubectl exec $PODNAME -c $CONTAINER_NAME -it -- /bin/bash -c "tail -n 100 -f /tmp/*.log"
```

{{< alert type="note" >}}

These commands run in the current namespace. Use `kubens` to switch to the workspace namespace before
running them.

{{< /alert >}}

#### Cleanup operations

Delete a namespace:

```shell
kubectl delete namespace NAMESPACE
```

Delete a pod:

```shell
kubectl -n NAMESPACE delete pods POD_NAME
```

Delete all workspace namespaces:

```shell
kubectl get namespace | grep gl- | cut -f1 -d" " | xargs -I {} kubectl delete namespace {}
```

{{< alert type="note" >}}

This cleanup may take time. If it stalls, restart Rancher Desktop and try again.

{{< /alert >}}

#### Additional resources

For information about how localhost traffic reaches Kubernetes when using GitLab Workspaces Proxy,
see [this comment](https://gitlab.com/gitlab-org/workspaces/gitlab-workspaces-proxy/-/merge_requests/7#note_2101447807).
