---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Permissions Conventions
---

## Introducing New Permissions

Introduce a new permission only when absolutely necessary. Always try to use an existing one first. For example, there's no need for a `read_issue_description` permission when we already have `read_issue`, and both require the same level of access. As a general guideline, a permission can be reused when the subject and action are the same. In the previous example the subject would be an `issue` and the action would be `read`. There is no need to create a new permission for each attribute of an issue a user may be able to read.

An example for when you should introduce a permission is when the permission is very broad, such as `admin_project`. In this case the permission is vague and is granted to project maintainers.
In theory, this permission can be used to control access to manage CI/CD variables in a project since that capability is granted to maintainers. Unfortunately, it is not clear by looking at the permission check what we are authorizing when a broad permission is used.
Additionally using permissions such as `admin_cicd_variable` or `manage_cicd_variable` should be avoided because they imply different actions that are being authorized. Instead, the action should be specific such as `create_cicd_variable` or `read_cicd_variable`.
Implementing granular permissions allows us to adhere to the principle of least privilege for custom roles and provides much more fine grained options for standard roles.

A new permission must enable support for the principle of least privilege. It must grant only the access required for a
single, well-defined action on a single resource, and no more. If a proposed permission would grant access to
more than one action or bundle unrelated capabilities, split it into separate permissions. If you cannot scope
the permission this narrowly, reconsider the design before introducing it.

