# User documentation

Welcome to GitLab! We're glad to have you here!

As a GitLab user you'll have access to all the features
your [subscription](https://about.gitlab.com/products/)
includes, except [GitLab administrator](../README.md#administrator-documentation)
settings, unless you have admin privileges to install, configure,
and upgrade your GitLab instance.

For GitLab.com, admin privileges are restricted to the GitLab team.

If you run your own GitLab instance and are looking for the administration settings,
please refer to the [administration](../README.md#administrator-documentation)
documentation.

## Overview

GitLab is a fully integrated software development platform that enables you
and your team to work cohesively, faster, transparently, and effectively,
since the discussion of a new idea until taking that idea to production all
all the way through, from within the same platform.

Please check this page for an overview on [GitLab's features](https://about.gitlab.com/features/).

## Use cases

GitLab is a git-based platforms that integrates a great number of essential tools for software development and deployment, and project management:

- Code hosting in repositories with version control
- Track proposals for new implementations, bug reports, and feedback with a
fully featured [Issue Tracker](project/issues/index.md#issue-tracker)
- Organize and prioritize with [Issue Boards](project/issues/index.md#issue-boards)
- Code review in [Merge Requests](project/merge_requests/index.md) with live-preview changes per
branch with [Review Apps](../ci/review_apps/index.md)
- Build, test and deploy with built-in [Continuous Integration](../ci/README.md)
- Deploy your personal and professional static websites with [GitLab Pages](project/pages/index.md)
- Integrate with Docker with [GitLab Container Registry](project/container_registry.md)
- Track the development lifecycle with [GitLab Cycle Analytics](project/cycle_analytics.md)

With GitLab Enterprise Edition, you can also:

- Provide support with [Service Desk](https://docs.gitlab.com/ee/user/project/service_desk.html)
- Improve collaboration with
[Merge Request Approvals](https://docs.gitlab.com/ee/user/project/merge_requests/index.html#merge-request-approvals),
[Multiple Assignees for Issues](https://docs.gitlab.com/ee/user/project/issues/multiple_assignees_for_issues.html),
and [Multiple Issue Boards](https://docs.gitlab.com/ee/user/project/issue_board.html#multiple-issue-boards)
- Create formal relashionships between issues with [Related Issues](https://docs.gitlab.com/ee/user/project/issues/related_issues.html)
- Use [Burndown Charts](https://docs.gitlab.com/ee/user/project/milestones/burndown_charts.html) to track progress during a sprint or while working on a new version of their software.
- Leverage [Elasticsearch](https://docs.gitlab.com/ee/integration/elasticsearch.html) with [Advanced Global Search](https://docs.gitlab.com/ee/user/search/advanced_global_search.html) and [Advanced Syntax Search](https://docs.gitlab.com/ee/user/search/advanced_search_syntax.html) for faster, more advanced code search across your entire GitLab instance
- [Authenticate users with Kerberos](https://docs.gitlab.com/ee/integration/kerberos.html)
- [Mirror a repository](https://docs.gitlab.com/ee/workflow/repository_mirroring.html) from elsewhere on your local server.
- [Export issues as CSV](https://docs.gitlab.com/ee/user/project/issues/csv_export.html)
- View your entire CI/CD pipeline involving more than one project with [Multiple-Project Pipeline Graphs](https://docs.gitlab.com/ee/ci/multi_project_pipeline_graphs.html)
- [Lock files](https://docs.gitlab.com/ee/user/project/file_lock.html) to prevent conflicts
- View of the current health and status of each CI environment running on Kubernetes with [Deploy Boards](https://docs.gitlab.com/ee/user/project/deploy_boards.html)
- Leverage your continuous delivery method with [Canary Deployments](https://docs.gitlab.com/ee/user/project/canary_deployments.html)

You can also [integrate](project/integrations/project_services.md) GitLab with numerous third-party applications, such as Mattermost, Microsoft Teams, HipChat, Trello, Slack, Bamboo CI, JIRA, and a lot more.

### Articles

For a complete workflow use case please check [GitLab Workflow, an Overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/#gitlab-workflow-use-case-scenario).

For more use cases please check our [Technical Articles](../articles/index.md).

## Projects

In GitLab, you can create [projects](project/index.md) for numerous reasons, such as, host
your code, use it as an issue tracker, collaborate on code, and continuously
build, test, and deploy your app with built-in GitLab CI/CD. Or, you can do
it all at once, from one single project.

### Repository

Host your codebase in [GitLab repositories](project/repository/index.md) with version control
and as part of a fully integrated platform.

### Issues

Explore the best of GitLab [Issues](project/issues/index.md).

### Merge Requests

Collanorate on code, gather reviews, live preview changes per branch, and
request approvals with [Merge Requests](project/merge_requests/index.md).

### Milestones

Work on multiple issues and merge requests towards the same target date
with [Milestones](project/milestones/index.md).

### GitLab Pages

Publish your static site directly from GitLab with [GitLab Pages](project/pages/index.md). You
can [build, test, and deploy any Static Site Generator](https://about.gitlab.com/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/) with Pages.

### Container Registry

Build and deploy Docker images with [GitLab Container Registry](project/container_registry.md).

## GitLab CI/CD

Use built-in [GitLab CI/CD](../ci/README.md) to test, build, and deploy your applications
directly from GitLab. No third-party integrations needed.

### Auto Deploy

Deploy your application out-of-the-box with [GitLab Auto Deploy](../ci/autodeploy/index.md).

### Review Apps

Live-preview the changes introduced by a merge request with [Review Apps](../ci/review_apps/index.md).

## Groups

With GitLab [Groups](group/index.md) you can assemble related projects together
and grant members access to several projects at once.

### Subgroups

Groups can also be nested in [subgroups](group/subgroups/index.md).

## Account

There is a lot you can customize and configure
to enjoy the best of GitLab.

[Manage your user settings](profile/index.md) to change your personal info,
personal access tokens, authorized applications, etc.

### Authentication

Read through the [authentication](../topics/authentication/index.md) methods available in GitLab.

### Permissions

Learn the different set of [permissions](permissions.md) for user type (guest, reporter, developer, master, owner).

## Integrations

[Integrate GitLab](../integration/README.md) with your preferred tool,
such as Trello, JIRA, etc.

## Git and GitLab

Learn what is [Git](../topics/git/index.md) and its best practices.

## Discussions

In GitLab, you can comment and mention collaborators in issues,
merge requests, code snippets, and commits.

When performing inline reviews to implementations
to your codebase through merge requests you can
gather feedback through [resolvable discussions](discussions/index.md#resolvable-discussions).

## Todos

Never forget to reply to your collaborators. [GitLab Todos](../workflow/todos.md)
are a tool for working faster and more effectively with your team,
by listing all user or group mentions, as well as issues and merge
requests you're assigned to.

## Search

[Search and filter](search/index.md) through groups, projects, issues, merge requests, files, code, and more.

## Snippets

[Snippets](snippets.md) are code blocks that you want to store in GitLab, from which
you have quick access to. You can also gather feedback on them through
[discussions](#discussions).

## Webhooks

Configure [webhooks](project/integrations/webhooks.html) to listen for
specific events like pushes, issues or merge requests. GitLab will send a
POST request with data to the webhook URL.

## API

Automate GitLab via [API](../api/README.html).

