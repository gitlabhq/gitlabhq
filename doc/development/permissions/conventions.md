---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Permissions Conventions
---

## Historical Context

We utilize the [`DeclarativePolicy` framework for authorization in GitLab](../policies.md), making it straightforward to add new permissions. Until 2024, there was no clear guidance on when to introduce new permissions and how to name them. This lack of direction is a significant reason why the number of permissions has become unmanageable.

The purpose of this document is to provide guidance on:

- When to introduce a new permission and when to reuse an existing one
- How to name new permissions
- What should be included in the `Policy` classes and what should not

### Introducing New Permissions

Introduce a new permission only when absolutely necessary. Always try to use an existing one first. For example, there's no need for a `read_issue_description` permission when we already have `read_issue`, and both require the same level of access. As a general guideline, a permission can be reused when the subject and action are the same. In the previous example the subject would be an `issue` and the action would be `read`. There is no need to create a new permission for each attribute of an issue a user may be able to read.

An example for when you should introduce a permission is when the permission is very broad, such as `admin_project`. In this case the permission is vague and is granted to project maintainers.
In theory, this permission can be used to control access to manage CI/CD variables in a project since that capability is granted to maintainers. Unfortunately, it is not clear by looking at the permission check what we are authorizing when a broad permission is used.
Additionally using permissions such as `admin_cicd_variable` or `manage_cicd_variable` should be avoided because they imply different actions that are being authorized. Instead, the action should be specific such as `create_cicd_variable` or `read_cicd_variable`.
Implementing granular permissions allows us to adhere to the principle of least privilege for custom roles and provides much more fine grained options for standard roles.

### Permission Definition File

Each permission should have a corresponding definition file. These files are used to build documentation and enable a permissions-first architecture around authorization logic.

To generate a new definition file, run the following command.

```shell
bundle exec rails generate authz:permission <permission_name>
```

Optionally, if you need to override the default action or resource you can use the `--action` and/or `--resource` options. This is helpful if the action is more than one word. For example, consider the permission `force_delete_ai_catalog_item`. By default the generator will assume that the permission action is `force` and the resource is `delete_ai_catalog_item` which would result in a definition file being written to `config/authz/permissions/delete_ai_catalog_item/force.yml`, which is incorrect.

The following command can be used to generate a definition file with the correct action and resource which will result in the definition file being written to `config/authz/permissions/ai_catalog_item/force_delete.yml`.

```shell
bundle exec rails generate authz:permission force_delete_ai_catalog_item --action force_delete
```

### Naming Permissions

Our goal is for all permissions to follow a consistent pattern: **`action_resource(_subresource)`**. These guidelines apply to both Assignable Permissions and Raw Permissions, but most strictly be followed with Assignable Permissions as they are public facing.

#### Preferred Actions

If you are introducing a new permission, prefer to use one of the following actions:

| Action   | What it does                 | Example        |
|----------|------------------------------|----------------|
| `create` | Creates a new object         | `create_issue` |
| `read`   | Views or retrieves an object | `read_project` |
| `update` | Modifies an existing object  | `update_merge_request` |
| `delete` | Removes an object            | `delete_issue` |

We recognize that this set of actions is limited and not applicable to every feature. Actions are [situationally allowed from outside this set](#when-to-introduce-new-actions), but require approval from the [Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/govern/authorization/#group-members).

#### Disallowed Actions

The following action patterns are examples of those that should not be introduced into the permission catalog:

| Action     | Why it’s disallowed |
|-----------|--------------------|
| `admin`   | Implies broad, undefined authority with unclear scope |
| `change`  | Redundant with `update` |
| `destroy` | Reflects implementation semantics rather than the domain action; prefer `delete` |
| `edit`    | Redundant with `update` |
| `list`    | Ambiguous read semantics; use `read` |
| `manage`  | Bundles multiple CRUD operations into a single ambiguous permission |
| `modify`  | Redundant with `update` |
| `set`     | Redundant with `update` |
| `view`    | Ambiguous read semantics; use `read` |
| `write`   | Does not align with our permission granularity; prefer specific actions like `create`, `update`, or `delete` |

While you may see permissions with these actions, they were likely introduced before these [conventions were established](#historical-context) and will eventually be refactored to align with the current guidelines.

#### When to Introduce New Actions

There are actions outside of [the preferred set](#preferred-actions) that are necessary for providing users with a secure and intuitive permissions model.

A new action may be introduced when:

1. The action represents a distinct lifecycle or state transition already present in the GitLab domain language. For example, `archive_project` or `protect_branch` represent specific actions that users understand and expect because they are already established within the GitLab domain language.

1. The action changes the relationship between resources that are a part of the GitLab domain language. For example, `transfer_project` or `move_issue` represent specific actions that change the relationship between the resource and its parent namespace.

1. The action is high-impact or irreversible and carries distinct domain meaning. For example, `purge_maven_virtual_registry_cache` uses the action `purge` which is irreversible and has established meaning when discussing caching in the broader software industry.

#### Resource Naming Conventions

The resource (and optional subresource) in a permission name should always:

1. Use the singular form (e.g., `read_project` instead of `read_projects`)

1. Match the domain object being acted upon. (e.g., if an action is being evaluated against an `Issue` the permission name should be in the format `{action}_issue`.)

1. Use user-facing domain terminology instead of exposing implementation details. (e.g., if a customer would have no way of knowing about your resource, it probably shouldn't be in the permission name)

#### Avoiding Resource Boundaries in Permission Names

Permissions **should NOT encode the resource boundary** (such as `project`, `group`, or `user`) directly into the permission name.

For example, avoid introducing separate permissions like `read_project_insights_dashboard` and `read_group_insights_dashboard`.
Instead, define a single semantic permission that describes the capability itself, such as `read_insights_dashboard`.

Including boundaries like `project` or `group` in the permission name is redundant because passing the **subject** in the `can?` check already determines the scope. For example:

```ruby
can?(:read_insights_dashboard, project)
can?(:read_insights_dashboard, group)
```

#### Exceptions

If you believe a new permission is needed that does not follow these conventions, consult the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/govern/authorization/). We're always open to discussion, these guidelines are meant to make the work of Engineers easier, not to complicate it.

### What to Include in Policy Classes

#### Role

Policy classes should include checks for both predefined and custom roles.

Examples:

```ruby
rule { developer } # Static role check
rule { can?(:developer_access) } # Another approach used in some classes
rule { custom_role_enables_read_dependency } # Custom role check
```

#### Checks Related to the Current User

Include checks that vary based on the current user's relationship with the object, such as being an assignee or author.

Examples:

```ruby
rule { is_author }.policy do
  enable :read_note
  enable :update_note
  enable :delete_note
end
```
