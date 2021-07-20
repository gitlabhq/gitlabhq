---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Audit Event Guide

This guide provides an overview of how Audit Events work, and how to instrument
new audit events.

## What are Audit Events?

Audit Events are a tool for GitLab owners and administrators to view records of important
actions performed across the application.

## Audit Event Schemas

To instrument an audit event, the following attributes should be provided:

| Attribute    | Type                 | Required? | Description                                         |
|:-------------|:---------------------|:----------|:----------------------------------------------------|
| `name`       | String               | false     | Action name to be audited. Used for error tracking  |
| `author`     | User                 | true      | User who authors the change                         |
| `scope`      | User, Project, Group | true      | Scope which the audit event belongs to              |
| `target`     | Object               | true      | Target object being audited                         |
| `message`    | String               | true      | Message describing the action                       |

## How to instrument new Audit Events

There are three ways of instrumenting audit events:

- Create a new class in `ee/lib/ee/audit/` and extend `AuditEventService`
- Call `AuditEventService` after a successful action
- Call `Gitlab::Audit::Auditor.audit` passing an action block

This inconsistency leads to unexpected bugs, increases maintainer effort, and worsens the
developer experience. Therefore, we suggest you use `Gitlab::Audit::Auditor` to
instrument new audit events.

With new service, we can instrument audit events in two ways:

- Using block for multiple events.
- Using standard method call for single events.

### Using block to record multiple events

This method is useful when events are emitted deep in the call stack.

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

Please note that this method does not support actions that are asynchronous, or
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
    message: 'Created a new approval rule'
  }

  ::Gitlab::Audit::Auditor.audit(audit_context)
end
```

## Audit Event instrumentation flows

The two ways we can instrument audit events have different flows.

### Using block to record multiple events

We wrap the operation block in a `Gitlab::Audit::Auditor` which captures the
initial audit context (that is, `author`, `scope`, `target`) object that are
available at the time the operation is initiated.

Extra instrumentation is required in the interacted classes in the chain with
`Auditable` mixin to add audit events to the Audit Event queue via `Gitlab::Audit::EventQueue`.

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
[a log file](../../administration/logs.md#audit_jsonlog).
