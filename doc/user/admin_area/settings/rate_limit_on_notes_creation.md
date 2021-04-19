---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rate limits on note creation **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53637) in GitLab 13.9.

This setting allows you to rate limit the requests to the note creation endpoint.

To change the note creation rate limit:

1. Go to **Admin Area > Settings > Network**.
1. Expand the **Notes Rate Limits** section.
1. Enter the new value.
1. Select **Save changes**.

This limit is:

- Applied independently per user.
- Not applied per IP address.

The default value is `300`.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 300, requests using the
[Projects::NotesController#create](https://gitlab.com/gitlab-org/gitlab/blob/master/app/controllers/projects/notes_controller.rb)
action exceeding a rate of 300 per minute are blocked. Access to the endpoint is allowed after one minute.
