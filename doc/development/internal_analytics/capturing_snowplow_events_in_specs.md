---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Capturing frontend and backend Snowplow events in feature specs
---

`expect_snowplow_event` is a mock on `Gitlab::Tracking.event`.
It never inspects a real payload and cannot see anything the browser sends, so frontend Snowplow
events could not be asserted in a spec at all.
This mechanism, built for feature specs, captures the actual payloads GitLab emits, from both the
backend and the browser.

## Why frontend events were invisible

Every spec calls `stub_snowplow`, which points the browser's Snowplow tracker at `localhost`.
Nothing listens there in a test environment, so the events the frontend fires are emitted correctly
but have nowhere to go.

## How the capture works

Specs tagged `:capture_snowplow_events` point the browser tracker's collector hostname at the
Capybara server the spec already runs against.
A Rack middleware (`Gitlab::Testing::SnowplowCollectorMiddleware`), registered in the test
environment, answers that collector path and records every payload.
Backend events keep flowing through the existing test emitter.
Both land in the same buffer, so a spec reads them from one place regardless of origin.

Because this relies on a real browser and Capybara server, the tag requires `:js` and raises a clear
error if it is missing.
Put `:capture_snowplow_events` on individual examples, not on the surrounding `describe` or
`context` block, so examples that assert nothing about tracking do not pay for the setup.

The event buffer is created before each tagged example and thrown away after, so events from one
example are never visible to another.
Whatever you assert has to be satisfiable in a single example.

> [!note]
> `expect_snowplow_event` does not work in a `:capture_snowplow_events` example. It asserts on a
> spy that `stub_snowplow` installs with `allow(Gitlab::Tracking).to receive(:event)`, but the
> `:capture_snowplow_events` tag deliberately skips `stub_snowplow`, because it needs to control
> the collector hostname itself. Without the spy, `expect_snowplow_event` fails with an error
> about the object not being a spy, rather than anything about tracking. Use the helpers on this
> page instead. This matters most when you convert an existing spec to use event capture.

## Assert events directly

For a one-off check, use these helpers directly:

- `captured_snowplow_events` returns everything captured so far, as `SnowplowEvent` structs.
- `find_snowplow_event(**attributes)` returns the first match, or `nil`, without waiting.
- `wait_for_snowplow_event(**attributes)` polls until a match appears, then returns it.

A `SnowplowEvent` has these readers:
`event_type`, `category`, `action`, `label`, `property`, `platform`, and `experiment_context`.

`platform` is a field Snowplow itself defines:
`"web"` for browser events, `"srv"` for backend events, and it is how you tell the two apart.
`event_type` is the Snowplow `e` field:
`"se"` for a structured event, `"pv"` for a page view.

You can match a page view with `event_type: 'pv'`, but you cannot assert which page it was.
The URL is not captured.

Frontend events are POSTed to the collector asynchronously, so prefer `wait_for_snowplow_event` over
`find_snowplow_event` when the event might not have arrived yet.
It polls for up to `Capybara.default_max_wait_time` (10 seconds locally, 30 in CI) and, on failure,
prints every event that was captured.

Attribute values are compared with case equality (`===`), so you can pass an RSpec matcher, such as
`include(...)`, or a regex, not only a literal string:

```ruby
it 'tracks the upgrade banner dismissal', :js, :capture_snowplow_events do
  click_button 'Dismiss'

  event = wait_for_snowplow_event(action: 'dismiss_upgrade_banner')

  expect(event.property).to include('trial')
end
```

## Assert a tracking journey contract

Assertions written inline in a spec disappear the day that spec is deleted or rewritten, taking the
guarantee that a set of events still fires with them.
A tracking journey contract survives that: a YAML file under
`spec/fixtures/snowplow_tracking_journeys/`, named after the journey, that declares the events the
journey must emit.
It outlives any one spec and is readable without reading the Ruby that walks the journey.

The filename maps directly to the argument you assert with.
A contract at `spec/fixtures/snowplow_tracking_journeys/invite_registration.yml` is asserted with
`expect_snowplow_tracking_journey('invite_registration')`, which waits for every declared event in
turn.

A full spec looks like this:

```ruby
RSpec.describe "What's new placement experiment", :js, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  before do
    stub_experiments(whats_new_placement: :candidate)
    sign_in(user)
    visit root_path
  end

  it 'emits every event the journey declares', :capture_snowplow_events do
    find_by_testid('user-menu-toggle').click
    find_by_testid('whats-new-for-you-profile-menu-item').click

    expect_snowplow_tracking_journey('whats_new_placement', variant: 'candidate')
  end
end
```

The assertion comes last, after the interactions that cause the events, so every declared event has
had a chance to fire.

A contract looks like this:

```yaml
---
description: |
  What this journey is, and why these events matter.

events:
  - category: InvitesController
    action: join_clicked
    label: invite_email

  - category: registrations:new
    action: register
    label: invite_registration
```

Only the fields you list are checked, so a contract can be as loose or as strict as the journey
needs.
Events that fire during the journey but are not declared are allowed.
The contract only guarantees that the declared events happen, not that nothing else does.

### Find out which events fire

Do not guess event names and categories.
Frontend categories in particular are the page the event fired on, which is rarely what you would
guess.

Instead, let a failing assertion tell you:

1. Write the spec with the interactions the journey needs, and assert a contract that declares one
   event you are confident about.
1. Run the spec. If an event is not found, the failure prints every event that was captured during
   the run, with its category, action, label, property, and experiment context.
