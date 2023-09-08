---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Activities for group actor **(EXPERIMENT)**

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

```javascript
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": GROUP_URL,
  "type": "Group",
  "name": GROUP_NAME,
  "summary": GROUP_DESCRIPTION,
  "url": GROUP_URL,
  "outbox": GROUP_OUTBOX_URL,
  "inbox": null,
}
```

## Outbox

The various activities for a group are:

- [The group was created](#the-group-was-created).
- All project activities for projects in that group, and its subgroups.
- [A user joined the group](#a-user-joined-the-group).
- [A user left the group](#a-user-left-the-group).
- [The group was deleted](#the-group-was-deleted).
- [A subgroup was created](#a-subgroup-was-created).
- [A subgroup was deleted](#a-subgroup-was-deleted).

### The group was created

```javascript
{
  "id": GROUP_OUTBOX_URL#event_id,
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
    "id": GROUP_URL,
    "type": "Group",
    "name": GROUP_NAME,
    "url": GROUP_URL,
  }
}
```

### A user joined the group

```javascript
{
  "id": GROUP_OUTBOX_URL#event_id,
  "type": "Join",
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
    "id": GROUP_URL,
    "type": "Group",
    "name": GROUP_NAME,
    "url": GROUP_URL,
  },
}
```

### A user left the group

```javascript
{
  "id": GROUP_OUTBOX_URL#event_id,
  "type": "Leave",
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
    "id": GROUP_URL,
    "type": "Group",
    "name": GROUP_NAME,
    "url": GROUP_URL,
  },
}
```

### The group was deleted

```javascript
{
  "id": GROUP_OUTBOX_URL#event_id,
  "type": "Delete",
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
    "id": GROUP_URL,
    "type": "Group",
    "name": GROUP_NAME,
    "url": GROUP_URL,
  }
}
```

### A subgroup was created

```javascript
{
  "id": GROUP_OUTBOX_URL#event_id,
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
    "id": GROUP_URL,
    "type": "Group",
    "name": GROUP_NAME,
    "url": GROUP_URL,
    "context": {
    "id": PARENT_GROUP_URL,
    "type": "Group",
    "name": PARENT_GROUP_NAME,
    "url": PARENT_GROUP_URL,
    }
  }
}
```

### A subgroup was deleted

```javascript
{
  "id": GROUP_OUTBOX_URL#event_id,
  "type": "Delete",
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
    "id": GROUP_URL,
    "type": "Group",
    "name": GROUP_NAME,
    "url": GROUP_URL,
    "context": {
    "id": PARENT_GROUP_URL,
    "type": "Group",
    "name": PARENT_GROUP_NAME,
    "url": PARENT_GROUP_URL,
    }
  }
}
```
