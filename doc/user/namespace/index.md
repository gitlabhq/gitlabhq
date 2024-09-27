---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Namespaces

In GitLab, a namespace provides a place to organize projects. Projects in a namespace are separate
from other namespaces, enabling you to use the same project name in different namespaces.

## Types of namespaces

GitLab has two types of namespaces:

- **User**: Your personal namespace is based on your username. In a personal namespace:
  - You cannot create subgroups.
  - Groups do not inherit your namespace permissions or group features.
  - All the projects you create are under the scope of this namespace.
  - Changes to your username also change project and namespace URLs. Before you change your username,
    read about [repository redirects](../project/repository/index.md#repository-path-changes).

- **Group**: A group or subgroup namespace is based on the group or subgroup name. In group and subgroup namespaces:
  - You can create multiple subgroups to manage multiple projects.
  - Subgroups inherit some of the parent group settings. You can view these in the subgroup **Settings**.
  - You can configure settings specifically for each subgroup and project.
  - You can manage the group or subgroup URL independently of the name.

## Determine which type of namespace you're viewing

To determine whether you're viewing a group or personal namespace, you can view the URL. For example:

| Namespace for | URL | Namespace |
| ------------- | --- | --------- |
| A user named `alex`. | `https://gitlab.example.com/alex` | `alex` |
| A group named `alex-team`. | `https://gitlab.example.com/alex-team` | `alex-team` |
| A group named `alex-team` with a subgroup named `marketing`. |  `https://gitlab.example.com/alex-team/marketing` | `alex-team/marketing` |

## Naming limitations for namespaces

When you choose a name for your namespace, keep in mind the [character limitations](../reserved_names.md#limitations-on-usernames-project-and-group-names-and-slugs) and [reserved group names](../reserved_names.md#reserved-group-names).

NOTE:
Namespaces with a period (`.`) cause issues with validating SSL certificates and the source path when [publishing Terraform modules](../packages/terraform_module_registry/index.md#publish-a-terraform-module).
