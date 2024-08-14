---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting direct transfer migrations

In a [rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session),
you can find the failure or error messages for the group import attempt using:

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import).last

# Alternative lookup by user
import = BulkImport.where(user_id: User.find(...)).last

# Get list of import entities. Each entity represents either a group or a project
entities = import.entities

# Get a list of entity failures
entities.map(&:failures).flatten

# Alternative failure lookup by status
entities.where(status: [-1]).pluck(:destination_name, :destination_namespace, :status)
```

You can also see all migrated entities with any failures related to them using an
[API endpoint](../../../api/bulk_imports.md#list-all-group-or-project-migrations-entities).

## Stale imports

When troubleshooting group migration, an import may not complete because the import workers took
longer than 8 hours to execute. In this case, the `status` of either a `BulkImport` or
`BulkImport::Entity` is `3` (`timeout`):

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import)

import.status #=> 3 means that the import timed out.
```

## Error: `404 Group Not Found`

If you attempt to import a group that has a path comprised of only numbers (for example, `5000`), GitLab attempts to
find the group by ID instead of the path. This causes a `404 Group Not Found` error in GitLab 15.4 and earlier.

To solve this, you must change the source group path to include a non-numerical character using either:

- The GitLab UI:

  1. On the left sidebar, select **Search or go to** and find your group.
  1. Select **Settings > General**.
  1. Expand **Advanced**.
  1. Under **Change group URL**, change the group URL to include non-numeric characters.

- The [Groups API](../../../api/groups.md#update-group).

## Other `404` errors

You can receive other `404` errors when importing a group, for example:

```json
"exception_message": "Unsuccessful response 404 from [FILTERED] Bo...",
"exception_class": "BulkImports::NetworkError",
```

This error indicates a problem transferring from the _source_ instance. To solve this, check that you have met the
[prerequisites](direct_transfer_migrations.md#prerequisites) on the source instance.

## Mismatched group or project path names

If a source group or project path doesn't conform to naming [limitations](../../reserved_names.md#limitations-on-usernames-project-and-group-names-and-slugs), the path is normalized to
ensure it is valid. For example, `Destination-Project-Path` is normalized to `destination-project-path`.
