---
stage: none
group: none
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Get started extending GitLab
---

Interact programmatically with GitLab.
Automate tasks, integrate with other tools, and create custom workflows.
GitLab also supports plugins and custom hooks.

Follow these steps to learn more about extending GitLab.

## Step 1: Set up integrations

GitLab has several major integrations that can help streamline your development workflow.

These integrations cover a variety of areas, including:

- **Authentication:** OAuth, SAML, LDAP
- **Planning:** Jira, Bugzilla, Redmine, Pivotal Tracker
- **Communication:** Slack, Microsoft Teams, Mattermost
- **Security:** Checkmarx, Veracode, Fortify

For more information, see:

- [The list of integrations](../../integration/_index.md)

## Step 2: Set up webhooks

Use webhooks to notify external services about GitLab events.

Webhooks listen for specific events like pushes, merges, and commits.
When one of those events occurs, GitLab sends an HTTP POST payload to the webhook's configured URL.
The payload sent by the webhook provides details about the event,
like the event name, project ID, and user and commit details.
Then the external system identifies and processes the event.

As an example, you can have a webhook that triggers a new Jenkins build every time code is pushed to GitLab.

You can configure webhooks per project or for the entire GitLab instance.
Per-project webhooks listen to events for one particular project.

You can use webhooks to integrate GitLab with a variety of external tools,
including CI/CD systems, chat and messaging platforms, and monitoring and logging tools.

For more information, see:

- [Webhooks](../../user/project/integrations/webhooks.md)

## Step 3: Use the APIs

Use the REST API or GraphQL API to interact programmatically with GitLab
and build custom integrations, retrieve data, or automate processes.
The APIs cover various aspects of GitLab, including projects, issues,
merge requests, and repositories.

The GitLab REST APIs follow RESTful principles and use JSON as the data format for requests and responses.
You can authenticate these requests and responses by using personal access tokens or OAuth 2.0 tokens.

GitLab also offers a GraphQL API, which is more flexible and efficient when querying data.

Start by exploring the APIs with cURL or a REST client
to understand the requests and responses.
Then use the API to automate tasks, like creating projects and adding members to groups.

For more information, see:

- [The REST API](../api_resources.md)
- [The GraphQL API](../graphql/reference/_index.md)

## Step 4: Use the GitLab CLI

The GitLab CLI can help you complete various GitLab operations and manage your GitLab instance.

You can use the GitLab CLI to do all kinds of bulk tasks more quickly, like:

- Creating new projects, groups, and other GitLab resources
- Managing users and permissions
- Importing and exporting projects between GitLab instances
- Triggering CI/CD pipelines

For more information, see:

- [Install the GitLab CLI](https://gitlab.com/gitlab-org/cli/#installation)
