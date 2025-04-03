---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External status checks
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `pending` status [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413723) in GitLab 16.5
- Timeout interval of two minutes for `pending` status checks [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388725) in GitLab 16.6.

{{< /history >}}

Status checks are API calls to external systems that request the status of an external requirement.

You can create a status check that sends merge request data to third-party tools.
When users create, change, or close merge requests, GitLab sends a notification. The users or automated workflows
can then update the status of merge requests from outside of GitLab.

With this integration, you can integrate with third-party workflow tools, like
ServiceNow, or the custom tool of your choice. The third-party tool
responds with an associated status. This status is then displayed as a non-blocking
widget within the merge request, which surfaces this status to the merge request author or reviewers
at the merge request level itself.

You can configure merge request status checks for each individual project. These are not shared between projects.

Status checks fail if they stay in the pending state for more than two minutes.

## Access permissions

External status check responses can be viewed by:

- Users with Reporter role or higher permissions in the project
- Any authenticated user who can view the merge request when the project has internal visibility

This means that if you have an internal project, any logged-in user who can access the merge request can view the external status check responses.

For more information about use cases, feature discovery, and development timelines,
see [epic 3869](https://gitlab.com/groups/gitlab-org/-/epics/3869).

## Block merges of merge requests unless all status checks have passed

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 [with a flag](../../../administration/feature_flags.md) named `only_allow_merge_if_all_status_checks_passed`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/372340) in GitLab 15.8.
- Enabled on GitLab Self-Managed and feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111492) in GitLab 15.9.

{{< /history >}}

By default, merge requests in projects can be merged even if external status checks fail. To block the merging of merge requests when external checks fail:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Select the **Status checks must succeed** checkbox.
1. Select **Save changes**.

## Lifecycle

External status checks have an **asynchronous** workflow. Merge requests emit a merge request webhook payload to an external service whenever:

- A merge request is updated, closed, reopened, approved, unapproved, or merged.
- Code is pushed to the source branch of the merge request.

```mermaid
sequenceDiagram
    Merge request->>+External service: Merge request payload
    External service-->>-Merge request: Status check response
    Note over External service,Merge request: Response includes SHA at HEAD
```

