---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-managed Kubernetes resources
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16130) in GitLab 17.9 [with a flag](../../../administration/feature_flags.md) named `gitlab_managed_cluster_resources`. Disabled by default.

{{< /history >}}

Use GitLab-managed Kubernetes resources to provision Kubernetes resources with environment templates. An environment template can:

- Create namespaces and service accounts automatically for new environments
- Manage access permissions through role bindings
- Configure other required Kubernetes resources

When developers deploy applications, GitLab creates the resources based on the environment template.

## Configure GitLab-managed Kubernetes resources

Prerequisites:

- You must have a configured [GitLab agent for Kubernetes](install/_index.md).
- You have [authorized the agent](ci_cd_workflow.md#authorize-agent-access) to access relevant projects or groups.
- (Optional) You have configured [agent impersonation](ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation) to prevent privilege escalations. The default environment template assumes you have configured [`ci_job` impersonation](ci_cd_workflow.md#impersonate-the-cicd-job-that-accesses-the-cluster).

### Turn on Kubernetes resource management

To turn on resource management, modify the agent configuration file to include the required permissions:

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

### Create environment templates

Environment templates define what Kubernetes resources are created, updated, or removed.

The [default environment template](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml) creates a `Namespace` and configures a `RoleBinding` for the CI/CD job.

To overwrite the default template, add a template configuration file called `default.yaml` in the agent directory:

```plaintext
.gitlab/agents/<agent-name>/environment_templates/default.yaml
```

#### Supported Kubernetes resources

The following Kubernetes resources (`kind`) are supported:

- `Namespace`
- `ServiceAccount`
- `RoleBinding`
- FluxCD Source Controller objects:
  - `GitRepository`
  - `HelmRepository`
  - `HelmChart`
  - `Bucket`
  - `OCIRepository`
- FluxCD Kustomize Controller objects:
  - `Kustomization`
- FluxCD Helm Controller objects:
  - `HelmRelease`
- FluxCD Notification Controller objects:
  - `Alert`
  - `Provider`
  - `Receiver`

#### Example environment template

The following example creates a namespace and grants a group administrator access to a cluster.

```yaml
objects:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: bind-{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}
      namespace: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
    subjects:
      - kind: Group
        apiGroup: rbac.authorization.k8s.io
        name: gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: admin

# Resource lifecycle configuration
apply_resources: on_start    # Resources are applied when environment is started/restarted
delete_resources: on_stop    # Resources are removed when environment is stopped
```

### Template variables

Environment templates support limited variable substitution.
The following variables are available:

| Category       | Variable                      | Description               | Type    | Default value when not set |
|----------------|-------------------------------|---------------------------|---------|----------------------------|
| Agent          | `{{ .agent.id }}`             | The agent ID.             | Integer | N/A                       |
| Agent          | `{{ .agent.name }}`           | The agent name.           | String  | N/A                       |
| Agent          | `{{ .agent.url }}`            | The agent URL.            | String  | N/A                       |
| Environment    | `{{ .environment.id }}`       | The environment ID.       | Integer | N/A                       |
| Environment    | `{{ .environment.name }}`     | The environment name.     | String  | N/A                       |
| Environment    | `{{ .environment.slug }}`     | The environment slug.     | String  | N/A                       |
| Environment    | `{{ .environment.url }}`      | The environment URL.      | String  | Empty string               |
| Environment    | `{{ .environment.page_url }}` | The environment page URL. | String  | N/A                       |
| Environment    | `{{ .environment.tier }}`     | The environment tier.     | String  | N/A                       |
| Project        | `{{ .project.id }}`           | The project ID.           | Integer | N/A                       |
| Project        | `{{ .project.slug }}`         | The project slug.         | String  | N/A                       |
| Project        | `{{ .project.path }}`         | The project path.         | String  | N/A                       |
| Project        | `{{ .project.url }}`          | The project URL.          | String  | N/A                       |
| CI/CD Pipeline | `{{ .ci_pipeline.id }}`       | The pipeline ID.          | Integer | Zero                       |
| CI/CD Job      | `{{ .ci_job.id }}`            | The CI/CD job ID.         | Integer | Zero                       |
| User           | `{{ .user.id }}`              | The user ID.              | Integer | N/A                       |
| User           | `{{ .user.username }}`        | The username.             | String  | N/A                       |

All variables should be referenced using the double curly brace syntax, for example: `{{ .project.id }}`.
See [`text/template`](https://pkg.go.dev/text/template) documentation for more information on the templating system used.

### Managed resource labels and annotations

The resources created by GitLab use a series of labels and annotations for tracking and troubleshooting purposes.

The following labels are defined on every resource created by GitLab. The values are intentionally left empty:

- `agent.gitlab.com/id-<agent_id>: ""`
- `agent.gitlab.com/project_id-<project_id>: ""`
- `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>: ""`
- `agent.gitlab.com/environment_slug-<gitlab_environment_slug>: ""`

On every resource created by GitLab, an `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>` annotation is defined.
The value of the annotation is a JSON object with the following keys:

| Key | Description                                      |
|-----|--------------------------------------------------|
| `environment_id` | The GitLab environment ID.                       |
| `environment_name` | The GitLab environment name.                     |
| `environment_slug` | The GitLab environment slug.                     |
| `environment_url` | The link to the environment. Optional.           |
| `environment_page_url` | The link to the GitLab environment page.         |
| `environment_tier` | The GitLab environment deployment tier.          |
| `agent_id` | The agent ID.                                    |
| `agent_name` | The agent name.                                  |
| `agent_url` | The agent URL in the agent registration project. |
| `project_id` | The GitLab project ID.                           |
| `project_slug` | The GitLab project slug.                         |
| `project_path` | The full GitLab project path.                    |
| `project_url` | The link to the GitLab project.                  |
| `template_name` | The name of the template used.                   |

## Troubleshooting

Any errors related to managed Kubernetes resources can be found on:

- The environment page in your GitLab project
- The CI/CD job logs when using the feature in pipelines
