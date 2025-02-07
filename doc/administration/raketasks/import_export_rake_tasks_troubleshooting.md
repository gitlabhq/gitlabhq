---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting project import and export
---

If you are having trouble with import or export, use a Rake task to enable debug mode:

```shell
# Import
IMPORT_DEBUG=true gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file_to_import.tar.gz]"

# Export
EXPORT_DEBUG=true gitlab-rake "gitlab:import_export:export[root, group/subgroup, projectnametoexport, /tmp/export_file.tar.gz]"
```

Then, review the following details on specific error messages.

## `Exception: undefined method 'name' for nil:NilClass`

The `username` is not valid.

## `Exception: undefined method 'full_path' for nil:NilClass`

The `namespace_path` does not exist.
For example, one of the groups or subgroups is mistyped or missing,
or you've specified the project name in the path.

The task only creates the project.
If you want to import it to a new group or subgroup, create it first.

## `Exception: No such file or directory @ rb_sysopen - (filename)`

The specified project export file in `archive_path` is missing.

## `Exception: Permission denied @ rb_sysopen - (filename)`

The specified project export file cannot be accessed by the `git` user.

To fix the issue:

1. Set the file owner to `git:git`.
1. Change the file permissions to `0400`.
1. Move the file to a public folder (for example `/tmp/`).

## `Name can contain only letters, digits, emoji ...`

```plaintext
Name can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. It must start with a letter,
digit, emoji, or '_', and Path can contain only letters, digits, '_', '-', or '.'. It cannot start
with '-', end in '.git', or end in '.atom'.
```

The project name specified in `project_path` is not valid for one of the specified reasons.

Only put the project name in `project_path`. For example, if you provide a path of subgroups
it fails with this error as `/` is not a valid character in a project name.

## `Name has already been taken and Path has already been taken`

A project with that name already exists.

## `Exception: Error importing repository into (namespace) - No space left on device`

The disk has insufficient space to complete the import.

During import, the tarball is cached in your configured `shared_path` directory. Verify the
disk has enough free space to accommodate both the cached tarball and the unpacked
project files on disk.

## Import succeeds with `Total number of not imported relations: XX` message

If you receive a `Total number of not imported relations: XX` message, and issues
aren't created during the import, check [exceptions_json.log](../logs/_index.md#exceptions_jsonlog).
You might see an error like `N is out of range for ActiveModel::Type::Integer with limit 4 bytes`,
where `N` is the integer exceeding the 4-byte integer limit. If that's the case, you
are likely hitting the issue with rebalancing of `relative_position` field of the issues.

```ruby
# Check the current maximum value of relative_position
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)

# Run the rebalancing process and check if the maximum value of relative_position has changed
Issues::RelativePositionRebalancingService.new(Project.find(ID).root_namespace.all_projects).execute
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)
```

Repeat the import attempt and check if the issues are imported successfully.

## Gitaly calls error when importing

If you're attempting to import a large project into a development environment, Gitaly might throw an error about too many calls or invocations. For example:

```plaintext
Error importing repository into qa-perf-testing/gitlabhq - GitalyClient#call called 31 times from single request. Potential n+1?
```

This error is due to a [n+1 calls limit for development setups](../../development/gitaly.md#toomanyinvocationserror-errors). To resolve this error, set `GITALY_DISABLE_REQUEST_LIMITS=1` as an environment variable. Then restart your development environment and import again.
