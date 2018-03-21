# Create a new Issue

Please read through the [GitLab Issue Documentation](index.md) for an overview on GitLab Issues.

When you create a new issue, you'll be prompted to fill in
the information illustrated on the image below.

![New issue from the issues list](img/new_issue.png)

Read through the [issues functionalities documentation](issues_functionalities.md#issues-functionalities)
to understand these fields one by one.

## New issue from the Issue Tracker

Navigate to your **Project's Dashboard** > **Issues** > **New Issue** to create a new issue:

![New issue from the issue list view](img/new_issue_from_tracker_list.png)

## New issue from an opened issue

From an **opened issue** in your project, click **New Issue** to create a new
issue in the same project:

![New issue from an open issue](img/new_issue_from_open_issue.png)

## New issue from the project's dashboard

From your **Project's Dashboard**, click the plus sign (**+**) to open a dropdown
menu with a few options. Select **New Issue** to create an issue in that project:

![New issue from a project's dashboard](img/new_issue_from_projects_dashboard.png)

## New issue from the Issue Board

From an Issue Board, create a new issue by clicking on the plus sign (**+**) on the top of a list.
It opens a new issue for that project labeled after its respective list.

![From the issue board](img/new_issue_from_issue_board.png)

## New issue via email

*This feature needs [incoming email](../../../administration/incoming_email.md)
to be configured by a GitLab administrator to be available for CE/EE users, and
it's available on GitLab.com.*

At the bottom of a project's issue page, click
**Email a new issue to this project**, and you will find an email address
which belongs to you. You could add this address to your contact.

This is a private email address, generated just for you.
**Keep it to yourself** as anyone who gets ahold of it can create issues or
merge requests as if they were you. You can add this address to your contact
list for easy access.

Sending an email to this address will create a new issue on your behalf for
this project, where the email subject becomes the issue title, and the email
body becomes the issue description. [Markdown] and [quick actions] are
supported.

![Bottom of a project issues page](img/new_issue_from_email.png)
