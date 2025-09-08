---
stage: AI-powered
group: Optimize
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: AI Usage Tracking
---

GitLab stores AI usage data to provide usage analytics for our customers. AI usage tracking have been generalized to
make it easy for developers to add new usage events and metrics.

### Usage event record structure

Usage records have mandatory and optional fields as described below:

| Field                     | Description                                                                                           |
|---------------------------|-------------------------------------------------------------------------------------------------------|
| `timestamp`               | Time (to milliseconds) when the event happened.                                                         |
| `user_id`                 | User who triggered the event.                                                                              |
| `event`                   | Event type ID as declared in the `AiTracking` class.                                                      |
| `namespace_id` (optional) | Reference to associated namespace. For project events it should correspond to the project namespace ID. |
| `extras` (optional)       | Any additional metadata related to specific event type.                                               |

Events are stored in the `ai_usage_events` table in Postgres and in the `ai_usage_events` table in ClickHouse, if it is available and
enabled for analytics.

### Adding new event for tracking

{{< alert type="note" >}}

If you prefer to follow along an example, see [MR 197139](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197139) which contains all the required steps to add a new
event to the AI tracking system.

{{< /alert >}}

To add a new event you must first declare the corresponding event in the `InternalEvents` subsystem.
See [Internal Event Quick Start guide](../internal_analytics/internal_event_instrumentation/quick_start.md#defining-event-and-metrics)
After you have defined the event, you must register it for AI tracking:

1. Add the event name and unique ID to `Gitlab::Tracking::AiTracking`:

   ```ruby
   events(troubleshoot_job: 7)
   ```

   {{< alert type="note" >}}

   The event type ID must be unique and will be stored in databases. If you change the ID for an existing event, ensure proper migration of existing data.

   {{< /alert >}}

   If your event has additional metadata that should be stored, you need to declare the event with a transformation.

   ```ruby
   events(troubleshoot_job: 7) do |context|
     { job_id: context['job'].id }
   end
   ```

   You can declare additional transformation blocks with the `transformation` method.

   {{< alert type="note" >}}

   Your transformation blocks must return a serializable hash, because it will be serialized to the `jsonb` column in the database.

   {{< /alert >}}

1. Invoke `InternalEvents.track_event` with your new event in appropriate codebase places to trigger the event.

### Removing an event from AI usage tracking

{{< alert type="note" >}}

If you like to be guided by example you can check [MR 199111](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199111) which contains all required steps to remove an event from AI tracking system.

{{< /alert >}}

To remove your event from the AI usage tracking system:

1. Remove all transformation blocks from the `AiTracking` definition.
1. Change the event definition to `deprecated_events(troubleshoot_job: 7)`, which will reserve ID and name for old data.
1. Regenerate the GraphQL docs with `bundle exec rake gitlab:graphql:compile_docs`.

You can completely remove definition in `AiTracking` only if you are sure no data with such ID exists anymore in databases or buffers.

### GraphQL exposure

All events declared for AI tracking can be automatically exposed
in the [`AiUsageData.all`](../../api/graphql/reference/_index.md#aiusagedata) GraphQL field.
To make this field support your new event type:

1. Add your event type to `enum` of types in `ee/app/graphql/types/analytics/ai_usage/ai_usage_event_type_enum.rb`.
1. Regenerate the GraphQL docs with `bundle exec rake gitlab:graphql:compile_docs`.

You must perform this action manually to prevent occasional breaking changes to the API when
editing or removing events.
If you want to completely remove an event type from GraphQL, you should follow the
[GraphQL field deprecation process](../../api/graphql/_index.md#deprecation-and-removal-process).

### External calls exposure

All events declared for AI tracking are automatically exposed for external event tracking. That can be useful
when tracking for events outside of Rails app. For example in IDE extension. External events can be tracked by calling
`/api/v4/usage_data/track_event` endpoint with corresponding payload in "addition_properties" field. For example:

```shell
curl "https://gitlab.com/api/v4/usage_data/track_event" --request POST --header "Authorization: Bearer glpat-XXX" --header 'Content-Type: application/json' --data '{"event": "code_suggestion_accepted_in_ide", "additional_properties": {"language": "javascript", "suggestion_size": 9, "timestamp": "2025-07-02 12:55:11 UTC", "branch_name": "my-new-feature"}, "project_id": 4}'
```

{{< alert type="note" >}}

Since external events can pass any data in additional_properties hash, it's recommended to whitelist related attributes in your event transformation block.

{{< /alert >}}
