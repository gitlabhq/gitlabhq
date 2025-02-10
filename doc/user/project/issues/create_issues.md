---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create an issue
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you create an issue, you are prompted to enter the fields of the issue.
If you know the values you want to assign to an issue, you can use
[quick actions](../quick_actions.md) to enter them.

You can create an issue in many ways in GitLab:

- [From a project](#from-a-project)
- [From a group](#from-a-group)
- [From another issue or incident](#from-another-issue-or-incident)
- [From an issue board](#from-an-issue-board)
- [By sending an email](#by-sending-an-email)
- [Using a URL with prefilled values](#using-a-url-with-prefilled-values)
- [Using Service Desk](#using-service-desk)

## From a project

Prerequisites:

- You must have at least the Guest role for the project.

To create an issue:

1. On the left sidebar, select **Search or go to** and find your project.
1. Either:

   - On the left sidebar, select **Plan > Issues**, and then, in the upper-right corner, select **New issue**.
   - On the left sidebar, at the top, select the plus sign (**{plus}**) and then, under **In this project**,
     select **New issue**.

1. Complete the [fields](#fields-in-the-new-issue-form).
1. Select **Create issue**.

The newly created issue opens.

## From a group

Issues belong to projects, but when you're in a group, you can access and create issues that belong
to the projects in the group.

Prerequisites:

- You must have at least the Guest role for the project in the group.

To create an issue from a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Issues**.
1. In the upper-right corner, select **Select project to create issue**.
1. Select the project you'd like to create an issue for. The button now reflects the selected
   project.
1. Select **New issue in `<project name>`**.
1. Complete the [fields](#fields-in-the-new-issue-form).
1. Select **Create issue**.

The newly created issue opens.

The project you selected most recently becomes the default for your next visit.
This can save you a lot of time, if you mostly create issues for the same project.

## From another issue or incident

You can create a new issue from an existing one. The two issues can then be marked as related.

Prerequisites:

- You must have at least the Guest role for the project.

To create an issue from another issue:

1. In an existing issue, select **Issue actions** (**{ellipsis_v}**).
1. Select **New related issue**.
1. Complete the [fields](#fields-in-the-new-issue-form).
   The new issue form has a **Relate to issue #123** checkbox, where `123` is the ID of the
   issue of origin. If you keep this checkbox checked, the two issues become
   [linked](related_issues.md).
1. Select **Create issue**.

The newly created issue opens.

## From an issue board

You can create a new issue from an [issue board](../issue_board.md).

Prerequisites:

- You must have at least the Guest role for the project.

To create an issue from a project issue board:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issue boards**.
1. At the top of a board list, select **Create new issue** (**{plus-square}**).
1. Enter the issue's title.
1. Select **Create issue**.

To create an issue from a group issue board:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Issue boards**.
1. At the top of a board list, select **Create new issue** (**{plus-square}**).
1. Enter the issue's title.
1. Under **Projects**, select the project in the group that the issue should belong to.
1. Select **Create issue**.

The issue is created and shows up in the board list. It shares the list's characteristic, so, for
example, if the list is scoped to a label `Frontend`, the new issue also has this label.

## By sending an email

You can send an email to create an issue in a project on the project's
**Issues** page.

Prerequisites:

- Your GitLab instance must have [incoming email](../../../administration/incoming_email.md)
  configured with [email sub-addressing or catch-all mailbox](../../../administration/incoming_email.md#requirements).
- There must be at least one issue in the issue list.
- You must have at least the Guest role for the project.

To email an issue to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues**.
1. At the bottom of the page, select **Email a new issue to this project**.
1. To copy the email address, select **Copy** (**{copy-to-clipboard}**).
1. From your email client, send an email to this address.
   The subject is used as the title of the new issue, and the email body becomes the description.
   You can use [Markdown](../../markdown.md) and [quick actions](../quick_actions.md).

A new issue is created, with your user as the author.
You can save this address as a contact in your email client to use it again.

WARNING:
The email address you see is a private email address, generated just for you.
**Keep it to yourself**, because anyone who knows it can create issues or merge requests as if they
were you.

To regenerate the email address:

1. On the **Issues** page, select **Email a new issue to this project**.
1. Select **reset this token**.

## Using a URL with prefilled values

To link directly to the new issue page with prefilled fields, use query
string parameters in a URL. You can embed a URL in an external
HTML page to create issues with certain fields prefilled.

| Field                | URL parameter         | Notes                                                                                                                           |
| -------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Title                | `issue[title]`        | Must be [URL-encoded](../../../api/rest/_index.md#namespaced-paths).                                                          |
| Issue type           | `issue[issue_type]`   | Either `incident` or `issue`.                                                                                                   |
| Description template (issues, epics, incidents, and merge requests) | `issuable_template`   | Must be [URL-encoded](../../../api/rest/_index.md#namespaced-paths).                                                          |
| Description template (tasks, OKRs and epics [with the new look](../../group/epics/epic_work_items.md)). | `description_template`   | Must be [URL-encoded](../../../api/rest/_index.md#namespaced-paths). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513095) in GitLab 17.9. |
| Description          | `issue[description]`  | Must be [URL-encoded](../../../api/rest/_index.md#namespaced-paths). If used in combination with `issuable_template` or a [default issue template](../description_templates.md#set-a-default-template-for-merge-requests-and-issues), the `issue[description]` value is appended to the template. |
| Confidential         | `issue[confidential]` | If `true`, the issue is marked as confidential.                                                                                 |
| Relate to…           | `add_related_issue`   | A numeric issue ID. If present, the issue form shows a [**Relate to** checkbox](#from-another-issue-or-incident) to optionally link the new issue to the specified existing issue. |

In [GitLab 17.8 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177215),
when you select an issue template, the URL changes to show the template used.

Adapt these examples to form your new issue URL with prefilled fields.
To create an issue in the GitLab project:

- With a prefilled title and description:

  ```plaintext
  https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Whoa%2C%20we%27re%20half-way%20there&issue[description]=Whoa%2C%20livin%27%20in%20a%20URL
  ```

- With a prefilled title and description template:

  ```plaintext
  https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Validate%20new%20concept&issuable_template=Feature%20Proposal%20-%20basic
  ```

- With a prefilled title, description, and marked as confidential:

  ```plaintext
  https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Validate%20new%20concept&issue[description]=Research%20idea&issue[confidential]=true
  ```

## Using Service Desk

To offer email support, enable [Service Desk](../service_desk/_index.md) for your project.

Now, when your customer sends a new email, a new issue can be created in
the appropriate project and followed up from there.

## Fields in the new issue form

> - Iteration field [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/233517) in GitLab 15.6.

When you're creating a new issue, you can complete the following fields:

- Title
- Type: either issue (default) or incident
- [Description template](../description_templates.md): overwrites anything in the Description text box
- Description: you can use [Markdown](../../markdown.md) and [quick actions](../quick_actions.md)
- Checkbox to make the issue [confidential](confidential_issues.md)
- [Assignees](managing_issues.md#assignees)
- [Weight](issue_weight.md)
- [Epic](../../group/epics/_index.md)
- [Due date](due_dates.md)
- [Milestone](../milestones/_index.md)
- [Labels](../labels.md)
- [Iteration](../../group/iterations/_index.md)
