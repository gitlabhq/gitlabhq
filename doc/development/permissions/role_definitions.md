---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Role definition YAML files
---

Default roles in GitLab are defined using YAML files in `config/authz/roles/`.
Each file defines a single role, its permissions, and its inheritance hierarchy.

The `Authz::Role` class loads these files at runtime, resolves inherited permissions,
and expands assignable permission groups into their constituent raw permissions.

## YAML schema

Each role definition file follows this structure:

```yaml
# config/authz/roles/<role_name>.yml
---
name: developer
description: Developer role
inherits_from:
  - reporter
raw_permissions:
  - push_code
  - create_pipeline
permissions:
  - read_work_item
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | yes | String | Unique, lowercase, underscored name matching the filename. |
| `description` | yes | String | Human-readable description of the role. |
| `inherits_from` | yes | Array | List of parent role names. Use `[]` for roles with no parent. |
| `raw_permissions` | no | Array | Permissions granted directly by this role. These are individual permission atoms defined in `config/authz/permissions/`. |
| `permissions` | no | Array | Assignable permission group names. Each name references a group defined in `config/authz/permission_groups/assignable_permissions/` and is expanded into its constituent raw permissions at load time. |

## How permissions are resolved

When `Authz::Role.get(:developer)` is called:

1. The YAML file at `config/authz/roles/developer.yml` is loaded and cached.
1. The `inherits_from` list is resolved recursively. For each parent role,
   the same loading and resolution process is applied.
1. Assignable permission group names listed in `permissions` are expanded via
   `Authz::PermissionGroups::Assignable`. Each group maps to one or more raw permissions.
1. The final permission set is the union of:
   - `raw_permissions` from this role
   - Expanded `permissions` (assignable groups) from this role
   - All permissions inherited from parent roles (recursively)

### Example resolution

Given these role definitions:

```yaml
# guest.yml
name: guest
inherits_from: []
raw_permissions:
  - read_issue
  - create_issue

# reporter.yml
name: reporter
inherits_from:
  - guest
raw_permissions:
  - read_code
  - download_code

# developer.yml
name: developer
inherits_from:
  - reporter
raw_permissions:
  - push_code
  - create_pipeline
```

Calling `Authz::Role.get(:developer).permissions` returns:

```ruby
[:read_issue, :create_issue,     # inherited from guest
 :read_code, :download_code,     # inherited from reporter
 :push_code, :create_pipeline]   # direct from developer
```

## Relationship to the permission architecture

Role YAML files are one layer of the GitLab permission architecture.
Understanding how they relate to other components:

### Raw permissions

Defined in `config/authz/permissions/<resource>/<action>.yml`. These are the
atomic units of authorization — each represents a single action on a single
resource (for example, `read_issue`, `create_pipeline`). Raw permissions are referenced
directly in `raw_permissions` arrays in role YAML files and in policy `enable`/`prevent` calls.

For details on creating and naming raw permissions, see [Permission conventions](conventions.md).

### Assignable permission groups

Defined in `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`.
These bundle multiple raw permissions into user-facing capability sets that can be
assigned to roles or used for granular PAT scoping.

For example, the `read_pipeline` assignable permission group might expand to:

```yaml
# config/authz/permission_groups/assignable_permissions/ci_cd/pipeline/read.yml
name: read_pipeline
description: Grants the ability to read pipelines
permissions:
  - read_pipeline
  - read_pipeline_bridge
  - read_pipeline_job
boundaries:
  - project
```

When a role YAML file lists `read_pipeline` under its `permissions` field, all three
raw permissions are granted to that role.

### Policy files

[DeclarativePolicy](predefined_roles.md) classes (`app/policies/`) define the runtime
authorization rules that evaluate whether a user can perform an action. Policy rules
reference raw permissions via `enable` and `prevent` calls. Role YAML files
determine which permissions a user holds based on their role, and policies
determine the conditions under which those permissions are evaluated.

### Custom abilities

Defined in `ee/config/custom_abilities/`. These allow Ultimate customers to create
custom roles with specific abilities. Custom ability YAML files include
`project_permissions` and `group_permissions` fields that map to raw permissions,
similar to how role YAML files use `raw_permissions`. See [Custom roles](custom_roles.md)
for details.

## Modifying an existing role

When adding or removing permissions from a role:

- When adding a permission to a role you should use an assignable permission group. If the permission is net-new then the assignable permission group should be created first or it should be added to an existing assignable permission group. If the permission is existing but needs to be moved into the role definition then assigning it as a `raw_permission` is acceptable.
- When removing a permission, verify it is not depended on by other features.
  Use `GITLAB_DEBUG_POLICIES=true` (see [Custom roles](custom_roles.md#finding-existing-abilities-checks))
  to trace where a permission is checked.
