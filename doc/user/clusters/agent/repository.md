---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Agent configuration repository **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259669) in GitLab 13.7.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3834) in GitLab 13.11, the GitLab Agent became available on GitLab.com.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) the `ci_access` attribute in GitLab 14.3.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332227) in GitLab 14.0, the `resource_inclusions` and `resource_exclusions` attributes were removed and `reconcile_timeout`, `dry_run_strategy`, `prune`, `prune_timeout`, `prune_propagation_policy`, and `inventory_policy` attributes were added.

The [GitLab Agent](index.md) supports hosting your configuration for
multiple agents in a single repository. These agents can be running
in the same cluster or in multiple clusters, and potentially with more than one agent per cluster.

The Agent bootstraps with the GitLab installation URL and an authentication token,
and you provide the rest of the configuration in your repository, following
Infrastructure as Code (IaaC) best practices.

A minimal repository layout looks like this, with `my-agent-1` as the name
of your Agent:

```plaintext
|- .gitlab
    |- agents
       |- my-agent-1
          |- config.yaml
```

Make sure that `<agent-name>` conforms to the [Agent's naming format](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/identity_and_auth.md#agent-identity-and-name).

## Synchronize manifest projects **(PREMIUM)**

Your `config.yaml` file contains a `gitops` section, which contains a `manifest_projects`
section. Each `id` in the `manifest_projects` section is the path to a Git repository
with Kubernetes resource definitions in YAML or JSON format. The Agent monitors
each project you declare, and when the project changes, GitLab deploys the changes
using the Agent.

To use multiple YAML files, specify a `paths` attribute in the `gitops.manifest_projects` section.

```yaml
gitops:
  # Manifest projects are watched by the agent. Whenever a project changes,
  # GitLab deploys the changes using the agent.
  manifest_projects:
    # No authentication mechanisms are currently supported.
    # The `id` is a path to a Git repository with Kubernetes resource definitions
    # in YAML or JSON format.
  - id: gitlab-org/cluster-integration/gitlab-agent
    # Namespace to use if not set explicitly in object manifest.
    # Also used for inventory ConfigMap objects.
    default_namespace: my-ns
    # Paths inside of the repository to scan for manifest files.
    # Directories with names starting with a dot are ignored.
    paths:
      # Read all .yaml files from team1/app1 directory.
      # See https://github.com/bmatcuk/doublestar#about and
      # https://pkg.go.dev/github.com/bmatcuk/doublestar/v2#Match for globbing rules.
    - glob: '/team1/app1/*.yaml'
      # Read all .yaml files from team2/apps and all subdirectories
    - glob: '/team2/apps/**/*.yaml'
      # If 'paths' is not specified or is an empty list, the configuration below is used
    - glob: '/**/*.{yaml,yml,json}'
    # Reconcile timeout defines whether the applier should wait
    # until all applied resources have been reconciled, and if so,
    # how long to wait.
    reconcile_timeout: 3600s # 1 hour by default
    # Dry run strategy defines whether changes should actually be performed,
    # or if it is just talk and no action.
    # https://github.com/kubernetes-sigs/cli-utils/blob/d6968048dcd80b1c7b55d9e4f31fc25f71c9b490/pkg/common/common.go#L68-L89
    # Can be: none, client, server
    dry_run_strategy: none # 'none' by default
    # Prune defines whether pruning of previously applied
    # objects should happen after apply.
    prune: true # enabled by default
    # Prune timeout defines whether we should wait for all resources
    # to be fully deleted after pruning, and if so, how long we should
    # wait.
    prune_timeout: 3600s # 1 hour by default
    # Prune propagation policy defines the deletion propagation policy
    # that should be used for pruning.
    # https://github.com/kubernetes/apimachinery/blob/44113beed5d39f1b261a12ec398a356e02358307/pkg/apis/meta/v1/types.go#L456-L470
    # Can be: orphan, background, foreground
    prune_propagation_policy: foreground # 'foreground' by default
    # Inventory policy defines if an inventory object can take over
    # objects that belong to another inventory object or don't
    # belong to any inventory object.
    # This is done by determining if the apply/prune operation
    # can go through for a resource based on the comparison
    # the inventory-id value in the package and the owning-inventory
    # annotation (config.k8s.io/owning-inventory) in the live object.
    # https://github.com/kubernetes-sigs/cli-utils/blob/d6968048dcd80b1c7b55d9e4f31fc25f71c9b490/pkg/inventory/policy.go#L12-L66
    # Can be: must_match, adopt_if_no_inventory, adopt_all
    inventory_policy: must_match # 'must_match' by default
```

### Using multiple manifest projects

Storing Kubernetes manifests in more than one repository can be handy, for example:

- You may store manifests for different applications in separate repositories.
- Different teams can work on manifests of independent projects in separate repositories.

To use multiple repositories as the source of Kubernetes manifests, specify them in the list of
`manifest_projects` in your `config.yaml`:

```yaml
gitops:
  manifest_projects:
  - id: group1/project1
  - id: group2/project2
```

Note that repositories are synchronized **concurrently** and **independently** from each other,
which means that, ideally, there should **not** be any dependencies shared by these repositories.
Storing a logical group of manifests in a single repository may work better than distributing it across several
repositories.

You cannot use a single repository as a source for multiple concurrent synchronization
operations. If such functionality is needed, you may use multiple agents reading
manifests from the same repository.

Ensure not to specify "overlapping" globs to avoid synchronizing the same files more than once.
This is detected by the Agent and leads to an error.

INCORRECT - both globs match `*.yaml` files in the root directory:

```yaml
gitops:
  manifest_projects:
  - id: project1
    paths:
    - glob: '/**/*.yaml'
    - glob: '/*.yaml'
```

CORRECT - single globs matches all `*.yaml` files recursively:

```yaml
gitops:
  manifest_projects:
  - id: project1
    paths:
    - glob: '/**/*.yaml'
```

## Authorize projects and groups to use an Agent

> - Group authorization [introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) in GitLab 14.3.
> - Project authorization [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327850) in GitLab 14.4.

If you use the same cluster across multiple projects, you can set up the [CI/CD Tunnel](ci_cd_tunnel.md)
to grant access to an Agent from one or more projects or groups. This way, all the authorized
projects can access the same Agent, which facilitates you to save resources and have a scalable setup.

When you authorize a project to use an agent through the [CI/CD Tunnel](ci_cd_tunnel.md),
the selected Kubernetes context is automatically injected into CI/CD jobs, allowing you to
run Kubernetes commands from your authorized projects' scripts. When you authorize a group,
all the projects that belong to that group can access the selected agent.

An Agent can only authorize projects or groups in the same group hierarchy as the Agent's configuration
project. You can authorize up to 100 projects and 100 groups per Agent.

### Authorize projects to use an Agent

To grant projects access to the Agent through the [CI/CD Tunnel](ci_cd_tunnel.md):

1. Go to your Agent's configuration project.
1. Edit the Agent's configuration file (`config.yaml`).
1. Add the `projects` attribute into `ci_access`.
1. Identify the project through its path:

   ```yaml
   ci_access:
     projects:
     - id: path/to/project
   ```

### Authorize groups to use an Agent

To grant access to all projects within a group:

1. Go to your Agent's configuration project.
1. Edit the Agent's configuration file (`config.yaml`).
1. Add the `groups` attribute into `ci_access`.
1. Identify the group or subgroup through its path:

   ```yaml
   ci_access:
     groups:
     - id: path/to/group/subgroup
   ```

### Use impersonation to restrict project and group access **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345014) in GitLab 14.5.

By default, the [CI/CD Tunnel](ci_cd_tunnel.md) inherits all the permissions from the service account used to install the
Agent in the cluster.
To restrict access to your cluster, you can use [impersonation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation).

To specify impersonations, use the `access_as` attribute in your Agent's configuration file and use Kubernetes RBAC rules to manage impersonated account permissions.

You can impersonate:

- The Agent itself (default).
- The CI job that accesses the cluster.
- A specific user or system account defined within the cluster.

#### Impersonate the Agent

The Agent is impersonated by default. You don't need to do anything to impersonate it.

#### Impersonate the CI job that accesses the cluster

To impersonate the CI job that accesses the cluster, add the `ci_job: {}` key-value
under the `access_as` key.

When the agent makes the request to the actual Kubernetes API, it sets the
impersonation credentials in the following way:

- `UserName` is set to `gitlab:ci_job:<job id>`. Example: `gitlab:ci_job:1074499489`.
- `Groups` is set to:
  - `gitlab:ci_job` to identify all requests coming from CI jobs.
  - The list of IDs of groups the project is in.
  - The project ID.
  - The slug of the environment this job belongs to.

    Example: for a CI job in `group1/group1-1/project1` where:

    - Group `group1` has ID 23.
    - Group `group1/group1-1` has ID 25.
    - Project `group1/group1-1/project1` has ID 150.
    - Job running in a prod environment.

   Group list would be `[gitlab:ci_job, gitlab:group:23, gitlab:group:25, gitlab:project:150, gitlab:project_env:150:prod]`.

- `Extra` carries extra information about the request. The following properties are set on the impersonated identity:

| Property | Description |
| -------- | ----------- |
| `agent.gitlab.com/id` | Contains the agent ID. |
| `agent.gitlab.com/config_project_id` | Contains the agent's configuration project ID. |
| `agent.gitlab.com/project_id` | Contains the CI project ID. |
| `agent.gitlab.com/ci_pipeline_id` | Contains the CI pipeline ID. |
| `agent.gitlab.com/ci_job_id` | Contains the CI job ID. |
| `agent.gitlab.com/username` | Contains the username of the user the CI job is running as. |
| `agent.gitlab.com/environment_slug` | Contains the slug of the environment. Only set if running in an environment. |

Example to restrict access by the CI job's identity:

```yaml
ci_access:
  projects:
  - id: path/to/project
    access_as:
      ci_job: {}
```

#### Impersonate a static identity

For the given CI/CD Tunnel connection, you can use a static identity for the impersonation.

Add the `impersonate` key under the `access_as` key to make the request using the provided identity.

The identity can be specified with the following keys:

- `username` (required)
- `uid`
- `groups`
- `extra`

See the [official Kubernetes documentation for more details](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation) on the usage of these keys.

## Surface network security alerts from cluster to GitLab **(ULTIMATE)**

The GitLab Agent provides an [integration with Cilium](index.md#kubernetes-network-security-alerts).
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

## Scan your container images for vulnerabilities **(ULTIMATE)**

You can use [cluster image scanning](../../application_security/cluster_image_scanning/index.md)
to scan container images in your cluster for security vulnerabilities.

To begin scanning all resources in your cluster, add a `starboard`
configuration block to your agent's `config.yaml` with no `filters`:

```yaml
starboard:
  vulnerability_report:
    filters: []
```

The namespaces that are able to be scanned depend on the [Starboard Operator install mode](https://aquasecurity.github.io/starboard/latest/operator/configuration/#install-modes).
By default, the Starboard Operator only scans resources in the `default` namespace. To change this
behavior, edit the `STARBOARD_OPERATOR` environment variable in the `starboard-operator` deployment
definition.

By adding filters, you can limit scans by:

- Resource name
- Kind
- Container name
- Namespace

```yaml
starboard:
  vulnerability_report:
    filters:
      - namespaces:
        - staging
        - production
        kinds:
        - Deployment
        - DaemonSet
        containers:
        - ruby
        - postgres
        - nginx
        resources:
        - my-app-name
        - postgres
        - ingress-nginx
```

A resource is scanned if the resource matches any of the given names and all of the given filter
types (`namespaces`, `kinds`, `containers`, `resources`). If a filter type is omitted, then all
names are scanned. In this example, a resource isn't scanned unless it has a container named `ruby`,
`postgres`, or `nginx`, and it's a `Deployment`:

```yaml
starboard:
  vulnerability_report:
    filters:
      - kinds:
        - Deployment
        containers:
        - ruby
        - postgres
        - nginx
```

There is also a global `namespaces` field that applies to all filters:

```yaml
starboard:
  vulnerability_report:
    namespaces:
    - production
    filters:
    - kinds:
      - Deployment
    - kinds:
      - DaemonSet
      resources:
      - log-collector
```

In this example, the following resources are scanned:

- All deployments (`Deployment`) in the `production` namespace
- All daemon sets (`DaemonSet`) named `log-collector` in the `production` namespace

## Debugging

To debug the cluster-side component (`agentk`) of the Agent, set the log
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
