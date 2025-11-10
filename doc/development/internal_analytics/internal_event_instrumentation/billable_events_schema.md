---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Billable Events Schema
---

## Overview

The billable events schema defines the structure and fields for tracking usage events that contribute to customer billing. This schema is used across GitLab SaaS, Dedicated, and Self-Managed deployments to capture standardized usage data for billing purposes.

This document serves as the reference for the billable usage event schema based on the [billable_usage jsonschema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/billable_usage/jsonschema).

## Field Descriptions

### Event Identification Fields

Fields that uniquely identify and categorize the billable event.

| Field | Description | Snowplow Field | Type |
|-------|-------------|----------------|------|
| `event_id` | Unique identifier for the event (RFC9562 UUID) | `event_id` | UUID (String) |
| `app_id` | Identifier for the application (e.g., Duo Workflow, Dedicated Hosted Runners) | `app_id` | String |
| `event_type` | Name of the billable event (breakdown of feature, e.g., `code_review`) | `event_type` | String |
| `timestamp` | Timestamp when the event occurred | `context_generated_at` | String |
| `correlation_id` | Unique request ID for each request | `correlation_id` | String |

### Instance & Environment Fields

Fields that identify the GitLab deployment environment and instance.

| Field | Description | Snowplow Field | Type |
|-------|-------------|----------------|------|
| `realm` | `SaaS`, `Dedicated`, or `SM` (Self-Managed) | `realm` | String (enum) |
| `deployment_type` | Deployment type: `.com`, `dedicated`, or `self-managed`. Created to replace `realm` in the future | `deployment_type` | String (enum) |
| `unique_instance_id` | Unique ID of the GitLab instance where the request originates | `unique_instance_id` | UUID (String) |
| `instance_id` | Unique ID of the GitLab instance where the request originates (GitLab version < 17.11) | `instance_id` | UUID (String) |
| `host_name` | Hostname of the GitLab instance where the request originates (e.g., `abc.xyz.com`) | `host_name` | String |

### User & Resource Identification Fields

Fields that identify users, seats, and resources associated with the billable event.

| Field | Description | Snowplow Field | Type |
|-------|-------------|----------------|------|
| `subject` | Identifier for the user in the customer organization or identifier for runner where user identification is not present | `subject` | String |
| `global_user_id` | Anonymized global user ID which is unique across instances | `global_user_id` | String |
| `assignments` | Product assignments associated with the user at the time of event creation (e.g., 'Duo Pro', 'Duo Enterprise') | - | Array[String] |
| `project_id` | ID of the associated project (e.g., `122344`) | `project_id` | Integer |
| `namespace_id` | ID of the associated namespace (e.g., `3445555`) | `namespace_id` | Integer |
| `root_namespace_id` | ID of the associated ultimate parent namespace (e.g., `5343322`) | `root_namespace_id` | Integer |
| `entity_id` | ID of the entity associated with the event | `entity_id` | String |

### Usage Measurement Fields

Fields that capture the actual usage quantities for billing.

| Field | Description | Snowplow Field | Type |
|-------|-------------|----------------|------|
| `unit_of_measure` | The base unit used for measurement and billing (e.g., 'byte', 'second', 'request'). Used for accurate unit conversion and billing calculations. | `unit_of_measure` | String |
| `quantity` | Quantity of usage measured in the specified unit | `quantity` | Decimal (Number) |
| `metadata` | Flexible metadata field for key-value pairs or nested objects containing additional context | `metadata` | Object (JSON) |

## Implementation Guidelines

### Required Fields for Billing

The following fields are critical for billing calculations and must be present in all billable events:

- `event_id`: Ensures event uniqueness and deduplication
- `event_type`: Categorizes the billable activity
- `unit_of_measure`: Defines the billing unit
- `realm`: Identifies the deployment model
- `timestamp`: Enables time-based billing and analysis

### Field Population Guidelines

1. **Event Identification**: Always generate a unique RFC9562 UUID for `event_id`
1. **Timestamps**: Use ISO 8601 format (e.g., `2025-11-04T10:30:00Z`)
1. **Unit of Measure**: Choose appropriate units (`byte`, `second`, `token`, `request`, etc.)
1. **Quantity**: Must be a non-negative, non-zero number representing actual usage
1. **Metadata**: Use for additional context that aids in analytics but is not required for billing

### Metadata fields for Duo Agent Platform

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `workflow_id` | String | Unique identifier for the workflow execution | Yes |
| `execution_environment` | String | Environment where the workflow was executed (e.g., `duo_agent_platform`) | Yes |
| `llm_operations` | Array | List of LLM operations performed during the workflow | Yes |
| `llm_operations[].token_count` | Integer | Total number of tokens used in the operation | Yes |
| `llm_operations[].model_id` | String | Identifier of the LLM model used (e.g., `claude-3-sonnet-20240229`) | Yes |
| `llm_operations[].prompt_tokens` | Integer | Number of tokens in the prompt | Yes |
| `llm_operations[].completion_tokens` | Integer | Number of tokens in the completion/response | Yes |

---

**Example:**

```json
{
    "workflow_id": "wf_123456",
    "execution_environment": "duo_agent_platform",
    "llm_operations": [
        {
            "token_count": 5328,
            "model_id": "claude-3-sonnet-20240229",
            "prompt_tokens": 3150,
            "completion_tokens": 2178
        },
        {
            "token_count": 5328,
            "model_id": "claude-opus-4.1",
            "prompt_tokens": 3150,
            "completion_tokens": 2178
        }
    ]
}
```

---
