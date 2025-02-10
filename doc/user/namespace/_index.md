---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Namespaces
---

Namespaces organize projects in GitLab. Because each namespace is separate,
you can use the same project name in multiple namespaces.

When you choose a name for your namespace, keep in mind:

- [Naming rules](../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)
- [Reserved group names](../reserved_names.md#reserved-group-names)

NOTE:
Namespaces with a period (`.`) cause issues with SSL certificate validation and the source path when [publishing Terraform modules](../packages/terraform_module_registry/_index.md#publish-a-terraform-module).

## Types of namespaces

GitLab has two types of namespaces:

- **User**: Your personal namespace is based on your username. In a personal namespace:
  - You cannot create subgroups.
  - Groups do not inherit your namespace permissions or group features.
  - All the projects you create are under the scope of this namespace.
  - Changes to your username also change project and namespace URLs. Before you change your username,
    read about [repository redirects](../project/repository/_index.md#repository-path-changes).

- **Group**: A group or subgroup namespace is based on the group or subgroup name. In group and subgroup namespaces:
  - You can create multiple subgroups to manage multiple projects.
  - Subgroups inherit some of the parent group settings. You can view these in the subgroup **Settings**.
  - You can configure settings specifically for each subgroup and project.
  - You can manage the group or subgroup URL independently of the name.

## Determine which type of namespace you're in

To determine whether you're in a group or personal namespace, you can view the URL. For example:

| Namespace for | URL | Namespace |
| ------------- | --- | --------- |
| A user named `alex`. | `https://gitlab.example.com/alex` | `alex` |
| A group named `alex-team`. | `https://gitlab.example.com/alex-team` | `alex-team` |
| A group named `alex-team` with a subgroup named `marketing`. |  `https://gitlab.example.com/alex-team/marketing` | `alex-team/marketing` |
