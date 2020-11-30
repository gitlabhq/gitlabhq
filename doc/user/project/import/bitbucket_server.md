---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import your project from Bitbucket Server to GitLab

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20164) in GitLab 11.2.

NOTE: **Note:**
The Bitbucket Server importer does not work with [Bitbucket Cloud](https://bitbucket.org).
Use the [Bitbucket Cloud importer](bitbucket.md) for that.

Import your projects from Bitbucket Server to GitLab with minimal effort.

## Overview

- In its current state, the Bitbucket importer can import:
  - the repository description (GitLab 11.2+)
  - the Git repository data (GitLab 11.2+)
  - the pull requests (GitLab 11.2+)
  - the pull request comments (GitLab 11.2+)
- Repository public access is retained. If a repository is private in Bitbucket
  it will be created as private in GitLab as well.

## Limitations

1. Currently GitLab doesn't allow comments on arbitrary lines of code, so any
   Bitbucket comments out of bounds will be inserted as comments in the merge
   request.
1. Bitbucket Server allows multiple levels of threading. GitLab import
   will collapse this into one thread and quote part of the original comment.
1. Declined pull requests have unreachable commits, which prevents the GitLab
   importer from generating a proper diff. These pull requests will show up as
   empty changes.
1. Attachments in Markdown are currently not imported.
1. Task lists are not imported.
1. Emoji reactions are not imported
1. Project filtering does not support fuzzy search (only `starts with` or `full
   match strings` are currently supported)

## How it works

The Bitbucket Server importer works as follows:

1. The user will be prompted to enter the URL, username, and password (or personal access token) to log in to Bitbucket.
   These credentials are preserved only as long as the importer is running.
1. The importer will attempt to list all the current repositories on the Bitbucket Server.
1. Upon selection, the importer will clone the repository and import pull requests and comments.

### User assignment

When issues/pull requests are being imported, the Bitbucket importer tries to
find the author's e-mail address with a confirmed e-mail address in the GitLab
user database. If no such user is available, the project creator is set as
the author. The importer will append a note in the comment to mark the original
creator.

The importer will create any new namespaces (groups) if they don't exist or in
the case the namespace is taken, the repository will be imported under the user's
namespace that started the import process.

#### User assignment by username

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218609) in GitLab 13.4.
> - It's [deployed behind a feature flag](../../feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to enable it.

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

If you've enabled this feature, the importer tries to find a user in the GitLab user database with
the author's:

- `username`
- `slug`
- `displayName`

If the user is not found by any of these properties, the search falls back to the author's
`email` address.

Alternatively, if there is also no email address, the project creator is set as the author.

##### Enable or disable User assignment by username

User assignment by username is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:bitbucket_server_user_mapping_by_username)
```

To disable it:

```ruby
Feature.disable(:bitbucket_server_user_mapping_by_username)
```

## Importing your Bitbucket repositories

1. Sign in to GitLab and go to your dashboard.
1. Click on **New project**.
1. Click on the "Bitbucket Server" button. If the button is not present, enable the importer in
   **Admin > Application Settings > Visibility and access controls > Import sources**.

   ![Bitbucket](img/import_projects_from_new_project_page.png)

1. Enter your Bitbucket Server credentials.

   ![Grant access](img/bitbucket_server_import_credentials.png)

1. Click on the projects that you'd like to import or **Import all projects**.
   You can also filter projects by name and select the namespace under which each project will be
   imported.

   ![Import projects](img/bitbucket_server_import_select_project_v12_3.png)

## Troubleshooting

If the GUI-based import tool does not work, you can try to:

- Use the [GitLab Import API](../../../api/import.md#import-repository-from-bitbucket-server) Bitbucket server endpoint.
- Set up [Repository Mirroring](../repository/repository_mirroring.md), which provides verbose error output.

See the [troubleshooting](bitbucket.md#troubleshooting) section for [Bitbucket](bitbucket.md).
