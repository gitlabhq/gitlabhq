---
type: howto
stage: Plan
group: Portfolio Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

<!-- When adding a new h2 section here, remember to mention it in index.md#manage-epics -->

# Manage epics **(PREMIUM)**

This page collects instructions for all the things you can do with [epics](index.md) or in relation
to them.

## Create an epic

A paginated list of epics is available in each group from where you can create
a new epic. The list of epics includes also epics from all subgroups of the
selected group. From your group page:

1. Go to **Epics**.
1. Click **New epic**.
1. Enter a descriptive title.
1. Click **Create epic**.

You will be taken to the new epic where can edit the following details:

- Title
- Description
- Start date
- Due date
- Labels

An epic's page contains the following tabs:

- **Epics and Issues**: epics and issues added to this epic. Child epics, and their issues, are
  shown in a tree view.
  - Click the <kbd>></kbd> beside a parent epic to reveal the child epics and issues.
  - Hover over the total counts to see a breakdown of open and closed items.
- **Roadmap**: a roadmap view of child epics which have start and due dates.

![epic view](img/epic_view_v13.0.png)

## Bulk-edit epics

You can edit multiple epics at once. To learn how to do it, visit
[Bulk editing issues, epics, and merge requests at the group level](../bulk_editing/index.md#bulk-edit-epics).

## Delete an epic

NOTE: **Note:**
To delete an epic, you need to be an [Owner](../../permissions.md#group-members-permissions) of a group/subgroup.

When editing the description of an epic, click the **Delete** button to delete the epic.
A modal appears to confirm your action.

Deleting an epic releases all existing issues from their associated epic in the system.

## Close an epic

Whenever you decide that there is no longer need for that epic,
close the epic by:

- Clicking the **Close epic** button.

  ![close epic - button](img/button_close_epic.png)

- Using a [quick action](../../project/quick_actions.md).

## Reopen a closed epic

You can reopen an epic that was closed by:

- Clicking the **Reopen epic** button.

  ![reopen epic - button](img/button_reopen_epic.png)

- Using a [quick action](../../project/quick_actions.md).

## Go to an epic from an issue

If an issue belongs to an epic, you can navigate to the containing epic with the
link in the issue sidebar.

![containing epic](img/containing_epic.png)

## Search for an epic from epics list page

> - Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/37081) to the [Premium](https://about.gitlab.com/pricing/) tier in GitLab 12.8.

You can search for an epic from the list of epics using filtered search bar (similar to
that of Issues and Merge Requests) based on following parameters:

- Title or description
- Author name / username
- Labels

![epics search](img/epics_search.png)

To search, go to the list of epics and click the field **Search or filter results**.
It will display a dropdown menu, from which you can add an author. You can also enter plain
text to search by epic title or description. When done, press <kbd>Enter</kbd> on your
keyboard to filter the list.

You can also sort epics list by:

- Created date
- Last updated
- Start date
- Due date

Each option contains a button that can toggle the order between **Ascending** and **Descending**.
The sort option and order is saved and used wherever you browse epics, including the
[Roadmap](../roadmap/index.md).

![epics sort](img/epics_sort.png)

## Make an epic confidential

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213068) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.0.
> - It's deployed behind a feature flag, disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-confidential-epics-premium-only). **(PREMIUM ONLY)**

When you're creating an epic, you can make it confidential by selecting the **Make this epic
confidential** checkbox.

### Enable Confidential Epics **(PREMIUM ONLY)**

The Confidential Epics feature is under development and not ready for production use.
It's deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it for your instance.

To enable it:

```ruby
Feature.enable(:confidential_epics)
```

To disable it:

```ruby
Feature.disable(:confidential_epics)
```

## Manage issues assigned to an epic

### Add an issue to an epic

You can add an existing issue to an epic, or, create a new issue that's
automatically added to the epic.

#### Add an existing issue to an epic

Existing issues that belong to a project in an epic's group, or any of the epic's
subgroups, are eligible to be added to the epic. Newly added issues appear at the top of the list of
issues in the **Epics and Issues** tab.

An epic contains a list of issues and an issue can be associated with at most one epic.
When you add an issue that's already linked to an epic, the issue is automatically unlinked from its
current parent.

To add an issue to an epic:

1. Click the **Add** dropdown button.
1. Click **Add an issue**.
1. Identify the issue to be added, using either of the following methods:
   - Paste the link of the issue.
   - Search for the desired issue by entering part of the issue's title, then selecting the desired
     match (introduced in [GitLab 12.5](https://gitlab.com/gitlab-org/gitlab/-/issues/9126)).

   If there are multiple issues to be added, press <kbd>Spacebar</kbd> and repeat this step.
1. Click **Add**.

#### Create an issue from an epic

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5419) in GitLab 12.7.

Creating an issue from an epic enables you to maintain focus on the broader context of the epic
while dividing work into smaller parts.

To create an issue from an epic:

1. On the epic's page, under **Epics and Issues**, click the **Add** dropdown button and select
   **Create new issue**.
1. Under **Title**, enter the title for the new issue.
1. From the **Project** dropdown, select the project in which the issue should be created.
1. Click **Create issue**.

### Remove an issue from an epic

You can remove issues from an epic when you're on the epic's details page.
After you remove an issue from an epic, the issue will no longer be associated with this epic.

To remove an issue from an epic:

1. Click the **Remove** (**{close}**) button next to the issue you want to remove.
   The **Remove issue** warning appears.
1. Click **Remove**.

![List of issues assigned to an epic](img/issue_list_v13_1.png)

### Reorder issues assigned to an epic

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9367) in GitLab 12.5.

New issues appear at the top of the list in the **Epics and Issues** tab.
You can reorder the list of issues by dragging them.

To reorder issues assigned to an epic:

1. Go to the **Epics and Issues** tab.
1. Drag issues into the desired order.

### Move issues between epics **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33039) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.0.

New issues appear at the top of the list in the **Epics and Issues**
tab. You can move issues from one epic to another.

To move an issue to another epic:

1. Go to the **Epics and Issues** tab.
1. Drag issues into the desired parent epic.

### Promote an issue to an epic

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3777) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/37081) to [GitLab Premium](https://about.gitlab.com/pricing/) in 12.8.

If you have the necessary [permissions](../../permissions.md) to close an issue and create an
epic in the parent group, you can promote an issue to an epic with the `/promote`
[quick action](../../project/quick_actions.md#quick-actions-for-issues-merge-requests-and-epics).
Only issues from projects that are in groups can be promoted. When attempting to promote a confidential
issue, a warning will display. Promoting a confidential issue to an epic will make all information
related to the issue public as epics are public to group members.

When the quick action is executed:

- An epic is created in the same group as the project of the issue.
- Subscribers of the issue are notified that the epic was created.

The following issue metadata will be copied to the epic:

- Title, description, activity/comment thread.
- Upvotes/downvotes.
- Participants.
- Group labels that the issue already has.

## Manage multi-level child epics **(ULTIMATE)**

### Add a child epic to an epic

To add a child epic to an epic:

1. Click the **Add** dropdown button.
1. Click **Add an epic**.
1. Identify the epic to be added, using either of the following methods:
   - Paste the link of the epic.
   - Search for the desired issue by entering part of the epic's title, then selecting the desired
     match (introduced in [GitLab 12.5](https://gitlab.com/gitlab-org/gitlab/-/issues/9126)).

   If there are multiple epics to be added, press <kbd>Spacebar</kbd> and repeat this step.
1. Click **Add**.

### Move child epics between epics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33039) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.0.

New child epics appear at the top of the list in the **Epics and Issues** tab.
You can move child epics from one epic to another.
When you add an epic that's already linked to a parent epic, the link to its current parent is removed.
Issues and child epics cannot be intermingled.

To move child epics to another epic:

1. Go to the **Epics and Issues** tab.
1. Drag epics into the desired parent epic.

### Reorder child epics assigned to an epic

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9367) in GitLab 12.5.

New child epics appear at the top of the list in the **Epics and Issues** tab.
You can reorder the list of child epics.

To reorder child epics assigned to an epic:

1. Go to the **Epics and Issues** tab.
1. Drag epics into the desired order.

### Remove a child epic from a parent epic

To remove a child epic from a parent epic:

1. Click on the <kbd>x</kbd> button in the parent epic's list of epics.
1. Click **Remove** in the **Remove epic** warning message.
