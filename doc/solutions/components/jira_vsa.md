---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Jira to GitLab VSA Integration
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab [Value Stream Analytics (VSA)](../../user/group/value_stream_analytics/_index.md) provides powerful insights into your development workflow, tracking key metrics such as:

- **Lead time**: Time from issue creation to completion
- **Issues created**: Number of new issues in a given time period
- **Issues closed**: Number of resolved issues in a given time period

For teams using Jira for issue tracking while leveraging GitLab for development, this integration enables automatic replication of Jira issues to GitLab in real-time. This ensures accurate VSA metrics without requiring teams to change their existing Jira workflows.

The integration also populates the GitLab **Value Streams Dashboard** (Ultimate only), which provides an overview of key DevSecOps metrics and can be found under **Analyze** > **Analytics dashboards** in your GitLab project or group.

**NOTE**: A similar integration exists for incident replication to generate specific DORA metrics (Change Failure Rate and Time to Restore Service). If you're interested in incident replication, refer to the [Jira Incident Replicator](jira_dora.md).

## Architecture

We will create 2 automation workflows using Jira automation:

1. Create GitLab issues when they are created in Jira
1. Close GitLab issues when they are resolved in Jira

### Issue Creation

When a new issue is created in Jira, the automation workflow sends a POST request to the GitLab Issues API to create a corresponding issue in the specified GitLab project.

### Issue Resolution

When a Jira issue transitions to a resolved state (Closed, Done, Resolved), the automation workflow sends a PUT request to close the corresponding GitLab issue.

## Setup

### Pre-requisites

This walkthrough assumes that you have:

- A GitLab project where you want VSA analytics to be generated
- A Jira project to replicate issues from
- GitLab Ultimate or Premium license (for Value Stream Analytics features)

