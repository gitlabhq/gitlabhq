---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Build templates for text frequently used in comments, and share those templates with your project or group."
title: Comment templates
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - User interface [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113232) in GitLab 15.10 [with a flag](../../administration/feature_flags.md) named `saved_replies`. Disabled by default. Enabled for GitLab team members only.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119468) in GitLab 16.0.
> - [Feature flag `saved_replies` removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123363) in GitLab 16.6.
> - Saved replies for groups [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12669) in GitLab 16.11 [with a flag](../../administration/feature_flags.md) named `group_saved_replies_flag`. Disabled by default.
> - Saved replies for groups [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/440817) on GitLab.com and GitLab Self-Managed in GitLab 16.11.
> - Saved replies for groups [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/504028) in GitLab 17.8. Feature flag `group_saved_replies_flag` removed.
> - Saved replies for projects [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12669) in GitLab 17.0 [with a flag](../../administration/feature_flags.md) named `project_saved_replies_flag`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/504028) in GitLab 17.8. Feature flag `project_saved_replies_flag` removed.

With comment templates, create and reuse text for any text area in:

- Merge requests, including diffs.
- Issues, including design management comments.
- Epics.
- Work items.

Comment templates can be small, like approving a merge request and unassigning yourself from it,
or large, like chunks of boilerplate text you use frequently:

![Comment templates dropdown list](img/group_comment_templates_v16_11.png)

## Use comment templates in a text area

To include the text of a comment template in your comment:

1. In the editor toolbar for your comment, select **Comment templates** (**{comment-lines}**).
1. Select your desired comment template.

## Create comment templates

You can create comment templates for your own use, or to share with all members of a group.

To create a comment template for your own use:

1. On the left sidebar, select your avatar.
1. From the dropdown list, select **Preferences**.
1. On the left sidebar, select **Comment templates** (**{comment-lines}**).
1. Select **Add new**.
1. Provide a **Name** for your comment template.
1. Enter the **Content** of your reply. You can use any formatting you use in
   other GitLab text areas.
1. Select **Save**, and the page reloads with your comment template shown.

### For a group

DETAILS:
**Tier:** Premium, Ultimate

To create a comment template shared with all members of a group:

1. In the editor toolbar for a comment, select **Comment templates**
   (**{comment-lines}**), then select **Manage group comment templates**.
1. Select **Add new**.
1. Provide a **Name** for your comment template.
1. Enter the **Content** of your reply. You can use any formatting you use in
   other GitLab text areas.
1. Select **Save**, and the page reloads with your comment template shown.

### For a project

DETAILS:
**Tier:** Premium, Ultimate

To create a comment template shared with all members of a project:

1. In the editor toolbar for a comment, select **Comment templates**
   (**{comment-lines}**), then select **Manage project comment templates**.
1. Select **Add new**.
1. Provide a **Name** for your comment template.
1. Enter the **Content** of your reply. You can use any formatting you use in
   other GitLab text areas.
1. Select **Save**, and the page reloads with your comment template shown.

## View comment templates

To see existing comment templates:

1. On the left sidebar, select your avatar.
1. From the dropdown list, select **Preferences**.
1. On the left sidebar, select **Comment templates** (**{comment-lines}**).
1. Scroll to **Comment templates**.

### For a group

DETAILS:
**Tier:** Premium, Ultimate

1. In the editor toolbar for a comment, select **Comment templates**
   (**{comment-lines}**).
1. Select **Manage group comment templates**.

### For a project

DETAILS:
**Tier:** Premium, Ultimate

1. In the editor toolbar for a comment, select **Comment templates**
   (**{comment-lines}**).
1. Select **Manage project comment templates**.

## Edit or delete comment templates

To edit or delete an existing comment template:

1. On the left sidebar, select your avatar.
1. From the dropdown list, select **Preferences**.
1. On the left sidebar, select **Comment templates** (**{comment-lines}**).
1. Scroll to **Comment templates**, and identify the comment template you want to edit.
1. To edit, select **Edit** (**{pencil}**).
1. To delete, select **Delete** (**{remove}**), then select **Delete** again on the dialog.

### For a group

DETAILS:
**Tier:** Premium, Ultimate

1. In the editor toolbar for a comment, select **Comment templates**
   (**{comment-lines}**), then select **Manage group comment templates**.
1. To edit, select **Edit** (**{pencil}**).
1. To delete, select **Delete** (**{remove}**), then select **Delete** again on the dialog.

### For a project

DETAILS:
**Tier:** Premium, Ultimate

1. In the editor toolbar for a comment, select **Comment templates**
   (**{comment-lines}**), then select **Manage project comment templates**.
1. To edit, select **Edit** (**{pencil}**).
1. To delete, select **Delete** (**{remove}**), then select **Delete** again on the dialog.
