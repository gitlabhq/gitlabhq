---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Organize work with projects **(FREE)**

In GitLab, you can create projects to host
your codebase. You can also use projects to track issues, plan work,
collaborate on code, and continuously build, test, and use
built-in CI/CD to deploy your app.

Projects can be available [publicly, internally, or privately](../../public_access/public_access.md).
GitLab does not limit the number of private projects you can create.

## Project features

Projects include the following [features](https://about.gitlab.com/features/):

**Repositories:**

- [Issue tracker](issues/index.md): Discuss implementations with your team.
  - [Issue Boards](issue_board.md): Organize and prioritize your workflow.
  - [Multiple Issue Boards](issue_board.md#multiple-issue-boards): Create team-specific workflows (Issue Boards) for a project.
- [Repositories](repository/index.md): Host your code in a fully-integrated platform.
  - [Branches](repository/branches/index.md): Use Git branching strategies to
  collaborate on code.
  - [Protected branches](protected_branches.md): Prevent collaborators
  from changing history or pushing code without review.
  - [Protected tags](protected_tags.md): Control who has
  permission to create tags and prevent accidental updates or deletions.
  - [Repository mirroring](repository/repository_mirroring.md)
  - [Signing commits](repository/gpg_signed_commits/index.md): Use GNU Privacy Guard (GPG) to sign your commits.
  - [Deploy tokens](deploy_tokens/index.md): Manage access to the repository and Container Registry.
- [Web IDE](web_ide/index.md)
- [CVE ID Requests](../application_security/cve_id_request.md): Request a CVE identifier to track a
  vulnerability in your project.

**Issues and merge requests:**

- [Issue tracker](issues/index.md): Discuss implementations with your team.
  - [Issue Boards](issue_board.md): Organize and prioritize your workflow.
  - [Multiple Issue Boards](issue_board.md#multiple-issue-boards): Create team-specific workflows (Issue Boards) for a project.
- [Merge Requests](merge_requests/index.md): Apply a branching
  strategy and get reviewed by your team.
  - [Merge Request Approvals](merge_requests/approvals/index.md): Ask for approval before
  implementing a change.
  - [Fix merge conflicts from the UI](merge_requests/resolve_conflicts.md): View Git diffs from the GitLab UI.
  - [Review Apps](../../ci/review_apps/index.md): By branch, preview the results
  of the changes proposed in a merge request.
- [Labels](labels.md): Organize issues and merge requests by labels.
- [Time Tracking](time_tracking.md): Track time estimated and
  spent on issues and merge requests.
- [Milestones](milestones/index.md): Work toward a target date.
- [Description templates](description_templates.md): Define context-specific
  templates for issue and merge request description fields.
- [Slash commands (quick actions)](quick_actions.md): Create text shortcuts for
  common actions.
- [Autocomplete characters](autocomplete_characters.md): Autocomplete
  references to users, groups, issues, merge requests, and other GitLab
  elements.
- [Web IDE](web_ide/index.md)

**GitLab CI/CD:**

- [GitLab CI/CD](../../ci/index.md): Use the built-in [Continuous Integration, Delivery, and Deployment](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) tool.
  - [Container Registry](../packages/container_registry/index.md): Build and push Docker
  images.
  - [Auto Deploy](../../topics/autodevops/stages.md#auto-deploy): Configure GitLab CI/CD
  to automatically set up your app's deployment.
  - [Enable and disable GitLab CI/CD](../../ci/enable_or_disable_ci.md)
  - [Pipelines](../../ci/pipelines/index.md): Configure and visualize
    your GitLab CI/CD pipelines from the UI.
    - [Scheduled Pipelines](../../ci/pipelines/schedules.md): Schedule a pipeline
      to start at a chosen time.
    - [Pipeline Graphs](../../ci/pipelines/index.md#visualize-pipelines): View your
      pipeline from the UI.
    - [Job artifacts](../../ci/pipelines/job_artifacts.md): Define,
      browse, and download job artifacts.
    - [Pipeline settings](../../ci/pipelines/settings.md): Set up Git strategy (how jobs fetch your repository),
      timeout (the maximum amount of time a job can run), custom path for `.gitlab-ci.yml`, test coverage parsing, pipeline visibility, and more.
  - [Kubernetes cluster integration](clusters/index.md): Connect your GitLab project
    with a Kubernetes cluster.
  - [Feature Flags](../../operations/feature_flags.md): Ship different features
    by dynamically toggling functionality. **(PREMIUM)**
- [GitLab Pages](pages/index.md): Build, test, and deploy your static
  website.

**Other features:**

- [Wiki](wiki/index.md): Document your GitLab project in an integrated Wiki.
- [Snippets](../snippets.md): Store, share and collaborate on code snippets.
- [Value Stream Analytics](../analytics/value_stream_analytics.md): Review your development lifecycle.
- [Insights](insights/index.md): Configure the insights that matter for your projects. **(ULTIMATE)**
- [Security Dashboard](../application_security/security_dashboard/index.md) **(ULTIMATE)**
- [Syntax highlighting](highlighting.md): Customize
  your code blocks, overriding the default language choice.
- [Badges](badges.md): Add an image to the **Project information** page.
- [Releases](releases/index.md): Take a snapshot of
  the source, build output, metadata, and artifacts
  associated with a released version of your code.
- [Package Registry](../packages/package_registry/index.md): Publish and install packages.
- [Code owners](code_owners.md): Specify code owners for specific files.
- [License Compliance](../compliance/license_compliance/index.md): Approve and deny licenses for projects. **(ULTIMATE)**
- [Dependency List](../application_security/dependency_list/index.md): View project dependencies. **(ULTIMATE)**
- [Requirements](requirements/index.md): Create criteria to check your products against. **(ULTIMATE)**
- [Static Site Editor](static_site_editor/index.md): Edit content on static websites without prior knowledge of the codebase or Git commands.
- [Code Intelligence](code_intelligence.md): Navigate code.

## Project integrations

[Integrate your project](integrations/index.md) with Jira, Mattermost,
Kubernetes, Slack, and a lot more.

## Import or export a project

- [Import a project](import/index.md) from:
  - [GitHub to GitLab](import/github.md)
  - [Bitbucket to GitLab](import/bitbucket.md)
  - [Gitea to GitLab](import/gitea.md)
  - [FogBugz to GitLab](import/fogbugz.md)
- [Export a project from GitLab](settings/import_export.md#exporting-a-project-and-its-data)
- [Importing and exporting projects between GitLab instances](settings/import_export.md)

## GitLab Workflow - VS Code extension

To avoid switching from the GitLab UI and VS Code while working in GitLab repositories, you can integrate
the [VS Code](https://code.visualstudio.com/) editor with GitLab through the
[GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).

To review or contribute to the extension's code, visit [its codebase in GitLab](https://gitlab.com/gitlab-org/gitlab-vscode-extension/).

## Project APIs

There are numerous [APIs](../../api/index.md) to use with your projects:

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
- [DORA4 Analytics](../../api/dora4_project_analytics.md)

## DORA4 analytics overview

Project details include the following analytics:

- Deployment Frequency

For more information, see [DORA4 Project Analytics API](../../api/dora4_project_analytics.md).
