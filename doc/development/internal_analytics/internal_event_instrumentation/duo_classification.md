---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GitLab Duo Classification
---

This guide explains how to properly add the `classification: duo` field to event definitions for AI and GitLab Duo features.

## What is the `classification` field?

The `classification` field is an optional property in event definitions that categorizes events based on their data handling requirements. Currently, the only supported value is `duo`, which is used specifically for AI and GitLab Duo-related features.

## When to use `classification: duo`

Add `classification: duo` to your event definition when:

- You are instrumenting AI or GitLab Duo features (e.g., GitLab Duo Chat, GitLab Duo Workflow, AI-powered suggestions)
- Your event is owned by AI Engineering product groups such as:
  - `duo_chat`
  - `ai_framework`
  - `duo_agent_framework`
  - Other AI-related product groups
- The event data should be considered operational data for GitLab self-managed instances

## When NOT to use `classification: duo`

**Important**: Do not add `classification: duo` if:

- Your event is not related to AI or GitLab Duo features
- You are instrumenting general GitLab features unrelated to AI

If your event doesn't fall under GitLab Duo features, remove the classification field entirely rather than leaving it empty.

## Data handling implications

Events with `classification: duo` are treated as operational data, which means:

- They will flow through GitLab self-managed instances even when analytics data collection is opted out
- This ensures essential AI feature functionality and monitoring continues to work
- The data is considered necessary for operational purposes rather than purely analytical

## Example event definition with `classification: duo`

Here's an example of a properly configured GitLab Duo Chat event:

```yaml
---
description: "User submits a Duo Chat message.
  The message is analyzed using LLM (e.g. categorization) and Ruby (e.g. message length).
  Schema: https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/ai_question_category/jsonschema
  Category list: https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/fixtures/categories.xml"
category: Gitlab::Llm::AiGateway::Completions::CategorizeQuestion
action: ai_question_category
classification: duo
identifiers:
  - user
product_group: duo_chat
milestone: '16.6'
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132803
tiers:
  - ultimate
additional_properties:
  property:
    description: Request ID to link to other events of the same AI request.
```

### Adding GitLab Duo events to external services

Events defined by other services that are forwarded through the monolith should be added to the list in [EventEligibilityChecker](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/tracking/event_eligibility_checker.rb#L10).

This ensures that events are forwarded through the instance even when analytics data collection is opted out.

### GitLab Duo Workflow Events

```yaml
---
description: Tracks duo workflow start event
internal_events: true
action: start_duo_workflow_execution
classification: duo
identifiers:
- user
- project
- namespace
product_group: duo_agent_framework
milestone: '17.0'
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150000
tiers:
- ultimate
```

## Validation

The classification field is validated against the JSON Schema. Currently, only `duo` is accepted as a valid value.
