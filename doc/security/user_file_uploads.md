---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User file uploads
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Users can upload files to:

- Issues or merge requests in a project.
- Epics in a group.

GitLab generates direct URLs for these uploaded files with a random 32-character ID to prevent unauthorized users from guessing the URLs. This randomization offers some security for files containing sensitive information.

Files uploaded by users to GitLab issues, merge requests, and epics contain `/uploads/<32-character-id>` in the URL path.

WARNING:
Exercise caution in downloading files uploaded by unknown or untrusted sources, especially if the file is an executable or script.

## Access control for uploaded files

> - Enforced authorization checks became [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352291) in GitLab 15.3. Feature flag `enforce_auth_checks_on_uploads` removed.
> - Project settings in the user interface [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88567) in GitLab 15.3.

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

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll to **Project visibility** and select **Require authentication to view media files**.

NOTE:
You cannot select this option for public projects.

## Delete uploaded files

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92791) in GitLab 15.3.
> - REST API [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) support in GitLab 17.2.

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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
