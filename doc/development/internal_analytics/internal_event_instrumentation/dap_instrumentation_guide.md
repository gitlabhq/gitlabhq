---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: DAP (Duo Agentic Platform) Instrumentation Guide
---

This guide provides comprehensive instructions for instrumenting GitLab Duo Agentic Platform (DAP) events using Internal Events Tracking.
DAP events require both Standard Context and AI Context to capture complete tracking information.

## Overview

The Duo Agentic Platform (DAP) is the framework for building and executing AI-powered workflows.
Proper instrumentation of DAP events is essential for:

- Tracking usage and adoption of AI features
- Monitoring performance and reliability
- Billing and resource allocation
- Understanding user behavior and workflow patterns
- Measuring token consumption and costs

## DAP Instrumentation Requirements

All DAP events must include:

1. **Event Definition** with `classification: duo`
1. **Standard Context** - Standard tracking fields (user, project, namespace)
1. **AI Context** - AI-specific fields (session, workflow, tokens, model)
1. **Session-level Events** - Standardized events for workflow lifecycle

## Required Contexts

### Standard Context

The Standard Context provides general tracking information and should include:

- `user` - The user executing the workflow
- `project` - The project associated with the workflow (when applicable)
- `namespace` - The namespace associated with the workflow

See [Standard Context Fields](standard_context_fields.md) for complete field descriptions.

### AI Context

The AI Context captures AI-specific attributes for DAP events. Required and recommended fields:

**Required Fields:**

- `session_id` - Local session identifier from the instance

**Recommended Fields:**

- `flow_type` - Type of DAP flow (e.g., `chat`, `software_development`, `code_review`)
- `agent_name` - Name of the agent executing the action
- `agent_type` - Type of agent executing the action
- `flow_version` - Version of the flow implementation
- `input_tokens` - Number of input tokens sent to the AI model
- `output_tokens` - Number of output tokens received from the AI model
- `total_tokens` - Total tokens used (input + output)
- `ephemeral_5m_input_tokens` - 5-minute cached input tokens
- `ephemeral_1h_input_tokens` - 1-hour cached input tokens
- `cache_read` - Cache read operations

**Model Information (Standard Context):**

Model information should be tracked in Standard Context, not AI Context:

- `model_provider` - AI model provider (e.g., `anthropic`, `openai`)
- `model_engine` - Model engine or family (e.g., `claude-3-5`, `gpt-4`)
- `model_name` - Specific model name (e.g., `claude-3-5-sonnet-20241022`)

See [AI Event Instrumentation Guide](ai_context_fields.md) for complete field descriptions and examples.

## Session-Level Events

DAP workflows should instrument the following standardized session-level events to track the complete workflow lifecycle:

### Workflow Lifecycle Events

| Event Name | Description | When to Track |
|------------|-------------|---------------|
| `receive_start_duo_workflow` | User initiates a Duo workflow | When the workflow start request is received |
| `request_duo_workflow` | Workflow execution request is sent | When the workflow execution begins |
| `request_duo_workflow_success` | Workflow execution completes successfully | When the workflow finishes without errors |
| `request_duo_workflow_failure` | Workflow execution fails | When the workflow encounters an error |
| `pause_duo_workflow` | User pauses an active workflow | When a workflow is paused by user action |
| `resume_duo_workflow` | User resumes a paused workflow | When a paused workflow is resumed |

### Tool Execution Events

| Event Name | Description | When to Track |
|------------|-------------|---------------|
| `duo_workflow_tool_success` | A tool within the workflow executes successfully | When a workflow tool completes successfully |
| `duo_workflow_tool_failure` | A tool within the workflow fails | When a workflow tool encounters an error |

### Maintenance Events

| Event Name | Description | When to Track |
|------------|-------------|---------------|
| `cleanup_stuck_agent_platform_session` | Cleanup of stuck or orphaned sessions | When a stuck session is detected and cleaned up |

## Token Tracking Best Practices

### Always Track Token Usage

For any AI model interaction, track token usage in AI Context and model information in Standard Context:

```ruby
track_internal_event(
  "token_usage_duo_workflow",
  user: user,
  project: project,
  additional_properties: {
    model_provider: "anthropic",
    model_engine: "claude-3-5",
    model_name: "claude-3-5-sonnet-20241022"
  },
  ai_context: {
    session_id: session.id,
    input_tokens: response.usage.input_tokens,
    output_tokens: response.usage.output_tokens,
    total_tokens: response.usage.total_tokens
  }
)
```

### Include Cache Metrics

When using cached prompts, track cache usage in AI Context:

```ruby
ai_context: {
  session_id: session.id,
  input_tokens: response.usage.input_tokens,
  output_tokens: response.usage.output_tokens,
  total_tokens: response.usage.total_tokens,
  ephemeral_5m_input_tokens: response.usage.cache_creation_input_tokens,
  ephemeral_1h_input_tokens: response.usage.cache_creation_1h_input_tokens,
  cache_read: response.usage.cache_read_input_tokens
}
```

### Model Information

Always include complete model information in Standard Context:

```ruby
additional_properties: {
  model_provider: "anthropic",  # or "openai", "vertex", etc.
  model_engine: "claude-3-5",   # or "gpt-4", etc.
  model_name: "claude-3-5-sonnet-20241022"  # specific model version
}
```
