---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits on note creation
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can configure the per-user rate limit for requests to the note creation endpoint.

To change the note creation rate limit:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Notes rate limit**.
1. In the **Maximum requests per minute** box, enter the new value.
1. Optional. In the **Users to exclude from the rate limit** box, list users allowed to exceed the limit.
1. Select **Save changes**.

This limit is:

- Applied independently per user.
- Not applied per IP address.

The default value is `300`.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 300, requests using the
[Projects::NotesController#create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/notes_controller.rb)
action exceeding a rate of 300 per minute are blocked. Access to the endpoint is allowed after one minute.
