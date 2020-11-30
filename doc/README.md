---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: 'Learn how to use and administer GitLab, the most scalable Git-based fully integrated platform for software development.'
---

<div class="d-none">
  <em>Visit <a href="https://docs.gitlab.com/ee/">docs.gitlab.com</a> for optimized
  navigation, discoverability, and readability.</em>
</div>
<!-- the div above will not display on the docs site but will display on /help -->

# GitLab Docs

Welcome to [GitLab](https://about.gitlab.com/) documentation.

Here you can access the complete documentation for GitLab, the single application for the
[entire DevOps lifecycle](#the-entire-devops-lifecycle).

## Overview

No matter how you use GitLab, we have documentation for you.

| Essential documentation                                                                                                             | Essential documentation                                                                                                    |
|:------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------|
| [**User documentation**](user/index.md)<br>Discover features and concepts for GitLab users.                                         | [**Administrator documentation**](administration/index.md)<br/>Everything GitLab self-managed administrators need to know. |
| [**Contributing to GitLab**](#contributing-to-gitlab)<br/>At GitLab, everyone can contribute!                                       | [**New to Git and GitLab?**](#new-to-git-and-gitlab)<br/>We have the resources to get you started.                         |
| [**Build an integration with GitLab**](#build-an-integration-with-gitlab)<br/>Consult our automation and integration documentation. | [**Coming to GitLab from another platform?**](#coming-to-gitlab-from-another-platform)<br/>Consult our guides.             |
| [**Install GitLab**](https://about.gitlab.com/install/)<br/>Installation options for different platforms.                           | [**Customers**](subscriptions/index.md)<br/>Information for new and existing customers.                                    |
| [**Update GitLab**](update/README.md)<br/>Update your GitLab self-managed instance to the latest version.                           | [**Reference Architectures**](administration/reference_architectures/index.md)<br/>GitLab's reference architectures        |
| [**GitLab releases**](https://about.gitlab.com/releases/)<br/>What's new in GitLab.                                                 |                                                                                                                            |

## Popular topics

Have a look at some of our most popular topics:

| Popular topic                                                                                              | Description                                                                |
|:-----------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------|
| [Two-factor authentication](user/profile/account/two_factor_authentication.md)                             | Improve the security of your GitLab account.                               |
| [GitLab groups](user/group/index.md)                                                                       | Manage projects together.                                                  |
| [GitLab CI/CD pipeline configuration reference](ci/yaml/README.md)                                         | Available configuration options for `.gitlab-ci.yml` files.                |
| [Activate GitLab EE with a license](user/admin_area/license.md) **(STARTER ONLY)**                         | Activate GitLab Enterprise Edition functionality with a license.           |
| [Back up and restore GitLab](raketasks/backup_restore.md) **(CORE ONLY)**                                  | Rake tasks for backing up and restoring GitLab self-managed instances.     |
| [GitLab release and maintenance policy](policy/maintenance.md)                                             | Policies for version naming and cadence, and also upgrade recommendations. |
| [Elasticsearch integration](integration/elasticsearch.md) **(STARTER ONLY)**                               | Integrate Elasticsearch with GitLab to enable advanced searching.          |
| [Omnibus GitLab database settings](https://docs.gitlab.com/omnibus/settings/database.html) **(CORE ONLY)** | Database settings for Omnibus GitLab self-managed instances.               |
| [Omnibus GitLab NGINX settings](https://docs.gitlab.com/omnibus/settings/nginx.html) **(CORE ONLY)**       | NGINX settings for Omnibus GitLab self-managed instances.                  |
| [Omnibus GitLab SSL configuration](https://docs.gitlab.com/omnibus/settings/ssl.html) **(CORE ONLY)**      | SSL settings for Omnibus GitLab self-managed instances.                    |
| [GitLab.com settings](user/gitlab_com/index.md)                                                            | Settings used for GitLab.com.                                              |

## The entire DevOps lifecycle

GitLab is the first single application for software development, security,
and operations that enables [Concurrent DevOps](https://about.gitlab.com/topics/concurrent-devops/),
making the software lifecycle faster and radically improving the speed of business.

GitLab provides solutions for [each of the stages of the DevOps lifecycle](https://about.gitlab.com/stages-devops-lifecycle/):

![DevOps Stages](img/devops-stages-13_3.png)

GitLab is like a top-of-the-line kitchen for making software. As the executive
chef, you decide what software you want to serve. Using your recipe, GitLab handles
all the prep work, cooking, and delivery, so you can turn around orders faster
than ever.

The following sections provide links to documentation for each DevOps stage:

| DevOps stage            | Documentation for                                           |
|:------------------------|:------------------------------------------------------------|
| [Manage](#manage)       | Statistics and analytics features.                          |
| [Plan](#plan)           | Project planning and management features.                   |
| [Create](#create)       | Source code, data creation, and management features.        |
| [Verify](#verify)       | Testing, code quality, and continuous integration features. |
| [Package](#package)     | Docker container registry.                                  |
| [Secure](#secure)       | Security capability features.                               |
| [Release](#release)     | Application release and delivery features.                  |
| [Configure](#configure) | Application and infrastructure configuration tools.         |
| [Monitor](#monitor)     | Application monitoring and metrics features.                |
| [Defend](#defend)       | Protection against security intrusions.                     |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Manage

GitLab provides statistics and insights into ways you can maximize the value of GitLab in your organization.

The following documentation relates to the DevOps **Manage** stage:

| Manage topics                                                                         | Description                                                                |
|:--------------------------------------------------------------------------------------|:---------------------------------------------------------------------------|
| [Authentication and<br/>Authorization](administration/auth/README.md) **(CORE ONLY)** | Supported authentication and authorization providers.                      |
| [GitLab Value Stream Analytics](user/analytics/value_stream_analytics.md)             | Measure the time it takes to go from an [idea to production](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#from-idea-to-production-with-gitlab) for each project you have. |
| [Instance-level analytics](user/admin_area/analytics/index.md)                        | Discover statistics on how many GitLab features you use and user activity. |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Plan

Whether you use Waterfall, Agile, or Conversational Development, GitLab streamlines your collaborative workflows.

Visualize, prioritize, coordinate, and track your progress your way with GitLab’s flexible project
management tools.

The following documentation relates to the DevOps **Plan** stage:

| Plan topics                                                                  | Description                                                                                                                    |
|:-----------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------|
| [Burndown charts](user/project/milestones/burndown_charts.md) **(STARTER)**  | Watch your project's progress throughout a specific milestone.                                                                 |
| [Discussions](user/discussions/index.md)                                     | Threads, comments, and resolvable threads in issues, commits, and merge requests.                                              |
| [Due dates](user/project/issues/due_dates.md)                                | Keep track of issue deadlines.                                                                                                 |
| [Epics](user/group/epics/index.md) **(ULTIMATE)**                            | Tracking groups of issues that share a theme.                                                                                  |
| [Issues](user/project/issues/index.md), including [confidential issues](user/project/issues/confidential_issues.md),<br/>[issue and merge request templates](user/project/description_templates.md),<br/>and [moving issues](user/project/issues/managing_issues.md#moving-issues) | Project issues and restricting access to issues as well as creating templates for submitting new issues and merge requests. Also, moving issues between projects. |
| [Labels](user/project/labels.md)                                             | Categorize issues or merge requests with descriptive labels.                                                                   |
| [Milestones](user/project/milestones/index.md)                               | Set milestones for delivery of issues and merge requests, with optional due date.                                              |
| [Project Issue Board](user/project/issue_board.md)                           | Display issues on a Scrum or Kanban board.                                                                                     |
| [Quick Actions](user/project/quick_actions.md)                               | Shortcuts for common actions on issues or merge requests, replacing the need to click buttons or use dropdowns in GitLab's UI. |
| [Related issues](user/project/issues/related_issues.md)                      | Create a relationship between issues.                                                                                          |
| [Requirements Management](user/project/requirements/index.md) **(ULTIMATE)** | Check your products against a set of criteria.                                                                                 |
| [Roadmap](user/group/roadmap/index.md) **(ULTIMATE)**                        | Visualize epic timelines.                                                                                                      |
| [Service Desk](user/project/service_desk.md)                                 | A simple way to allow people to create issues in your GitLab instance without needing their own user account.                  |
| [Time Tracking](user/project/time_tracking.md)                               | Track time spent on issues and merge requests.                                                                                 |
| [To-Do list](user/todos.md)                                                  | Keep track of work requiring attention with a chronological list displayed on a simple dashboard.                              |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Create

Consolidate source code into a single [distributed version control system](https://en.wikipedia.org/wiki/Distributed_version_control)
that’s easily managed and controlled without disrupting your workflow.

GitLab repositories come complete with branching tools and access
controls, providing a scalable, single source of truth for collaborating
on projects and code.

The following documentation relates to the DevOps **Create** stage:

#### Projects and groups

| Create topics - Projects and Groups                                                | Description                                                                                      |
|:-----------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------|
| [Advanced search](user/search/advanced_global_search.md) **(STARTER)**             | Leverage Elasticsearch for faster, more advanced code search across your entire GitLab instance. |
| [Advanced syntax search](user/search/advanced_search_syntax.md) **(STARTER)**      | Use advanced queries for more targeted search results.                                           |
| [Contribution analytics](user/group/contribution_analytics/index.md) **(STARTER)** | See detailed statistics of group contributors.                                                   |
| [Create](gitlab-basics/create-project.md) and [fork](gitlab-basics/fork-project.md) projects, and<br/>[import and export projects<br/>between instances](user/project/settings/import_export.md) | Create, duplicate, and move projects. |
| [File locking](user/project/file_lock.md) **(PREMIUM)**                            | Lock files to avoid merge conflicts.                                                             |
| [GitLab Pages](user/project/pages/index.md)                                        | Build, test, and deploy your static website with GitLab Pages.                                   |
| [Groups](user/group/index.md) and [Subgroups](user/group/subgroups/index.md)       | Organize your projects in groups.                                                                |
| [Issue analytics](user/group/issues_analytics/index.md) **(PREMIUM)**              | Check how many issues were created per month.                                                    |
| [Merge Request analytics](user/analytics/merge_request_analytics.md) **(PREMIUM)** | Check your throughput productivity - how many merge requests were merged per month.              |
| [Projects](user/project/index.md), including [project access](public_access/public_access.md)<br/>and [settings](user/project/settings/index.md) | Host source code, and control your project's visibility and set configuration. |
| [Search through GitLab](user/search/index.md)                                      | Search for issues, merge requests, projects, groups, and to-dos.                                 |
| [Snippets](user/snippets.md)                                                       | Snippets allow you to create little bits of code.                                                |
| [Web IDE](user/project/web_ide/index.md)                                           | Edit files within GitLab's user interface.                                                       |
| [Static Site Editor](user/project/static_site_editor/index.md)                     | Edit content on static websites.                                                                 |
| [Wikis](user/project/wiki/index.md)                                                | Enhance your repository documentation with built-in wikis.                                       |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### Repositories

| Create topics - Repositories                                                                                                             | Description                                                      |
|:-----------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------|
| [Branches](user/project/repository/branches/index.md) and the [default branch](user/project/repository/branches/index.md#default-branch) | How to use branches in GitLab.                                   |
| [Commits](user/project/repository/index.md#commits) and [signing commits](user/project/repository/gpg_signed_commits/index.md)           | Work with commits, and use GPG to sign your commits.             |
| [Create branches](user/project/repository/web_editor.md#create-a-new-branch), [create](user/project/repository/web_editor.md#create-a-file)<br/>and [upload](user/project/repository/web_editor.md#upload-a-file) files, and [create directories](user/project/repository/web_editor.md#create-a-directory) | Create branches, create and upload files, and create directories within GitLab. |
| [Delete merged branches](user/project/repository/branches/index.md#delete-merged-branches)                                               | Bulk delete branches after their changes are merged.             |
| [File templates](user/project/repository/web_editor.md#template-dropdowns)                                                               | File templates for common files.                                 |
| [Files](user/project/repository/index.md#files)                                                                                          | Files management.                                                |
| [Jupyter Notebook files](user/project/repository/jupyter_notebooks/index.md#jupyter-notebook-files)                                      | GitLab's support for `.ipynb` files.                             |
| [Protected branches](user/project/protected_branches.md)                                                                                 | Use protected branches.                                          |
| [Push rules](push_rules/push_rules.md) **(STARTER)**                                                                                     | Additional control over pushes to your projects.                 |
| [Repositories](user/project/repository/index.md)                                                                                         | Manage source code repositories in GitLab's user interface.      |
| [Repository mirroring](user/project/repository/repository_mirroring.md) **(STARTER)**                                                    | Push to or pull from repositories outside of GitLab              |
| [Start a merge request](user/project/repository/web_editor.md#tips)                                                                      | Start merge request when committing via GitLab's user interface. |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### Merge requests

| Create topics - Merge Requests                                                                     | Description                                                                                                                           |
|:---------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------|
| [Checking out merge requests locally](user/project/merge_requests/reviewing_and_managing_merge_requests.md#checkout-merge-requests-locally-through-the-head-ref) | Tips for working with merge requests locally.                           |
| [Cherry-picking](user/project/merge_requests/cherry_pick_changes.md)                               | Use GitLab for cherry-picking changes.                                                                                                |
| [Merge request thread resolution](user/discussions/index.md#moving-a-single-thread-to-a-new-issue) | Resolve threads, move threads in a merge request to an issue, and only allow merge requests to be merged if all threads are resolved. |
| [Merge requests](user/project/merge_requests/index.md)                                             | Merge request management.                                                                                                             |
| [Draft merge requests](user/project/merge_requests/work_in_progress_merge_requests.md)             | Prevent merges of draft merge requests.                                                                                               |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### Integration and Automation

| Create topics - Integration and Automation                      | Description                                                                                                            |
|:----------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------|
| [GitLab REST API](api/README.md)                                | Integrate with GitLab using our REST API.                                                                              |
| [GitLab GraphQL API](api/graphql/index.md)                      | Integrate with GitLab using our GraphQL API.                                                                           |
| [GitLab integrations](integration/README.md)                    | Integrate with multiple third-party services with GitLab to allow external issue trackers and external authentication. |
| [GitLab Webhooks](user/project/integrations/webhooks.md)        | Let GitLab notify you when new code has been pushed to your project.                                                   |
| [Jira Development Panel](integration/jira_development_panel.md) | See GitLab information in the Jira Development Panel.                                                                  |
| [Integrations](user/project/integrations/overview.md)           | Integrate a project with external services, such as CI and chat.                                                       |
| [Trello Power-Up](integration/trello_power_up.md)               | Integrate with GitLab's Trello Power-Up.                                                                               |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Verify

Spot errors sooner, improve security and shorten feedback cycles with built-in
static code analysis, code testing, code quality, dependency checking, and Review
Apps. Customize your approval workflow controls, automatically test the quality
of your code, and spin up a staging environment for every code change.

GitLab Continuous Integration is the most popular next generation testing system that
scales to run your tests faster.

The following documentation relates to the DevOps **Verify** stage:

| Verify topics                                                          | Description                                                                                             |
|:-----------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------|
| [Code Quality reports](user/project/merge_requests/code_quality.md)    | Analyze source code quality.                                                                            |
| [GitLab CI/CD](ci/README.md)                                           | Explore the features and capabilities of Continuous Integration with GitLab.                            |
| [Unit test reports](ci/unit_test_reports.md)                           | Display Unit test reports on merge requests.                                                            |
| [Multi-project pipelines](ci/multi_project_pipelines.md) **(PREMIUM)** | Visualize entire pipelines that span multiple projects, including all cross-project inter-dependencies. |
| [Pipeline graphs](ci/pipelines/index.md#visualize-pipelines)           | Visualize builds.                                                                                       |
| [Review Apps](ci/review_apps/index.md)                                 | Preview changes to your application right from a merge request.                                         |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Package

GitLab Packages allows organizations to use GitLab as a private repository
for a variety of common package managers. Users are able to build and publish
packages, which can be consumed as a dependency in downstream projects.

The following documentation relates to the DevOps **Package** stage:

| Package topics                                                  | Description                                                                                                                            |
|:----------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| [Container Registry](user/packages/container_registry/index.md) | The GitLab Container Registry enables every project in GitLab to have its own space to store [Docker](https://www.docker.com/) images. |
| [Dependency Proxy](user/packages/dependency_proxy/index.md)     | The GitLab Dependency Proxy sets up a local proxy for frequently used upstream images/packages.                                        |
| [Package Registry](user/packages/package_registry/index.md)     | Use GitLab as a private or public registry for a variety of common package managers, including [NPM](user/packages/npm_registry/index.md), [Maven](user/packages/maven_repository/index.md), [PyPI](user/packages/pypi_repository/index.md), and others. You can also store generic files. |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Secure

Check your application for security vulnerabilities that may lead to unauthorized access, data
leaks, or denial of service. GitLab can perform static and dynamic tests on your application's code,
looking for known flaws and reporting them in the merge request. You can then fix flaws prior to
merge. Security teams can use dashboards to get a high-level view on projects and groups, and start
remediation processes when needed.

The following documentation relates to the DevOps **Secure** stage:

| Secure topics                                                                                                                 | Description                                                            |
|:------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------|
| [Compliance Dashboard](user/compliance/compliance_dashboard/index.md) **(ULTIMATE)**                                          | View the most recent Merge Request activity in a group.                |
| [Container Scanning](user/application_security/container_scanning/index.md) **(ULTIMATE)**                                    | Use Clair to scan Docker images for known vulnerabilities.             |
| [Dependency List](user/application_security/dependency_list/index.md) **(ULTIMATE)**                                          | View your project's dependencies and their known vulnerabilities.      |
| [Dependency Scanning](user/application_security/dependency_scanning/index.md) **(ULTIMATE)**                                  | Analyze your dependencies for known vulnerabilities.                   |
| [Dynamic Application Security Testing (DAST)](user/application_security/dast/index.md) **(ULTIMATE)**                         | Analyze running web applications for known vulnerabilities.            |
| [Group Security Dashboard](user/application_security/security_dashboard/index.md#group-security-dashboard) **(ULTIMATE)**     | View vulnerabilities in all the projects in a group and its subgroups. |
| [Instance Security Center](user/application_security/security_dashboard/index.md#instance-security-center) **(ULTIMATE)**     | View vulnerabilities in all the projects you're interested in.         |
| [License Compliance](user/compliance/license_compliance/index.md) **(ULTIMATE)**                                              | Search your project's dependencies for their licenses.                 |
| [Pipeline Security](user/application_security/security_dashboard/index.md#pipeline-security) **(ULTIMATE)**                   | View the security reports for your project's pipelines.                |
| [Project Security Dashboard](user/application_security/security_dashboard/index.md#project-security-dashboard) **(ULTIMATE)** | View the latest security reports for your project.                     |
| [Static Application Security Testing (SAST)](user/application_security/sast/index.md) **(ULTIMATE)**                          | Analyze source code for known vulnerabilities.                         |

### Release

Spend less time configuring your tools, and more time creating. Whether you’re
deploying to one server or thousands, build, test, and release your code
confidently and securely with GitLab’s built-in Continuous Delivery and Deployment.

The following documentation relates to the DevOps **Release** stage:

| Release topics                                                                                                 | Description                                                                                                                           |
|:---------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------|
| [Auto Deploy](topics/autodevops/stages.md#auto-deploy)                                                         | Configure GitLab for the deployment of your application.                                                                              |
| [Canary Deployments](user/project/canary_deployments.md) **(PREMIUM)**                                         | Employ a popular CI strategy where a small portion of the fleet is updated to the new version first.                                  |
| [Deploy Boards](user/project/deploy_boards.md) **(PREMIUM)**                                                   | View the current health and status of each CI environment running on Kubernetes, displaying the status of the pods in the deployment. |
| [Environments and deployments](ci/environments/index.md)                                                       | With environments, you can control the continuous deployment of your software within GitLab.                                          |
| [Environment-specific variables](ci/variables/README.md#limit-the-environment-scopes-of-environment-variables) | Limit the scope of variables to specific environments.                                                                                |
| [GitLab CI/CD](ci/README.md)                                                                                   | Explore the features and capabilities of Continuous Deployment and Delivery with GitLab.                                              |
| [GitLab Pages](user/project/pages/index.md)                                                                    | Build, test, and deploy a static site directly from GitLab.                                                                           |
| [Protected runners](ci/runners/README.md#prevent-runners-from-revealing-sensitive-information)                 | Select Runners to only pick jobs for protected branches and tags.                                                                     |
| [Schedule pipelines](ci/pipelines/schedules.md)                                                                | Execute pipelines on a schedule.                                                                                                      |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Configure

Automate your entire workflow from build to deploy and monitoring with GitLab
Auto DevOps. Best practice templates help get you started with minimal to zero
configuration. Then customize everything from buildpacks to CI/CD.

The following documentation relates to the DevOps **Configure** stage:

| Configure topics                                                                              | Description                                                               |
|:----------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------|
| [Auto DevOps](topics/autodevops/index.md)                                                     | Automatically employ a complete DevOps lifecycle.                         |
| [Create Kubernetes clusters](user/project/clusters/add_remove_clusters.md#create-new-cluster) | Use Kubernetes and GitLab.                                                |
| [Executable Runbooks](user/project/clusters/runbooks/index.md)                                | Documented procedures that explain how to carry out particular processes. |
| [GitLab ChatOps](ci/chatops/README.md)                                                        | Interact with CI/CD jobs through chat services.                           |
| [Installing applications](user/project/clusters/index.md#installing-applications)             | Install Helm charts such as Ingress and Prometheus on Kubernetes.         |
| [Mattermost slash commands](user/project/integrations/mattermost_slash_commands.md)           | Enable and use slash commands from within Mattermost.                     |
| [Multiple Kubernetes clusters](user/project/clusters/index.md#multiple-kubernetes-clusters)   | Associate more than one Kubernetes clusters to your project.              |
| [Protected variables](ci/variables/README.md#protect-a-custom-variable)                       | Restrict variables to protected branches and tags.                        |
| [Serverless](user/project/clusters/serverless/index.md)                                       | Run serverless workloads on Kubernetes.                                   |
| [Slack slash commands](user/project/integrations/slack_slash_commands.md)                     | Enable and use slash commands from within Slack.                          |
| [Manage your infrastructure with Terraform](user/infrastructure/index.md)                     | Manage your infrastructure as you run your CI/CD pipeline.                |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Monitor

Ensure your applications are always responsive and available.

GitLab collects and displays performance metrics for deployed applications so you can know in an
instant how code changes impact your production environment.

The following documentation relates to the DevOps **Monitor** stage:

| Monitor topics                                                                                  | Description                                                                                                                              |
|:------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------|
| [GitLab Performance Monitoring](administration/monitoring/performance/index.md) **(CORE ONLY)** | Use Prometheus and Grafana to monitor the performance of your GitLab instance.                                                           |
| [GitLab Prometheus](administration/monitoring/prometheus/index.md) **(CORE ONLY)**              | Configure the bundled Prometheus to collect various metrics from your GitLab instance.                                                   |
| [Health check](user/admin_area/monitoring/health_check.md)                                      | GitLab provides liveness and readiness probes to indicate service health and reachability to required services.                          |
| [Prometheus project integration](user/project/integrations/prometheus.md)                       | Configure the Prometheus integration per project and monitor your CI/CD environments.                                                    |
| [Prometheus metrics](user/project/integrations/prometheus_library/index.md)                     | Let Prometheus collect metrics from various services, like Kubernetes, NGINX, NGINX Ingress controller, HAProxy, and Amazon Cloud Watch. |
| [Incident management](operations/incident_management/index.md)                                  | Use GitLab to help you better respond to incidents that may occur in your systems.                                                       |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Defend

GitLab Defend enables organizations to proactively protect cloud-native environments by providing
context-aware technologies to reduce overall security risk. Defend is a natural extension of your
existing operation's practices and provides security visibility across the entire DevSecOps
lifecycle. This visibility empowers your organization to apply DevSecOps best practices from the
first line of code written and extends all the way through to greater monitoring and protection for
your applications that are deployed in production.

The following documentation relates to the DevOps **Defend** stage:

| Defend topics                                                                                | Description                                                                          |
|:---------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------|
| [Web Application Firewall with ModSecurity](user/compliance/compliance_dashboard/index.md)   | Filter, monitor, and block HTTP traffic to and from a web application.               |
| [Container host security](user/clusters/applications.md#install-falco-using-gitlab-cicd)     | Detect and respond to security threats at the Kubernetes, network, and host level.   |
| [Container network security](user/clusters/applications.md#install-cilium-using-gitlab-cicd) | Detect and block unauthorized network traffic between pods and to/from the internet. |

## New to Git and GitLab?

Working with new systems can be daunting.

We have the following documentation to rapidly uplift your GitLab knowledge:

| Topic                                                                                             | Description                                                    |
|:--------------------------------------------------------------------------------------------------|:---------------------------------------------------------------|
| [GitLab basics guides](gitlab-basics/README.md)                                                   | Start working on the command line and with GitLab.             |
| [GitLab workflow overview](https://about.gitlab.com/blog/2016/10/25/gitlab-workflow-an-overview/) | Enhance your workflow with the best of GitLab Workflow.        |
| [Get started with GitLab CI/CD](ci/quick_start/README.md)                                         | Quickly implement GitLab CI/CD.                                |
| [Auto DevOps](topics/autodevops/index.md)                                                         | Learn more about GitLab's Auto DevOps.                         |
| [GitLab Markdown](user/markdown.md)                                                               | GitLab's advanced formatting system (GitLab Flavored Markdown) |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### User account

Learn more about GitLab account management:

| Topic                                                      | Description                                                                                                                |
|:-----------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------|
| [User account](user/profile/index.md)                      | Manage your account.                                                                                                       |
| [Authentication](topics/authentication/index.md)           | Account security with two-factor authentication, set up your SSH keys, and deploy keys for secure access to your projects. |
| [Profile settings](user/profile/index.md#profile-settings) | Manage your profile settings, two factor authentication, and more.                                                         |
| [User permissions](user/permissions.md)                    | Learn what each role in a project can do.                                                                                  |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Git and GitLab

Learn more about using Git, and using Git with GitLab:

| Topic                                                                        | Description                                                                |
|:-----------------------------------------------------------------------------|:---------------------------------------------------------------------------|
| [Git](topics/git/index.md)                                                   | Getting started with Git, branching strategies, Git LFS, and advanced use. |
| [Git cheat sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf) | Download a PDF describing the most used Git operations.                    |
| [GitLab Flow](topics/gitlab_flow.md)                                         | Explore the best of Git with the GitLab Flow strategy.                     |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Coming to GitLab from another platform

If you are coming to GitLab from another platform, the following information is useful:

| Topic                                               | Description                                                                            |
|:----------------------------------------------------|:---------------------------------------------------------------------------------------|
| [Importing to GitLab](user/project/import/index.md) | Import your projects from GitHub, Bitbucket, GitLab.com, FogBugz, and SVN into GitLab. |
| [Migrating from SVN](user/project/import/svn.md)    | Convert a SVN repository to Git and GitLab.                                            |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Build an integration with GitLab

There are many ways to integrate with GitLab, including:

| Topic                                                      | Description                                    |
|:-----------------------------------------------------------|:-----------------------------------------------|
| [GitLab REST API](api/README.md)                           | Integrate with GitLab using our REST API.      |
| [GitLab GraphQL API](api/graphql/index.md)                 | Integrate with GitLab using our GraphQL API.   |
| [Integrations and automation](#integration-and-automation) | All GitLab integration and automation options. |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Contributing to GitLab

GitLab Community Edition is [open source](https://gitlab.com/gitlab-org/gitlab-foss/)
and GitLab Enterprise Edition is [open-core](https://gitlab.com/gitlab-org/gitlab/).

Learn how to contribute to GitLab with the following resources:

| Topic                                                       | Description                              |
|:------------------------------------------------------------|:-----------------------------------------|
| [Development](development/README.md)                        | How to contribute to GitLab development. |
| [Legal](legal/README.md)                                    | Contributor license agreements.          |
| [Writing documentation](development/documentation/index.md) | How to contribute to GitLab Docs.        |

<div align="right">
  <a type="button" class="btn btn-default" href="#overview">
    Back to Overview <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>