1. Copy the events that matter into the contract, and leave out incidental ones, such as
   organization fallbacks or generic activity events.

### Experiments

A contract can name an experiment and declare its arms under `variants:`:

```yaml
---
experiment: whats_new_placement
description: |
  ...

variants:
  candidate:
    events:
      - action: render_whats_new_for_you_menu_item
        property: profile_menu

  control:
    events:
      - action: render_whats_new_for_you_menu_item
        property: help_menu
```

Assert one arm at a time with a `variant:`:

```ruby
expect_snowplow_tracking_journey('whats_new_placement', variant: variant)
```

When `experiment:` is set, every event declared for the arm under test is additionally required to
carry that experiment's context, for the given variant, so you never repeat the context on each
event.

Match experiment events on that context, not on `category`.
Backend experiment events use the experiment name as their category, but frontend events are
categorized by the page they fired on, for example `root:index`.
The context is the only field both kinds of event carry.

`variants:` is meant to be temporary.
After the experiment is cleaned up, move the winning arm's events to a top-level `events:` key and
delete `experiment:` and `variants:`, leaving a permanent journey contract behind.

### Errors you might see

`expect_snowplow_tracking_journey` raises `ArgumentError` when the spec or the contract is
misconfigured.
Each of these means something to fix in the spec or the YAML file, not a problem with the product:

| Message | Meaning |
| ------- | ------- |
| `No tracking journey named '<NAME>' in <DIRECTORY>` | No contract file with that name exists. |
| `<NAME> declares no variants, drop variant: <VARIANT>` | You passed `variant:` to a contract that has no `variants:` section. |
| `<NAME> declares variants a, b, pass one` | The contract has arms, so you must say which one with `variant:`. |
| `<NAME> has no variant '<VARIANT>', only a, b` | The arm name you passed does not match any arm in the contract. |
| `<NAME> declares no events to assert` | The contract, or the arm you selected, declares no events, so the assertion would pass without checking anything. |

## Read the events a spec captured

Every example tagged `:capture_snowplow_events` writes what it captured to disk, in addition to
anything you assert in the example itself.
No extra setup is needed.
Locally, dumps land under `tmp/captured_snowplow_events/`.
In CI, they land under `rspec/captured_snowplow_events/`, which the test jobs collect as a job
artifact, because the `.artifact-base` anchor in `.gitlab/ci/rails/shared.gitlab-ci.yml` covers
that directory.
The artifact expires after 31 days.

Each example gets its own directory, named after the RSpec example ID, which is the spec file path
plus the example's scoped position, for example `1-1-1-1`.
The ID is used instead of the description because descriptions are not unique.
A shared example carries the same description into every context it runs in, so both arms of an
experiment would otherwise collide on the same directory:

```plaintext
tmp/captured_snowplow_events/
  index.json
  ee/spec/features/experiments/whats_new_placement_events_spec/
    1-1-1-1/   events.yml  payloads.json
    1-2-1-1/   events.yml  payloads.json
```

Each example directory holds two files:

- `events.yml` holds the structured events, in the same shape as a tracking journey contract,
  deduplicated, and leaving out fields the event did not carry.
  A header comment records the example description, its file and line, a UTC timestamp, and a
  count of page view and self-describing events, none of which a contract can express.
- `payloads.json` holds the raw payloads exactly as they would have been POSTed to the collector.

```yaml
# Captured from: What's new placement experiment when assigned the candidate variant ...
# ./ee/spec/features/experiments/whats_new_placement_events_spec.rb:16 at 2026-09-02T08:28:00Z
#
# Frontend categories are the page an event fired on, so they are rarely worth asserting.
# Also captured, not expressible in a contract: 1 page view, 1 self-describing event
---
events:
- category: whats_new_placement
  action: assignment
- category: root:index
  action: click_whats_new_for_you_menu_item
  property: profile_menu
```

`index.json`, at the root of the dump, maps each example's dump to the tracking journey and
variant it proves, one entry per example, so you can find a dump by experiment name without
knowing which spec produced it.
An example that captured events without asserting a journey, or that failed its journey
assertion, is listed with `"journey": null`.
A successful entry looks like this:

```json
{
  "journey": "whats_new_placement",
  "variant": "candidate",
  "events": "ee/spec/features/experiments/whats_new_placement_events_spec/1-1-1-1/events.yml",
  "payloads": "ee/spec/features/experiments/whats_new_placement_events_spec/1-1-1-1/payloads.json"
}
```

Re-running an example replaces its directory, so what is on disk is always from the most recent
run.

This removes the need to run Snowplow Micro in Docker and copy events out of its UI by hand when
you post evidence of an experiment's events into a rollout issue.
Paste the contents of `events.yml` into the issue.

Each CI job writes only the examples that ran in it, so the dumps are spread across the parallel
`rspec system` and `rspec-ee system` jobs, and each `index.json` covers a single job.
Finding the right shard takes longer than running the spec yourself, so a local run is usually the
quicker way to collect rollout evidence.

## Scope and limits

- This proves the payload the application actually emits. The capture happens at the last point
  before the HTTP POST, so it is the real payload, not a reconstruction of one.
- No collector runs, so event contexts are not validated against the Iglu schema registry. For
  that, use Snowplow Micro. See
  [Local setup and debugging](internal_event_instrumentation/local_setup_and_debugging.md).
- A contract does not record whether an event is frontend or backend, so an event that moves
  between the two still satisfies its contract.
