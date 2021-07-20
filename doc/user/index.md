---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, index
description: 'Read through the GitLab User documentation to learn how to use, configure, and customize GitLab and GitLab.com to your own needs.'
---

# User Docs **(FREE)**

Welcome to GitLab! We're glad to have you here!

As a GitLab user you have access to all the features
your [subscription](https://about.gitlab.com/pricing/)
includes, except [GitLab administrator](../administration/index.md)
settings, unless you have admin privileges to install, configure,
and upgrade your GitLab instance.

Admin privileges for [GitLab.com](https://gitlab.com/) are restricted to the GitLab team.

For more information on configuring GitLab self-managed instances, see the [Administrator documentation](../administration/index.md).

## Overview

GitLab is a fully integrated software development platform that enables your team to be transparent, fast, effective, and cohesive from discussion on a new idea to production, all on the same platform.

For more information, see [All GitLab Features](https://about.gitlab.com/features/).

### Concepts

To get familiar with the concepts needed to develop code on GitLab, read the following articles:

- [Demo: Mastering Code Review With GitLab](https://about.gitlab.com/blog/2017/03/17/demo-mastering-code-review-with-gitlab/).
- [What is GitLab Flow?](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/).
- [Tutorial: It's all connected in GitLab](https://about.gitlab.com/blog/2016/03/08/gitlab-tutorial-its-all-connected/): an overview on code collaboration with GitLab.
- [Trends in Version Control Land: Microservices](https://about.gitlab.com/blog/2016/08/16/trends-in-version-control-land-microservices/).
- [Trends in Version Control Land: Innersourcing](https://about.gitlab.com/topics/version-control/what-is-innersource/).

## Use cases

GitLab is a Git-based platform that integrates a great number of essential tools for software development and deployment, and project management:

- Hosting code in repositories with version control.
- Tracking proposals for new implementations, bug reports, and feedback with a
  fully featured [Issue tracker](project/issues/index.md).
- Organizing and prioritizing with [Issue Boards](project/issue_board.md).
- Reviewing code in [Merge Requests](project/merge_requests/index.md) with live-preview changes per
  branch with [Review Apps](../ci/review_apps/index.md).
- Building, testing, and deploying with built-in [Continuous Integration](../ci/index.md).
- Deploying personal and professional static websites with [GitLab Pages](project/pages/index.md).
- Integrating with Docker by using [GitLab Container Registry](packages/container_registry/index.md).
- Tracking the development lifecycle by using [GitLab Value Stream Analytics](analytics/value_stream_analytics.md).
- Provide support with [Service Desk](project/service_desk.md).
- [Export issues as CSV](project/issues/csv_export.md).

With GitLab Enterprise Edition, you can also:

- Improve collaboration with:
  - [Merge Request Approvals](project/merge_requests/approvals/index.md).
  - [Multiple Assignees for Issues](project/issues/multiple_assignees_for_issues.md).
  - [Multiple Issue Boards](project/issue_board.md#multiple-issue-boards).
- Create formal relationships between issues with [linked issues](project/issues/related_issues.md).
- Use [Burndown Charts](project/milestones/burndown_and_burnup_charts.md) to track progress during a sprint or while working on a new version of their software.
- Leverage [Elasticsearch](../integration/elasticsearch.md) with [Advanced Search](search/advanced_search.md) for faster, more advanced code search across your entire GitLab instance.
- [Authenticate users with Kerberos](../integration/kerberos.md).
- [Mirror a repository](project/repository/repository_mirroring.md) from elsewhere on your local server.
- View your entire CI/CD pipeline involving more than one project with [Multiple-Project Pipelines](../ci/pipelines/multi_project_pipelines.md).
- [Lock files](project/file_lock.md) to prevent conflicts.
- View the current health and status of each CI environment running on Kubernetes with [Deploy Boards](project/deploy_boards.md).
- Leverage continuous delivery method with [Canary Deployments](project/canary_deployments.md).
- Scan your code for vulnerabilities and [display them in merge requests](application_security/sast/index.md).

You can also [integrate](project/integrations/overview.md) GitLab with numerous third-party applications, such as Mattermost, Microsoft Teams, Trello, Slack, Bamboo CI, Jira, and a lot more.

## User types

There are several types of users in GitLab:

- Regular users and GitLab.com users. <!-- Note: further description TBA -->
- [Groups](group/index.md) of users.
- GitLab [admin area](admin_area/index.md) user.
- [GitLab Administrator](../administration/index.md) with full access to
  self-managed instances' features and settings.
- [Internal users](../development/internal_users.md).

## User activity

You can follow or unfollow other users from their [user profiles](profile/index.md#access-your-user-profile).
To view a user's activity in a top-level Activity view:

1. From a user's profile, select **Follow**.
1. In the GitLab menu, select **Activity**.
1. Select the **Followed users** tab.

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

## Account

There is a lot you can customize and configure
to enjoy the best of GitLab.

- [Settings](profile/index.md): Manage your user settings to change your personal information,
  personal access tokens, authorized applications, etc.
- [Authentication](../topics/authentication/index.md): Read through the authentication
  methods available in GitLab.
- [Permissions](permissions.md): Learn the different set of permissions levels for each
  user type (guest, reporter, developer, maintainer, owner).
- [Feature highlight](feature_highlight.md): Learn more about the little blue dots
  around the app that explain certain features.
- [Abuse reports](report_abuse.md): Report abuse from users to GitLab administrators.

## Groups

With GitLab [Groups](group/index.md) you can assemble related projects together
and grant members access to several projects at once.

Groups can also be nested in [subgroups](group/subgroups/index.md).

## Discussions

In GitLab, you can comment and mention collaborators in issues,
merge requests, code snippets, and commits.

When performing inline reviews to implementations
to your codebase through merge requests you can
gather feedback through [resolvable threads](discussions/index.md#resolve-a-thread).

### GitLab Flavored Markdown (GFM)

Read through the [GFM documentation](markdown.md) to learn how to apply
the best of GitLab Flavored Markdown in your threads, comments,
issues and merge requests descriptions, and everywhere else GFM is
supported.

## To-Do List

Never forget to reply to your collaborators. [GitLab To-Do List](todos.md)
is a tool for working faster and more effectively with your team,
by listing all user or group mentions, as well as issues and merge
requests you're assigned to.

## Search

[Search and filter](search/index.md) through groups, projects, issues, merge requests, files, code, and more.

## Snippets

[Snippets](snippets.md) are code blocks that you want to store in GitLab, from which
you have quick access to. You can also gather feedback on them through
[Discussions](#discussions).

## GitLab CI/CD

Use built-in [GitLab CI/CD](../ci/index.md) to test, build, and deploy your applications
directly from GitLab. No third-party integrations needed.

## Features behind feature flags

Understand what [features behind feature flags](feature_flags.md) mean.

## Keyboard shortcuts

There are many [keyboard shortcuts](shortcuts.md) in GitLab to help you navigate between
pages and accomplish tasks faster.

## Integrations

[Integrate GitLab](../integration/index.md) with your preferred tool,
such as Trello, Jira, etc.

## Webhooks

Configure [webhooks](project/integrations/webhooks.md) to listen for
specific events like pushes, issues or merge requests. GitLab sends a
POST request with data to the webhook URL.

## API

Automate GitLab via [API](../api/index.md).

## Git and GitLab

Learn what is [Git](../topics/git/index.md) and its best practices.

## Instance-level analytics

See [various statistics](admin_area/analytics/index.md) of your GitLab instance.

## Operations Dashboard

See [Operations Dashboard](operations_dashboard/index.md) for a summary of each
project's operational health.
