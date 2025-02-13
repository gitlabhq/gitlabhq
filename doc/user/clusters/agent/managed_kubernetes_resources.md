---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-managed Kubernetes resources
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16130) in GitLab 17.9

Use GitLab-managed Kubernetes resources to provision Kubernetes resources with environment templates. An environment template can:

- Create namespaces and service accounts automatically for new environments
- Manage access permissions through role bindings
- Configure other required Kubernetes resources

When developers deploy applications, GitLab creates the resources based on the environment template.

## Configure GitLab-managed Kubernetes resources

Prerequisites:

- You must have a configured [GitLab agent for Kubernetes](install/_index.md).
- You have [authorized the agent](ci_cd_workflow.md#authorize-the-agent) to access relevant projects or groups.
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

To create an environment template, add a template configuration file in the agent directory at:

```plaintext
.gitlab/agents/<agent-name>/environment_templates/<template-name>.yaml
```

You can specify which template is included in a CI/CD pipeline. For more information, see [Use templates in CI/CD pipelines](#use-managed-resources-in-cicd-pipelines).

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

# Resource lifecycle configuration
apply_resources: on_start    # Resources are applied when environment is started/restarted
delete_resources: on_stop    # Resources are removed when environment is stopped
```

### Template variables

Environment templates support limited variable substitution.
The following variables are available:

| Category | Variable | Description |
|----------|----------|-------------|
| Agent | `{{ .agent.id }}` | The agent identifier. |
| Agent | `{{ .agent.name }}` | The agent name. |
| Agent | `{{ .agent.url }}` | The agent URL. |
| Environment | `{{ .environment.name }}` | The environment name. |
| Environment | `{{ .environment.slug }}` | The environment slug. |
| Environment | `{{ .environment.url }}` | The environment URL. |
| Environment | `{{ .environment.tier }}` | The environment tier. |
| Project | `{{ .project.id }}` | The project identifier. |
| Project | `{{ .project.slug }}` | The project slug. |
| Project | `{{ .project.path }}` | The project path. |
| Project | `{{ .project.url }}` | The project URL. |
| CI Pipeline | `{{ .ci_pipeline.id }}` | The pipeline identifier. |
| CI Job | `{{ .ci_job.id }}` | The CI/CD job identifier. |
| User | `{{ .user.id }}` | The user identifier. |
| User | `{{ .user.username }}` | The username. |

All variables should be referenced using the double curly brace syntax, for example: `{{ .project.id }}`.
See [`text/template`](https://pkg.go.dev/text/template) documentation for more information on the templating system used.

### Resource lifecycle management

Use the following settings to configure when Kubernetes resources should be applied or removed from an environment:

```yaml
# Apply resources when environment is started or restarted
apply_resources: on_start

# Never delete resources
delete_resources: never

# Delete resources when environment is stopped
delete_resources: on_stop
```

### Use managed resources in CI/CD pipelines

To use managed Kubernetes resources in your CI/CD pipelines, specify the agent and optionally the template name in your environment configuration:

```yaml
deploy:
  environment:
    name: production
    kubernetes:
      agent: agent-name
      template: my-template  # Optional, uses default template if not specified
```

## Troubleshooting

Any errors related to managed Kubernetes resources can be found on:

- The environment page in your GitLab project
- The CI/CD job logs when using the feature in pipelines
