---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Implement an ActivityPub actor
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

ActivityPub is based on three standard documents:

- [ActivityPub](https://www.w3.org/TR/activitypub/) defines the HTTP
  requests happening to implement federation.
- [ActivityStreams](https://www.w3.org/TR/activitystreams-core/) defines the
  format of the JSON messages exchanged by the users of the protocol.
- [Activity Vocabulary](https://www.w3.org/TR/activitystreams-vocabulary/)
  defines the various messages recognized by default.

The first one is typically handled by controllers, while the two others are
related to what happen in serializers.

To implement an ActivityPub actor, you must:

- Implement the profile page of the resource.
- Implement the outbox page.
- Handle incoming requests on the inbox.

All requests are made using
`application/ld+json; profile="https://www.w3.org/ns/activitystreams"` as `Accept` HTTP header.

The actors we've implemented for the social features:

- [Releases](releases.md)

For more information on planned actors, see [epic 11247](https://gitlab.com/groups/gitlab-org/-/epics/11247).

## Profile page

Querying the profile page is used to retrieve:

- General information about it, like name and description.
- URLs for the inbox and the outbox.

To implement a profile page, create an ActivityStreams
serializer in `app/serializers/activity_pub/`, making your serializer
inherit from `ActivityStreamsSerializer`. See below in the serializers
section about the mandatory fields.

To call your serializer in your controller:

```ruby
opts = {
  inbox: nil,
  outbox: outbox_project_releases_url(project)
}

render json: ActivityPub::ReleasesActorSerializer.new.represent(project, opts)
```

- `outbox` is the endpoint where to find the activities feed for this
  actor.
- `inbox` is where to POST to subscribe to the feed. Not yet implemented, so pass `nil`.

## Outbox page

The outbox is the list of activities for the resource. It's a feed for the
resource, and it allows ActivityPub clients to show public activities for
this actor without having yet subscribed to it.

To implement an outbox page, create an ActivityStreams
serializer in `app/serializers/activity_pub/`, making your serializer
inherit from `ActivityStreamsSerializer`. See below in the serializers
section about the mandatory fields.

You call your serializer in your controller like this:

```ruby
serializer = ActivityPub::ReleasesOutboxSerializer.new.with_pagination(request, response)
render json: serializer.represent(releases)
```

This converts the response to an `OrderedCollection`
ActivityPub type, with all the correct fields.

## Inbox

Not yet implemented.

The inbox is where the ActivityPub compatible third-parties makes their
requests, to subscribe to the actor or send it messages.

## ActivityStreams serializers

The serializers implement half the core of ActivityPub support: they're all
about [ActivityStreams](https://www.w3.org/TR/activitystreams-core/), the
message format used by ActivityPub.

To leverage the features doing most of the formatting for you, your
serializer should inherit from `ActivityPub::ActivityStreamsSerializer`.

To use it, call the `#represent` method. It requires you to provide
`inbox` and `outbox` options (as mentioned above) if it
is an actor profile page. You don't need those if your serializer
represents an object that is just meant to be embedded as part of actors,
like the object representing the contact information for a user.

Each resource serialized (included other objects embedded in your
actor) must provide an `id` and a `type` field.

`id` is a URL. It's meant to be a unique identifier for the resource, and
it must point to an existing page: ideally, an actor. Otherwise, you can
just reference the closest actor and use an anchor, like this:

```plaintext
https://gitlab.com/user/project/-/releases#release-1
```

`type` should be taken from ActivityStreams core vocabulary:

- [Activity types](https://www.w3.org/TR/activitystreams-vocabulary/#activity-types)
- [Actor types](https://www.w3.org/TR/activitystreams-vocabulary/#actor-types)
- [Object types](https://www.w3.org/TR/activitystreams-vocabulary/#object-types)

The properties you can use are all documented in
[the ActivityStreams vocabulary document](https://www.w3.org/TR/activitystreams-vocabulary/).
Given the type you have chosen for your resource, find the
`properties` list, telling you all available properties, direct or
inherited.

It's worth noting that Mastodon adds one more property, `preferredName`.
Mastodon expects it to be set on any actor, or that actor is not recognized by
Mastodon.
