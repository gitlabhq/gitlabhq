---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Assignable Permissions
---

## Assignable Permissions

Assignable permissions bundle one or more raw permissions into user-facing permission groups. They allow you to adjust the level of granularity presented to users, letting the product group decide whether to group permissions finely (e.g., read issue and read snippet permissions separately) or more broadly (e.g., all read work item permissions together). This maintains fine-grained control at the code level while providing a user-friendly experience in the UI.

### Create the Assignable Permission File

Create a new YAML file manually at `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`:

```yaml
---
name: run_job
description: Grants the ability to run jobs
permissions:
  - play_job
  - retry_job
boundaries:
  - group
  - project
```

### Assignable Permission File Fields

| Field | Description |
|-------|-------------|
| `name` | Unique identifier for the assignable permission |
| `description` | Human-readable description of what the assignable permission grants |
| `permissions` | Array of raw permissions included in this assignable permission (must already exist as [raw permission definition files](permission_definitions.md#permission-definition-file)) |
| `boundaries` | List of organizational levels where the assignable permission applies |
| `deprecated` | Optional. When set to `true`, hides the assignable permission from the UI so users can no longer select it when creating new tokens. Existing tokens that already have this permission continue to work. Use this during [rename migrations](#renaming-assignable-permissions) or when phasing out a permission. |

### Understanding the Directory Structure

The directory structure uses three levels: `<category>/<resource>/<action>.yml`

### When Do You Need Metadata Files?

| File | When Required | Purpose |
|------|---------------|---------|
| Category `.metadata.yml` | Optional | Override folder name display (e.g., `ci_cd` → "CI/CD" instead of "Ci Cd") |
| Resource `.metadata.yml` | Optional | Override the generated resource description or titleized resource name |

> [!note]
> The assignable permission YAML file (at `<category>/<resource>/<action>.yml`) is always required and is not a metadata file—it's the main configuration file that defines the permission bundle.

**Category Level:** The `<category>` subfolder represents the name of the category displayed in the UI where assignable permissions are grouped. The folder name is titleized when displayed (e.g., `project_management` becomes "Project Management"). This category name is displayed in permission selection UIs, helping users organize and find permissions by functional area.

Create a `.metadata.yml` file in the category folder **only if** titleization produces an incorrect display name. For example, acronyms or abbreviations that don't titleize well:

```yaml
---
name: "CI/CD"
```

**Examples of category-level metadata:**

- Folder: `project_management` → Without metadata: Displays as "Project Management"
- Folder: `ci_cd` → Without metadata: Displays as "Ci Cd" (incorrect)
- Folder: `ci_cd` → With `.metadata.yml` override: Displays as "CI/CD" (correct)

**Resource Level:** Optionally create a `.metadata.yml` file at `config/authz/permission_groups/assignable_permissions/<category>/<resource>/.metadata.yml` to override default values:

```yaml
---
description: "Grants the ability to <actions> SSH keys."
name: "SSH Key"
```

By default, the resource name is derived from the directory name (titleized), and the description is generated from the resource's actions (e.g., "Grants the ability to assign, create, and read runners.").

**Fields:**

- `description` (optional) - Overrides the generated resource description. Must include `<actions>` interpolation, which is replaced at runtime with the alphabetically sorted list of actions from the resource's YAML files. Use `<actions>` to keep the action list in sync automatically while customizing the noun (e.g., `"Grants the ability to <actions> CI variables."`).
- `name` (optional) - Overrides the titleized resource name for display. Use this for acronyms or special formatting where titleization won't work correctly (e.g., `name: "SSH Key"` instead of auto-titleized name)

**Example in the UI:**

The following screenshot shows how category and resource metadata are displayed in a permission selection UI:

![Permission selection UI showing resource metadata](../img/granular_pat_resource_metadata_ui_v18_10.png)

In this example:

- **CI/CD** - This is the category name, which comes from the folder name and can be overridden with category `.metadata.yml`
- **CI Config** - This is the resource name, which comes from the folder name and can be overridden with resource `.metadata.yml`
- The description below shows the resource description, which is either overridden in the resource `.metadata.yml` file or generated from the resource's actions

**When to create a resource `.metadata.yml`:**

- The resource name contains an acronym or brand name that doesn't titleize correctly (e.g., `ssh_key` → "`Ssh Key`" instead of "SSH Key")
- The generated description needs a custom noun (e.g., "CI variables" instead of "variables", or "code" instead of "codes")
- The resource has an unconventional action name that looks ugly in prose (e.g., `renew_secret`)
- The directory name is uncountable or pluralizes awkwardly (e.g., "code" → "codes", "metadata" → "metadatas")

You do **not** need a metadata file when the directory name titleizes and pluralizes correctly (the majority of resources).

### Determining Boundaries

The `boundaries` field specifies which organizational levels support this assignable permission. Choose based on where the bundled raw permissions can be applied. Use the principle of least privilege—only include boundaries where the permissions actually apply.

**Boundary Types:**

- `project` - Permissions applicable to projects and project-level resources (manage issues, create pipelines, update repository settings)
  - Include this if your raw permissions work on project endpoints like `/projects/:id/...`
- `group` - Permissions applicable to groups and group-level resources (manage group members, group settings, group-owned projects)
  - Include this if your raw permissions work on group endpoints like `/groups/:id/...`
- `user` - Permissions applicable to user-level resources (personal profile, personal settings, user-owned resources)
  - Include this if your raw permissions work on user endpoints like `/users/:id/...` or personal namespace operations
- `instance` - Permissions applicable at the GitLab instance level (operations like reading snippets, viewing audit logs, or managing system settings)
  - **Use sparingly** — typically only for admin-facing permissions

**Selecting Boundaries:**
Review the endpoint routes in your API file or the GraphQL types and mutations you are protecting. If endpoints follow patterns like `/projects/:id/...`, include `project`. If endpoints follow `/groups/:id/...`, include `group`. For GraphQL, check the `boundary_type` declared in your directives. Only include boundaries that your endpoints actually support.

### Important Constraints

- Each raw permission included in the assignable permission **must already exist** (created as a [raw permission definition file](permission_definitions.md#permission-definition-file))
- Only raw permissions assigned to assignable permissions can be used for token authorization
- Use consistent naming across related assignable permissions

### Validate Assignable Permissions

Assignable permission validation is run automatically by Lefthook's pre-push hook when running `git push`. You can also run it manually:

```shell
bundle exec rake gitlab:permissions:validate
```

The validation task enforces several constraints:

- Assignable permissions must be at exactly: `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`
- No extra directories allowed between the base path and the final filename
- Each REST API route's `boundary_type` and each GraphQL directive's `boundary_type` must match at least one boundary in the assignable permission's `boundaries` field (e.g., if a route or directive declares `boundary_type: :project`, the assignable permission must include `project` in its boundaries)

### Maintaining Assignable Permissions

Assignable permissions might need changes over time. This section covers common change scenarios and their impact.

#### How tokens resolve permissions

Understanding how tokens store and resolve permissions is essential before making changes.

Tokens store **assignable permission names** (not raw permissions) in the database. At request time, the system dynamically resolves these names to raw permissions using the current YAML definitions. This means changes to YAML files take effect immediately for all existing tokens without requiring a migration.

This is implemented in `app/models/authz/granular_scope.rb`:

```ruby
scope
  .pluck(Arel.sql('DISTINCT jsonb_array_elements_text(permissions)'))
  .flat_map { |p| ::Authz::PermissionGroups::Assignable.get(p)&.permissions }
  .compact.map(&:to_sym)
```

If `Assignable.get(p)` cannot find the stored name in the current YAML definitions, it returns `nil` and the permission is silently ignored. This is the root cause of breakage when assignable permissions are renamed or removed.

#### Adding assignable permissions

Adding a new assignable permission is safe. New YAML files are automatically discovered and made visible in the UI when creating granular scopes. Existing tokens are not affected.

> [!note]
> When none of the raw permissions included in an assignable permission are used for API authorization, users creating tokens see no effect from adding that permission. There is no static validation to protect against this, because assignable permissions may also be used outside of API authorization (for example, `Repository > Code > Download/Push` permissions are used for Git operations).

#### Removing assignable permissions

Removing an assignable permission is a **breaking change**. Tokens created with that assignable permission lose all API access the included raw permissions granted, because `Assignable.get(p)` returns `nil` for the removed name.

Only remove assignable permissions when the underlying API functionality is also being removed.

#### Renaming assignable permissions

Renaming an assignable permission is a **breaking change**. Tokens created with the old name lose access because the stored name no longer matches any YAML definition.

This requires a two-step process:

1. Create a merge request that:
   - Adds the new assignable permission YAML file
   - Adds a `rename_granular_scope_permission` post-deploy batched background migration to update stored names in the database, see below
   - Marks the old assignable permission as deprecated
1. After the migration has completed, create a follow-up merge request to remove the deprecated permission

<details><summary>Creating the rename migration</summary>

Generate the migration scaffold, replacing `old` and `new` with the actual assignable permission names:

```shell
bundle exec rails g batched_background_migration rename_granular_scope_permission_<old>_to_<new> --table-name=granular_scopes --feature-category=permissions
```

Replace the generated migration content with:

```ruby
# frozen_string_literal: true

class QueueRenameGranularScopePermissionOldToNew < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'RenameGranularScopePermissionOldToNew'
  OLD_PERMISSION = 'old'
  NEW_PERMISSION = 'new'

  def up
    queue_batched_background_migration(
      MIGRATION,
      :granular_scopes,
      :id,
      OLD_PERMISSION,
      NEW_PERMISSION
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :granular_scopes, :id,
      [OLD_PERMISSION, NEW_PERMISSION])
  end
end
```

Replace the generated background migration content with:

```ruby
# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RenameGranularScopePermissionOldToNew < BatchedMigrationJob
      include Gitlab::Database::MigrationHelpers::GranularScopePermissions

      feature_category :permissions
    end
  end
end
```

Update `OLD_PERMISSION` and `NEW_PERMISSION` constants, the class names, and the `milestone` to match your rename and target release.

</details>

#### Adding raw permissions to an assignable permission

Adding raw permissions to an existing assignable permission causes previously created tokens with that assignable permission to gain increased access.

Because resolution is dynamic, the new raw permissions take effect immediately. While this may seem to defeat the principle of least privilege, the validation that each raw permission can only belong to one assignable permission means the new functionality would not have been accessible through any other permission. The user likely expects the assignable permission to cover new functionality for the same resource.

Only add raw permissions when adding support for new API endpoints. Add the raw permission to the `permissions` array in the assignable permission's YAML file.

#### Removing raw permissions from an assignable permission

Removing raw permissions from an assignable permission is a **breaking change**. Tokens with that assignable permission immediately lose access that the removed raw permissions granted.

This can be mitigated by using the `rename_granular_scope_permission` migration to replace the old assignable permission with a combination of the old permission (minus the removed raw permissions) and a new assignable permission that includes the moved raw permissions.

> [!note]
> Be aware that this approach may lead to increased access if the new assignable permission contains additional raw permissions beyond the ones being moved.

#### Changing the boundary type of an endpoint or directive

Changing the `boundary_type` of a REST API `route_setting` or GraphQL `authorize_granular_token` directive can be a **breaking change** for existing tokens.

The `boundaries` field on an assignable permission must cover the union of all `boundary_type` values declared by its raw permissions' endpoints and directives. You don't change assignable permission boundaries directly — they change as a consequence of endpoints adding or changing their `boundary_type`, or raw permissions being added to or removed from the assignable permission. The Lefthook pre-push validation catches any mismatches.

Tokens store granular scopes as a combination of a boundary (namespace) and assignable permissions. When the `boundary_type` of an endpoint changes, the authorization check evaluates the token's scopes against the new boundary. If a token was created with a scope for the old boundary, it may no longer match.

**Changing between `project` and `group`** is safe. Because projects belong to groups, a token with a group-bound granular scope also covers projects within that group, and a project-bound scope is unaffected by group endpoints.

**Changing to or from `user` or `instance`** (e.g., from `project` to `instance`) is a **breaking change**. Tokens created with a project-bound granular scope for that permission no longer have access. The token holder would need to create a new scope at the new boundary.

#### Renaming raw permissions used in API authorization

Renaming a raw permission has no impact on the UI or existing tokens. Because tokens store assignable permission names (not raw permission names), a raw permission rename only requires updating the YAML files:

- The raw permission definition file (`config/authz/permissions/<resource>/<action>.yml`)
- Any assignable permission YAML files that reference it

No database migration is required.
