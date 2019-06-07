# Create a new Issue

Please read through the [GitLab Issue Documentation](index.md) for an overview on GitLab Issues.

When you create a new issue, you'll be prompted to fill in
the information illustrated on the image below.

![New issue from the issues list](img/new_issue.png)

Read through the [issue data and actions documentation](issue_data_and_actions.md#parts-of-an-issue)
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

At the bottom of a project's Issues List page, a link to **Email a new issue to this project**
is displayed if your GitLab instance has [incoming email](../../../administration/incoming_email.md) configured.

![Bottom of a project issues page](img/new_issue_from_email.png)

When you click this link, an email address is displayed which belongs to you for creating issues in this project.
You can save this address as a contact in your email client for easy acceess.

CAUTION: **Caution:**
This is a private email address, generated just for you. **Keep it to yourself**,
as anyone who gets ahold of it can create issues or merge requests as if they
were you. If the address is compromised, or you'd like it to be regenerated for
any reason, click **Email a new issue to this project** again and click the reset link.

Sending an email to this address will create a new issue on your behalf for
this project, where:

- The email subject becomes the issue title.
- The email body becomes the issue description.
- [Markdown](../../markdown.md) and [quick actions](../quick_actions.md) are supported.

NOTE: **Note:**
In GitLab 11.7, we updated the format of the generated email address.
However the older format is still supported, allowing existing aliases
or contacts to continue working._

## New issue via Service Desk **[PREMIUM]**

Enable [Service Desk](../service_desk.md) to your project and offer email support.
By doing so, when your customer sends a new email, a new issue can be created in
the appropriate project and followed up from there.

## New issue from the group-level Issue Tracker

Head to the Group dashboard and click "Issues" in the sidebar to visit the Issue Tracker
for all projects in your Group. Select the project you'd like to add an issue for
using the dropdown button at the top-right of the page.

![Select project to create issue](img/select_project_from_group_level_issue_tracker.png)

We'll keep track of the project you selected most recently, and use it as the default
for your next visit. This should save you a lot of time and clicks, if you mostly
create issues for the same project.

![Create issue from group-level issue tracker](img/create_issue_from_group_level_issue_tracker.png)

## New issue via URL with prefilled fields

You can link directly to the new issue page for a given project, with prefilled
field values using query string parameters in a URL. This is useful for embedding
a URL in an external HTML page, and also certain scenarios where you want the user to
create an issue with certain fields prefilled.

The title, description, and description template fields can be prefilled using
this method. The description and description template fields cannot be pre-entered
in the same URL (since a description template just populates the description field).

Follow these examples to form your new issue URL with prefilled fields.

- For a new issue in the GitLab Community Edition project with a pre-entered title
  and a pre-entered description, the URL would be `https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issue[title]=Validate%20new%20concept&issue[description]=Research%20idea`
- For a new issue in the GitLab Community Edition project with a pre-entered title
  and a pre-entered description template, the URL would be `https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issue[title]=Validate%20new%20concept&issuable_template=Research%20proposal`
