---
stage: Software Supply Chain Security
group: Compliance
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Audit event development guidelines
---

This guide provides an overview of how audit events work, and how to instrument
new audit events.

## What are audit events?

Audit events are a tool for GitLab owners and administrators to view records of important
actions performed across the application.

## What should not be audit events?

While any events could trigger an audit event, not all events should. In general, events that are not good candidates for audit events are:

- Not attributable to one specific user.
- Not of specific interest to an administrator or owner persona.
- Are tracking information for product feature adoption.
- Are covered in the direction page's discussion on [what is not planned](https://about.gitlab.com/direction/govern/compliance/audit-events/#what-is-not-planned-right-now).

If you have any questions, reach out to `@gitlab-org/govern/compliance` to see if an audit event, or some other approach, may be best for your event.

## Audit event schemas

To instrument an audit event, the following attributes should be provided:

| Attribute    | Type                                | Required? | Description                                                       |
|:-------------|:------------------------------------|:----------|:------------------------------------------------------------------|
| `name`       | String                              | false     | Action name to be audited. Represents the [type of the event](#event-type-definitions). Used for error tracking |
| `author`     | User                                | true      | User who authors the change. Can be an [internal user](../../administration/internal_users.md). For example, [inactive project deletion](../../administration/inactive_project_deletion.md) audit events are authored by `GitLab-Admin-Bot`. |
| `scope`      | User, Project, Group, or Instance | true      | Scope which the audit event belongs to                            |
| `target`     | Object                              | true      | Target object being audited                                       |
| `message`    | String                              | true      | Message describing the action ([not translated](#i18n-and-the-audit-event-message-attribute)) |
| `created_at` | DateTime                            | false     | The time when the action occurred. Defaults to `DateTime.current` |

## How to instrument new audit events

1. Create a [YAML type definition](#add-a-new-audit-event-type) for the new audit event.
1. Call `Gitlab::Audit::Auditor.audit`, passing an action block.

The following ways of instrumenting audit events are deprecated:

- Create a new class in `ee/lib/ee/audit/` and extend `AuditEventService`
- Call `AuditEventService` after a successful action

With `Gitlab::Audit::Auditor` service, we can instrument audit events in two ways:

- Using block for multiple events.
- Using standard method call for single events.

### Using block to record multiple events

You can use this method when events are emitted deep in the call stack.

For example, we can record multiple audit events when the user updates a merge
request approval rule. As part of this user flow, we would like to audit changes
to both approvers and approval groups. In the initiating service
(for example, `MergeRequestRuleUpdateService`), we can wrap the `execute` call as follows:

```ruby
# in the initiating service
audit_context = {
  name: 'update_merge_approval_rule',
  author: current_user,
  scope: project_alpha,
  target: merge_approval_rule,
  message: 'Attempted to update an approval rule'
}

::Gitlab::Audit::Auditor.audit(audit_context) do
  service.execute
end
```

In the model (for example, `ApprovalProjectRule`), we can push audit events on model
callbacks (for example, `after_save` or `after_add`).

```ruby
# in the model
include Auditable

def audit_add(model)
  push_audit_event('Added an approver on Security rule')
end

def audit_remove(model)
  push_audit_event('Removed an approver on Security rule')
end
```

This method does not support actions that are asynchronous, or
span across multiple processes (for example, background jobs).

### Using standard method call to record single event

This method allows recording single audit event and involves fewer moving parts.

```ruby
if merge_approval_rule.save
  audit_context = {
    name: 'create_merge_approval_rule',
    author: current_user,
    scope: project_alpha,
    target: merge_approval_rule,
    message: 'Created a new approval rule',
    created_at: DateTime.current # Useful for pre-dating an audit event when created asynchronously.
  }

  ::Gitlab::Audit::Auditor.audit(audit_context)
end
```

### Data volume considerations

Because every audit event is persisted to the database, consider the amount of data we expect to generate, and the rate of generation, for new
audit events. For new audit events that produce a lot of data in the database, consider adding a
[streaming-only audit event](#event-streaming) instead. If you have questions about this, feel free to ping
`@gitlab-org/govern/compliance/backend` in an issue or merge request.

## Audit event instrumentation flows

The two ways we can instrument audit events have different flows.

### Using block to record multiple events

We wrap the operation block in a `Gitlab::Audit::Auditor` which captures the
initial audit context (that is, `author`, `scope`, `target`) object that are
available at the time the operation is initiated.

Extra instrumentation is required in the interacted classes in the chain with
`Auditable` mixin to add audit events to the audit event queue via `Gitlab::Audit::EventQueue`.

The `EventQueue` is stored in a local thread via `SafeRequestStore` and then later
extracted when we record an audit event in `Gitlab::Audit::Auditor`.

```plantuml
skinparam shadowing false
skinparam BoxPadding 10
skinparam ParticipantPadding 20

participant "Instrumented Class" as A
participant "Audit::Auditor" as A1 #LightBlue
participant "Audit::EventQueue" as B #LightBlue
participant "Interacted Class" as C
participant "AuditEvent" as D

A->A1: audit <b>{ block }
activate A1
A1->B: begin!
A1->C: <b>block.call
activate A1 #FFBBBB
activate C
C-->B: push [ message ]
C-->A1: true
deactivate A1
deactivate C
A1->B: read
activate A1 #FFBBBB
activate B
B-->A1: [ messages ]
deactivate B
A1->D: bulk_insert!
deactivate A1
A1->B: end!
A1-->A:
deactivate A1
```

### Using standard method call to record single event

This method has a more straight-forward flow, and does not rely on `EventQueue`
and local thread.

```plantuml
skinparam shadowing false
skinparam BoxPadding 10
skinparam ParticipantPadding 20

participant "Instrumented Class" as A
participant "Audit::Auditor" as B #LightBlue
participant "AuditEvent" as C

A->B: audit
activate B
B->C: bulk_insert!
B-->A:
deactivate B
```

In addition to recording to the database, we also write these events to
[a log file](../../administration/logs/_index.md#audit_jsonlog).

## Event type definitions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367847) in GitLab 15.4.

All new audit events must have a type definition stored in `config/audit_events/types/` or `ee/config/audit_events/types/` that contains a single source of truth for every auditable event in GitLab.

### Add a new audit event type

To add a new audit event type:

1. Create the YAML definition. You can either:
   - Use the `bin/audit-event-type` CLI to create the YAML definition automatically.
   - Perform manual steps to create a new file in `config/audit_events/types/` with the filename matching the name of the event type. For example,
     a definition for the event type triggered when a user is added to a project might be stored in `config/audit_events/types/project_add_user.yml`.
1. Add contents to the file that conform to the [schema](#schema) defined in `config/audit_events/types/type_schema.json`.
1. Ensure that all calls to `Gitlab::Audit::Auditor` use the `name` defined in your file.

### Schema

| Field | Required | Description |
| ----- | -------- |--------------|
| `name` | yes     | Unique, lowercase and underscored name describing the type of event. Must match the filename. |
| `description` | yes | Human-readable description of how this event is triggered |
| `group` | yes | Name of the group that introduced this audit event. For example, `manage::compliance` |
| `introduced_by_issue` | yes | Issue URL that proposed the addition of this type |
| `introduced_by_mr` | yes | MR URL that added this new type |
| `milestone` | yes | Milestone in which this type was added |
| `saved_to_database` | yes | Indicate whether to persist events to database and JSON logs |
| `streamed` | yes | Indicate that events should be streamed to external services (if configured) |
| `scope` | yes | List of scopes that this audit event type is available for. Should be an Array containing one or more of `Project`, `User`, `Group` or `Instance` |

### Generate documentation

Audit event types documentation is automatically generated and [published](../../user/compliance/audit_event_types.md)
to the GitLab documentation site.

If you add a new audit event type, run the
[`gitlab:audit_event_types:compile_docs` Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/audit_event_types/audit_event_types.rake)
to update the documentation:

```shell
bundle exec rake gitlab:audit_event_types:compile_docs
```

Run the [`gitlab:audit_event_types:check_docs` Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/audit_event_types/audit_event_types.rake)
to check if the documentation is up-to-date:

```shell
bundle exec rake gitlab:audit_event_types:check_docs
```

## Event streaming

All events where the entity is a `Group` or `Project` are recorded in the audit log, and also streamed to one or more
[event streaming destinations](../../administration/audit_event_streaming/_index.md). When the entity is a:

- `Group`, events are streamed to the group's root ancestor's event streaming destinations.
- `Project`, events are streamed to the project's root ancestor's event streaming destinations.

You can add streaming-only events that are not stored in the GitLab database. Streaming-only events are primarily intended to be used for actions that generate
a large amount of data. See [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76719/diffs#d56e47632f0384722d411ed3ab5b15e947bd2265_26_36)
for an example.
This feature is under heavy development. Follow the [parent epic](https://gitlab.com/groups/gitlab-org/-/epics/5925) for updates on feature
development.

### I18N and the audit event `:message` attribute

We intentionally do not translate audit event messages because translated messages would be saved in the database and served to users, regardless of their locale settings.

For example, this could mean that we use the locale for the authenticated user to record an audit event message and stream the message to an external streaming
destination in the wrong language for that destination. Users could find that confusing.
