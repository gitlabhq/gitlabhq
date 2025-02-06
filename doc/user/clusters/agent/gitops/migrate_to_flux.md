---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from legacy GitOps to Flux
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Most users can migrate from their legacy agent-based GitOps solution
to Flux without additional work or downtime. In most cases, Flux can
take over existing workloads without any restarts.

## Example GitOps configuration

Your legacy GitOps setup might contain an agent configuration like:

```yaml
gitops:
  manifest_projects:
  - id: <your-group>/<your-repository>
    paths:
    - glob: 'manifests/*.yaml'
```

The `manifests` directory referenced in the `paths.glob` might have two
manifests. One manifest defines a `Namespace`:

```yaml
# /manifests/namespace.yaml

---
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

And the other manifest defines a `Deployment`:

```yaml
# /manifests/deployment.yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: production
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

The topics on this page use this configuration to
demonstrate a migration to Flux.

## Disable legacy GitOps functionality in the agent

When the GitOps configuration is removed, the agent
doesn't delete any running workloads it applied.
To remove the GitOps functionality from your agent:

- Delete the `gitops` section from the agent configuration file.

You still need a functional agent,
so don't delete your entire `config.yaml` file.

If you have multiple items under `gitops.manifest_projects` or under the `paths` list, you can migrate one part at a time by removing only the specific project or path.

## Bootstrap Flux

Before you begin:

- You disabled the GitOps functionality in your agent.
- You installed the Flux CLI in a terminal with access to your cluster.

To bootstrap Flux:

- In your terminal, run the `flux bootstrap gitlab` command. For example:

  ```shell
  flux bootstrap gitlab \
  --owner=<your-group> \
  --repository=<your-repository> \
  --branch=main \
  --path=manifests/ \
  --deploy-token-auth
  ```

Flux is installed on your cluster, and the necessary
Flux configuration files are committed to `manifests/flux-system`,
which syncs Flux and the entire `manifests` directory.

Because the workloads (the `Namespace` and `Deployment` manifests)
are already declared in the `manifests` directory, there is
no extra work involved.

For more information about configuring Flux with GitLab, see
[Tutorial: Set up Flux for GitOps](flux_tutorial.md).

## Troubleshooting

### `flux bootstrap` doesn't reconcile manifests correctly

The `flux bootstrap` command creates a `kustomizations.kustomize.toolkit.fluxcd.io`
resource that points to the `manifests` directory.
This resource applies to all the Kubernetes manifests in the directory,
without requiring a [Kustomization file](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization).

This process might not work with your configuration.
To troubleshoot, review the Flux Kustomization status for potential issues:

```shell
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -n flux-system
```

### Use a `default_namespace` in the agent configuration

You might encounter an issue if your legacy agent-based GitOps setup
refers to a `default_namespace` in the agent configuration, but omits this
namespace in the manifests itself. This causes an error where
your bootstrapped Flux doesn't know that your existing manifests are applied
to the `default_namespace`.

To solve this issue, you can either:

- Set the namespace manually in your previously existing resource YAML.
- Move your resources into a dedicated directory, and point Flux at it with `kustomize.toolkit.fluxcd.io/Kustomization`, where `spec.targetNamespace` specifies the namespace.
- Move the resources into a subdirectory and add a `kustomization.yaml` file that sets the `spec.namespace` property.

If you prefer to move the resources outside the path already configured for Flux,
you should use `kustomize.toolkit.fluxcd.io/Kustomization`.
If you prefer to move the resources into a subdirectory of a path already watched by
Flux, you should use a `kustomize.config.k8s.io/Kustomization`.
