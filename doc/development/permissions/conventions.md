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

Our goal is for all permissions to follow a consistent pattern: `action_resource(_subresource)`. The resource and subresource should always be in the singular and match the object being acted upon. For example, if an action is being evaluated against a `Project` the permission name should be in the format `action_project`. Additionally, we aim to limit the actions used to ensure clarity. The preferred actions are:

- `create` - for creating an object. For example, `create_issue`.
- `read` - for reading an object. For example, `read_issue`.
- `update` - for updating an object. For example, `update_issue`.
- `delete` - for deleting an object. For example, `delete_issue`.
- `push` and `download` - these are specific actions for file-related permissions. Other industry terms can be permitted after a justification.

We recognize that this set of actions is limited and not applicable to every feature. If you're unsure about a new permission name, consult a member of the [Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authorization/#group-members) for advice or approval for exceptions.

#### Preferred Actions

- `create` is preferred over `build` or `import`
- `read` is preferred over `access`
- `push` is preferred over `upload`
- `delete` is preferred over `destroy`

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
