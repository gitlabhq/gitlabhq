---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User file uploads
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Users can upload files to:

- Issues or merge requests in a project.
- Epics in a group.

GitLab generates direct URLs for these uploaded files with a random 32-character ID to prevent unauthorized users from guessing the URLs. This randomization offers some security for files containing sensitive information.

Files uploaded by users to GitLab issues, merge requests, and epics contain `/uploads/<32-character-id>` in the URL path.

{{< alert type="warning" >}}

Exercise caution in downloading files uploaded by unknown or untrusted sources, especially if the file is an executable or script.

{{< /alert >}}

## Access control for uploaded files

{{< history >}}

- Enforced authorization checks became [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352291) in GitLab 15.3. Feature flag `enforce_auth_checks_on_uploads` removed.
- Project settings in the user interface [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88567) in GitLab 15.3.

{{< /history >}}

Access to non-image files uploaded to:

- Issues or merge requests is determined by the project visibility.
- Group epics is determined by the group visibility.

For public projects or groups, anyone can access these files through the direct attachment URL, even if the issue, merge request, or epic is confidential.
For private and internal projects, GitLab ensures only authenticated project members can access non-image file uploads, such as PDFs.
By default, image files do not have the same restriction, and anyone can view them using the URL. To protect image files, [enable authorization checks for all media files](#enable-authorization-checks-for-all-media-files), making them viewable only by authenticated users.

Authentication checks for images can cause display issues in the body of notification emails.
Emails are frequently read from clients (such as Outlook, Apple Mail, or your mobile device)
not authenticated with GitLab. Images in emails appear broken and unavailable if
the client is not authorized to GitLab.

## Enable authorization checks for all media files

Only authenticated project members can view non-image attachments (including PDFs) in private and internal projects.

To apply authentication requirements to image files in private or internal projects:

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- Your project visibility settings must be **Private** or **Internal**.

To configure authentication settings for all media files:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll to **Project visibility** and select **Require authentication to view media files**.

{{< alert type="note" >}}

You cannot select this option for public projects.

{{< /alert >}}

## Delete uploaded files

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92791) in GitLab 15.3.
- REST API [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) support in GitLab 17.2.

{{< /history >}}

You should delete an uploaded file when that file contains sensitive or confidential information. When you have deleted that file, users cannot access the file and the direct URL returns a 404 error.

Project Owners and Maintainers can use the [interactive GraphQL explorer](../api/graphql/_index.md#interactive-graphql-explorer) to access a [GraphQL endpoint](../api/graphql/reference/_index.md#mutationuploaddelete) and delete an uploaded file.

For example:

```graphql
mutation{
  uploadDelete(input: { projectPath: "<path/to/project>", secret: "<32-character-id>" , filename: "<filename>" }) {
    upload {
      id
      size
      path
    }
    errors
  }
}
```

Project members that do not have the Owner or Maintainer role cannot access this GraphQL endpoint.

You can also use the REST API for [projects](../api/project_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename) or [groups](../api/group_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename) to delete an uploaded file.
