---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Namespaces

In GitLab, a *namespace* provides one place to organize your related projects. Projects in one namespace are separate from projects in other namespaces,
which means you can use the same name for projects in different namespaces.

## Types of namespaces

GitLab has two types of namespaces:

- A *personal* namespace, which is based on your username and provided to you when you create your account.
  - You cannot create subgroups in a personal namespace.
  - Groups in your namespace do not inherit your namespace permissions and group features.
  - All the projects you create are under the scope of this namespace.
  - If you change your username, the project and namespace URLs in your account also change. Before you change your username,
    read about [repository redirects](../project/repository/index.md#what-happens-when-a-repository-path-changes).

- A *group* or *subgroup* namespace, which is based on the group or subgroup name:
  - You can create multiple subgroups to manage multiple projects.
  - You can configure settings specifically for each subgroup and project in the namespace.
  - When you create a subgroup, it inherits some of the parent group settings. You can view these in the subgroup **Settings**.
  - You can change the URL of group and subgroup namespaces.

## Determine which type of namespace you're viewing

To determine whether you're viewing a group or personal namespace, you can view the URL. For example:

| Namespace for | URL | Namespace |
| ------------- | --- | --------- |
| A user named `alex`. | `https://gitlab.example.com/alex` | `alex` |
| A group named `alex-team`. | `https://gitlab.example.com/alex-team` | `alex-team` |
| A group named `alex-team` with a subgroup named `marketing`. |  `https://gitlab.example.com/alex-team/marketing` | `alex-team/marketing` |

## Naming limitations for namespaces

When choosing a name for your namespace, keep in mind the [character limitations](../reserved_names.md#limitations-on-usernames-project-and-group-names-and-slugs) and [reserved group names](../reserved_names.md#reserved-group-names).

NOTE:
If your namespace contains a `.`, you will encounter issues with the validation of your SSL certificates and the source path when [publishing Terraform modules](../packages/terraform_module_registry/index.md#publish-a-terraform-module).
