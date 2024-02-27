---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tracking cluster resources managed by GitLab (deprecated)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332227) in GitLab 14.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/346567) from GitLab Premium to GitLab Free in 15.3.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/406545) in GitLab 16.2.
To manage cluster resources with GitOps, you should use the [Flux integration](../../../clusters/agent/gitops.md).

GitLab uses an inventory object to track the resources you deploy to your cluster.
The inventory object is a `ConfigMap` that contains a list of controlled objects.
The managed resources use the `cli-utils.sigs.k8s.io/inventory-id` annotation.

## Default location of the inventory object

In the agent configuration file, you specify a list of projects. For example:

```yaml
gitops:
  manifest_projects:
  - id: gitlab-org/cluster-integration/gitlab-agent
    default_namespace: my-ns
```

The agent creates an inventory object for every item in the `manifest_projects` list.
The inventory object is stored in the namespace you specify for `default_namespace`.

The name and location of the inventory object is based on:

- The `default_namespace`. If you don't specify this parameter,
  the inventory object is stored in the `default` namespace.
- The `name`, which is the ID of the project with the manifest and the ID of the agent.

WARNING:
The agent cannot locate the existing inventory object if you change
the `default_namespace` parameter or move manifests to another project.

## Change the location of the inventory object

You can configure the namespace and the name of the inventory object.
This action changes the location of the object in the cluster.

1. Create an inventory object template, which is a `ConfigMap` object.
   For example:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: unique-name-for-the-inventory
     namespace: my-project-namespace
     labels:
       cli-utils.sigs.k8s.io/inventory-id: unique-name-for-the-inventory
   ```

1. Specify a `namespace` and `name`. Ensure that the `name` is unique so it doesn't conflict with other
   inventory objects in the same namespace in the future.
1. Ensure the value for `cli-utils.sigs.k8s.io/inventory-id` is unique. This value is used for objects
   tracked by this inventory object. Their `config.k8s.io/owning-inventory` annotation is set to this value.

   The value doesn't have to match the `name` but it's convenient to set them to the same value.

1. Save the file with the manifest files as a single logical group.

## `inventory_policy` options

Sometimes your manifest changes affect resources that aren't tracked by the GitLab inventory object.

To change how the agent behaves when it overwrites existing and previously untracked resources,
change the `inventory_policy` value.

`inventory_policy` value | Description                                                                                 |
------------------------ | ------------------------------------------------------------------------------------------- |
`must_match`             | The default policy. To be updated, a live object must have the `config.k8s.io/owning-inventory` annotation set to the same value as the `cli-utils.sigs.k8s.io/inventory-id` label on the corresponding inventory object. If the values don't match or the object doesn't have the annotation, the object is not updated and an error is reported. |
`adopt_if_no_inventory`  | Adopt an object if it doesn't have the `config.k8s.io/owning-inventory` annotation. Use this mode if you want to start managing existing objects by using the GitOps feature. To avoid unexpected adoptions, after all objects have been adopted, put the setting back to the default `must_match` mode. |
`adopt_all`              | Adopt an object even if it has the `config.k8s.io/owning-inventory` annotation set to a different value. Use this mode if you want to migrate a set of objects from one agent to another, or from some other tool to the agent. To avoid unexpected adoptions, after all objects have been adopted, put the setting back to the default `must_match` mode. |
