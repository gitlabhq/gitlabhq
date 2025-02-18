---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Test import project
---

For testing, we can import our own [GitLab CE](https://gitlab.com/gitlab-org/gitlab-foss/) project (named `gitlabhq` in this case) under a group named `qa-perf-testing`. Project tarballs that can be used for testing can be found over on the [performance-data](https://gitlab.com/gitlab-org/quality/performance-data) project. A different project could be used if required.

You can import the project into your GitLab environment in a number of ways. They are detailed as follows with the
assumption that the recommended group `qa-perf-testing` and project `gitlabhq` are being set up.

## Importing the project

Use one of these methods to import the test project.

### Import by using the UI

The first option is to [import the project tarball file by using the GitLab UI](../user/project/settings/import_export.md#import-a-project-and-its-data):

1. Create the group `qa-perf-testing`.
1. Import the [GitLab FOSS project tarball](https://gitlab.com/gitlab-org/quality/performance-data/-/blob/master/projects_export/gitlabhq_export.tar.gz) into the group.

It should take up to 15 minutes for the project to fully import. You can head to the project's main page for the current status.

This method ignores all the errors silently (including the ones related to `GITALY_DISABLE_REQUEST_LIMITS`) and is used by GitLab users. For development and testing, check the other methods below.

### Import by using the `import-project` script

A convenient script, [`bin/import-project`](https://gitlab.com/gitlab-org/quality/performance/-/blob/main/bin/import-project), is provided with [performance](https://gitlab.com/gitlab-org/quality/performance) project to import the Project tarball into a GitLab environment via API from the terminal.

It requires some preparation to use the script if you haven't done so already:

1. First, set up [`Ruby`](https://www.ruby-lang.org/en/documentation/installation/) and [`Ruby Bundler`](https://bundler.io) if they aren't already available on the machine.
1. Next, install the required Ruby Gems via Bundler with `bundle install`.

For details how to use `bin/import-project`, run:

```shell
bin/import-project --help
```

The process should take up to 15 minutes for the project to import fully. The script checks the status periodically and exits after the import has completed.

### Import by using GitHub

There is also an option to [import the project via GitHub](../user/project/import/github.md):

1. Create the group `qa-perf-testing`
1. Import the GitLab FOSS repository that's [mirrored on GitHub](https://github.com/gitlabhq/gitlabhq) into the group via the UI.

This method takes longer to import than the other methods and depends on several factors. It's recommended to use the other methods.

To test importing from GitHub Enterprise (GHE) to GitLab, you need a GHE instance. You can request a
[GitHub Enterprise Server trial](https://docs.github.com/en/enterprise-cloud@latest/admin/overview/setting-up-a-trial-of-github-enterprise-server) and install it on Google Cloud Platform.

- GitLab team members can use [Sandbox Cloud Realm](https://handbook.gitlab.com/handbook/company/infrastructure-standards/realms/sandbox/) for this purpose.
- Others can request a [Google Cloud Platforms free trial](https://cloud.google.com/free).

### Import by using a Rake task

To import the test project by using a Rake task, see
[Import large projects](../administration/raketasks/project_import_export.md#import-large-projects).

### Import by using the Rails console

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
bundle exec rails r  /path_to_script/script.rb project_name /path_to_extracted_project request_store_enabled
```

## Access token setup

Many of the tests also require a GitLab personal access token because numerous endpoints require authentication themselves.

[The GitLab documentation details how to create this token](../user/profile/personal_access_tokens.md#create-a-personal-access-token).
The tests require that the token is generated by an administrator and that it has the `API` and `read_repository` permissions.

Details on how to use the Access Token with each type of test are found in their respective documentation.
