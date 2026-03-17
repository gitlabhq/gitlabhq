---
stage: none
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutorial: Edit a file using the Web Editor'
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Project](../../user/project/organize_work_with_projects.md) files may be edited by team members who have [appropriate access](../../user/project/members/_index.md).

Learn how to edit an individual file directly in the GitLab UI using the simple Web Editor.

## Select the file you wish to edit

First, go to the project home page to get a list of files in the project.

![A file listing on the project home page. It shows a project named "Company Handbook" with files named things like "break-room.md".](img/project_file_listing_v18_9.png)

Select any file to view its details.

![The "break-room.md" file is shown in detail. Its contents show amenities such as cards, video games, and a pool table.](img/file_in_detail_v18_9.png)

## Edit the file

Select the **Edit** dropdown list, and then select **Edit single file**.

![The Edit button expands to show the dropdown list options, "Open in Web IDE" and "Edit Single File".](img/edit_dropdown_v18_9.png)

In the editor, make your edits to the file as needed.

![The file reappears in an editable text field, allowing the viewer to change its contents.](img/edit_file_v18_9.png)

## Commit your changes and create a merge request

It is possible to commit (save) your changes directly to the file. However, this is not recommended for most teams, as it is good practice to first have your changes reviewed by a team member. In this step, you'll create a branch and merge request with the new changes.

After you have finished editing:

1. Select **Commit changes**.
1. Fill in the **commit message** text box with a description of your changes.
1. Under **Branch**, select **Commit to a new branch**.
1. Under **Commit to a new branch**, enter a name for your new branch or leave the automatically generated one provided for you.
1. Make sure **Create a merge request for this change** is selected.

![The commit changes form with example values. The commit message is "Remove mention of the ping-pong table", "commit to a new branch" is selected, and the branch is named "ping-pong-table-removal".](img/commit_changes_v18_9.png)

Finally, select **Commit changes** to commit your changes to the new branch. The new merge request form appears. To create the request, do the following:

1. Set the **Title** to an appropriate summary of the changes.
1. Put more details about your changes in the **Description** field.
1. Set the **Assignee** to yourself.
1. If you know who should review your changes, set the **Reviewer**.
1. Optional. Set the [milestone](../../user/project/milestones/_index.md) of your merge request.
1. Optional. Set labels for your merge request to better categorize it.
1. Select **Create merge request** to create your merge request.

![The form of the new merge request, showing the title set as "Remove mention of the ping-pong table" and the description as "This merge request removes the ping-pong table from the break room page since we no longer have one."](img/merge_request_v18_9.png)

Your edits are now in a merge request, and ready to be reviewed by another contributor.

## Next steps

Next you can:

- Review someone else's merge request
- [Create an issue on your existing project](../create_issue_in_existing_project/_index.md)
