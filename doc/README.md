---
toc: false
comments: false
---

# GitLab Documentation

Welcome to [GitLab](https://about.gitlab.com/), a Git-based fully featured
platform for software development!

GitLab offers the most scalable Git-based fully integrated platform for software development, with flexible products and subscription plans:

- **GitLab Community Edition (CE)** is an [opensource product](https://gitlab.com/gitlab-org/gitlab-ce/),
self-hosted, free to use. Every feature available in GitLab CE is also available on GitLab Enterprise Edition (Starter and Premium) and GitLab.com.
- **GitLab Enterprise Edition (EE)** is an [opencore product](https://gitlab.com/gitlab-org/gitlab-ee/),
self-hosted, fully featured solution of GitLab, available under distinct [subscriptions](https://about.gitlab.com/products/): **GitLab Enterprise Edition Starter (EES)** and **GitLab Enterprise Edition Premium (EEP)**.
- **GitLab.com**: SaaS GitLab solution, with [free and paid subscriptions](https://about.gitlab.com/gitlab-com/). GitLab.com is hosted by GitLab, Inc., and administrated by GitLab (users don't have access to admin settings).

> **GitLab EE** contains all features available in **GitLab CE**,
plus premium features available in each version: **Enterprise Edition Starter**
(**EES**) and **Enterprise Edition Premium** (**EEP**). Everything available in
**EES** is also available in **EEP**.

----

Shortcuts to GitLab's most visited docs:

| [GitLab CI/CD](ci/README.md) | Other |
| :----- | :----- |
| [Quick start guide](ci/quick_start/README.md) | [API](api/README.md) |
| [Configuring `.gitlab-ci.yml`](ci/yaml/README.md) | [SSH authentication](ssh/README.md) |
| [Using Docker images](ci/docker/using_docker_images.md) | [GitLab Pages](user/project/pages/index.md) |

- [User documentation](user/index.md)
- [Administrator documentation](#administrator-documentation)
- [Technical Articles](articles/index.md)

## Getting started with GitLab

- [GitLab Basics](gitlab-basics/README.md): Start working on your command line and on GitLab.
- [GitLab Workflow](workflow/README.md): Enhance your workflow with the best of GitLab Workflow.
  - See also [GitLab Workflow - an overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/).
- [GitLab Markdown](user/markdown.md): GitLab's advanced formatting system (GitLab Flavored Markdown).
- [GitLab Quick Actions](user/project/quick_actions.md): Textual shortcuts for common actions on issues or merge requests that are usually done by clicking buttons or dropdowns in GitLab's UI.
- [Auto DevOps](topics/autodevops/index.md)

### User account

- [User account](user/profile/index.md): Manage your account
  - [Authentication](topics/authentication/index.md): Account security with two-factor authentication, setup your ssh keys and deploy keys for secure access to your projects.
  - [Profile settings](user/profile/index.md#profile-settings): Manage your profile settings, two factor authentication and more.
- [User permissions](user/permissions.md): Learn what each role in a project (external/guest/reporter/developer/master/owner) can do.

### Projects and groups

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

### Repository

Manage your [repositories](user/project/repository/index.md) from the UI (user interface):

- [Files](user/project/repository/index.md#files)
  - [Create a file](user/project/repository/web_editor.md#create-a-file)
  - [Upload a file](user/project/repository/web_editor.md#upload-a-file)
  - [File templates](user/project/repository/web_editor.md#template-dropdowns)
  - [Create a directory](user/project/repository/web_editor.md#create-a-directory)
  - [Start a merge request](user/project/repository/web_editor.md#tips) (when committing via UI)
- [Branches](user/project/repository/branches/index.md)
  - [Default branch](user/project/repository/branches/index.md#default-branch)
  - [Create a branch](user/project/repository/web_editor.md#create-a-new-branch)
  - [Protected branches](user/project/protected_branches.md#protected-branches)
  - [Delete merged branches](user/project/repository/branches/index.md#delete-merged-branches)
- [Commits](user/project/repository/index.md#commits)
  - [Signing commits](user/project/repository/gpg_signed_commits/index.md): use GPG to sign your commits.

### Issues and Merge Requests (MRs)

- [Discussions](user/discussions/index.md): Threads, comments, and resolvable discussions in issues, commits, and  merge requests.
- [Issues](user/project/issues/index.md)
- [Project issue Board](user/project/issue_board.md)
- [Issues and merge requests templates](user/project/description_templates.md): Create templates for submitting new issues and merge requests.
- [Labels](user/project/labels.md): Categorize your issues or merge requests based on descriptive titles.
- [Merge Requests](user/project/merge_requests/index.md)
  - [Work In Progress Merge Requests](user/project/merge_requests/work_in_progress_merge_requests.md)
  - [Merge Request discussion resolution](user/discussions/index.md#moving-a-single-discussion-to-a-new-issue): Resolve discussions, move discussions in a merge request to an issue, only allow merge requests to be merged if all discussions are resolved.
  - [Checkout merge requests locally](user/project/merge_requests/index.md#checkout-merge-requests-locally)
  - [Cherry-pick](user/project/merge_requests/cherry_pick_changes.md)
- [Milestones](user/project/milestones/index.md): Organize issues and merge requests into a cohesive group, optionally setting a due date.
- [Todos](workflow/todos.md): A chronological list of to-dos that are waiting for your input, all in a simple dashboard.

### Git and GitLab

- [Git](topics/git/index.md): Getting started with Git, branching strategies, Git LFS, advanced use.
- [Git cheatsheet](https://gitlab.com/gitlab-com/marketing/raw/master/design/print/git-cheatsheet/print-pdf/git-cheatsheet.pdf): Download a PDF describing the most used Git operations.
- [GitLab Flow](workflow/gitlab_flow.md): explore the best of Git with the GitLab Flow strategy.

### Migrate and import your projects from other platforms

- [Importing to GitLab](user/project/import/index.md): Import your projects from GitHub, Bitbucket, GitLab.com, FogBugz and SVN into GitLab.
- [Migrating from SVN](workflow/importing/migrating_from_svn.md): Convert a SVN repository to Git and GitLab.

### Continuous Integration, Delivery, and Deployment

- [GitLab CI](ci/README.md): Explore the features and capabilities of Continuous Integration, Continuous Delivery, and Continuous Deployment with GitLab.
  - [Auto Deploy](ci/autodeploy/index.md): Configure GitLab CI for the deployment of your application.
  - [Review Apps](ci/review_apps/index.md): Preview changes to your app right from a merge request.
- [GitLab Cycle Analytics](user/project/cycle_analytics.md): Cycle Analytics measures the time it takes to go from an [idea to production](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#from-idea-to-production-with-gitlab) for each project you have.
- [GitLab Container Registry](user/project/container_registry.md): Learn how to use GitLab's built-in Container Registry.

### Automation

- [API](api/README.md): Automate GitLab via a simple and powerful API.
- [GitLab Webhooks](user/project/integrations/webhooks.md): Let GitLab notify you when new code has been pushed to your project.

### Integrations

- [Project Services](user/project/integrations/project_services.md): Integrate a project with external services, such as CI and chat.
- [GitLab Integration](integration/README.md): Integrate with multiple third-party services with GitLab to allow external issue trackers and external authentication.
- [Trello Power-Up](integration/trello_power_up.md): Integrate with GitLab's Trello Power-Up

----

## Administrator documentation

Learn how to administer your GitLab instance. Regular users don't
have access to GitLab administration tools and settings.

### Install, update, upgrade, migrate

- [Install](install/README.md): Requirements, directory structures and installation from source.
- [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/): Integrate [Mattermost](https://about.mattermost.com/) with your GitLab installation.
- [Migrate GitLab CI to CE/EE](migrate_ci_to_ce/README.md): If you have an old GitLab installation (older than 8.0), follow this guide to migrate your existing GitLab CI data to GitLab CE/EE.
- [Restart GitLab](administration/restart_gitlab.md): Learn how to restart GitLab and its components.
- [Update](update/README.md): Update guides to upgrade your installation.

### User permissions

- [Access restrictions](user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols): Define which Git access protocols can be used to talk to GitLab
- [Authentication/Authorization](topics/authentication/index.md#gitlab-administrators): Enforce 2FA, configure external authentication with LDAP, SAML, CAS and additional Omniauth providers.

### Features

- [Container Registry](administration/container_registry.md): Configure Docker Registry with GitLab.
- [Custom Git hooks](administration/custom_hooks.md): Custom Git hooks (on the filesystem) for when webhooks aren't enough.
- [Git LFS configuration](workflow/lfs/lfs_administration.md): Learn how to use LFS under GitLab.
- [GitLab Pages configuration](administration/pages/index.md): Configure GitLab Pages.
- [High Availability](administration/high_availability/README.md): Configure multiple servers for scaling or high availability.
- [User cohorts](user/admin_area/user_cohorts.md): View user activity over time.
- [Web terminals](administration/integration/terminal.md): Provide terminal access to environments from within GitLab.
- GitLab CI
    - [CI admin settings](user/admin_area/settings/continuous_integration.md): Define max artifacts size and expiration time.

### Integrations

- [Integrations](integration/README.md): How to integrate with systems such as JIRA, Redmine, Twitter.
- [Mattermost](user/project/integrations/mattermost.md): Set up GitLab with Mattermost.

### Monitoring

- [GitLab performance monitoring with InfluxDB](administration/monitoring/performance/introduction.md): Configure GitLab and InfluxDB for measuring performance metrics.
- [GitLab performance monitoring with Prometheus](administration/monitoring/prometheus/index.md): Configure GitLab and Prometheus for measuring performance metrics.
- [Monitoring uptime](user/admin_area/monitoring/health_check.md): Check the server status using the health check endpoint.
- [Monitoring GitHub imports](administration/monitoring/github_imports.md)

### Performance

- [Housekeeping](administration/housekeeping.md): Keep your Git repository tidy and fast.
- [Operations](administration/operations.md): Keeping GitLab up and running.
- [Polling](administration/polling.md): Configure how often the GitLab UI polls for updates.
- [Request Profiling](administration/monitoring/performance/request_profiling.md): Get a detailed profile on slow requests.
- [Performance Bar](administration/monitoring/performance/performance_bar.md): Get performance information for the current page.

### Customization

- [Adjust your instance's timezone](workflow/timezone.md): Customize the default time zone of GitLab.
- [Environment variables](administration/environment_variables.md): Supported environment variables that can be used to override their defaults values in order to configure GitLab.
- [Header logo](customization/branded_page_and_email_header.md): Change the logo on the overall page and email header.
- [Issue closing pattern](administration/issue_closing_pattern.md): Customize how to close an issue from commit messages.
- [Libravatar](customization/libravatar.md): Use Libravatar instead of Gravatar for user avatars.
- [Welcome message](customization/welcome_message.md): Add a custom welcome message to the sign-in page.

### Admin tools

- [Gitaly](administration/gitaly/index.md): Configuring Gitaly, GitLab's Git repository storage service
- [Raketasks](raketasks/README.md): Backups, maintenance, automatic webhook setup and the importing of projects.
    - [Backup and restore](raketasks/backup_restore.md): Backup and restore your GitLab instance.
- [Reply by email](administration/reply_by_email.md): Allow users to comment on issues and merge requests by replying to notification emails.
- [Repository checks](administration/repository_checks.md): Periodic Git repository checks.
- [Repository storage paths](administration/repository_storage_paths.md): Manage the paths used to store repositories.
- [Security](security/README.md): Learn what you can do to further secure your GitLab instance.
- [System hooks](system_hooks/system_hooks.md): Notifications when users, projects and keys are changed.

### Troubleshooting

- [Debugging tips](administration/troubleshooting/debug.md): Tips to debug problems when things go wrong
- [Log system](administration/logs.md): Where to look for logs.
- [Sidekiq Troubleshooting](administration/troubleshooting/sidekiq.md): Debug when Sidekiq appears hung and is not processing jobs.

## Contributor documentation

- [Development](development/README.md): All styleguides and explanations how to contribute.
- [Legal](legal/README.md): Contributor license agreements.
- [Writing documentation](development/writing_documentation.md): Contributing to GitLab Docs.
