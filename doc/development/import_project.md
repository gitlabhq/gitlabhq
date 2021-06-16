---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Test Import Project

For testing, we can import our own [GitLab CE](https://gitlab.com/gitlab-org/gitlab-foss/) project (named `gitlabhq` in this case) under a group named `qa-perf-testing`. Project tarballs that can be used for testing can be found over on the [performance-data](https://gitlab.com/gitlab-org/quality/performance-data) project. A different project could be used if required.

There are several options for importing the project into your GitLab environment. They are detailed as follows with the assumption that the recommended group `qa-perf-testing` and project `gitlabhq` are being set up.

## Importing the project

There are several ways to import a project.

### Importing via UI

The first option is to simply [import the Project tarball file via the GitLab UI](../user/project/settings/import_export.md#importing-the-project):

1. Create the group `qa-perf-testing`
1. Import the [GitLab FOSS project tarball](https://gitlab.com/gitlab-org/quality/performance-data/-/blob/master/projects_export/gitlabhq_export.tar.gz) into the Group.

It should take up to 15 minutes for the project to fully import. You can head to the project's main page for the current status.

This method ignores all the errors silently (including the ones related to `GITALY_DISABLE_REQUEST_LIMITS`) and is used by GitLab users. For development and testing, check the other methods below.

### Importing via the `import-project` script

A convenient script, [`bin/import-project`](https://gitlab.com/gitlab-org/quality/performance/blob/master/bin/import-project), is provided with [performance](https://gitlab.com/gitlab-org/quality/performance) project to import the Project tarball into a GitLab environment via API from the terminal.

Note that to use the script, it requires some preparation if you haven't done so already:

1. First, set up [`Ruby`](https://www.ruby-lang.org/en/documentation/installation/) and [`Ruby Bundler`](https://bundler.io) if they aren't already available on the machine.
1. Next, install the required Ruby Gems via Bundler with `bundle install`.

For details how to use `bin/import-project`, run:

```shell
bin/import-project --help
```

The process should take up to 15 minutes for the project to import fully. The script checks the status periodically and exits after the import has completed.

### Importing via GitHub

There is also an option to [import the project via GitHub](../user/project/import/github.md):

1. Create the group `qa-perf-testing`
1. Import the GitLab FOSS repository that's [mirrored on GitHub](https://github.com/gitlabhq/gitlabhq) into the group via the UI.

This method takes longer to import than the other methods and depends on several factors. It's recommended to use the other methods.

### Importing via a Rake task

> The [Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/import_export/import.rake) was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20724) in GitLab 12.6, replacing a GitLab.com Ruby script.

This script was introduced in GitLab 12.6 for importing large GitLab project exports.

As part of this script we also disable direct and background upload to avoid situations where a huge archive is being uploaded to GCS (while being inside a transaction, which can cause idle transaction timeouts).

We can simply run this script from the terminal:

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `username`      | string | yes | User name |
| `namespace_path` | string | yes | Namespace path |
| `project_path` | string | yes | Project name |
| `archive_path` | string | yes | Path to the exported project tarball you want to import |

```shell
bundle exec rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]"
```

If you're running Omnibus, run the following Rake task:

```shell
gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]"
```

#### Troubleshooting

Check the common errors listed below, what they mean, and how to fix them.

##### `Exception: undefined method 'name' for nil:NilClass`

The `username` is not valid.

##### `Exception: undefined method 'full_path' for nil:NilClass`

The `namespace_path` does not exist.
For example, one of the groups or subgroups is mistyped or missing
or you've specified the project name in the path.

The task only creates the project.
If you want to import it to a new group or subgroup then create it first.

##### `Exception: No such file or directory @ rb_sysopen - (filename)`

The specified project export file in `archive_path` is missing.

##### `Exception: Permission denied @ rb_sysopen - (filename)`

The specified project export file can not be accessed by the `git` user.

Setting the file owner to `git:git`, changing the file permissions to `0400`, and moving it to a
public folder (for example `/tmp/`) fixes the issue.

##### `Name can contain only letters, digits, emojis ...`

```plaintext
Name can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter,
digit, emoji or '_'. and Path can contain only letters, digits, '_', '-' and '.'. Cannot start
with '-', end in '.git' or end in '.atom'
```

The project name specified in `project_path` is not valid for one of the specified reasons.

Only put the project name in `project_path`. For example, if you provide a path of subgroups
it fails with this error as `/` is not a valid character in a project name.

##### `Name has already been taken and Path has already been taken`

A project with that name already exists.

### Importing via the Rails console

The last option is to import a project using a Rails console:

1. Start a Ruby on Rails console:

   ```shell
   # Omnibus GitLab
   gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Create a project and run `Project::TreeRestorer`:

   ```ruby
   shared_class = Struct.new(:export_path) do
     def error(message)
       raise message
     end
   end

   user = User.first

   shared = shared_class.new(path)

   project = Projects::CreateService.new(user, { name: name, namespace: user.namespace }).execute
   begin
     #Enable Request store
     RequestStore.begin!
     Gitlab::ImportExport::Project::TreeRestorer.new(user: user, shared: shared, project: project).restore
   ensure
     RequestStore.end!
     RequestStore.clear!
   end
   ```

1. In case you need the repository as well, you can restore it using:

   ```ruby
   repo_path = File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename)

   Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: repo_path,
                                          shared: shared,
                                          importable: project).restore
   ```

   We are storing all import failures in the `import_failures` data table.

   To make sure that the project import finished without any issues, check:

   ```ruby
   project.import_failures.all
   ```

## Performance testing

For Performance testing, we should:

- Import a quite large project, [`gitlabhq`](https://gitlab.com/gitlab-org/quality/performance-data#gitlab-performance-test-framework-data) should be a good example.
- Measure the execution time of `Project::TreeRestorer`.
- Count the number of executed SQL queries during the restore.
- Observe the number of GC cycles happening.

You can use this snippet: `https://gitlab.com/gitlab-org/gitlab/snippets/1924954` (must be logged in), which restores the project, and measures the execution time of `Project::TreeRestorer`, number of SQL queries and number of GC cycles happening.

You can execute the script from the `gdk/gitlab` directory like this:

```shell
bundle exec rails r  /path_to_sript/script.rb project_name /path_to_extracted_project request_store_enabled
```

## Troubleshooting

This section details known issues we've seen when trying to import a project and how to manage them.

### Gitaly calls error when importing

If you're attempting to import a large project into a development environment, you may see Gitaly throw an error about too many calls or invocations, for example:

```plaintext
Error importing repository into qa-perf-testing/gitlabhq - GitalyClient#call called 31 times from single request. Potential n+1?
```

This is due to a [n+1 calls limit being set for development setups](gitaly.md#toomanyinvocationserror-errors). You can work around this by setting `GITALY_DISABLE_REQUEST_LIMITS=1` as an environment variable, restarting your development environment and importing again.

## Access token setup

Many of the tests also require a GitLab Personal Access Token. This is due to numerous endpoints themselves requiring authentication.

[The official GitLab docs detail how to create this token](../user/profile/personal_access_tokens.md#create-a-personal-access-token). The tests require that the token is generated by an admin user and that it has the `API` and `read_repository` permissions.

Details on how to use the Access Token with each type of test are found in their respective documentation.
