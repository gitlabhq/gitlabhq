---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Internal permission groups
---

Internal permission groups are YAML-based configuration files that define logical
groupings of permissions which are activated or deactivated together based on
internal resource state. They allow you to centrally manage sets of permissions
that should be collectively prevented (or enabled) when a specific condition is
met, such as a group being archived.

## How they work

Internal permission groups are defined as YAML files under
`config/authz/permission_groups/internal/`. Each file contains a description and
a list of permission names. At runtime, the
`Authz::PermissionGroups::Internal` class loads these files and provides a lookup
API to retrieve a group by its identifier.

### Naming convention

The identifier for an internal permission group is derived from its file path
relative to the `config/authz/permission_groups/internal/` directory:

- Directory names become colon-separated prefixes.
- The file name (without extension) becomes the final segment.

For example, `config/authz/permission_groups/internal/group/archived.yml`
produces the identifier `group:archived`.

### YAML file structure

Each YAML file must contain:

- `description`: A human-readable explanation of when these permissions apply.
- `permissions`: A list of permission (ability) names as strings.

Example (`config/authz/permission_groups/internal/group/archived.yml`):

```yaml
description: Permissions that are disabled when a group is archived
permissions:
  - activate_group_member
  - admin_build
  - create_projects
  - push_code
  # ... additional permissions
```

## Using an internal permission group in a policy

To use an internal permission group in a `DeclarativePolicy` policy, call
`Authz::PermissionGroups::Internal.get` with the group identifier and splat
the returned permissions into a `prevent` rule:

```ruby
# app/policies/group_policy.rb

condition(:archived, scope: :subject) { @subject.self_or_ancestors_archived? }

rule { archived }.policy do
  prevent(*Authz::PermissionGroups::Internal.get('group:archived').permissions)
end
```

This prevents all listed permissions when the `archived` condition is true,
replacing the need to maintain a long inline list of `prevent` calls.

## Creating a new internal permission group

1. **Create the YAML file.** Add a new `.yml` file under
   `config/authz/permission_groups/internal/`. Use directories to namespace by
   resource type:

   ```plaintext
   config/authz/permission_groups/internal/<resource>/<subresource>/<name>.yml
   ```

   For example, to define permissions to prevent when a project is locked:

   ```yaml
   # config/authz/permission_groups/internal/project/locked.yml
   description: Permissions that are disabled when a project is locked
   permissions:
     - push_code
     - create_merge_request_from
     - admin_merge_request
   ```

1. **Reference it in a policy.** Use the identifier derived from the file path
   (`project:locked` in this example):

   ```ruby
   # app/policies/project_policy.rb

   condition(:locked, scope: :subject) { @subject.locked? }

   rule { locked }.policy do
     prevent(*Authz::PermissionGroups::Internal.get('project:locked').permissions)
   end
   ```

## When to use internal permission groups

Use internal permission groups when:

- A resource state change (such as archiving or locking) should disable many
  permissions at once.
- The same set of permissions needs to be referenced from multiple places
  (policies, specs, or shared examples).
- You want a single source of truth for which permissions a condition affects,
  rather than scattering `prevent` calls throughout policy files.

Do **not** use internal permission groups for:

- Role-based permission assignment. Use
  [role definitions](role_definitions.md) or
  [custom roles](custom_roles.md) instead.
- Token-scoped permissions. Use
  [assignable permissions](granular_access/assignable_permissions.md) instead.
