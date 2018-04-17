# Projects

In GitLab, you can create projects for hosting
your codebase, use it as an issue tracker, collaborate on code, and continuously
build, test, and deploy your app with built-in GitLab CI/CD.

Your projects can be [available](../../public_access/public_access.md)
publicly, internally, or privately, at your choice. GitLab does not limit
the number of private projects you create.

## Project's features

When you create a project in GitLab, you'll have access to a large number of
[features](https://about.gitlab.com/features/):

**Issues and merge requests:**

- [Issue tracker](issues/index.md): Discuss implementations with your team within issues
  - [Issue Boards](issue_board.md): Organize and prioritize your workflow
  - [Multiple Issue Boards](https://docs.gitlab.com/ee/user/project/issue_board.html#multiple-issue-boards) (**Starter/Premium**): Allow your teams to create their own workflows (Issue Boards) for the same project
- [Repositories](repository/index.md): Host your code in a fully
integrated platform
  - [Branches](repository/branches/index.md): use Git branching strategies to
  collaborate on code
  - [Protected branches](protected_branches.md): Prevent collaborators
  from messing with history or pushing code without review
  - [Protected tags](protected_tags.md): Control over who has
  permission to create tags, and prevent accidental update or deletion
  - [Signing commits](gpg_signed_commits/index.md): use GPG to sign your commits
  - [Deploy tokens](deploy_tokens/index.md): Manage project-based deploy tokens that allow permanent access to the repository and Container Registry.
- [Merge Requests](merge_requests/index.md): Apply your branching
strategy and get reviewed by your team
  - [Merge Request Approvals](https://docs.gitlab.com/ee/user/project/merge_requests/merge_request_approvals.html) (**Starter/Premium**): Ask for approval before
  implementing a change
  - [Fix merge conflicts from the UI](merge_requests/resolve_conflicts.md):
  Your Git diff tool right from GitLab's UI
  - [Review Apps](../../ci/review_apps/index.md): Live preview the results
  of the changes proposed in a merge request in a per-branch basis
- [Labels](labels.md): Organize issues and merge requests by labels
- [Time Tracking](../../workflow/time_tracking.md): Track estimate time
and time spent on
  the conclusion of an issue or merge request
- [Milestones](milestones/index.md): Work towards a target date
- [Description templates](description_templates.md): Define context-specific
templates for issue and merge request description fields for your project
- [Slash commands (quick actions)](quick_actions.md): Textual shortcuts for
common actions on issues or merge requests
- [Web IDE](web_ide/index.md)

**GitLab CI/CD:**

- [GitLab CI/CD](../../ci/README.md): GitLab's built-in [Continuous Integration, Delivery, and Deployment](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) tool
  - [Container Registry](container_registry.md): Build and push Docker
  images out-of-the-box
  - [Auto Deploy](../../ci/autodeploy/index.md): Configure GitLab CI/CD
  to automatically set up your app's deployment
  - [Enable and disable GitLab CI](../../ci/enable_or_disable_ci.md)
  - [Pipelines](../../ci/pipelines.md#pipelines): Configure and visualize
  your GitLab CI/CD pipelines from the UI
     - [Scheduled Pipelines](pipelines/schedules.md): Schedule a pipeline
     to start at a chosen time
     - [Pipeline Graphs](../../ci/pipelines.md#pipeline-graphs): View your
     entire pipeline from the UI
     - [Job artifacts](pipelines/job_artifacts.md): Define,
     browse, and download job artifacts
     - [Pipeline settings](pipelines/settings.md): Set up Git strategy (choose the default way your repository is fetched from GitLab in a job),
     timeout (defines the maximum amount of time in minutes that a job is able run), custom path for `.gitlab-ci.yml`, test coverage parsing, pipeline's visibility, and much more
  - [GKE cluster integration](clusters/index.md): Connecting your GitLab project
    with Google Kubernetes Engine
- [GitLab Pages](pages/index.md): Build, test, and deploy your static
website with GitLab Pages

**Other features:**

- [Cycle Analytics](cycle_analytics.md): Review your development lifecycle
- [Syntax highlighting](highlighting.md): An alternative to customize
your code blocks, overriding GitLab's default choice of language
- [Badges](badges.md): Badges for the project overview

### Project's integrations

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
  - [BitBucket to GitLab](import/bitbucket.md)
  - [Gitea to GitLab](import/gitea.md)
  - [FogBugz to GitLab](import/fogbugz.md)
- [Export a project from GitLab](settings/import_export.md#exporting-a-project-and-its-data)
- [Importing and exporting projects between GitLab instances](settings/import_export.md)

## Project's members

Learn how to [add members to your projects](members/index.md).

### Leave a project

**Leave project** will only display on the project's dashboard
when a project is part of a group (under a
[group namespace](../group/index.md#namespaces)).
If you choose to leave a project you will no longer be a project
member, therefore, unable to contribute.

## Redirects when changing repository paths

When a repository path changes, it is essential to smoothly transition from the
old location to the new one. GitLab provides two kinds of redirects: the web UI
and Git push/pull redirects.

Depending on the situation, different things apply.

When [renaming a user](../profile/index.md#changing-your-username),
[changing a group path](../group/index.md#changing-a-group-s-path) or [renaming a repository](settings/index.md#renaming-a-repository):

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
