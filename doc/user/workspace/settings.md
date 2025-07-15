---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure the GitLab agent for Kubernetes to support workspaces.
title: Workspace settings
---

Workspace settings configure how the GitLab agent for Kubernetes manages remote development environments
in
your Kubernetes cluster. These settings control:

- Resource allocation
- Security
- Networking
- Lifecycle management

## Set up a basic workspace configuration

To set up a basic Workspace configuration:

1. Open your configuration YAML file.
1. Add these minimum required settings:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "<workspaces.example.dev>"
   ```

1. Commit the changes.

If your workspace configuration is not working, see [Troubleshooting workspaces](workspaces_troubleshooting.md).

{{< alert type="note" >}}

If a setting has an invalid value, it's not possible to update any setting until you fix that value.
Updating any of these settings, except `enabled`, does not affect existing workspaces.

{{< /alert >}}

## Configuration reference

| Setting                                                                                   | Description                                                                                   | Format                                                      | Default value                           | Required |
|-------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------|-----------------------------------------|----------|
| [`enabled`](#enabled)                                                                     | Indicates whether remote development is enabled for the GitLab agent for Kubernetes.                         | Boolean                                                     | `false`                                 | Yes      |
| [`dns_zone`](#dns_zone)                                                                   | DNS zone where workspaces are available.                                                      | String. Valid DNS format.                                   | None                                    | Yes      |
| [`gitlab_workspaces_proxy`](#gitlab_workspaces_proxy)                                     | Namespace where [`gitlab-workspaces-proxy`](set_up_gitlab_agent_and_proxies.md) is installed. | String. Valid Kubernetes namespace name.                    | `gitlab-workspaces`                     | No       |
| [`network_policy`](#network_policy)                                                       | Firewall rules for workspaces.                                                                | Object containing `enabled` and `egress` fields.            | See [`network_policy`](#network_policy) | No       |
| [`default_resources_per_workspace_container`](#default_resources_per_workspace_container) | Default requests and limits for CPU and memory per workspace container.                       | Object with `requests` and `limits` for CPU and memory.     | `{}`                                    | No       |
| [`max_resources_per_workspace`](#max_resources_per_workspace)                             | Maximum requests and limits for CPU and memory per workspace.                                 | Object with `requests` and `limits` for CPU and memory      | `{}`                                    | No       |
| [`workspaces_quota`](#workspaces_quota)                                                   | Maximum number of workspaces for the GitLab agent for Kubernetes.                                            | Integer                                                     | `-1`                                    | No       |
| [`workspaces_per_user_quota`](#workspaces_per_user_quota)                                 | Maximum number of workspaces per user.                                                        | Integer                                                     | `-1`                                    | No       |
| [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces)                       | Indicates whether to use user namespaces in Kubernetes.                                       | Boolean: `true` or `false`                                  | `false`                                 | No       |
| [`default_runtime_class`](#default_runtime_class)                                         | Default Kubernetes `RuntimeClass`.                                                            | String. Valid `RuntimeClass` name.                          | `""`                                    | No       |
| [`allow_privilege_escalation`](#allow_privilege_escalation)                               | Allow privilege escalation.                                                                   | Boolean                                                     | `false`                                 | No       |
| [`image_pull_secrets`](#image_pull_secrets)                                               | Existing Kubernetes secrets to pull private images for workspaces.                            | Array of objects with `name` and `namespace` fields.        | `[]`                                    | No       |
| [`annotations`](#annotations)                                                             | Annotations to apply to Kubernetes objects.                                                   | Map of key-value pairs. Valid Kubernetes annotation format. | `{}`                                    | No       |
| [`labels`](#labels)                                                                       | Labels to apply to Kubernetes objects.                                                        | Map of key-value pairs. Valid Kubernetes label format       | `{}`                                    | No       |
| [`max_active_hours_before_stop`](#max_active_hours_before_stop)                           | Maximum number of hours a workspace can be active before it is stopped.                       | Integer                                                     | `36`                                    | No       |
| [`max_stopped_hours_before_termination`](#max_stopped_hours_before_termination)           | Maximum number of hours a workspace can be stopped before it is terminated.                   | Integer                                                     | `744`                                   | No       |
| [`shared_namespace`](#shared_namespace)                                                   | Indicates whether to use a shared Kubernetes namespace.                                    | String                                                      | `""`                                    | No       |

### `enabled`

Use this setting to define whether:

- The GitLab agent for Kubernetes can communicate with the GitLab instance.
- You can [create a workspace](configuration.md#create-a-workspace) with the GitLab agent for Kubernetes.

The default value is `false`.

To enable remote development in the agent configuration, set `enabled` to `true`:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  enabled: true
```

