# Projects

In GitLab, you can create projects for hosting
your codebase, use it as an issue tracker, collaborate on code, and continuously
build, test, and deploy your app with built-in GitLab CI/CD.

Your projects can be [available](../../public_access/public_access.md)
publicly, internally, or privately, at your choice. GitLab does not limit
the number of private projects you create.

## Project features

When you create a project in GitLab, you'll have access to a large number of
[features](https://about.gitlab.com/features/):

**Repositories:**

- [Issue tracker](issues/index.md): Discuss implementations with your team within issues
  - [Issue Boards](issue_board.md): Organize and prioritize your workflow
  - [Multiple Issue Boards](issue_board.md#multiple-issue-boards): Allow your teams to create their own workflows (Issue Boards) for the same project
- [Repositories](repository/index.md): Host your code in a fully
  integrated platform
  - [Branches](repository/branches/index.md): use Git branching strategies to
  collaborate on code
  - [Protected branches](protected_branches.md): Prevent collaborators
  from messing with history or pushing code without review
  - [Protected tags](protected_tags.md): Control over who has
  permission to create tags, and prevent accidental update or deletion
  - [Repository mirroring](repository/repository_mirroring.md)
  - [Signing commits](gpg_signed_commits/index.md): use GPG to sign your commits
  - [Deploy tokens](deploy_tokens/index.md): Manage project-based deploy tokens that allow permanent access to the repository and Container Registry.
- [Web IDE](web_ide/index.md)

**Issues and merge requests:**

- [Issue tracker](issues/index.md): Discuss implementations with your team within issues
  - [Issue Boards](issue_board.md): Organize and prioritize your workflow
  - [Multiple Issue Boards](issue_board.md#multiple-issue-boards): Allow your teams to create their own workflows (Issue Boards) for the same project
- [Merge Requests](merge_requests/index.md): Apply your branching
  strategy and get reviewed by your team
  - [Merge Request Approvals](merge_requests/merge_request_approvals.md): Ask for approval before
  implementing a change **(STARTER)**
  - [Fix merge conflicts from the UI](merge_requests/resolve_conflicts.md):
  Your Git diff tool right from GitLab's UI
  - [Review Apps](../../ci/review_apps/index.md): Live preview the results
  of the changes proposed in a merge request in a per-branch basis
- [Labels](labels.md): Organize issues and merge requests by labels
- [Time Tracking](time_tracking.md): Track estimate time
  and time spent on
  the conclusion of an issue or merge request
- [Milestones](milestones/index.md): Work towards a target date
- [Description templates](description_templates.md): Define context-specific
  templates for issue and merge request description fields for your project
- [Slash commands (quick actions)](quick_actions.md): Textual shortcuts for
  common actions on issues or merge requests
- [Autocomplete characters](autocomplete_characters.md): Autocomplete
  references to users, groups, issues, merge requests, and other GitLab
  elements.
- [Web IDE](web_ide/index.md)

**GitLab CI/CD:**

- [GitLab CI/CD](../../ci/README.md): GitLab's built-in [Continuous Integration, Delivery, and Deployment](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) tool
  - [Container Registry](../packages/container_registry/index.md): Build and push Docker
  images out-of-the-box
  - [Auto Deploy](../../topics/autodevops/index.md#auto-deploy): Configure GitLab CI/CD
  to automatically set up your app's deployment
  - [Enable and disable GitLab CI](../../ci/enable_or_disable_ci.md)
  - [Pipelines](../../ci/pipelines.md): Configure and visualize
    your GitLab CI/CD pipelines from the UI
    - [Scheduled Pipelines](pipelines/schedules.md): Schedule a pipeline
      to start at a chosen time
    - [Pipeline Graphs](../../ci/pipelines.md#visualizing-pipelines): View your
      entire pipeline from the UI
    - [Job artifacts](pipelines/job_artifacts.md): Define,
      browse, and download job artifacts
    - [Pipeline settings](pipelines/settings.md): Set up Git strategy (choose the default way your repository is fetched from GitLab in a job),
      timeout (defines the maximum amount of time in minutes that a job is able run), custom path for `.gitlab-ci.yml`, test coverage parsing, pipeline's visibility, and much more
  - [Kubernetes cluster integration](clusters/index.md): Connecting your GitLab project
    with a Kubernetes cluster
  - [Feature Flags](operations/feature_flags.md): Feature flags allow you to ship a project in
    different flavors by dynamically toggling certain functionality **(PREMIUM)**
- [GitLab Pages](pages/index.md): Build, test, and deploy your static
  website with GitLab Pages

**Other features:**

- [Wiki](wiki/index.md): document your GitLab project in an integrated Wiki.
- [Snippets](../snippets.md): store, share and collaborate on code snippets.
- [Cycle Analytics](cycle_analytics.md): review your development lifecycle.
- [Insights](insights/index.md): configure the Insights that matter for your projects. **(ULTIMATE)**
- [Security Dashboard](security_dashboard.md): Security Dashboard. **(ULTIMATE)**
- [Syntax highlighting](highlighting.md): an alternative to customize
  your code blocks, overriding GitLab's default choice of language.
- [Badges](badges.md): badges for the project overview.
- [Releases](releases/index.md): a way to track deliverables in your project as snapshot in time of
  the source, build output, and other metadata or artifacts
  associated with a released version of your code.
- [Conan packages](../packages/conan_repository/index.md): your private Conan repository in GitLab. **(PREMIUM)**
- [Maven packages](../packages/maven_repository/index.md): your private Maven repository in GitLab. **(PREMIUM)**
- [NPM packages](../packages/npm_registry/index.md): your private NPM package registry in GitLab. **(PREMIUM)**
- [Code owners](code_owners.md): specify code owners for certain files **(STARTER)**
- [License Compliance](../application_security/license_compliance/index.md): approve and blacklist licenses for projects. **(ULTIMATE)**
- [Dependency List](../application_security/dependency_list/index.md): view project dependencies. **(ULTIMATE)**

### Project integrations

[Integrate your project](integrations/index.md) with Jira, Mattermost,
Kubernetes, Slack, and a lot more.

## New project

Learn how to [create a new project](../../gitlab-basics/create-project.md) in GitLab.

### Fork a project

You can [fork a project](../../gitlab-basics/fork-project.md) in order to:

- Collaborate on code by forking a project and creating a merge request
  from your fork to the upstream project
- Fork a sample project to work on the top of that

## Project settings

Set the project's visibility level and  the access levels to its various pages
and perform actions like archiving, renaming or transferring a project.

Read through the documentation on [project settings](settings/index.md).

## Import or export a project

- [Import a project](import/index.md) from:
  - [GitHub to GitLab](import/github.md)
  - [Bitbucket to GitLab](import/bitbucket.md)
  - [Gitea to GitLab](import/gitea.md)
  - [FogBugz to GitLab](import/fogbugz.md)
- [Export a project from GitLab](settings/import_export.md#exporting-a-project-and-its-data)
- [Importing and exporting projects between GitLab instances](settings/import_export.md)

## CI/CD for external repositories **(PREMIUM)**

Instead of importing a repository directly to GitLab, you can connect your repository
as a CI/CD project.

Read through the documentation on [CI/CD for external repositories](../../ci/ci_cd_for_external_repos/index.md).

## Project members

Learn how to [add members to your projects](members/index.md).

### Leave a project

**Leave project** will only display on the project's dashboard
when a project is part of a group (under a
[group namespace](../group/index.md#namespaces)).
If you choose to leave a project you will no longer be a project
member, therefore, unable to contribute.

## Project's landing page

The project's landing page shows different information depending on
the project's visibility settings and user permissions.

For public projects, and to members of internal and private projects
with [permissions to view the project's code](../permissions.md#project-members-permissions):

- The content of a
  [`README` or an index file](repository/#repository-readme-and-index-files)
  is displayed (if any), followed by the list of directories within the
  project's repository.
- If the project doesn't contain either of these files, the
  visitor will see the list of files and directories of the repository.

For users without permissions to view the project's code:

- The wiki homepage is displayed, if any.
- The list of issues within the project is displayed.

## Redirects when changing repository paths

When a repository path changes, it is essential to smoothly transition from the
old location to the new one. GitLab provides two kinds of redirects: the web UI
and Git push/pull redirects.

Depending on the situation, different things apply.

When [renaming a user](../profile/index.md#changing-your-username),
[changing a group path](../group/index.md#changing-a-groups-path) or [renaming a repository](settings/index.md#renaming-a-repository):

- Existing web URLs for the namespace and anything under it (e.g., projects) will
  redirect to the new URLs.
- Starting with GitLab 10.3, existing Git remote URLs for projects under the
  namespace will redirect to the new remote URL. Every time you push/pull to a
  repository that has changed its location, a warning message to update
  your remote will be displayed instead of rejecting your action.
  This means that any automation scripts, or Git clients will continue to
  work after a rename, making any transition a lot smoother.
- The redirects will be available as long as the original path is not claimed by
  another group, user or project.

## Use your project as a Go package

Any project can be used as a Go package including private projects in subgroups.
GitLab responds correctly to `go get` and `godoc.org` discovery requests,
including the [`go-import`](https://golang.org/cmd/go/#hdr-Remote_import_paths)
and [`go-source`](https://github.com/golang/gddo/wiki/Source-Code-Links) meta
tags, respectively. To use packages hosted in private projects with the `go get`
command, use a [`.netrc` file](https://ec.haxx.se/usingcurl-netrc.html) and a
[personal access token](../profile/personal_access_tokens.md) in the password
field.

For example:

```text
machine example.gitlab.com
login <gitlab_user_name>
password <personal_access_token>
```

## Access project page with project ID

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/53671) in GitLab 11.8.

To quickly access a project from the GitLab UI using the project ID,
visit the `/projects/:id` URL in your browser or other tool accessing the project.

## Project aliases **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/3264) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.1.

When migrating repositories to GitLab and they are being accessed by other systems,
it's very useful to be able to access them using the same name especially when
they are a lot. It reduces the risk of changing significant number of Git URLs in
a large number of systems.

GitLab provides a functionality to help with this. In GitLab, repositories are
usually accessed with a namespace and project name. It is also possible to access
them via a project alias. This feature is only available on Git over SSH.

A project alias can be only created via API and only by GitLab administrators.
Follow the [Project Aliases API documentation](../../api/project_aliases.md) for
more details.

Once an alias has been created for a project (e.g., an alias `gitlab` for the
project `https://gitlab.com/gitlab-org/gitlab`), the repository can be cloned
using the alias (e.g `git clone git@gitlab.com:gitlab.git` instead of
`git clone git@gitlab.com:gitlab-org/gitlab.git`).

## Project APIs

There are numerous [APIs](../../api/README.md) to use with your projects:

- [Badges](../../api/project_badges.md)
- [Clusters](../../api/project_clusters.md)
- [Threads](../../api/discussions.md)
- [General](../../api/projects.md)
- [Import/export](../../api/project_import_export.md)
- [Issue Board](../../api/boards.md)
- [Labels](../../api/labels.md)
- [Markdown](../../api/markdown.md)
- [Merge Requests](../../api/merge_requests.md)
- [Milestones](../../api/milestones.md)
- [Services](../../api/services.md)
- [Snippets](../../api/project_snippets.md)
- [Templates](../../api/project_templates.md)
- [Traffic](../../api/project_statistics.md)
- [Variables](../../api/project_level_variables.md)
- [Aliases](../../api/project_aliases.md)
