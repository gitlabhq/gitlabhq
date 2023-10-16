---
status: proposed
creation-date: "2023-09-12"
authors: [ "@oelmekki", "@jpcyiza" ]
coach: "@tkuah"
approvers: [ "@derekferguson" ]
owning-stage: ""
participating-stages: [ "~section::dev" ]
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# ActivityPub support

## Summary

The end goal of this proposal is to build interoperability features into
GitLab so that it's possible on one instance of GitLab to open a merge
request to a project hosted on an other instance, merging all willing
instances in a global network.

To achieve that, we propose to use ActivityPub, the w3c standard used by
the Fediverse. This will allow us to build upon a robust and battle-tested
protocol, and it will open GitLab to a wider community.

Before starting implementing cross-instance merge requests, we want to
start with smaller steps, helping us to build up domain knowledge about
ActivityPub and creating the underlying architecture that will support the
more advanced features. For that reason, we propose to start with
implementing social features, allowing people on the Fediverse to subscribe
to activities on GitLab, for example to be notified on their social network
of choice when their favorite project hosted on GitLab makes a new release.
As a bonus, this is an opportunity to make GitLab more social and grow its
audience.

## Description of the related tech and terms

Feel free to jump to [Motivation](#motivation) if you already know what
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

## Motivation

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

### Goals

- allowing to share interesting events on ActivityPub based social media
- allowing to open an issue and discuss it from one instance to an other
- allowing to fork a project from one instance to an other
- allowing to open a merge request, discuss it and merge it from one instance to an other
- allowing to perform a network wide search?

### Non-Goals

- federation of private resources
- allowing to perform a network wide search?

## Proposal

The idea of this implementation path is not to take the fastest route to
the feature with the most value added (cross-instance merge requests), but
to go on with the smallest useful step at each iteration, making sure each step
brings something immediately useful.

1. **Implement ActivityPub for social following**.
   After this, the Fediverse can follow activities on GitLab instances.
    1. ActivityPub to subscribe to project releases.
    1. ActivityPub to subscribe to project creation in topics.
    1. ActivityPub to subscribe to project activities.
    1. ActivityPub to subscribe to group activities.
    1. ActivityPub to subscribe to user activities.
1. **Implement cross-instance forks** to enable forking a project from an other instance.
1. **Implement ActivityPub for cross-instance discussions** to enable discussing
   issues and merge requests from another instance:
    1. In issues.
    1. In merge requests.
1. **Implement ActivityPub to submit cross-instance merge requests** to enable
   submitting merge requests to other instances.
1. **Implement cross-instance search** to enable discovering projects on other instances.

It's open to discussion if this last step should be included at all.
Currently, in most Fediverse apps, when you want to display a resource from
an instance that your instance does not know about (typically a user you
want to follow), you paste the URL of the resource in the search box of
your instance, and it fetches and displays the remote resource, now
actionable from your instance. We plan to do that at first.

The question is : do we keep it at that? This UX has severe frictions,
especially for users not used to Fediverse UX patterns (which is probably
most GitLab users). On the other hand, distributed search is a subject
complicated enough to deserve its own blueprint (although it's not as
complicated as it used to be, now that decentralization protocols and
applications worked on it for a while).

## Design and implementation details

First, it's a good idea to get familiar with the specifications of the
three standards we're going to use:

- [ActivityPub](https://www.w3.org/TR/activitypub/) defines the HTTP
  requests happening to implement federation.
- [ActivityStreams](https://www.w3.org/TR/activitystreams-core/) defines the
  format of the JSON messages exchanged by the users of the protocol.
- [Activity Vocabulary](https://www.w3.org/TR/activitystreams-vocabulary/)
  defines the various messages recognized by default.

Feel free to ping @oelmekki if you have questions or find the documents too
dense to follow.

### Production readiness

TBC

### The social following part

This part is laying the ground work allowing to
[add new ActivityPub actors](../../../development/activitypub/actors/index.md) to
GitLab.

There are 5 actors we want to implement:

- the `releases` actor, to be notified when given project makes a new
  release
- the `topic` actor, to be notified when a new project is added to a topic
- the `project` actor, regarding all activities from a project
- the `group` actor, regarding all activities from a group
- the `user` actor, regarding all activities from a user

We're only dealing with public resources for now. Allowing federation of
private resources is a tricky subject that will be solved later, if it's
possible at all.

#### Endpoints

Each actor needs 3 endpoints:

- the profile endpoint, containing basic info, like name, description, but
  also including links to the inbox and outbox
- the outbox endpoint, allowing to show previous activities for an actor
- the inbox endpoint, on which to post to submit follow and unfollow
  requests (among other things we won't use for now).

The controllers providing those endpoints are in
`app/controllers/activity_pub/`. It's been decided to use this namespace to
avoid mixing the ActivityPub JSON responses with the ones meant for the
frontend, and also because we may need further namespacing later, as the
way we format activities may be different for one Fediverse app, for an
other, and for our later cross-instance features. Also, this namespace
allow us to easily toggle what we need on all endpoints, like making sure
no private project can be accessed.

#### Serializers

The serializers in `app/serializers/activity_pub/` are the meat of our
implementation, are they provide the ActivityStreams objects. The abstract
class `ActivityPub::ActivityStreamsSerializer` does all the heavy lifting
of validating developer provided data, setting up the common fields and
providing pagination.

That pagination part is done through `Gitlab::Serializer::Pagination`, which
uses offset pagination.
[We need to allow it to do keyset pagination](https://gitlab.com/gitlab-org/gitlab/-/issues/424148).

#### Subscription

Subscription to a resource is done by posting a
[Follow activity](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-follow)
to the actor inbox. When receiving a Follow activity,
[we should generate an Accept or Reject activity in return](https://www.w3.org/TR/activitypub/#follow-activity-inbox),
sent to the subscriber's inbox.

The general workflow of the implementation is as following:

- A POST request is made to the inbox endpoint, with the Follow activity
  encoded as JSON
- if the activity received is not of a supported type (e.g. someone tries to
  comment on the activity), we ignore it ; otherwise:
- we create an `ActivityPub::Subscription` with the profile URL of the
  subscriber
- we queue a job to resolve the subscriber's inbox URL
  - in which we perform a HTTP request to the subscriber profile to find
    their inbox URL (and the shared inbox URL if any)
  - we store that URL in the subscription record
- we queue a job to accept the subscription
  - in which we perform a HTTP request to the subscriber inbox to post an
    Accept activity
  - we update the state of the subscription to `:accepted`

`ActivityPub::Subscription` is a new abstract model, from which inherit
models related to our actors, each with their own table:

- ActivityPub::ReleasesSubscription, table `activity_pub_releases_subscriptions`
- ActivityPub::TopicSubscription, table `activity_pub_topic_subscriptions`
- ActivityPub::ProjectSubscription, table `activity_pub_project_subscriptions`
- ActivityPub::GroupSubscription, table `activity_pub_group_subscriptions`
- ActivityPub::UserSubscription, table `activity_pub_user_subscriptions`

The reason to go with a multiple models rather than, say, a simpler `actor`
enum in the Subscription model with a single table is because we needs
specific associations and validations for each (an
`ActivityPub::ProjectSubscription` belongs to a Project, an
`ActivityPub::UserSubscription` does not). It also gives us more room for
extensibility in the future.

#### Unfollow

When receiving
[an Undo activity](https://www.w3.org/TR/activitypub/#undo-activity-inbox)
mentioning previous Follow, we remove the subscription from our database.

We are not required to send back any activity, so we don't need any worker
here, we can directly remove the record from database.

#### Sending activities out

When specific events (which ones?) happen related to our actors, we should
queue events to issue activities on the subscribers inboxes (the activities
are the same than we display in the actor's outbox).

We're supposed to deduplicate the subscriber list to make sure we don't
send an activity twice to the same person - although it's probably better
handled by a uniqueness validation from the model when receiving the Follow
activity.

More importantly, we should group requests for a same host : if ten users
are all on `https://mastodon.social/`, we should issue a single request on
the shared inbox provided, adding all the users as recipients, rather than
sending one request per user.

#### [Webfinger](https://gitlab.com/gitlab-org/gitlab/-/issues/423079)

Mastodon
[requires instance to implement the Webfinger protocol](https://docs.joinmastodon.org/spec/webfinger/).
This protocol is about adding an endpoint at a well known location which
allows to query for a resource name and have it mapped to whatever URL we
want (so basically, it's used for discovery). Mastodon uses this to query
other fediverse apps for actor names, in order to find their profile URLs.

Actually, GitLab already implements the Webfinger protocol endpoint through
Doorkeeper
([this is the action that maps to its route](https://github.com/doorkeeper-gem/doorkeeper-openid_connect/blob/5987683ccc22262beb6e44c76ca4b65288d6067a/app/controllers/doorkeeper/openid_connect/discovery_controller.rb#L14-L16)),
implemented in GitLab
[in JwksController](https://gitlab.com/gitlab-org/gitlab/-/blob/efa76816bd0603ba3acdb8a0f92f54abfbf5cc02/app/controllers/jwks_controller.rb).

There is no incompatibility here, we can just extend this controller.
Although, we'll probably have to rename it, as it won't be related to Jwks
alone anymore.

One difficulty we may have is that contrary to Mastodon, we don't only deal
with users. So we need to figure something to differentiate asking for a
user from asking for a project, for example. One obvious way would be to
use a prefix, like `user-<username>`, `project-<project_name>`, etc. I'm
pondering that from afar, while we haven't implemented much code in the
epic and I haven't dig deep into Webfinger's specs, this remark may be
deprecated when we reach actual implementation.

#### [HTTP signatures](https://gitlab.com/gitlab-org/gitlab/-/issues/423083)

Mastodon
[requires HTTP signatures](https://docs.joinmastodon.org/spec/security/#http),
which is yet an other standard, in order to make sure no spammer tries to
impersonate a given server.

This is asymmetrical cryptography, with a private key and a public key,
like SSH or PGP. We will need to implement both signing requests, and
verifying them. This will be of considerable help when we'll want to have
various GitLab instances communicate later in the epic.

### Host allowlist and denylist

To give GitLab instance owners control over potential spam, we need to
allow to maintain two mutually exclusive lists of hosts:

- the allowlist : only hosts mentioned in this list can be federated with.
- the denylist : all hosts can be federated with but the ones mentioned in
  that list.

A setting should allow the owner to switch between the allowlist and the denylist.
In the beginning, this can be managed in rails console, but it will
ultimately need a section in the admin interface.

### Limits and rollout

In order to control the load when releasing the feature in the first
months, we're going to set `gitlab.com` to use the allowlist and rollout
federation to a few Fediverse servers at a time, so that we can see how it
takes the load progressively, before ultimately switching to denylist
(note: there are
[some ongoing discussions](https://gitlab.com/gitlab-org/gitlab/-/issues/426373#note_1584232842)
regarding if federation should be activated on `gitlab.com` or not).

We also need to implement limits to make sure the federation is not abused:

- limit to the number of subscriptions a resource can receive.
- limit to the number of subscriptions a third party server can generate.

### The cross-instance issues and merge requests part

We'll wait to be done with the social following part before designing this
part, to have ground experience with ActivityPub.