Jira places [limits](https://www.atlassian.com/software/jira/pricing) on the frequency of Automation runs depending on your Jira license:

| **Tier**   | **Limit**                    |
|------------|------------------------------|
| Free       | 100 runs per month           |
| Standard   | 1700 runs per month          |
| Premium    | 1000 runs per user per month |
| Enterprise | Unlimited runs               |

Each issue creation counts as 1 run, and each issue resolution counts as 1 run.

### GitLab Project Access Token

First, we need to create a GitLab project access token with the necessary permissions to create and update issues via the API.

1. Navigate to your GitLab project where you want Jira issues to be replicated. From the sidebar, go to **Settings** > **Access Tokens**.
1. Click **Add new token**.
1. Set the following configuration:
   - **Token name**: `Jira VSA Integration` (or any descriptive name)
   - **Expiration date**: Set according to your security policies
   - **Role**: `Owner` (This is required to set custom issue IDs)
   - **Scopes**: Check `api` (full API access)

**Important**: An **Owner** level access token is required because the integration needs to force-set custom issue IDs when creating issues in GitLab. This ensures that when Jira issues are closed, the automation can identify and close the corresponding GitLab issue using the same ID mapping. Without the Owner role, the GitLab API will not allow setting custom issue IDs, breaking the synchronization between Jira issue closure and GitLab issue closure.

1. Click **Create project access token** and save the generated token securely - you'll need it for the Jira automation setup.

### Jira Issue Creation Workflow

To automatically create GitLab issues when Jira issues are created, we'll use [Jira automation](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828).

1. Navigate to your Jira project. From the sidebar, head to **Project settings** > **Automation**.
1. Click **Create rule** in the upper right.
1. For your trigger, search for and select **Issue created**. Click **Save**.
1. *Optional*: Add conditions to filter which issues should be replicated. For example, you might want to add an **Issue fields condition** to only replicate issues of certain types or with specific labels.
1. Select **THEN: Add an action**. Search for and select **Send web request**.
1. Configure the web request:
   - **Web request URL**: `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues` (replace `gitlab.com` with your GitLab instance URL if self-hosted, and `<GITLAB_PROJECT_ID>` with your GitLab project's numerical ID, e.g., `42718690`)
   - **HTTP method**: **POST**
   - **Web request body**: **Custom data**
1. Add the following headers:

    | Name | Value |
    | ------ | ------ |
    | Authorization | Bearer `<YOUR_GITLAB_TOKEN>` |
    | Content-Type | `application/json` |

   Set the Authorization header to "Hidden" for security.

1. In the **Custom data** field, enter:

   ```json
   {
     "title": "{{issue.summary}}",
     "iid": {{issue.key.replace("VSA-", "1000")}}
   }
   ```

   Replace `"VSA-"` with your Jira project prefix (e.g., if your Jira issues are numbered `PROJ-123`, use `"PROJ-"`). The `1000` is a base number that gets added to ensure no conflict with issues that may have been created directly within GitLab itself via the UI - you can adjust this value as needed.

1. Click **Save**, give your automation a descriptive name (e.g., `Jira to GitLab Issue Creation`), and click **Turn it on**.

### Jira Issue Resolution Workflow

Create a second automation workflow to close GitLab issues when Jira issues are resolved:

1. Follow steps 1-2 from the creation workflow to start a new rule.
1. Set the trigger to **Issue transitioned**:
   - Leave "From status" field blank
   - Set "To status" to resolved statuses: `Closed`, `Done`, `Resolved` (adjust based on your Jira workflow)
1. Skip conditions (or add custom ones if needed).
1. Add a **Send web request** action with:
   - **Web request URL**: `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{{issue.key.replace("<JIRA_PROJECT_PREFIX>-", "1000").urlEncode}}` (replace `gitlab.com` with your GitLab instance URL if self-hosted, `<GITLAB_PROJECT_ID>` with your GitLab project's numerical ID, and `<JIRA_PROJECT_PREFIX>` with your Jira project prefix like `VSA` or `PROJ`)
   - **HTTP method**: **PUT**
   - **Web request body**: **Custom data**
1. Use the same headers as the creation workflow.
1. In the **Custom data** field, enter:

   ```json
   {
     "state_event": "close"
   }
   ```

1. Save and enable the automation rule with a descriptive name (e.g., `Jira to GitLab Issue Closer`).

## Value Stream Analytics Configuration

Once your automation workflows are active, GitLab will begin receiving issue data. Here's how to access your analytics:

### Value Streams Dashboard (Automatic - Ultimate Only)

The **Value Streams Dashboard** is automatically populated with metrics from your replicated issues and is available with GitLab Ultimate:

1. In your GitLab project or group, navigate to **Analyze** > **Analytics dashboards**
1. Click on **Value Streams Dashboard**
1. You'll see metrics including Issues created, Issues closed, Lead time, and Cycle time

### Value Stream Analytics (Requires Setup - Premium and Ultimate)

For more detailed analytics and custom value streams (available with GitLab Premium and Ultimate):

1. Navigate to **Analyze** > **Value stream analytics** in your GitLab project or group
1. Click **New value stream** to create a custom value stream
1. Configure stages and workflows according to your development process
1. Metrics like lead time and new issues count will be automatically generated and displayed next to the stages you create
1. Refer to the [GitLab Value Stream Analytics documentation](../../user/group/value_stream_analytics/_index.md#create-a-value-stream) for detailed setup instructions

## Multi-Project Considerations

If you want to replicate issues from multiple Jira projects using a single set of automation rules, consider using a timestamp-based approach for generating unique issue IDs instead of the project prefix method:

Replace the `iid` value in your custom data with:

```json
"iid": {{issue.created.replace("-","").replace("T","").replace(":","").replace(".","").replace("+","")}}
```

This converts the creation timestamp (format: `2025-02-15T09:45:32.7+0000`) into a numeric value. Note that this approach may result in very long issue IDs and has a small risk of conflicts if two issues are created at exactly the same time.

## Resources

- [GitLab Value Stream Analytics](../../user/group/value_stream_analytics/_index.md)
  - [Create a Value Stream](../../user/group/value_stream_analytics/_index.md#create-a-value-stream)
- [GitLab Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md)
- [GitLab Issues API](../../api/issues.md)
  - [Create new issue](../../api/issues.md#new-issue)
  - [Edit issue](../../api/issues.md#edit-an-issue)
- [GitLab Project Access Tokens](../../user/project/settings/project_access_tokens.md)
- [Jira automation with web requests](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
