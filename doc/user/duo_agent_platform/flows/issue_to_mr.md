---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Issue to Merge Request Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../../policy/development_stages_support.md) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci`. Disabled by default, but can be enabled for the instance or a user.
- The `duo_workflow` flag must also be enabled, but it is enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The Issue to Merge Request Flow streamlines the process of converting issues into actionable merge requests. This flow:

- Analyzes the issue description and requirements.
- Opens a draft merge request that's linked to the original issue.
- Creates a development plan based on the issue details.
- Creates code structure or implementation.
- Updates the merge request with the code changes.

This flow is available in the GitLab UI only.

## Prerequisites

To create a merge request from an issue, you must:

- Have an existing GitLab issue with clear requirements.
- Have at least the Developer role in the project.
- Meet [the other prerequisites](../../duo_agent_platform/_index.md#prerequisites).
- Configure push rules to allow the GitLab Duo service account (if push rules are enabled).

### Configure push rules for GitLab Duo

The Issue to Merge Request Flow uses a service account that:

- Creates commits with its own email address.
- Creates branches with the `workloads/` prefix (for example, `workloads/a1b2c3d4e5f`).

If your project or instance has [push rules](../../project/repository/push_rules.md) enabled,
you must configure them to allow the GitLab Duo service account to create commits and branches.

To configure push rules for a project:

1. Find the email address associated with the service account:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. Select **Overview** > **Users** and search for `duo-developer`.
   1. Locate the `duo-developer` user and copy the email address.

1. Allow the email address to push to the project:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Settings** > **Repository**.
   1. Expand **Push rules**.
   1. In **Commit author's email**, add a regular expression that allows the email address you just copied.
   1. Select **Save push rules**.

1. Allow the `workloads/` branch prefix:
   1. In the **Push rules** section, find **Branch name**.
   1. Add a regular expression that allows branches starting with `workloads/`.
      For example: `^workloads/.*$`
   1. Select **Save push rules**.

If you are an administrator, you can create push rules for the instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Push rules**.
1. Follow the previous steps to allow **Commit author's email** and **Branch name**.
1. Select **Save push rules**.

For more information about push rules, see the [push rules documentation](../../project/repository/push_rules.md).

## Use the flow

To convert your issue to a merge request:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Issues**.
1. Select the issue you want to create a merge request for.
1. Below the issue header, select **Generate MR with Duo**.
1. Monitor progress by selecting **Automate** > **Sessions**.
1. When the pipeline has successfully executed, a link to the merge request
   is displayed in the issue's activity section.
1. Review the merge request and make changes as needed.

## Best practices

- Keep the issues well-scoped. Break down complex tasks into smaller, focused, and action-oriented requests.
- Specify exact file paths.
- Write specific acceptance criteria.
- Include code examples of existing patterns to maintain consistency.

## Example

This example shows a well-crafted issue that can be used to generate a merge request.

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
