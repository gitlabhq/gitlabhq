---
description: 'Read through the GitLab User documentation to learn how to use, configure, and customize GitLab and GitLab.com to your own needs.'
---

# User Docs

Welcome to GitLab! We're glad to have you here!

As a GitLab user you'll have access to all the features
your [subscription](https://about.gitlab.com/pricing/)
includes, except [GitLab administrator](../administration/index.md)
settings, unless you have admin privileges to install, configure,
and upgrade your GitLab instance.

Admin privileges for [GitLab.com](https://gitlab.com/) are restricted to the GitLab team.

For more information on configuring GitLab self-managed instances, see [Administrator documentation](../administration/index.md).

## Overview

GitLab is a fully integrated software development platform that enables your team to be transparent, fast, effective, and cohesive from discussion on a new idea to production, all on the same platform.

For more information, see [All GitLab Features](https://about.gitlab.com/features/).

### Concepts

To get familiar with the concepts needed to develop code on GitLab, read the following articles:

- [Demo: Mastering Code Review With GitLab](https://about.gitlab.com/2017/03/17/demo-mastering-code-review-with-gitlab/).
- [GitLab Workflow: An Overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/#gitlab-workflow-use-case-scenario).
- [Tutorial: It's all connected in GitLab](https://about.gitlab.com/2016/03/08/gitlab-tutorial-its-all-connected/): an overview on code collaboration with GitLab.
- [Trends in Version Control Land: Microservices](https://about.gitlab.com/2016/08/16/trends-in-version-control-land-microservices/).
- [Trends in Version Control Land: Innersourcing](https://about.gitlab.com/2016/07/07/trends-version-control-innersourcing/).

## Use cases

GitLab is a Git-based platform that integrates a great number of essential tools for software development and deployment, and project management:

- Hosting code in repositories with version control.
- Tracking proposals for new implementations, bug reports, and feedback with a
  fully featured [Issue Tracker](project/issues/index.md#issues-list).
- Organizing and prioritizing with [Issue Boards](project/issues/index.md#issue-boards).
- Reviewing code in [Merge Requests](project/merge_requests/index.md) with live-preview changes per
  branch with [Review Apps](../ci/review_apps/index.md).
- Building, testing, and deploying with built-in [Continuous Integration](../ci/README.md).
- Deploying personal and professional static websites with [GitLab Pages](project/pages/index.md).
- Integrating with Docker by using [GitLab Container Registry](project/container_registry.md).
- Tracking the development lifecycle by using [GitLab Cycle Analytics](project/cycle_analytics.md).

With GitLab Enterprise Edition, you can also:

- Provide support with [Service Desk](project/service_desk.md).
- Improve collaboration with
  [Merge Request Approvals](project/merge_requests/index.md#merge-request-approvals-starter),
  [Multiple Assignees for Issues](project/issues/multiple_assignees_for_issues.md),
  and [Multiple Issue Boards](project/issue_board.md#multiple-issue-boards).
- Create formal relationships between issues with [Related Issues](project/issues/related_issues.md).
- Use [Burndown Charts](project/milestones/burndown_charts.md) to track progress during a sprint or while working on a new version of their software.
- Leverage [Elasticsearch](../integration/elasticsearch.md) with [Advanced Global Search](search/advanced_global_search.md) and [Advanced Syntax Search](search/advanced_search_syntax.md) for faster, more advanced code search across your entire GitLab instance.
- [Authenticate users with Kerberos](../integration/kerberos.md).
- [Mirror a repository](../workflow/repository_mirroring.md) from elsewhere on your local server.
- [Export issues as CSV](project/issues/csv_export.md).
- View your entire CI/CD pipeline involving more than one project with [Multiple-Project Pipelines](../ci/multi_project_pipeline_graphs.md).
- [Lock files](project/file_lock.md) to prevent conflicts.
- View the current health and status of each CI environment running on Kubernetes with [Deploy Boards](project/deploy_boards.md).
- Leverage continuous delivery method with [Canary Deployments](project/canary_deployments.md).
- Scan your code for vulnerabilities and [display them in merge requests](application_security/sast/index.md).

You can also [integrate](project/integrations/project_services.md) GitLab with numerous third-party applications, such as Mattermost, Microsoft Teams, HipChat, Trello, Slack, Bamboo CI, Jira, and a lot more.

## Projects

In GitLab, you can create [projects](project/index.md) to host
your code, track issues, collaborate on code, and continuously
build, test, and deploy your app with built-in GitLab CI/CD. Or, you can do
it all at once, from one single project.

- [Repositories](project/repository/index.md): Host your codebase in
  repositories with version control and as part of a fully integrated platform.
- [Issues](project/issues/index.md): Explore the best of GitLab Issues' features.
- [Merge Requests](project/merge_requests/index.md): Collaborate on code,
  reviews, live preview changes per branch, and request approvals with Merge Requests.
- [Milestones](project/milestones/index.md): Work on multiple issues and merge
  requests towards the same target date with Milestones.

## GitLab CI/CD

Use built-in [GitLab CI/CD](../ci/README.md) to test, build, and deploy your applications
directly from GitLab. No third-party integrations needed.

- [GitLab Auto Deploy](../ci/autodeploy/index.md): Deploy your application out-of-the-box with GitLab Auto Deploy.
- [Review Apps](../ci/review_apps/index.md): Live-preview the changes introduced by a merge request with Review Apps.
- [GitLab Pages](project/pages/index.md): Publish your static site directly from
  GitLab with GitLab Pages. You can build, test, and deploy any Static Site Generator with Pages.
- [GitLab Container Registry](project/container_registry.md): Build and deploy Docker
  images with Container Registry.

## Account

There is a lot you can customize and configure
to enjoy the best of GitLab.

- [Settings](profile/index.md): Manage your user settings to change your personal info,
  personal access tokens, authorized applications, etc.
- [Authentication](../topics/authentication/index.md): Read through the authentication
  methods available in GitLab.
- [Permissions](permissions.md): Learn the different set of permissions levels for each
  user type (guest, reporter, developer, maintainer, owner).
- [Feature highlight](feature_highlight.md): Learn more about the little blue dots
  around the app that explain certain features.
- [Abuse reports](abuse_reports.md): Report abuse from users to GitLab administrators.

## Groups

With GitLab [Groups](group/index.md) you can assemble related projects together
and grant members access to several projects at once.

Groups can also be nested in [subgroups](group/subgroups/index.md).

## Discussions

In GitLab, you can comment and mention collaborators in issues,
merge requests, code snippets, and commits.

When performing inline reviews to implementations
to your codebase through merge requests you can
gather feedback through [resolvable threads](discussions/index.md#resolvable-comments-and-threads).

### GitLab Flavored Markdown (GFM)

Read through the [GFM documentation](markdown.md) to learn how to apply
the best of GitLab Flavored Markdown in your threads, comments,
issues and merge requests descriptions, and everywhere else GMF is
supported.

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
[Discussions](#Discussions).

## Integrations

[Integrate GitLab](../integration/README.md) with your preferred tool,
such as Trello, Jira, etc.

## Webhooks

Configure [webhooks](project/integrations/webhooks.md) to listen for
specific events like pushes, issues or merge requests. GitLab will send a
POST request with data to the webhook URL.

## API

Automate GitLab via [API](../api/README.md).

## Git and GitLab

Learn what is [Git](../topics/git/index.md) and its best practices.

## Instance statistics

See [various statistics](instance_statistics/index.md) of your GitLab instance.

## Operations Dashboard **(PREMIUM)**

See [Operations Dashboard](operations_dashboard/index.md) for a summary of each
project's operational health.