{{< alert type="note" >}}

If `enabled` is set to `false` for an agent that has active or stopped workspaces,
those workspaces become orphaned and unusable.

Before you disable remote development on an agent:

- Ensure all associated workspaces are no longer needed.
- Manually delete any running workspaces to remove them from the Kubernetes cluster.

{{< /alert >}}

### `dns_zone`

Use this setting to define the DNS zone of the URL where workspaces are available.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  dns_zone: "<workspaces.example.dev>"
```

### `gitlab_workspaces_proxy`

Use this setting to define the namespace where
[`gitlab-workspaces-proxy`](set_up_gitlab_agent_and_proxies.md) is installed.
The default value for `gitlab_workspaces_proxy.namespace` is `gitlab-workspaces`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  gitlab_workspaces_proxy:
    namespace: "<custom-gitlab-workspaces-proxy-namespace>"
```

### `network_policy`

Use this setting to define the network policy for each workspace.
This setting controls network traffic for workspaces.

The default value is:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  network_policy:
    enabled: true
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
```

In this configuration:

- The network policy is generated for each workspace because `enabled` is `true`.
- The egress rules allow all traffic to the internet (`0.0.0.0/0`) except to the
  IP CIDR ranges `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`.

The behavior of the network policy depends on the Kubernetes network plugin.
For more information, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

#### `network_policy.enabled`

Use this setting to define whether the network policy is generated for each workspace.
The default value for `network_policy.enabled` is `true`.

#### `network_policy.egress`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11629) in GitLab 16.7.

{{< /history >}}

Use this setting to define a list of IP CIDR ranges to allow as egress destinations from a workspace.

Define egress rules when:

- The GitLab instance is on a private IP range.
- The workspace must access a cloud resource on a private IP range.

Each element of the list defines an `allow` attribute with an optional `except` attribute.
`allow` defines an IP range to allow traffic from.
`except` lists IP ranges to exclude from the `allow` range.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  network_policy:
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
      - allow: "172.16.123.1/32"
```

In this example, traffic from the workspace is allowed if:

- The destination IP is any range except `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`.
- The destination IP is `172.16.123.1/32`.

### `default_resources_per_workspace_container`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11625) in GitLab 16.8.

{{< /history >}}

