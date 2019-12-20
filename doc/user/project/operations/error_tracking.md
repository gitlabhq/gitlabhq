# Error Tracking

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/169) in GitLab 11.8.

Error tracking allows developers to easily discover and view the errors that their application may be generating. By surfacing error information where the code is being developed, efficiency and awareness can be increased.

## Sentry error tracking

[Sentry](https://sentry.io/) is an open source error tracking system. GitLab allows administrators to connect Sentry to GitLab, to allow users to view a list of Sentry errors in GitLab.

### Deploying Sentry

You may sign up to the cloud hosted <https://sentry.io> or deploy your own [on-premise instance](https://docs.sentry.io/server/installation/).

### Enabling Sentry

NOTE: **Note:**
You will need at least Maintainer [permissions](../../permissions.md) to enable the Sentry integration.

GitLab provides an easy way to connect Sentry to your project:

1. Sign up to Sentry.io or [deploy your own](#deploying-sentry) Sentry instance.
1. [Create](https://docs.sentry.io/guides/integrate-frontend/create-new-project/) a new Sentry project. For each GitLab project that you want to integrate, we recommend that you create a new Sentry project.
1. [Find or generate](https://docs.sentry.io/api/auth/) a Sentry auth token for your Sentry project.
   Make sure to give the token at least the following scopes: `event:read` and `project:read`.
1. Navigate to your project’s **Settings > Operations**.
1. Ensure that the **Active** checkbox is set.
1. In the **Sentry API URL** field, enter your Sentry hostname. For example, `https://sentry.example.com`.
1. In the **Auth Token** field, enter the token you previously generated.
1. Click the **Connect** button to test the connection to Sentry and populate the **Project** dropdown.
1. From the **Project** dropdown, choose a Sentry project to link to your GitLab project.
1. Click **Save changes** for the changes to take effect.
1. You can now visit **Operations > Error Tracking** in your project's sidebar to [view a list](#error-tracking-list) of Sentry errors.

### Enabling GitLab issues links

You may also want to enable Sentry's GitLab integration by following the steps in the [Sentry documentation](https://docs.sentry.io/workflow/integrations/global-integrations/#gitlab)

## Error Tracking List

NOTE: **Note:**
You will need at least Reporter [permissions](../../permissions.md) to view the Error Tracking list.

The Error Tracking list may be found at **Operations > Error Tracking** in your project's sidebar.
Errors can be filtered by title or sorted by Frequency, First Seen or Last Seen. Errors are always sorted in descending order by the field specified.

![Error Tracking list](img/error_tracking_list_v12_6.png)

## Error Details

From error list, users can navigate to the error details page by clicking the title of any error.

This page has:

- A link to the Sentry issue.
- Other details about the issue, including a full stack trace.

If the error has not been linked to an existing GitLab issue, a 'Create Issue' button will be visible:

![Error Details without Issue Link](img/error_details_v12_6.png)

If a link does exist, it will be shown in the details and the 'Create Issue' button will be hidden:

![Error Details with Issue Link](img/error_details_with_issue_v12_6.png)
