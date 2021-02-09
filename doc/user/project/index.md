---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Projects

In GitLab, you can create projects for hosting
your codebase, use it as an issue tracker, collaborate on code, and continuously
build, test, and deploy your app with built-in GitLab CI/CD.

Your projects can be [available](../../public_access/public_access.md)
publicly, internally, or privately, at your choice. GitLab does not limit
the number of private projects you create.

## Project features

Projects include the following [features](https://about.gitlab.com/features/):

**Repositories:**

- [Issue tracker](issues/index.md): Discuss implementations with your team in issues
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
  - [Signing commits](repository/gpg_signed_commits/index.md): use GPG to sign your commits
  - [Deploy tokens](deploy_tokens/index.md): Manage project-based deploy tokens that allow permanent access to the repository and Container Registry.
- [Web IDE](web_ide/index.md)
- [CVE ID Requests](../application_security/cve_id_request.md): Request a CVE identifier to track a
  vulnerability in your project.

**Issues and merge requests:**

- [Issue tracker](issues/index.md): Discuss implementations with your team in issues
  - [Issue Boards](issue_board.md): Organize and prioritize your workflow
  - [Multiple Issue Boards](issue_board.md#multiple-issue-boards): Allow your teams to create their own workflows (Issue Boards) for the same project
- [Merge Requests](merge_requests/index.md): Apply your branching
  strategy and get reviewed by your team
  - [Merge Request Approvals](merge_requests/merge_request_approvals.md): Ask for approval before
  implementing a change
  - [Fix merge conflicts from the UI](merge_requests/resolve_conflicts.md):
  Your Git diff tool right from the GitLab UI
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

- [GitLab CI/CD](../../ci/README.md): the GitLab built-in [Continuous Integration, Delivery, and Deployment](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) tool
  - [Container Registry](../packages/container_registry/index.md): Build and push Docker
  images out-of-the-box
  - [Auto Deploy](../../topics/autodevops/stages.md#auto-deploy): Configure GitLab CI/CD
  to automatically set up your app's deployment
  - [Enable and disable GitLab CI/CD](../../ci/enable_or_disable_ci.md)
  - [Pipelines](../../ci/pipelines/index.md): Configure and visualize
    your GitLab CI/CD pipelines from the UI
    - [Scheduled Pipelines](../../ci/pipelines/schedules.md): Schedule a pipeline
      to start at a chosen time
    - [Pipeline Graphs](../../ci/pipelines/index.md#visualize-pipelines): View your
      entire pipeline from the UI
    - [Job artifacts](../../ci/pipelines/job_artifacts.md): Define,
      browse, and download job artifacts
    - [Pipeline settings](../../ci/pipelines/settings.md): Set up Git strategy (choose the default way your repository is fetched from GitLab in a job),
      timeout (defines the maximum amount of time in minutes that a job is able run), custom path for `.gitlab-ci.yml`, test coverage parsing, pipeline's visibility, and much more
  - [Kubernetes cluster integration](clusters/index.md): Connecting your GitLab project
    with a Kubernetes cluster
  - [Feature Flags](../../operations/feature_flags.md): Feature flags allow you to ship a project in
    different flavors by dynamically toggling certain functionality **(PREMIUM)**
- [GitLab Pages](pages/index.md): Build, test, and deploy your static
  website with GitLab Pages

**Other features:**

- [Wiki](wiki/index.md): document your GitLab project in an integrated Wiki.
- [Snippets](../snippets.md): store, share and collaborate on code snippets.
- [Value Stream Analytics](../analytics/value_stream_analytics.md): review your development lifecycle.
- [Insights](insights/index.md): configure the Insights that matter for your projects. **(ULTIMATE)**
- [Security Dashboard](../application_security/security_dashboard/index.md): Security Dashboard. **(ULTIMATE)**
- [Syntax highlighting](highlighting.md): an alternative to customize
  your code blocks, overriding the GitLab default choice of language.
- [Badges](badges.md): badges for the project overview.
- [Releases](releases/index.md): a way to track deliverables in your project as snapshot in time of
  the source, build output, other metadata, and other artifacts
  associated with a released version of your code.
- [Conan packages](../packages/conan_repository/index.md): your private Conan repository in GitLab.
- [Maven packages](../packages/maven_repository/index.md): your private Maven repository in GitLab.
- [NPM packages](../packages/npm_registry/index.md): your private NPM package registry in GitLab.
- [Code owners](code_owners.md): specify code owners for certain files
- [License Compliance](../compliance/license_compliance/index.md): approve and deny licenses for projects. **(ULTIMATE)**
- [Dependency List](../application_security/dependency_list/index.md): view project dependencies. **(ULTIMATE)**
- [Requirements](requirements/index.md): Requirements allow you to create criteria to check your products against. **(ULTIMATE)**
- [Static Site Editor](static_site_editor/index.md): quickly edit content on static websites without prior knowledge of the codebase or Git commands.
- [Code Intelligence](code_intelligence.md): code navigation features.

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

## CI/CD for external repositories **(PREMIUM)**

Instead of importing a repository directly to GitLab, you can connect your repository
as a CI/CD project.

Read through the documentation on [CI/CD for external repositories](../../ci/ci_cd_for_external_repos/index.md).

## GitLab Workflow - VS Code extension

To avoid switching from the GitLab UI and VS Code while working in GitLab repositories, you can integrate
the [VS Code](https://code.visualstudio.com/) editor with GitLab through the
[GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).

To review or contribute to the extension's code, visit [its codebase in GitLab](https://gitlab.com/gitlab-org/gitlab-vscode-extension/).

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
- [Analytics](../../api/project_analytics.md)

## Project activity analytics overview **(ULTIMATE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/279039) in GitLab [Ultimate](https://about.gitlab.com/pricing/) 13.7 as a [Beta feature](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta).

Project details include the following analytics:

- Deployment Frequency

For more information, see [Project Analytics API](../../api/project_analytics.md).
