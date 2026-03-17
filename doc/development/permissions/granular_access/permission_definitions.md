---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Permission Definitions
---

## Permission Definition File

Each permission should have a corresponding definition file (also called a "raw permission"). These files are used to build documentation and enable a permissions-first architecture around authorization logic.

Generate the permission definition and resource metadata files using the `bin/permission` command.

**Interactive mode** — pass just the permission name and the command walks you through each field, using the name to suggest defaults:

```shell
bin/permission <permission_name>
```

**Non-interactive mode** — pass `-a` (action) and `-r` (resource) as flags to skip prompts. The description auto-defaults to `"Grants the ability to <action> <resource>"`. Add `-c` to also skip the feature category prompt:

```shell
bin/permission <permission_name> -a <action> -r <resource> -c <feature_category>
```

Overriding the action or resource is helpful when the action is more than one word. For example, consider the permission `force_delete_ai_catalog_item`. By default the command splits the name at the first underscore, suggesting `force` as the action and `delete_ai_catalog_item` as the resource. This would result in the definition file being written to `config/authz/permissions/delete_ai_catalog_item/force.yml`, which is incorrect.

The following command generates a definition file with the correct action and resource, writing it to `config/authz/permissions/ai_catalog_item/force_delete.yml`:

```shell
bin/permission force_delete_ai_catalog_item -a force_delete -r ai_catalog_item -c ai_catalog
```

Any field can be overridden with a flag (for example `-d` for a custom description). Run `bin/permission --help` for all available options.

This creates two files:

1. A permission definition at `config/authz/permissions/<resource>/<action>.yml`:

   ```yaml
   ---
   name: read_job
   description: Grants the ability to read CI/CD jobs
   ```

1. A resource metadata file at `config/authz/permissions/<resource>/_metadata.yml` (if one does not already exist):

   ```yaml
   ---
   feature_category: continuous_integration
   ```

### Permission Definition Fields

| Field | Description |
|-------|-------------|
| `name` | Permission name (auto-populated from the action and resource) |
| `description` | Human-readable description of what the permission allows |

### Resource Metadata Fields

The resource metadata file is created once per resource directory. When you add a second permission for the same resource, the command detects the existing metadata and skips all metadata prompts (feature category, display name, and description).

**Required Fields:**

- `feature_category` (required) - Must be a valid entry from `config/feature_categories.yml`. Look at existing endpoints in the API file for that resource to find the correct feature category. For example, CI/CD endpoints typically use `continuous_integration`, while package-related endpoints use `package_registry`.

**Optional Fields:**

- `name` - Overrides the titleized resource name for display
- `description` - Provides context about what permissions in this resource group grant

### Permission Naming and Validation

The validation task (`bundle exec rake gitlab:permissions:validate`) enforces several constraints:

**Permission Name Format:**

For guidance on how to name permissions, see [Naming Permissions](../conventions.md#naming-permissions).

**Action Words:**

For a list of disallowed actions, see [Disallowed Actions](../conventions.md#disallowed-actions).

**File Structure:**

- Raw permissions must be at exactly: `config/authz/permissions/<resource>/<action>.yml`
- No extra directories allowed between the base path and the final filename

All violations are caught automatically by Lefthook's pre-push hook when running `git push`. You can also run the validation manually with `bundle exec rake gitlab:permissions:validate`.
