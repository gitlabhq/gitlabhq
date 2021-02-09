---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Active sessions

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17867) in GitLab 10.8.

GitLab lists all devices that have logged into your account. This allows you to
review the sessions, and revoke any you don't recognize.

## Listing all active sessions

To list all active sessions:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Active Sessions**.

![Active sessions list](img/active_sessions_list.png)

## Active sessions limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31611) in GitLab 12.6.

GitLab allows users to have up to 100 active sessions at once. If the number of active sessions
exceeds 100, the oldest ones are deleted.

## Revoking a session

To revoke an active session:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Active Sessions**.
1. Select **Revoke** next to a session. The current session cannot be revoked, as this would sign you out of GitLab.

NOTE:
When any session is revoked all **Remember me** tokens for all
devices are revoked. See ['Why do I keep getting signed out?'](index.md#why-do-i-keep-getting-signed-out)
for more information about the **Remember me** feature.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
