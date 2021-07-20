---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Inventory object **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332227) in GitLab 14.0.

An inventory object is a `ConfigMap` object for keeping track of the set of objects applied to a cluster.
When you remove objects from a manifest repository, GitLab Kubernetes Agent uses a corresponding inventory object to
prune (delete) objects from the cluster.

The GitLab Kubernetes Agent creates an inventory object for each manifest project specified in the
`gitops.manifest_projects` configuration section. The inventory object has to be stored somewhere in the cluster.
The default behavior is:

- The `namespace` used comes from `gitops.manifest_projects[].default_namespace`. If you don't specify this parameter
  explicitly, the inventory object is stored in the `default` namespace.
- The `name` is generated from the numeric project ID of the manifest project and the numeric agent ID.

  This way the GitLab Kubernetes Agent constructs the name and local where the inventory object is
  stored in the cluster.

The GitLab Kubernetes Agent cannot locate the existing inventory object if you:

- Change `gitops.manifest_projects[].default_namespace` parameter.
- Move manifests into another project.

## Inventory object template

The inventory object template is a `ConfigMap` object that allows you to configure the namespace and the name of the inventory
object. Store this template with manifest files in a single group.

Example inventory object template:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: unique-name-for-the-inventory
  namespace: my-project-namespace
  labels:
    cli-utils.sigs.k8s.io/inventory-id: unique-name-for-the-inventory
```

- The `namespace` and `name` fields configure where the real inventory object is created.
- The `cli-utils.sigs.k8s.io/inventory-id` label with its corresponding value is set on the inventory object, created
  from this template. Make sure that the value is unique (for example, a string of random characters) and doesn't clash
  with any existing or future inventory object templates.
- Objects tracked by this inventory object have the `config.k8s.io/owning-inventory` annotation set to the value of
  the `cli-utils.sigs.k8s.io/inventory-id` label.
- The label's value doesn't have to match the `name` but it's convenient to have them set to the same value.
- Make sure that the `name` is unique so that it doesn't conflict with another inventory object in the same
  namespace in the future.

## Using GitOps with pre-existing Kubernetes objects

The GitLab Kubernetes Agent treats manifest files in the manifest repository as the source of truth. When it applies
objects from the files to the cluster, it tracks them in an inventory object. If an object already exists,
GitLab Kubernetes Agent behaves differently based on the `gitops.manifest_projects[].inventory_policy` configuration.
Check the table below with the available options and when to use them.

`inventory_policy` value | Description                                                                                 |
------------------------ | ------------------------------------------------------------------------------------------- |
`must_match`             | This is the default policy. A live object must have the `config.k8s.io/owning-inventory` annotation set to the same value as the `cli-utils.sigs.k8s.io/inventory-id` label on the corresponding inventory object to be updated. Object is not updated and an error is reported if the values don't match or the object doesn't have the annotation. |
`adopt_if_no_inventory`  | This mode allows to "adopt" an object if it doesn't have the `config.k8s.io/owning-inventory` annotation. Use this mode if you want to start managing existing objects using the GitOps feature. Once all objects have been "adopted", we recommend you to put the setting back into the default `must_match` mode to avoid any unexpected adoptions. |
`adopt_all`              | This mode allows to "adopt" an object even if it has the `config.k8s.io/owning-inventory` annotation set to a different value. This mode can be useful if you want to migrate a set of objects from one agent to another one or from some other tool to the GitLab Kubernetes Agent. Once all objects have been "adopted", we recommend you to put the setting back into the default `must_match` mode to avoid any unexpected adoptions. |
