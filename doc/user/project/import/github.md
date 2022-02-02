---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import your project from GitHub to GitLab **(FREE)**

Using the importer, you can import your GitHub repositories to GitLab.com or to
your self-managed GitLab instance.

The following aspects of a project are imported:

- Repository description (GitLab.com & 7.7+)
- Git repository data (GitLab.com & 7.7+)
- Issues (GitLab.com & 7.7+)
- Pull requests (GitLab.com & 8.4+)
- Wiki pages (GitLab.com & 8.4+)
- Milestones (GitLab.com & 8.7+)
- Labels (GitLab.com & 8.7+)
- Release note descriptions (GitLab.com & 8.12+)
- Pull request review comments (GitLab.com & 10.2+)
- Pull request reviews (GitLab.com & 13.7+)
- Pull request "merged by" information (GitLab.com & 13.7+)
- Regular issue and pull request comments
- [Git Large File Storage (LFS) Objects](../../../topics/git/lfs/index.md)
- Pull request comments replies in discussions ([GitLab.com & 14.5+](https://gitlab.com/gitlab-org/gitlab/-/issues/336596))
- Diff Notes suggestions ([GitLab.com & 14.7+](https://gitlab.com/gitlab-org/gitlab/-/issues/340624)) [with a flag](../../../administration/feature_flags.md) named `github_importer_use_diff_note_with_suggestions`. Enabled by default.

References to pull requests and issues are preserved (GitLab.com & 8.7+), and
each imported repository maintains visibility level unless that [visibility
level is restricted](../../../public_access/public_access.md#restrict-use-of-public-or-internal-projects),
in which case it defaults to the default project visibility.

The namespace is a user or group in GitLab, such as `gitlab.com/janedoe` or
`gitlab.com/customer-success`. You can do some bulk actions to move projects to
different namespaces in the rails console.

This process does not migrate or import any types of groups or organizations
from GitHub to GitLab.

## Use cases

The steps you take depend on whether you are importing from GitHub.com or
GitHub Enterprise. The steps also depend on whether you are importing to GitLab.com or
self-managed GitLab instance.

- If you're importing to GitLab.com, you can alternatively import GitHub repositories
  using a [personal access token](#use-a-github-token). We do not recommend
  this method, as it does not associate all user activity (such as issues and
  pull requests) with matching GitLab users.
- If you're importing to a self-managed GitLab instance, you can alternatively use the
  [GitHub Rake task](../../../administration/raketasks/github_import.md) to import
  projects without the constraints of a [Sidekiq](../../../development/sidekiq_style_guide.md) worker.
- If you're importing from GitHub Enterprise to your self-managed GitLab instance:
  - You must first enable [GitHub integration](../../../integration/github.md).
  - To import projects from GitHub Enterprise to GitLab.com, use the [Import API](../../../api/import.md).
  - If GitLab is behind a HTTP/HTTPS proxy you must populate the [allowlist for local requests](../../../security/webhooks.md#allowlist-for-local-requests)
    with `github.com` and `api.github.com` to solve the hostname. For more information, read the issue
    [Importing a GitHub project requires DNS resolution even when behind a proxy](https://gitlab.com/gitlab-org/gitlab/-/issues/37941)
- If you're importing from GitHub.com to your self-managed GitLab instance,
  setting up GitHub integration is not required. You can use the [Import API](../../../api/import.md).

## How it works

When issues and pull requests are being imported, the importer attempts to find
their GitHub authors and assignees in the database of the GitLab instance (note
that pull requests are called "merge requests" in GitLab).

For this association to succeed, each GitHub author and assignee in the repository
must meet one of the following conditions prior to the import:

- Have previously logged in to a GitLab account using the GitHub icon.
- Have a GitHub account with a [public-facing email address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-user-account/managing-email-preferences/setting-your-commit-email-address)
  that matches their GitLab account's email address.

  NOTE:
  GitLab content imports that use GitHub accounts require that the GitHub
  public-facing email address is populated so that all comments and
  contributions are properly mapped to the same user in GitLab. GitHub
  Enterprise (on premise) does not require this field to be populated to use the
  product, so you may have to add it on existing accounts for the imported
  content to be properly mapped to the user in the new system. Refer to GitHub
  documentation for instructions on how to add this email address.

If a user referenced in the project is not found in the GitLab database, the project creator (typically the user
that initiated the import process) is set as the author/assignee, but a note on the issue mentioning the original
GitHub author is added.

The importer creates any new namespaces (groups) if they do not exist, or, if the namespace is taken, the
repository is imported under the namespace of the user who initiated the import process. The namespace/repository
name can also be edited, with the proper permissions.

The importer will also import branches on forks of projects related to open pull requests. These branches will be
imported with a naming scheme similar to `GH-SHA-username/pull-request-number/fork-name/branch`. This may lead to
a discrepancy in branches compared to those of the GitHub repository.

For additional technical details, you can refer to the
[GitHub Importer](../../../development/github_importer.md "Working with the GitHub importer")
developer documentation.

For an overview of the import process, see the video [Migrating from GitHub to GitLab](https://youtu.be/VYOXuOg9tQI).

## Import your GitHub repository into GitLab

### Use the GitHub integration

Before you begin, ensure that any GitHub users who you want to map to GitLab users have either:

- A GitLab account that has logged in using the GitHub icon
  \- or -
- A GitLab account with an email address that matches the [publicly visible email address](https://docs.github.com/en/rest/reference/users#get-a-user) in the profile of the GitHub user

User-matching attempts occur in that order, and if a user is not identified either way, the activity is associated with
the user account that is performing the import.

NOTE:
If you are using a self-managed GitLab instance or if you are importing from GitHub Enterprise, this process requires that you have configured
[GitHub integration](../../../integration/github.md).

1. From the top navigation bar, click **+** and select **New project**.
1. Select the **Import project** tab and then select **GitHub**.
1. Select the first button to **List your GitHub repositories**. You are redirected to a page on [GitHub](https://github.com) to authorize the GitLab application.
1. Click **Authorize GitlabHQ**. You are redirected back to the GitLab Import page and all of your GitHub repositories are listed.
1. Continue on to [selecting which repositories to import](#select-which-repositories-to-import).

### Use a GitHub token

NOTE:
Using a personal access token to import projects is not recommended. If you are a GitLab.com user,
you can use a personal access token to import your project from GitHub, but this method cannot
associate all user activity (such as issues and pull requests) with matching GitLab users.
If you are an administrator of a self-managed GitLab instance or if you are importing from
GitHub Enterprise, you cannot use a personal access token.
The [GitHub integration method (above)](#use-the-github-integration) is recommended for all users.
Read more in the [How it works](#how-it-works) section.

If you are not using the GitHub integration, you can still perform an authorization with GitHub to grant GitLab access your repositories:

1. Go to <https://github.com/settings/tokens/new>
1. Enter a token description.
1. Select the repository scope.
1. Click **Generate token**.
1. Copy the token hash.
1. Go back to GitLab and provide the token to the GitHub importer.
1. Hit the **List Your GitHub Repositories** button and wait while GitLab reads your repositories' information.
   Once done, you are taken to the importer page to select the repositories to import.

To use a newer personal access token in imports after previously performing these steps, sign out of
your GitLab account and sign in again, or revoke the older personal access token in GitHub.

### Select which repositories to import

After you have authorized access to your GitHub repositories, you are redirected to the GitHub importer page and
your GitHub repositories are listed.

1. By default, the proposed repository namespaces match the names as they exist in GitHub, but based on your permissions,
   you can choose to edit these names before you proceed to import any of them.
1. Select the **Import** button next to any number of repositories, or select **Import all repositories**. Additionally,
   you can filter projects by name. If filter is applied, **Import all repositories** only imports matched repositories.
1. The **Status** column shows the import status of each repository. You can choose to leave the page open and it will
   update in real-time or you can return to it later.
1. Once a repository has been imported, click its GitLab path to open its GitLab URL.

![GitHub importer page](img/import_projects_from_github_importer_v12_3.png)

## Mirror a repository and share pipeline status **(PREMIUM)**

Depending on your GitLab tier, [repository mirroring](../repository/mirror/index.md) can be set up to keep
your imported repository in sync with its GitHub copy.

Additionally, you can configure GitLab to send pipeline status updates back to GitHub with the
[GitHub Project Integration](../integrations/github.md).

If you import your project using [CI/CD for external repository](../../../ci/ci_cd_for_external_repos/index.md), then both
of the above are automatically configured.

NOTE:
Mirroring does not sync any new or updated pull requests from your GitHub project.

## Improve the speed of imports on self-managed instances

Administrator access on the GitLab server is required for this process.

For large projects it may take a while to import all data. To reduce the time necessary, you can increase the number of
Sidekiq workers that process the following queues:

- `github_importer`
- `github_importer_advance_stage`

For an optimal experience, it's recommended having at least 4 Sidekiq processes (each running a number of threads equal
to the number of CPU cores) that *only* process these queues. It's also recommended that these processes run on separate
servers. For 4 servers with 8 cores this means you can import up to 32 objects (for example, issues) in parallel.

Reducing the time spent in cloning a repository can be done by increasing network throughput, CPU capacity, and disk
performance (by using high performance SSDs, for example) of the disks that store the Git repositories (for your GitLab instance).
Increasing the number of Sidekiq workers does *not* reduce the time spent cloning repositories.

## Alternative way to import notes and diff notes

When GitHub Importer runs on extremely large projects not all notes & diff notes can be imported due to GitHub API `issues_comments` & `pull_requests_comments` endpoints limitation.
Not all pages can be fetched due to the following error coming from GitHub API: `In order to keep the API fast for everyone, pagination is limited for this resource. Check the rel=last link relation in the Link response header to see how far back you can traverse.`.

An alternative approach for importing notes and diff notes is available behind a feature flag.

Instead of using `issues_comments` and `pull_requests_comments`, use individual resources `issue_comments` and `pull_request_comments` instead to pull notes from one object at a time.
This allows us to carry over any missing comments, however it increases the number of network requests required to perform the import, which means its execution takes a longer time.

To use the alternative way of importing notes, the `github_importer_single_endpoint_notes_import` feature flag must be enabled on the group project is being imported into.

Start a [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

```ruby
group = Group.find_by_full_path('my/group/fullpath')

# Enable
Feature.enable(:github_importer_single_endpoint_notes_import, group)

# Disable
Feature.disable(:github_importer_single_endpoint_notes_import, group)
```

## Reduce GitHub API request objects per page

Some GitHub API endpoints may return a 500 or 502 error for project imports from large repositories.
To reduce the chance of such errors, you can enable the feature flag
`github_importer_lower_per_page_limit` in the group project importing the data. This reduces the
page size from 100 to 50.

To enable this feature flag, start a [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session)
and run the following `enable` command:

```ruby
group = Group.find_by_full_path('my/group/fullpath')

# Enable
Feature.enable(:github_importer_lower_per_page_limit, group)
```

To disable the feature, run this command:

```ruby
# Disable
Feature.disable(:github_importer_lower_per_page_limit, group)
```

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](index.md#automate-group-and-project-import).
