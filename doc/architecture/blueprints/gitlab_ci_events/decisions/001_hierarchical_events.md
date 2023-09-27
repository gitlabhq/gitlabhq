---
owning-stage: "~devops::verify"
description: 'GitLab CI Events ADR 001: Use hierarchical events'
---

# GitLab CI Events ADR 001: Use hierarchical events

## Context

We did some brainstorming in [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424865)
with multiple use-cases for running CI pipelines based on subscriptions to CI
events. The pattern of using hierarchical events emerged, it is clear that
events may be grouped together by type or by origin.

For example:

```yaml
annotate:
  on: issue/created
  script: ./annotate $[[ event.issue.id ]]

summarize:
  on: issue/closed
  script: ./summarize $[[ event.issue.id ]]
```

When making this decision we didn't focus on the syntax yet, but the grouping
of events seems to be useful in majority of use-cases.

We considered making it possible for users to subscribe to multiple events in a
group at once:

```yaml
audit:
  on: events/gitlab/gitlab-org/audit/*
  script: ./audit $[[ event.operation.name ]]
```

The implication of this is that events within the same groups should share same
fields / schema definition.

## Decision

Use hierarchical events: events that can be grouped together and that will
share the same fields following a stable contract. For example: all _issue_
events will contain `issue.iid` field.

How we group events has not been decided yet, we can either do that by
labeling or grouping using path-like syntax.

## Consequences

The implication is that we will need to build a system with stable interface
describing events' payload and / or schema.

## Alternatives

An alternative is not to use hierarchical events, and making it necessary to
subscribe to every event separately, without giving users any guarantess around
common schema for different events. This would be especially problematic for
events that naturally belong to some group and users expect a common schema
for, like audit events.
