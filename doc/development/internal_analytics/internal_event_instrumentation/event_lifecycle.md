---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Event lifecycle
---

The following guidelines explain the steps to follow at each stage of an event's lifecycle.

## Add an event

See the [event definition guide](event_definition_guide.md) for more details.

## Remove an event

To remove an event:

1. Move the event definition file to the `/removed` subfolder.
1. Update the event definition file to set the `status` field to `removed`.
1. Update the event definition file to set the `milestone_removed` field to the milestone when the event was removed.
1. Update the event definition file to set the `removed_by_url` field to the URL of the merge request that removed the event.
1. Remove the event tracking from the codebase.
1. Remove the event tracking tests.
