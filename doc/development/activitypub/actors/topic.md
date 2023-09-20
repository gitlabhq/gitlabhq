---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Activities for topic actor **(EXPERIMENT)**

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
  "id": TOPIC_URL,
  "type": "Group",
  "name": TOPIC_NAME,
  "url": TOPIC_URL,
  "summary": TOPIC_DESCRIPTION,
  "outbox": TOPIC_OUTBOX_URL,
  "inbox": null,
}
```

## Outbox

Like the release actor, the topic specification is not complex. It generates an
activity only when a new project has been added to the given topic.

```javascript
{
  "id": TOPIC_OUTBOX_URL#event_id,
  "type": "Add",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "url": PROJECT_URL,
  },
  "object": {
    "id": TOPIC_URL,
    "type": "Group",
    "name": TOPIC_NAME,
    "url": TOPIC_URL,
    },
  },
}
```

## Possible difficulties

There is hidden complexity here.

The simpler way to build this endpoint is to take the projects associated
to a topic, and sort them by descending creation date. However,
if we do that, discrepancies will occur when implementing the
activity push part of the standard.

Adding the project to a topic is not made at project creation time. It's
made when a project's topics are _edited_. That action can happen a very long time
after the project creation date. In that case, a push activity is
created and sent to federated instances when adding the topic to the
project. However, the list in the outbox endpoint that sorts projects by descending
creation date doesn't show the project, because it was created long ago.

No special logic happens when a topic is added to a project, except:

- Cleaning up the topic list.
- Creating the topic in database, if it doesn't exist yet.

No event is generated. We should add such an event so the activity
push create an event, ideally in `Projects::UpdateService`. Then, the outbox endpoint
can list those events to be sure to match what was sent. When doing that, we should
verify that it doesn't affect other pages or endpoints dealing with events.
