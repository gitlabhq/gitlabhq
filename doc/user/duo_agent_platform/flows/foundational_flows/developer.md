---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Developer Flow
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab 18.3 [with a feature flag](../../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci`. Disabled by default, but can be enabled for the instance or a user.
- Renamed from `Issue to MR` to the `Developer Flow` with a flag named `duo_developer_button` in GitLab 18.6. Disabled by default, but can be enabled for the instance or a user. Feature flag `duo_workflow` must also be enabled, but it is enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Feature flags `duo_workflow_in_ci`, `duo_developer_button`, and `duo_workflow` removed in GitLab 18.9.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.
- Mention triggers [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817) in GitLab 18.11.

{{< /history >}}

The Developer Flow helps you work more efficiently across issues and merge requests.
You can use the Developer Flow to:

- Create a draft merge request from an issue.
- Iterate on an existing merge request based on review feedback.
- Research implementation approaches and post findings to a discussion.
- Split a large merge request into smaller, focused merge requests.
- Resolve merge conflicts.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Turn on **Allow foundational flows** and **Developer** [for the top-level group](_index.md#turn-foundational-flows-on-or-off).
- Have the Developer, Maintainer, or Owner role for the project.
- [Configure push rules to allow a service account](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configure your own runners](../execution.md#configure-runners-to-execute-flows) or turn on [GitLab hosted runners](../../../../ci/runners/hosted_runners/_index.md) for your project.

## Set up your project

To help the Developer Flow produce better results, you should configure your project with the following optional settings:

- Add an `AGENTS.md` file: Document your project conventions, such as test commands,
  linting rules, commit format, and coding patterns. The Developer Flow uses this file
  for context when working in your repository.
  For more information, see [AGENTS.md customization files](../../customize/agents_md.md).
- Configure the execution environment: If your project requires specific tooling
  (for example, Go, Python, or Node.js), configure the agent environment with an `agent-config.yml` file.
  With a properly configured environment, the Developer Flow can run tests and verify
  its own changes before committing.
  For more information, see [Configure flow execution](../execution.md).

## Use the flow

Prerequisites:

- The event types **Mention** and **Assign** are [configured](../../triggers/_index.md) in the trigger for the Developer Flow.

### Mention Duo Developer in a discussion

To turn your comment into an actionable task for the Developer Flow, mention `@duo-developer-<namespace>` in a comment. Replace `<namespace>` with your GitLab namespace path (for example, `gitlab-org`).

Depending on the issue or merge request content and the amount of context you provide, the flow can execute the following tasks:

- Code changes
- Merge request and issue creation
- Research an implementation approach and report back or updates accordingly

For example:

```plaintext
@duo-developer-<namespace> research approaches for implementing pagination
on the /users endpoint, then create a draft MR with the most
promising approach.
```

The Developer Flow responds with a link to its session.

Alternatively, to monitor progress, in the left sidebar, select **AI** > **Sessions**.

### Generate a merge request from an issue

To create a merge request from an issue:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Plan** > **Work items**, then filter by **Type** = **Issue**.
1. Select the issue you want to create a merge request for.
1. To create a merge request from the issue, either:
   - Assign the Duo Developer service account to the issue:
     1. In the right sidebar, in the **Assignees** section, select **Edit**.
     1. Type `duo developer` and select it from the search results.
   - Below the issue header, select **Implement work item**.
1. To monitor progress, in the left sidebar, select **AI** > **Sessions**.
1. When the session completes, review the merge request from the link in
   the **Activity** section of the issue.

### Use the flow in Agentic Chat

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20484) in GitLab 19.2 [with a feature flag](../../../../administration/feature_flags/_index.md) named `agentic_foundational_flow_tool`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

You can use the Developer Flow in a GitLab Duo Agentic Chat conversation to
complete different tasks, such as:

- Accomplish a coding goal. You do not need an issue associated with
  this goal.
- Resolve an issue by opening a merge request.

To use the flow in an Agentic Chat conversation:

1. In the top bar, select **Search or go to** and find your project.
1. In the GitLab Duo sidebar, open a new or existing Agentic Chat conversation.
1. Ask Agentic Chat to use the Developer Flow to accomplish a task.

   The flow progress is displayed in the Chat conversation. For more information,
   you can do the following:
   - Select **View Agent Session** in the conversation.
   - In the left sidebar, select **AI** > **Sessions**.

## Best practices

### Provide clear context

The Developer Flow only knows what you tell it or what is available
in the context of the issue, merge request, Chat conversation, or discussion thread.
The same practices that help a human collaborator apply here:

- Write a clear problem description with links to relevant files or discussions.
- Include acceptance criteria that define what "done" looks like.
- Specify exact file paths when you know them.
- Include code examples of existing patterns to maintain consistency.

### Be explicit when mentioning Duo Developer in discussions

When you mention Duo Developer in a discussion, tell it exactly
what you want it to do. For example:

- "Create a draft merge request that implements pagination for the `/api/users` endpoint."
- "Address the review feedback on this merge request."
- "Split the logging changes into a separate merge request."
- "Research approaches for migrating this service to gRPC and post your findings here."
- "There are merge conflicts on this merge request. Please resolve them."

Without explicit instructions, the flow chooses its own approach,
which might not match your expectations.

### Keep tasks focused

Break down complex tasks into smaller, focused, and action-oriented requests.
Large, open-ended tasks are more likely to hit iteration limits.

## Examples

### Issue for generating a merge request

This example shows a well-crafted issue that the Developer Flow can use
to generate a merge request.

```plaintext
## Description
The users endpoint currently returns all users at once,
which will cause performance issues as the user base grows.
Implement cursor-based pagination for the `/api/users` endpoint
to handle large datasets efficiently.

## Implementation plan
Add pagination to GET /users API endpoint.
Include pagination metadata in /users API response (per_page, page).
Add query parameters for per page size limit (default 5, max 20).

#### Files to modify
- `src/api/users.py` - Add pagination parameters and logic.
- `src/models/user.py` - Add pagination query method.
- `tests/api/test_users_api.py` - Add pagination tests.

## Acceptance criteria
- Accepts page and per_page query parameters (default: page=5, per_page=10).
- Limits per_page to a maximum of 20 users.
- Maintains existing response format for user objects in data array.
```

### Iterate on merge request review feedback

After reviewing a merge request, you can mention the Developer Flow
to address your feedback. For example, in a review comment on a specific line:

```plaintext
@duo-developer-<namespace> move this validation logic into the `BaseService` class
in `app/services/base_service.rb` instead of duplicating it here.
```

You can also submit a full review and then mention the Developer Flow
to address all open threads:

```plaintext
@duo-developer-<namespace> please address the review feedback on this MR.
```

### Split a merge request

If a merge request has grown too large, you can ask the Developer Flow
to extract part of it into a separate merge request:

```plaintext
@duo-developer-<namespace> the logging changes in this MR are out of scope.
Split them into a separate MR.
```

### Research an implementation approach

You can ask the Developer Flow to investigate a problem and report back
before making any changes:

```plaintext
@duo-developer-<namespace> research whether the `PUT /api/users` endpoint also needs
rate limiting like we added to the `POST /api/users` endpoint.
Post your findings here.
```

### Use the Developer Flow in Agentic Chat

You can use the Developer Flow in an Agentic Chat conversation to
complete different tasks:

- To accomplish a coding goal, you can enter the following:
  - `Use the developer flow to resolve this code review feedback.`
  - `Use the developer flow to update this dependency.`
- To resolve an issue by opening a merge request, you can enter the following:
  - `Resolve this issue.`
  - `Open a merge request to resolve this issue.`
