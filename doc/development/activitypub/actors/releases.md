---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Activities for following releases actor
---

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) in GitLab 16.5 [with two flags](../../../administration/feature_flags.md) named `activity_pub` and `activity_pub_project`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available,
an administrator can [enable the feature flags](../../../administration/feature_flags.md)
named `activity_pub` and `activity_pub_project`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

This feature requires two feature flags:

- `activity_pub`: Enables or disables all ActivityPub-related features.
- `activity_pub_project`: Enables and disable ActivityPub features specific to
  projects. Requires the `activity_pub` flag to also be enabled.

## Profile

The profile is this actor is a bit different from other actors. We don't want to
show activities for a given release, but instead the releases for a given project.

The profile endpoint is handled by `Projects::ReleasesController#index`
on the list of releases, and should reply with something like this:

```javascript
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": PROJECT_RELEASES_URL,
  "type": "Application",
  "name": PROJECT_NAME + " releases",
  "url": PROJECT_RELEASES_URL,
  "content": PROJECT_DESCRIPTION,
  "context": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
  "outbox": PROJECT_RELEASES_OUTBOX_URL,
  "inbox": null,
}
```

## Outbox

The release actor is relatively simple: the only activity happening is the
**Create release** event.

```javascript
{
  "id": PROJECT_RELEASES_OUTBOX_URL#release_id,
  "type": "Create",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": RELEASE_URL,
    "type": "Application",
    "name": RELEASE_TITLE,
    "url": RELEASE_URL,
    "content": RELEASE_DESCRIPTION,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
}
```
