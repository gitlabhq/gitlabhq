---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Kubernetes Agent configuration repository **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259669) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.7.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3834) in GitLab 13.11, the Kubernetes Agent became available on GitLab.com.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332227) in GitLab 14.0, the `resource_inclusions` and `resource_exclusions` attributes were removed and `reconcile_timeout`, `dry_run_strategy`, `prune`, `prune_timeout`, `prune_propagation_policy`, and `inventory_policy` attributes were added.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

The [GitLab Kubernetes Agent integration](index.md) supports hosting your configuration for
multiple GitLab Kubernetes Agents in a single repository. These agents can be running
in the same cluster or in multiple clusters, and potentially with more than one Agent per cluster.

The Agent bootstraps with the GitLab installation URL and an authentication token,
and you provide the rest of the configuration in your repository, following
Infrastructure as Code (IaaC) best practices.

A minimal repository layout looks like this, with `my_agent_1` as the name
of your Agent:

```plaintext
|- .gitlab
    |- agents
       |- my_agent_1
          |- config.yaml
```

## Synchronize manifest projects

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
This is detected by the GitLab Kubernetes Agent and leads to an error.

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

## Surface network security alerts from cluster to GitLab

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

## Debugging

To debug the cluster-side component (`agentk`) of the GitLab Kubernetes Agent, set the log
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
