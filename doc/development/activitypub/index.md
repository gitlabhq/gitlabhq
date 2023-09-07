---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# ActivityPub **(EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) in GitLab 16.5 [with two flags](../../administration/feature_flags.md) named `activity_pub` and `activity_pub_project`. Disabled by default. This feature is an [Experiment](../../policy/experiment-beta-support.md).

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
an administrator can [enable the feature flags](../../administration/feature_flags.md)
named `activity_pub` and `activity_pub_project`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

The goal of those documents is to provide an implementation path for adding
Fediverse capabilities to GitLab.

This page describes the conceptual and high level point of view, while
sub-pages discuss implementation in more technical depth (as in, how to
implement this in the actual rails codebase of GitLab).

## What

Feel free to jump to [the Why section](#why) if you already know what
ActivityPub and the Fediverse are.

Among the push for [decentralization of the web](https://en.wikipedia.org/wiki/Decentralized_web),
several projects tried different protocols with different ideals behind their reasoning.
Some examples:

- [Secure Scuttlebutt](https://en.wikipedia.org/wiki/Secure_Scuttlebutt) (or SSB for short)
- [Dat](https://en.wikipedia.org/wiki/Dat_%28software%29)
- [IPFS](https://en.wikipedia.org/wiki/InterPlanetary_File_System),
- [Solid](https://en.wikipedia.org/wiki/Solid_%28web_decentralization_project%29)

One gained traction recently: [ActivityPub](https://en.wikipedia.org/wiki/ActivityPub),
better known for the colloquial [Fediverse](https://en.wikipedia.org/wiki/Fediverse) built
on top of it, through applications like
[Mastodon](https://en.wikipedia.org/wiki/Mastodon_%28social_network%29)
(which could be described as some sort of decentralized Facebook) or
[Lemmy](https://en.wikipedia.org/wiki/Lemmy_%28software%29) (which could be
described as some sort of decentralized Reddit).

ActivityPub has several advantages that makes it attractive
to implementers and could explain its current success:

- **It's built on top of HTTP**. You don't need to install new software or
  to tinker with TCP/UDP to implement ActivityPub, if you have a webserver
  or an application that provides an HTTP API (like a rails application),
  you already have everything you need.
- **It's built on top of JSON**. All communications are basically JSON
  objects, which web developers are already used to, which simplifies adoption.
- **It's a W3C standard and already has multiple implementations**. Being
  piloted by the W3C is a guarantee of stability and quality work. They
  have profusely demonstrated in the past through their work on HTML, CSS
  or other web standards that we can build on top of their work without
  the fear of it becoming deprecated or irrelevant after a few years.

### The Fediverse

The core idea behind Mastodon and Lemmy is called the Fediverse. Rather
than full decentralization, those applications rely on federation, in the
sense that there still are servers and clients. It's not P2P like SSB,
Dat and IPFS, but instead a galaxy of servers chatting with each other
instead of having central servers controlled by a single entity.

The user signs up to one of those servers (called **instances**), and they
can then interact with users either on this instance, or on other ones.
From the perspective of the user, they access a global network, and not
only their instance. They see the articles posted on other instances, they
can comment on them, upvote them, etc.

What happens behind the scenes:
their instance knows where the user they reply to is hosted. It
contacts that other instance to let them know there is a message for them -
somewhat similar to SMTP. Similarly, when a user subscribes
to a feed, their instance informs the instance where the feed is
hosted of this subscription. That target instance then posts back
messages when new activities are created. This allows for a push model, rather
than a constant poll model like RSS. Of course, what was just described is
the happy path; there is moderation, validation and fault tolerance
happening all the way.

### ActivityPub

Behind the Fediverse is the ActivityPub protocol. It's a HTTP API
attempting to be as general a social network implementation as possible,
while giving options to be extendable.

The basic idea is that an `actor` sends and receives `activities`. Activities
are structured JSON messages with well-defined properties, but are extensible
to cover any need. An actor is defined by four endpoints, which are
contacted with the
`application/ld+json; profile="https://www.w3.org/ns/activitystreams"` HTTP Accept header:

- `GET /inbox`: used by the actor to find new activities intended for them.
- `POST /inbox`: used by instances to push new activities intended for the actor.
- `GET /outbox`: used by anyone to read the activities created by the actor.
- `POST /outbox`: used by the actor to publish new activities.

Among those, Mastodon and Lemmy only use `POST /inbox` and `GET /outbox`, which
are the minimum needed to implement federation:

- Instances push new activities for the actor on the inbox.
- Reading the outbox allows reading the feed of an actor.

Additionally, Mastodon and Lemmy implement a `GET /` endpoint (with the
mentioned Accept header). This endpoint responds with general information about the
actor, like name and URL of the inbox and outbox. While not required by the
standard, it makes discovery easier.

While a person is the main use case for an actor, an actor does not
necessarily map to a person. Anything can be an actor: a topic, a
subreddit, a group, an event. For GitLab, anything with activities (in the sense
of what GitLab means by "activity") can be an ActivityPub actor. This includes
items like projects, groups, and releases. In those more abstract examples,
an actor can be thought of as an actionable feed.

ActivityPub by itself does not cover everything that is needed to implement
the Fediverse. Most notably, these are left for the implementers to figure out:

- Finding a way to deal with spam. Spam is handled by authorizing or
  blocking ("defederating") other instances.
- Discovering new instances.
- Performing network-wide searches.

## Why

Why would a social media protocol be useful for GitLab? People want a single,
global GitLab network to interact between various projects, without having to
register on each of their hosts.

Several very popular discussions around this have already happened:

- [Share events externally via ActivityPub](https://gitlab.com/gitlab-org/gitlab/-/issues/21582)
- [Implement cross-server (federated) merge requests](https://gitlab.com/gitlab-org/gitlab/-/issues/14116)
- [Distributed merge requests](https://gitlab.com/groups/gitlab-org/-/epics/260).

The ideal workflow would be:

1. Alice registers to her favorite GitLab instance, like `gitlab.example.org`.
1. She looks for a project on a given topic, and sees Bob's project, even though
   Bob is on `gitlab.com`.
1. Alice selects **Fork**, and the `gitlab.com/Bob/project.git` is
   forked to `gitlab.example.org/Alice/project.git`.
1. She makes her edits, and opens a merge request, which appears in Bob's
   project on `gitlab.com`.
1. Alice and Bob discuss the merge request, each one from their own GitLab
   instance.
1. Bob can send additional commits, which are picked up by Alice's instance.
1. When Bob accepts the merge request, his instance picks up the code from
   Alice's instance.

In this process, ActivityPub would help in:

- Letting Bob know a fork happened.
- Sending the merge request to Bob.
- Enabling Alice and Bob to discuss the merge request.
- Letting Alice know the code was merged.

It does _not_ help in these cases, which need specific implementations:

- Implementing a network-wide search.
- Implementing cross-instance forks. (Not needed, thanks to Git.)

Why use ActivityPub here rather than implementing cross-instance merge requests
in a custom way? Two reasons:

1. **Building on top of a standard helps reach beyond GitLab**.
   While the workflow presented above only mentions GitLab, building on top
   of a W3C standard means other forges can follow GitLab
   there, and build a massive Fediverse of code sharing.
1. **An opportunity to make GitLab more social**. To prepare the
   architecture for the workflow above, smaller steps can be taken, allowing
   people to subscribe to activity feeds from their Fediverse social
   network. Anything that has a RSS feed could become an ActivityPub feed.
   People on Mastodon could follow their favorite developer, project, or topic
   from GitLab and see the news in their feed on Mastodon, hopefully raising
   engagement with GitLab.

## How

The idea of this implementation path is not to take the fastest route to
the feature with the most value added (cross-instance merge requests), but
to go on with the smallest useful step at each iteration, making sure each step
brings something immediately.

1. **Implement ActivityPub for social following**.
   After this, the Fediverse can follow activities on GitLab instances.
    1. ActivityPub to subscribe to project releases.
    1. ActivityPub to subscribe to project creation in topics.
    1. ActivityPub to subscribe to project activities.
    1. ActivityPub to subscribe to group activities.
    1. ActivityPub to subscribe to user activities.
1. **Implement cross-instance search** to enable discovering projects on other instances.
1. **Implement cross-instance forks** to enable forking a project from an other instance.
1. **Implement ActivityPub for cross-instance discussions** to enable discussing
   issues and merge requests from another instance:
    1. In issues.
    1. In merge requests.
1. **Implement ActivityPub to submit cross-instance merge requests** to enable
   submitting merge requests to other instances.

For now, see [how to implement an ActivityPub actor](actor.md).
