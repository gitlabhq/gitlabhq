---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Active sessions
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab lists all devices that have logged into your account. You can
review the sessions, and revoke any you don't recognize.

## List all active sessions

To list all active sessions:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Active Sessions**.

![Active sessions list](img/active_sessions_list_v12_7.png)

## Active sessions limit

GitLab allows users to have up to 100 active sessions at once. If the number of active sessions
exceeds 100, the oldest ones are deleted.

## Revoke a session

To revoke an active session:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Active Sessions**.
1. Select **Revoke** next to a session. The current session cannot be revoked, as this would sign you out of GitLab.

NOTE:
When any session is revoked all **Remember me** tokens for all
devices are revoked. For details about **Remember me**, see
[cookies used for sign-in](_index.md#cookies-used-for-sign-in).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
