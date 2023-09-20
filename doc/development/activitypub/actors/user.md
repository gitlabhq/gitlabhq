---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Activities for following user actor **(EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) in GitLab 16.5 [with two flags](../../../administration/feature_flags.md) named `activity_pub` and `activity_pub_project`. Disabled by default. This feature is an [Experiment](../../../policy/experiment-beta-support.md).

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
an administrator can [enable the feature flags](../../../administration/feature_flags.md)
named `activity_pub` and `activity_pub_project`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

This feature requires two feature flags:

- `activity_pub`: Enables or disables all ActivityPub-related features.
- `activity_pub_project`: Enables and disable ActivityPub features specific to
  projects. Requires the `activity_pub` flag to also be enabled.

## Profile

This activity is the first resource ActivityPub has in mind:

```javascript
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": USER_PROFILE_URL,
  "type": "Person",
  "name": USER_NAME,
  "url": USER_PROFILE_URL,
  "outbox": USER_OUTBOX_URL,
  "inbox": null,
}
```

## Outbox

The user actor is special because it can be linked to all events happening on the platform.
It's a join of events on other resources:

- All release activities.
- All project activities.
- All group activities.
