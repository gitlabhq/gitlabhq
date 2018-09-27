# Create

Consolidate source code into a single [DVCS](https://en.wikipedia.org/wiki/Distributed_version_control)
that’s easily managed and controlled without disrupting your workflow.
GitLab’s git repositories come complete with branching tools and access
controls, providing a scalable, single source of truth for collaborating
on projects and code.

## Projects and groups

- [Projects](user/project/index.md):
  - [Project settings](user/project/settings/index.md)
  - [Create a project](gitlab-basics/create-project.md)
  - [Fork a project](gitlab-basics/fork-project.md)
  - [Importing and exporting projects between instances](user/project/settings/import_export.md).
  - [Project access](public_access/public_access.md): Setting up your project's visibility to public, internal, or private.
  - [GitLab Pages](user/project/pages/index.md): Build, test, and deploy your static website with GitLab Pages.
- [Groups](user/group/index.md): Organize your projects in groups.
  - [Subgroups](user/group/subgroups/index.md)
- [Search through GitLab](user/search/index.md): Search for issues, merge requests, projects, groups, todos, and issues in Issue Boards.
- [Snippets](user/snippets.md): Snippets allow you to create little bits of code.
- [Wikis](user/project/wiki/index.md): Enhance your repository documentation with built-in wikis.
- [Web IDE](user/project/web_ide/index.md)

## Repositories

Manage your [repositories](user/project/repository/index.md) from the UI (user interface):

- [Files](user/project/repository/index.md#files)
  - [Create a file](user/project/repository/web_editor.md#create-a-file)
  - [Upload a file](user/project/repository/web_editor.md#upload-a-file)
  - [File templates](user/project/repository/web_editor.md#template-dropdowns)
  - [Jupyter Notebook files](user/project/repository/index.md#jupyter-notebook-files)
  - [Create a directory](user/project/repository/web_editor.md#create-a-directory)
  - [Start a merge request](user/project/repository/web_editor.md#tips) (when committing via UI)
- [Branches](user/project/repository/branches/index.md)
  - [Default branch](user/project/repository/branches/index.md#default-branch)
  - [Create a branch](user/project/repository/web_editor.md#create-a-new-branch)
  - [Protected branches](user/project/protected_branches.md#protected-branches)
  - [Delete merged branches](user/project/repository/branches/index.md#delete-merged-branches)
- [Commits](user/project/repository/index.md#commits)
  - [Signing commits](user/project/repository/gpg_signed_commits/index.md): use GPG to sign your commits.

## Merge Requests

- [Merge Requests](user/project/merge_requests/index.md)
  - [Work In Progress "WIP" Merge Requests](user/project/merge_requests/work_in_progress_merge_requests.md)
  - [Merge Request discussion resolution](user/discussions/index.md#moving-a-single-discussion-to-a-new-issue): Resolve discussions, move discussions in a merge request to an issue, only allow merge requests to be merged if all discussions are resolved.
  - [Checkout merge requests locally](user/project/merge_requests/index.md#checkout-merge-requests-locally)
  - [Cherry-pick](user/project/merge_requests/cherry_pick_changes.md)

## Integrations

- [Project Services](user/project/integrations/project_services.md): Integrate a project with external services, such as CI and chat.
- [GitLab Integration](integration/README.md): Integrate with multiple third-party services with GitLab to allow external issue trackers and external authentication.
- [Trello Power-Up](integration/trello_power_up.md): Integrate with GitLab's Trello Power-Up

## Automation

- [API](api/README.md): Automate GitLab via a simple and powerful API.
- [GitLab Webhooks](user/project/integrations/webhooks.md): Let GitLab notify you when new code has been pushed to your project.