When the payload is received, the external service can then run any required processes before posting its response back to the merge request [using the REST API](../../../api/status_checks.md#set-status-of-an-external-status-check).

Merge requests return a `409 Conflict` error to any responses that do not refer to the current `HEAD` of the source branch. As a result, it's safe for the external service to process and respond to out-of-date commits.

External status checks have the following states:

- `pending` - The default state. No response has been received by the merge request from the external service.
- `passed` - A response from the external service has been received and approved by it.
- `failed` - A response from the external service has been received and denied by it.

If something changes outside of GitLab, you can [set the status of an external status check](../../../api/status_checks.md#set-status-of-an-external-status-check)
using the API. You don't need to wait for a merge request webhook payload to be sent first.

## View status check services

To view a list of status check services added to a project from the merge request settings:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Scroll down to **Status checks**. This list shows the service name, API URL, targeted branch,
   and HMAC authentication status.

![Status checks list](img/status_checks_list_view_v14_0.png)

You can also view a list of status check services from the [Branch rules](../repository/branches/branch_rules.md#add-a-status-check-service) settings.

## Add or update a status check service

### Add a status check service

Within the **Status checks** sub-section, select the **Add status check** button.
The **Add status check** form is then shown.

![Status checks create form](img/status_checks_create_form_v14_0.png)

Filling in the form and selecting the **Add status check** button creates a new status check.

The status check is applied to all new merge requests, but does not apply retroactively to existing merge requests.

### Update a status check service

In the **Status checks** sub-section, select **Edit** ({{< icon name="pencil" >}})
next to the status check you want to edit.
The **Update status check** form is then shown.

![Status checks update form](img/status_checks_update_form_v14_0.png)

{{< alert type="note" >}}

You cannot see or modify the value of the HMAC shared secret. To change the shared secret, delete and recreate the external status check with a new value for the shared secret.

{{< /alert >}}

To update the status check, change the values in the form and select **Update status check**.

Status check updates are applied to all new merge requests, but do not apply retroactively to existing merge requests.

### Form values

For common form errors see the [troubleshooting](#troubleshooting) section below.

#### Service name

This name can be any alphanumerical value and **must** be set. The name **must** be unique for
the project.
The name **has** to be unique for the project.

#### API to check

This field requires a URL and **must** use either the HTTP or HTTPS protocols.
We **recommend** using HTTPS to protect your merge request data in transit.
The URL **must** be set and **must** be unique for the project.

#### Target branch

If you want to restrict the status check to a single branch,
you can use this field to set this limit.

![Status checks branch selector](img/status_checks_branches_selector_v14_0.png)

The branches list is populated from the projects [protected branches](../repository/branches/protected.md).

You can scroll through the list of branches or use the search box
when there are a lot of branches and the branch you are looking
for doesn't appear immediately. The search box requires
**three** alphanumeric characters to be entered for the search to begin.

If you want the status check to be applied to **all** merge requests,
you can select the **All branches** option.

#### HMAC shared secret

HMAC authentication prevents tampering with requests
and ensures they come from a legitimate source.

## Delete a status check service

Within the **Status checks** sub-section, select **Remove** ({{< icon name="remove" >}})
next to the status check you want to delete.
The **Remove status check?** modal is then shown.

![Status checks delete modal](img/status_checks_delete_modal_v14_0.png)

To complete the deletion of the status check you must select the
**Remove status check** button. This **permanently** deletes
the status check and it **is not** recoverable.

## Status checks widget

{{< history >}}

- UI [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91504) in GitLab 15.2.
- Ability to retry failed external status checks [added](https://gitlab.com/gitlab-org/gitlab/-/issues/383200) in GitLab 15.8.
- Widget [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111763) to poll for updates when there are pending status checks in GitLab 15.11.

{{< /history >}}

The status checks widget displays in merge requests and displays the following statuses:

- **pending** ({{< icon name="status-neutral" >}}), while GitLab waits for a response from an external status check.
- **success** ({{< icon name="status-success" >}}) or **failed** ({{< icon name="status-failed" >}}), when GitLab receives a response from an external status check.

When there are pending status checks, the widget polls for updates every few seconds until it receives a **success** or **failed** response.

To retry a failed status check:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Scroll to the merge request reports section, and expand the dropdown list to show the list of external status checks.
1. Select **Retry** ({{< icon name="retry" >}}) on the failed external status check row. The status check is put back into a pending state.

An organization might have a policy that does not allow merging merge requests if
external status checks do not pass. However, the details in the widget are for informational
purposes only.

{{< alert type="note" >}}

GitLab cannot guarantee that the external status checks are properly processed by
the related external service.

{{< /alert >}}

## Troubleshooting

### Duplicate value errors

```plaintext
Name is already taken
---
External API is already in use by another status check
```

On a per project basis, status checks can only use a name or API URL once.
These errors mean that either the status checks name or API URL have already
been used in this projects status checks.

You must either choose a different
value on the current status check or update the value on the existing status check.

### Invalid URL error

```plaintext
Please provide a valid URL
```

The API to check field requires the URL provided to use either the HTTP or HTTPs protocols.
You must update the value of the field to meet this requirement.

### Branch list error during retrieval or search

```plaintext
Unable to fetch branches list, please close the form and try again
```

An unexpected response was received from the branches retrieval API.
As suggested, you should close the form and reopen again or refresh the page. This error should be temporary, although
if it persists, check the [GitLab status page](https://status.gitlab.com/) to see if there is a wider outage.

### Failed to load status checks

```plaintext
Failed to load status checks
```

An unexpected response was received from the external status checks API.
You should:

- Refresh the page in case this error is temporary.
- Check the [GitLab status page](https://status.gitlab.com/) if the problem persists,
  to see if there is a wider outage.

## Related topics

- [External status checks API](../../../api/status_checks.md)
