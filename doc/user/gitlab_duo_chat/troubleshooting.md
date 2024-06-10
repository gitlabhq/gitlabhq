---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Chat troubleshooting

When working with GitLab Duo Chat, you might encounter the following issues.

## The **GitLab Duo Chat** button is not displayed

If the button is not visible in the upper-right of the UI,
ensure GitLab Duo Chat [is enabled](turn_on_off.md).

The **GitLab Duo Chat** button is not displayed on personal projects,
as well as
[groups and projects with GitLab Duo features disabled](turn_on_off.md).

After you enable GitLab Duo Chat, it might take a few minutes for the
button to appear.

## `This feature is only allowed in groups or projects that enable this feature`

This error occurs when you ask about resources that do have
GitLab Duo [disabled](turn_on_off.md).

If any of the settings are not enabled, information about resources
(like issues, epics, and merge requests) in the group or project
cannot be processed by GitLab Duo Chat.

## `I am sorry, I am unable to find what you are looking for`

This error occurs when you ask GitLab Duo Chat about resources you don't have access to,
or about resources that do not exist.

Try again, asking about resources you have access to.

## `I'm sorry, I can't find the answer, but it's my fault, not yours. Please try something different`

This is a fallback error that occurs when there is a problem with GitLab Duo Chat.
Please try your request again, or leave feedback to help us improve.