Use this setting to define the default [requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)
for CPU and memory per workspace container.
Any resources you define in your [devfile](_index.md#devfile) override this setting.

For `default_resources_per_workspace_container`, `requests` and `limits` are required.
For more information about possible CPU and memory values, see [Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes).

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_resources_per_workspace_container:
    requests:
      cpu: "0.5"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"
```

### `max_resources_per_workspace`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11625) in GitLab 16.8.

{{< /history >}}

Use this setting to define the maximum [requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)
for CPU and memory per workspace.

For `max_resources_per_workspace`, `requests` and `limits` are required.
For more information about possible CPU and memory values, see:

- [Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)
- [Resource quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

Workspaces fail when they exceed the values you set for `requests` and `limits`.

{{< alert type="note" >}}

If [`shared_namespace`](#shared_namespace) is set, `max_resources_per_workspace` must be an
empty hash. Users can create a Kubernetes [Resource quota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
in the `shared_namespace` to achieve the same result as specifying this value here.

{{< /alert >}}

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_resources_per_workspace:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "2Gi"
```

The maximum resources you define must include any resources required for init containers
to perform bootstrapping operations such as cloning the project repository.

### `workspaces_quota`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11586) in GitLab 16.9.

{{< /history >}}

Use this setting to set the maximum number of workspaces for the GitLab agent for Kubernetes.

You cannot create new workspaces for an agent when:

- The number of workspaces for the agent has reached the defined `workspaces_quota`.
- `workspaces_quota` is set to `0`.

If `workspaces_quota` is set to a value below the number of non-terminated workspaces
for an agent, the agent's workspaces are not terminated automatically.

The default value is `-1` (unlimited).
Possible values are greater than or equal to `-1`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  workspaces_quota: 10
```

### `workspaces_per_user_quota`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11586) in GitLab 16.9.

{{< /history >}}

Use this setting to set the maximum number of workspaces per user.

You cannot create new workspaces for a user when:

- The number of workspaces for the user has reached the defined `workspaces_per_user_quota`.
- `workspaces_per_user_quota` is set to `0`.

If `workspaces_per_user_quota` is set to a value below the number of non-terminated workspaces
for a user, the user's workspaces are not terminated automatically.

The default value is `-1` (unlimited).
Possible values are greater than or equal to `-1`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  workspaces_per_user_quota: 3
```

### `use_kubernetes_user_namespaces`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Use this setting to specify whether to use the user namespaces feature in Kubernetes.

[User namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/) isolate the user
running inside the container from the user on the host.

The default value is `false`. Before you set the value to `true`, ensure your Kubernetes cluster supports user namespaces.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  use_kubernetes_user_namespaces: true
```

For more information about `use_kubernetes_user_namespaces`, see
[user namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/).

### `default_runtime_class`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Use this setting to select the container runtime configuration used to run the containers in the workspace.

The default value is `""`, which denotes the absence of a value.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_runtime_class: "example-runtime-class-name"
```

A valid value:

- Contains 253 characters or less.
- Contains only lowercase letters, numbers, `-`, or `.`.
- Starts with an alphanumeric character
- Ends with an alphanumeric character.

For more information about `default_runtime_class`, see
[Runtime Class](https://kubernetes.io/docs/concepts/containers/runtime-class/).

### `allow_privilege_escalation`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Use this setting to control whether a process can gain more privileges than its parent process.

This setting directly controls whether the [`no_new_privs`](https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt)
flag gets set on the container process.

The default value is `false`. The value can be set to `true` only if either:

- [`default_runtime_class`](#default_runtime_class) is set to a non-empty value.
- [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces) is set to `true`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_runtime_class: "example-runtime-class-name"
  allow_privilege_escalation: true
```

For more information about `allow_privilege_escalation`, see
[Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

### `image_pull_secrets`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14664) in GitLab 17.6.

{{< /history >}}

Use this setting to specify existing Kubernetes secrets of the type `kubernetes.io/dockercfg`
or `kubernetes.io/dockerconfigjson` required by workspaces to pull private images.

The default value is `[]`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  image_pull_secrets:
    - name: "image-pull-secret-name"
      namespace: "image-pull-secret-namespace"
```

In this example, the secret `image-pull-secret-name` from the namespace
`image-pull-secret-namespace` is synced to the namespace of the workspace.

For `image_pull_secrets`, the `name` and `namespace` attributes are required.
The name of the secret must be unique.
If [`shared_namespace`](#shared_namespace) is set, the namespace of the secret must be the same as the `shared_namespace`.

If the secret you've specified does not exist in the Kubernetes cluster, the secret is ignored.
When you delete or update the secret, the secret is deleted or updated
in all the namespaces of the workspaces where the secret is referenced.

### `annotations`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Use this setting to attach arbitrary non-identifying metadata to the Kubernetes objects.

The default value is `{}`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  annotations:
    "example.com/key": "value"
```

A valid annotation key is a string made of two parts:

- Optional. A prefix. The prefix must be 253 characters or less, and contain period-separated DNS labels. The prefix must end with a slash (`/`).
- A name. The name must be 63 characters or less and contain only alphanumeric characters, dashes (`-`), underscores (`_`), and periods (`.`). The name must begin and end with an alphanumeric character.

You shouldn't use prefixes that end with `kubernetes.io` and `k8s.io` because they are reserved for Kubernetes core components.
Prefixes that end with `gitlab.com` are also reserved.

A valid annotation value is a string.

For more information about `annotations`, see
[Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/).

### `labels`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Use this setting to attach arbitrary identifying metadata to the Kubernetes objects.

The default value is `{}`.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  labels:
    "example.com/key": "value"
```

A label key is a string made of two parts:

- Optional. A prefix. The prefix must be 253 characters or less, and contain period-separated DNS labels. The prefix must end with a slash (`/`).
- A name. The name must be 63 characters or less and contain only alphanumeric characters, dashes (`-`), underscores (`_`), and periods (`.`). The name must begin and end with an alphanumeric character.

You shouldn't use prefixes that end with `kubernetes.io` and `k8s.io` because they are reserved for Kubernetes core components.
Prefixes that end with `gitlab.com` are also reserved.

A valid label value:

- Contains 63 characters or less. The value can be empty.
- Begins and ends with an alphanumeric character.
- Can contain dashes (`-`), underscores (`_`), and periods (`.`).

For more information about `labels`, see
[Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/).

### `max_active_hours_before_stop`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14910) in GitLab 17.6.

{{< /history >}}

This setting automatically stops the agent's workspaces after they have been active for the specified
number of hours. An active state is any non-stopped or non-terminated state.

The timer for this setting starts when you create the workspace, and is reset every time you
restart the workspace.
It also applies even if the workspace is in an error or failure state.

The default value is `36`, or one and a half days. This avoids stopping the workspace during
the user's typical working hours.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_active_hours_before_stop: 60
```

A valid value:

- Is an integer.
- Is greater than or equal to `1`.
- Is less than or equal to `8760` (one year).
- `max_active_hours_before_stop` + `max_stopped_hours_before_termination` must be less than or equal to `8760`.

The automatic stop is only triggered on a full reconciliation, which happens every hour.
This means that the workspace might be active for up to one hour longer than the configured value.

### `max_stopped_hours_before_termination`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14910) in GitLab 17.6.

{{< /history >}}

Use this setting to automatically terminate the agent's workspaces after they have been in the stopped
state for the specified number of hours.

The default value is `722`, or approximately one month.

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_stopped_hours_before_termination: 4332
```

A valid value:

- Is an integer.
- Is greater than or equal to `1`.
- Is less than or equal to `8760` (one year).
- `max_active_hours_before_stop` + `max_stopped_hours_before_termination` must be less than or equal to `8760`.

The automatic termination is only triggered on a full reconciliation, which happens every hour.
This means that the workspace might stop for up to one hour longer than the configured value.

### `shared_namespace`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12327) in GitLab 18.0.

{{< /history >}}

Use this setting to specify a shared Kubernetes namespace for all workspaces.

The default value is `""`, which creates each new workspace in its own separate Kubernetes namespace.

When you specify a value, all workspaces exist in that Kubernetes namespace instead of individual namespaces.

Setting a value for `shared_namespace` imposes restrictions on the acceptable values for [`image_pull_secrets`](#image_pull_secrets) and [`max_resources_per_workspace`](#max_resources_per_workspace).

Example configuration:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  shared_namespace: "example-shared-namespace"
```

A valid value:

- Contains at most 63 characters.
- Contains only lowercase alphanumeric characters or '-'.
- Starts with an alphanumeric character.
- Ends with an alphanumeric character.

For more information about Kubernetes namespaces, see
[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).

## Complete example configuration

The following configuration is a complete, example configuration.
It includes all available settings in the [configuration reference](#configuration-reference):

```yaml
remote_development:
  enabled: true
  dns_zone: workspaces.dev.test
  gitlab_workspaces_proxy:
    namespace: "gitlab-workspaces"

  network_policy:
    enabled: true
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"

  default_resources_per_workspace_container:
    requests:
      cpu: "0.5"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"

  max_resources_per_workspace:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

  workspaces_quota: 10
  workspaces_per_user_quota: 3

  use_kubernetes_user_namespaces: false
  default_runtime_class: "standard"
  allow_privilege_escalation: false

  image_pull_secrets:
    - name: "registry-secret"
      namespace: "default"

  annotations:
    environment: "production"
    team: "engineering"

  labels:
    app: "workspace"
    tier: "development"

  max_active_hours_before_stop: 60
  max_stopped_hours_before_termination: 4332
  shared_namespace: ""
```
