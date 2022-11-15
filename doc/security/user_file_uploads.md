---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User file uploads **(FREE)**

> - Enforced authorization checks [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80117) in GitLab 14.8 [with a flag](../administration/feature_flags.md) named `enforce_auth_checks_on_uploads`. Disabled by default.
> - Enforced authorization checks became [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352291) in GitLab 15.3. Feature flag `enforce_auth_checks_on_uploads` removed.
> - Project settings in the user interface [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88567) in GitLab 15.3.

In private or internal projects, GitLab restricts access to uploaded files (such as PDFs)
to authenticated users only. By default, image files are not subject to the same
restriction, and unauthenticated users can use the URL to view the
file. If you enable authorization checks for all media files, images
receive the same protection and are viewable only by authenticated users.

Users can upload files to issues, merge requests, or comments in a project. Direct URLs
to these images in GitLab contain a random 32-character ID to help prevent
unauthorized users from guessing image URLs. This randomization provides some protection
if an image contains sensitive information.

Authentication checks for images can cause display issues in the body of notification emails.
Emails are frequently read from clients (such as Outlook, Apple Mail, or your mobile device)
not authenticated with GitLab. Images in emails appear broken and unavailable if
the client is not authorized to GitLab.

## Enable authorization checks for all media files

Non-image attachments (including PDFs) always require authentication to be viewed.
You can use this setting to extend this protection to image files.

Prerequisite:

- You must have the Maintainer or Owner role for the project.
- Your project visibility settings must be **Private** or **Internal**.

To configure authentication settings for all media files:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll to **Project visibility** and select **Require authentication to view media files**.
   You cannot select this option for projects with **Public** visibility.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
