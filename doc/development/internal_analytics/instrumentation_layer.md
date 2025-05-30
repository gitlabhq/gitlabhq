---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Single Instrumentation Layer
---

## Single Instrumentation Layer

The Single Instrumentation Layer is an event tracking abstraction that allows to track any events in GitLab using a single interface. It
uses events definitions from [Internal Event framework](internal_event_instrumentation/event_definition_guide.md) to declare event processing logic.

## Why a Single Instrumentation Layer?

The Single Instrumentation Layer allows to:

- Instrument events and processing logic in a single place
- Use the same event definitions for both instrumentation and processing
- Eliminate the need to write duplicate tracking code for the same event

## How a Single Instrumentation Layer works

[See example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415/diffs).

[Event definitions](internal_event_instrumentation/event_definition_guide.md) are used as a declarative specification for processing logic and are single source of truth for event properties, tracking parameters, and other metadata.

### Additional tracking systems

When an event is intended to be processed by tracking systems (for example, [AiTracking](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/tracking/ai_tracking.rb)), the event definition is extended to
include the additional processing logic. [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415/diffs#a77ac5c62df6c489c00e9c5dd46960f390c951d0_17_17)

This logic is declared using additional processing classes using standard interface.

## How to implement it for your tracking system

To implement it for your tracking system, you need to:

1. Add a [new event definition](internal_event_instrumentation/event_definition_guide.md) or use existing one ([see events dictionary](https://metrics.gitlab.com/events)).
1. Implement the processing logic in a new tracking class. The class should have a class method `track_event` that accepts
   an event name and additional named parameters

   ```ruby
   module Gitlab
     module Tracking
       class NewTrackingSystemProcessor
         def self.track_event(event_name, **kwargs)
           # add your tracking logic here
         end
       end
     end
   end
   ```

1. Extend the event definition with the new tracking class added in `extra_tracking_classes:` property

   ```yaml
   extra_tracking_classes:
     - Gitlab::Tracking::NewTrackingSystemProcessor
   ```

1. [Trigger the event](internal_event_instrumentation/quick_start.md#trigger-events) in your code using Internal Events framework

`**kwargs` is used to pass additional parameters to the tracking class from the Internal Events framework.
The actual parameters depend on the tracking parameters passed to the event invocation above.
Usually, it includes `user`, `namespace` and `project` along with `additional_properties` that can be used to pass any additional data.

The tracking systems will be triggered by the order of the `extra_tracking_classes:` property.

## Systems that use the Single Instrumentation Layer

1. [Internal Event](internal_event_instrumentation/quick_start.md). Is the main system that implements the tracking layer.
1. [AiTracking](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/tracking/ai_tracking.rb?ref_type=heads). Work in progress on migrating to the new layer.