Permissions are referenced by [role definition YAML files](role_definitions.md) (for default roles),
[custom ability YAML files](custom_roles.md) (for custom roles), and
[assignable permission groups](granular_access/rest_api_implementation_guide.md#step-4-create-or-update-assignable-permissions)
(for granular PAT scoping).

## Naming Permissions

Our goal is for all permissions to follow a consistent pattern: **`action_resource(_subresource)`**. These guidelines apply to both Assignable Permissions and Raw Permissions, but most strictly be followed with Assignable Permissions as they are public facing.

### Preferred Actions

If you are introducing a new permission, prefer to use one of the following actions:

| Action   | What it does                 | Example        |
|----------|------------------------------|----------------|
| `create` | Creates a new object         | `create_issue` |
| `read`   | Views or retrieves an object | `read_project` |
| `update` | Modifies an existing object  | `update_merge_request` |
| `delete` | Removes an object            | `delete_issue` |

We recognize that this set of actions is limited and not applicable to every feature. Actions are [situationally allowed from outside this set](#when-to-introduce-new-actions), but require approval from the [Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/govern/authorization/#group-members).

### Disallowed Actions

The following action patterns are examples of those that should not be introduced into the permission catalog:

| Action     | Why it’s disallowed |
|-----------|--------------------|
| `admin`   | Implies broad, undefined authority with unclear scope |
| `change`  | Redundant with `update` |
| `configure` | Redundant with `update` |
| `destroy` | Reflects implementation semantics rather than the domain action; prefer `delete` |
| `edit`    | Redundant with `update` |
| `list`    | Ambiguous read semantics; use `read` |
| `manage`  | Bundles multiple CRUD operations into a single ambiguous permission |
| `modify`  | Redundant with `update` |
| `set`     | Redundant with `update` |
| `view`    | Ambiguous read semantics; use `read` |
| `write`   | Encompasses create, update, and delete operations, causing unintentional privilege escalation that results in security incidents where users accidentally receive delete access when only needing create or update permissions. Use specific actions like `create`, `update`, or `delete` |

While you may see permissions with these actions, they were likely introduced before these conventions were established and will eventually be refactored to align with the current guidelines.

### When to Introduce New Actions

There are actions outside of [the preferred set](#preferred-actions) that are necessary for providing users with a secure and intuitive permissions model.

A new action may be introduced when:

1. The action represents a distinct lifecycle or state transition already present in the GitLab domain language. For example, `archive_project` or `protect_branch` represent specific actions that users understand and expect because they are already established within the GitLab domain language.
1. The action changes the relationship between resources that are a part of the GitLab domain language. For example, `transfer_project` or `move_issue` represent specific actions that change the relationship between the resource and its parent namespace.
1. The action is high-impact or irreversible and carries distinct domain meaning. For example, `purge_maven_virtual_registry_cache` uses the action `purge` which is irreversible and has established meaning when discussing caching in the broader software industry.

### Resource Naming Conventions

The resource (and optional subresource) in a permission name should always:

1. Use the singular form (e.g., `read_project` instead of `read_projects`)
1. Match the domain object being acted upon. (e.g., if an action is being evaluated against an `Issue` the permission name should be in the format `{action}_issue`.)
1. Use user-facing domain terminology instead of exposing implementation details. (e.g., if a customer would have no way of knowing about your resource, it probably shouldn't be in the permission name)

### Avoiding Resource Boundaries in Permission Names

Permissions **should NOT encode the resource boundary** (such as `project`, `group`, or `user`) directly into the permission name.

For example, avoid introducing separate permissions like `read_project_insights_dashboard` and `read_group_insights_dashboard`.
Instead, define a single semantic permission that describes the capability itself, such as `read_insights_dashboard`.

Including boundaries like `project` or `group` in the permission name is redundant because passing the **subject** in the `can?` check already determines the scope. For example:

```ruby
can?(:read_insights_dashboard, project)
can?(:read_insights_dashboard, group)
```

### Exceptions

If you believe a new permission is needed that does not follow these conventions, consult the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authorization). We're always open to discussion, these guidelines are meant to make the work of Engineers easier, not to complicate it.

## Private permissions

Private permissions are narrowly-scoped permissions that represent conditional
or nuanced capabilities. They are prefixed with an underscore (`_`) to signal
that they are **private to policy logic only** and must not be checked directly
at enforcement points (controllers, services, finders, GraphQL).

### Why private permissions exist

In the GitLab RBAC model, the same action can behave differently depending on the
role. For example:

- **Guest** can read confidential issues **they authored or are assigned to**.
- **Planner+** can read **any** confidential issue.

Without private permissions, both cases map to a single `read_issue`
permission and the nuance is buried in procedural policy logic. This creates problems:

- **Privilege escalation risk**: When a user invites another user, the system
  must verify that the invited role's permissions do not exceed the inviting
  user's own. With a flat permission like `read_issue`, a Guest who can only
  read authored issues and an Owner who can read all issues appear identical.
- **Custom role ambiguity**: Custom roles built from flat permissions cannot
  express "read only authored issues." A custom role either gets full
  `read_issue` (too broad) or nothing (too restrictive).

Private permissions solve these problems by making the nuance explicit and
machine-readable.

### Naming convention

Private permissions follow the pattern **`_<action>_<qualifier>_<resource>`**,
where the qualifier describes the condition under which the permission applies:

| Permission | Description | Typical roles |
|---|---|---|
| `_read_authored_issue` | Read an issue you authored regardless of confidentiality | Guest+, Internal |
| `_read_assigned_issue` | Read an issue you are assigned to regardless of confidentiality | Guest+, Internal |
| `_read_confidential_issue` | Read any confidential issue | Planner, Reporter+ |

The underscore prefix serves several purposes:

1. It visually distinguishes private permissions from public permissions in
   code and YAML definitions.
1. It signals to developers and tooling that this permission must not appear in
   a `can?` check outside of a policy file.
1. It makes it easy for linters to flag inappropriate use.
1. Convention over configuration. The underscore syntax is preferable to storing metadata in the permission definition.

#### Qualifier Naming Conventions

The qualifier should generally be an attribute of the resource. It describes a subset of the resource that the permission applies to, based on a property that exists on the resource itself.

Guidelines for qualifiers:

1. The qualifier must correspond to a real attribute or relationship on the resource. Do not use qualifiers that describe the actor (e.g., avoid `admin_read_issue`).
1. Prefer past-participle or adjective forms that read naturally as a description of the resource (e.g., `confidential`, `authored`, `assigned`).
1. Qualifiers should only be introduced when the same action on the same resource requires different access levels depending on the resource's state. If all instances of the resource require the same access level, a qualifier is unnecessary.

### How to use private permissions in a policy

Private permissions act as gates. A role enables the private permission via
the role YAML definition. The policy then combines the private permission with
a subject-level condition to enable the broader public permission:

```ruby
# In the role YAML (e.g., config/authz/roles/guest.yml):
#   raw_permissions:
#     - _read_authored_issue
#     - _read_assigned_issue
#     - read_issue
#
# In the role YAML (e.g., config/authz/roles/reporter.yml):
#   raw_permissions:
#     - _read_authored_issue
#     - _read_assigned_issue
#     - _read_confidential_issue
#     - read_issue

# In the issue policy (e.g., app/policies/issue_policy.rb):
condition(:is_author) { @subject.author == @user }
condition(:is_assignee) { @subject.assignees.include?(@user) }
condition(:is_confidential) { @subject.confidential? }

rule { ~is_author }.prevent :_read_authored_issue
rule { ~is_assignee }.prevent :_read_assigned_issue

rule { can?(:_read_authored_issue) | can?(:_read_assigned_issue) }.policy do
  enable :read_issue
  enable :_read_confidential_issue
end

rule { is_confidential & ~can?(:_read_confidential_issue) }.prevent :read_issue
```

Enforcement points (controllers, services, GraphQL) only check the public
permission:

```ruby
# Correct - check the public permission
authorize :read_issue

# Wrong - never check a private permission at an enforcement point
authorize :_read_authored_issue
```

### When to use private permissions

Use a private permission when:

1. A role can perform an action **only when a subject-level condition is met**
   (authored by the user, assigned to the user, created by the user).
1. Different roles have different levels of access to the same action (some
   unconditional, some conditional).
1. The distinction matters for **privilege escalation checks** or
   **custom role composition**.

Do not use private permissions for:

- Feature flag or license checks. Use `prevent` rules instead.
- Settings-based restrictions. Use `prevent` rules instead.
- Conditions that apply equally to all roles. Use a single `prevent` rule.

### Permission definition files

Private permissions require a definition file like any other permission.
The file name uses the underscore prefix to match the permission name:

```plaintext
config/authz/permissions/<resource>/_<action>_<qualifier>.yml
```

For example:

```yaml
# config/authz/permissions/issue/_read_authored.yml
---
name: _read_authored_issue
description: Allows users to read issues they authored when they would not otherwise have access
```

### Declare broader permissions with conditionally_enables

Every private permission must declare a `conditionally_enables` field. It lists the broader
public permission, or permissions, that already grant the capability this private permission
scopes down. Role expansion reads this field: a role that holds every listed permission
implicitly holds the private permission, so you do not list the private permission on roles
that already hold the broader one.

Use a single broader permission when one public permission supersedes the private one:

```yaml
# config/authz/permissions/work_item/_read_authored.yml
---
name: _read_authored_work_item
description: Grants the ability to read work items that were authored by the user.
conditionally_enables: read_work_item
```

A role that grants `read_work_item` then also grants `_read_authored_work_item` through
expansion. A role that does not grant `read_work_item` is unaffected, so a Guest can still
receive `_read_authored_work_item` directly through its role definition.

List several permissions when the role must hold all of them to imply the private permission:

```yaml
conditionally_enables:
  - push_code
  - create_merge_request_from
  - create_merge_request_in
```

Use `null` when no public permission supersedes the private one. This generally applies when the private permission conditionally prevents versus conditionally enables:

```yaml
# config/authz/permissions/job/_update_protected.yml
---
name: _update_protected_job
description: Private permission to enable/prevent job update and write abilities
conditionally_enables: null
```

The validation task fails if a private permission omits `conditionally_enables`.
