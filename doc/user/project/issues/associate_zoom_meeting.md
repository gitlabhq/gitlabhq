---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Associate a Zoom meeting with an issue **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16609) in GitLab 12.4.

In order to communicate synchronously for incidents management,
GitLab allows to associate a Zoom meeting with an issue.
After you start a Zoom call for a fire-fight, you need a way to
associate the conference call with an issue. This is so that your
team members can join swiftly without requesting a link.

## Adding a Zoom meeting to an issue

To associate a Zoom meeting with an issue, you can use GitLab
[quick actions](../quick_actions.md#issues-merge-requests-and-epics).

In an issue, leave a comment using the `/zoom` quick action followed by a valid Zoom link:

```shell
/zoom https://zoom.us/j/123456789
```

If the Zoom meeting URL is valid and you have at least [Reporter permissions](../../permissions.md),
a system alert notifies you of its successful addition.
The issue's description is automatically edited to include the Zoom link, and a button
appears right under the issue's title.

![Link Zoom Call in Issue](img/zoom-quickaction-button.png)

You are only allowed to attach a single Zoom meeting to an issue. If you attempt
to add a second Zoom meeting using the `/zoom` quick action, it doesn't work. You
need to [remove it](#removing-an-existing-zoom-meeting-from-an-issue) first.

## Removing an existing Zoom meeting from an issue

Similarly to adding a Zoom meeting, you can remove it with a quick action:

```shell
/remove_zoom
```

If you have at least [Reporter permissions](../../permissions.md),
a system alert notifies you that the meeting URL was successfully removed.
