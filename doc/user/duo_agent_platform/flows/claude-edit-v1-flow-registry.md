---
stage: AI-powered features
group: Workflow Catalog
title: Flow Registry Framework v1
ignore_in_report: true
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

Use the Flow Registry Framework v1 to build custom AI-powered workflows on the GitLab Duo Agent Platform by defining components, tools, and routing logic in a single YAML file.

## YAML configuration structure

Every flow is a single YAML file. The top-level structure is:

```yaml
version: "v1"
environment: ambient

components:
  # List of components (see Component types)

routers:
  # Routing rules between components (see Routers)

flow:
  entry_point: "component_name"   # First component to run

prompts:                           # Optional - inline prompt definitions
  # Locally defined prompts (see Prompts)
```

### Required fields

| Field | Description |
|---|---|
| `version` | Always `"v1"` |
| `environment` | Flow interaction style - see [Environment](#environment) |
| `components` | List of components that make up the flow - see [Component types](#component-types)|
| `routers` | Routing rules between components - see [Routers](#routers) |
| `flow` | Entry point and optional context inputs - see [flow section](#flow-section) |

### Optional fields

| Field | Description |
|---|---|
| `name` | Human-readable flow name |
| `description` | Description of the flow |
| `product_group` | Team ownership (for example, `agent_foundations`) |
| `prompts` | Inline prompt definitions - see [Locally defined prompts](#locally-defined-prompts) |
| `response_schemas` | Inline response schema definitions - see [Response schemas](#response-schemas) |

### Environment

The `environment` field declares the expected level of human-AI interaction.

| Value | Description |
|---|---|
| `ambient` | Hands-off background execution. The human delegates a task and the agent runs autonomously. Minimize human participation. Use this for most custom flows. |
| `chat` | Interactive back-and-forth conversation through a chat-like interface. |
| `chat-partial` | Simplified `chat` variant for single-agent flows. Skips boilerplate. Requires exactly one `AgentComponent`. |

## Quick start

To invoke a flow, pass your flow config in a `StartWorkflowRequest`:

```plaintext
flowConfigId: "<your_flow_id>"
flowConfigSchemaVersion: "v1"
flowVersion: "1.0.0"
```

The rest of this page documents the YAML structure for the flow config. For instructions
on registering a new foundational flow in the codebase, see the
[Foundational flows developer guide](foundational_flows/developer.md).

## Session context variables

Every component `inputs` block pulls values from the session context using
`from: "context:<key>"`. The framework automatically populates a set of variables
that are always available. You do not need to declare these variables, but you must reference
them explicitly in each component's `inputs` block.

### Always-available variables

| Variable | Type | Description |
|---|---|---|
| `context:goal` | string | The user's goal or message that triggered the workflow |
| `context:project_id` | string | GitLab project ID (numeric, as string) |
| `context:project_http_url_to_repo` | string | Full HTTPS clone URL of the repository |

> [!note]
> `context:project_id` is not injected into prompt templates automatically.
> If your agent calls any GitLab API tool (for example, `get_merge_request`, `list_issues`,
> or `create_merge_request`), you must add it to the component's `inputs`
> and include `Project ID: {{ project_id }}` in the prompt `user:` block. Omitting
> this is the most common cause of flow failures.

### Agent platform standard context variables

These variables are only available when you declare the `flow.inputs` stanza.
They carry branch and session metadata injected by the CI runner.

| Variable | Type | Description |
|---|---|---|
| `context:inputs.agent_platform_standard_context.primary_branch` | string | Default branch of the repo (for example, `main`) |
| `context:inputs.agent_platform_standard_context.workload_branch` | string | Git ref used by the CI workload runner |
| `context:inputs.agent_platform_standard_context.session_owner_id` | string | GitLab user ID of the person who triggered the flow |

Declare these when your flow creates branches, opens merge requests, or needs to
know the default branch. For more information, see the [flow section](#flow-section).

## Flow section

The `flow` section defines the entry point and, optionally, which external context
categories to inject.

### Minimal

```yaml
flow:
  entry_point: "my_first_component"
```

### With agent platform standard context

Required when your flow needs `primary_branch`, `workload_branch`, or
`session_owner_id`:

```yaml
flow:
  entry_point: "create_feature_branch"
  inputs:
    - category: agent_platform_standard_context
      input_schema:
        primary_branch:
          type: string
          description: The default/primary branch of the repository (for example, 'main', 'master')
        workload_branch:
          type: string
          description: git ref to workload branch
        session_owner_id:
          type: string
          description: Human user's ID that initiated the flow
```

## Component types

| Component | Purpose | AI involved | When to use |
|---|---|:---:|---|
| [AgentComponent](#agentcomponent) | Multi-turn AI reasoning with tools | Yes | Complex tasks requiring iterative decision-making, conversation, or multi-step tool use. |
| [OneOffComponent](#oneoffcomponent) | Single-round AI tool execution | Yes | Bounded tasks completable in one LLM call with built-in retry logic. |
| [DeterministicStepComponent](#deterministicstepcomponent) | Execute a single tool with fixed arguments | No | Predictable, repeatable operations where tool arguments come directly from state. |
| [HumanInputComponent](#humaninputcomponent) | Request and process user input | No | Approval gates, interactive chat, or any point where human feedback is needed. |
| [EndComponent / AbortComponent](#endcomponent-and-abortcomponent) | Terminate the workflow | No | Every flow must terminate with `"end"` (success) or `"abort"` (error). |

## AgentComponent

The AgentComponent is the primary building block for AI-powered flows. It uses an
LLM to:

- Process inputs,
- Make decisions based on a prompt
- Call tools.
- Maintain conversation history.
- Generate outputs for downstream components.

### Required parameters

| Parameter | Description |
|---|---|
| `name` | Unique identifier. Must not contain `:` or `.` characters. |
| `type` | Must be `"AgentComponent"`. |
| `prompt_id` | ID of the prompt template (local or registry-based). |

### Optional parameters

| Parameter | Default | Description |
|---|---|---|
| `prompt_version` | omitted | Semver constraint (for example, `"^1.0.0"`). Omit to use a locally defined prompt. |
| `inputs` | `["context:goal"]` | List of input data sources. |
| `toolset` | `[]` | Tools available to the agent. See [Available tools](#available-tools). |
| `description` | None | Required when used as a sub-agent under a supervisor. |
| `subagents` | None | List of sub-agent names. Enables [Supervisor Mode](#supervisor-mode). |
| `max_delegations` | unlimited | Max `delegate_task` calls in Supervisor Mode. |
| `response_schema_id` | None | ID of structured output schema. |
| `response_schema_version` | None | Semver for registry-based schema. |
| `model_size_preference` | `null` | `"small"` or `"large"`. |
| `require_tool_approval` | `false` | Pause for human approval before each tool call. |
| `pre_approved_tools` | `[]` | Tools that skip the approval step. |
| `compaction` | None | Conversation compaction configuration. |
| `ui_log_events` | `[]` | Events to surface in the UI. See [UI log events](#agentcomponent-ui-log-events). |
| `ui_role_as` | `"agent"` | Display role in UI (`"agent"` or `"tool"`). |

### Outputs

| Output key | Description |
|---|---|
| `context:{name}.final_answer` | Agent's final response (string, or dict with custom schema). |
| `context:{name}.final_answer.{field}` | Individual field when using a custom response schema. |
| `conversation_history:{name}` | Full message history. |

### Inputs

Component inputs pull values from the session context and make them available as
template variables in the prompt. The `as:` alias must match the `{{ variable }}`
placeholder in the prompt template exactly.

```yaml
# In the component inputs:
inputs:
  - from: "context:goal"
    as: "goal"
  - from: "context:project_id"
    as: "project_id"
  - from: "context:previous_agent.final_answer"
    as: "previous_result"
  - from: "some constant value"
    as: "my_constant"
    literal: true

# In the prompt user block:
user: |
  Project ID: {{ project_id }}
  Goal: {{ goal }}
  Previous result: {{ previous_result }}
```

### Prompts

Every AgentComponent needs a prompt. Define it inline in the flow YAML (recommended
for custom flows) or reference one from the AI Gateway prompt registry.

#### Locally defined prompts

Omit `prompt_version` to use an inline prompt defined in the top-level `prompts` block:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    # prompt_version omitted - uses local prompt

prompts:
  - prompt_id: "my_prompt"
    name: "My Prompt"
    unit_primitives: []           # always include, even if empty
    prompt_template:
      system: |
        You are a helpful assistant.

        When your task is complete, your final answer is a plain text summary
        of what you did. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history        # include explicitly
    params:
      timeout: 180
```

#### Registry prompts

Specify `prompt_version` to load from the AI Gateway prompt registry at
`ai_gateway/prompts/definitions/`:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_flow/my_prompt"
    prompt_version: "^1.0.0"
```

#### Prompt writing best practices

- Always tell the agent when it is done. Without an explicit stopping instruction
  the agent loops. End every `system:` prompt with a sentence such as:
  `"When [condition], your final answer is [what to say]. No further steps are needed after that."`
- Always pass `project_id` in the `user:` block for any agent that calls GitLab
  API tools. The agent cannot discover it on its own.
- Match variable names exactly. The `as:` alias in `inputs` must match the
  `{{ variable }}` placeholder in the prompt template.
- Always include `unit_primitives: []` on inline prompts, even when empty.
- Always include `placeholder: history` in inline prompt templates.

### Available tools

Configure tools by passing their snake_case name in `toolset`. The complete list is
in `duo_workflow_service/components/tools_registry.py`. Common examples:

- File operations: `read_file`, `create_file_with_contents`, `edit_file`,
`list_dir`, `find_files`, `grep`
- Git operations: `run_command`, `create_merge_request`, `create_branch`
- GitLab API: `get_issue`, `list_issues`, `get_merge_request`,
`gitlab_merge_request_search`, `get_work_item`, `get_repository_file`,
`list_repository_tree`, `create_issue_note`, `create_merge_request_note`,
`create_commit`, `gitlab_api_get`, `get_project`

### Tool options

Override a tool's parameters at the component level so the LLM cannot change them:

```yaml
toolset:
  - "get_merge_request"                    # simple string - no overrides
  - "create_merge_request_note":           # object form - override a parameter
      "internal": true
```

Options are validated against the tool's Pydantic input schema at initialization
time. If an option key does not match a valid parameter, a `ValueError` is raised.
At execution time, tool options take precedence over LLM-provided values.

### AgentComponent UI log events

| Event | Description |
|---|---|
| `on_agent_final_answer` | Agent calls its final response. This enables visibility of the full final answer in the session UI and CI log. Disable if output contains sensitive data. |
| `on_tool_execution_success` | A tool call completed successfully. |
| `on_tool_execution_failed` | A tool call failed. |
| `on_tool_approval_request` | Tool approval is pending user decision. Must be included to show approval requests in UI. |

### Tool approval

When `require_tool_approval: true`, the workflow pauses after the agent generates
tool calls and waits for the user's decision before proceeding.

The following decision types are supported:

| Decision | Behavior |
|---|---|
| `APPROVE` | Tool executes normally. |
| `REJECT` | Rejection message added to history; agent tries an alternative approach. |
| `MODIFY` | Rejection plus user feedback added to history; agent adjusts accordingly. |

A tool is pre-approved and skips the approval step if it appears in either of the following:

- Component-level: Listed in the `pre_approved_tools` parameter on the component. Controlled by the flow author in the YAML.
- Workflow-level: Specified through `pre_approved_agent_privileges` in the workflow `startRequest`. Controlled by the workflow caller at invocation time.

If all tool calls are pre-approved from either source, the approval flow is skipped entirely and tools execute immediately.

```yaml
components:
  - name: "code_editor"
    type: AgentComponent
    prompt_id: "code_assistant"
    prompt_version: "^1.0.0"
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset: ["read_file", "list_dir", "find_files", "edit_file", "run_command"]
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_tool_approval_request"
    inputs: ["context:goal"]
```

### Usage modes

| Mode | When | `description` required |
|---|---|---|
| Standalone | Regular component in the flow. | No |
| Managed | Sub-agent delegated to by a supervisor. | Yes |
| Supervisor | Orchestrates sub-agents through `delegate_task`. | No (on supervisor itself) |

### Supervisor Mode

When `subagents` is provided, the agent becomes a supervisor with access to
`delegate_task` and `final_response_tool` automatically. When the LLM calls
`delegate_task`, the framework:

1. Assigns or resumes a numbered subsession for the named sub-agent.
1. Seeds the sub-agent's conversation history with the delegation prompt.
1. Routes execution to the sub-agent's ReAct loop.
1. On sub-agent completion, injects the result back into the supervisor's history
   and returns control to the supervisor.

#### Constraints

- `subagents` must contain at least one entry.
- Every sub-agent listed must have a `description` field.
- An `AgentComponent` may be owned by at most one supervisor.
- The supervisor prompt must instruct the LLM when to use `delegate_task` and
  `final_response_tool`.

#### Supervisor outputs

| Output key | Description |
|---|---|
| `context:{supervisor_name}.final_answer` | Supervisor's final response. |
| `conversation_history:{supervisor_name}` | Supervisor's own message history. |

### Response schemas

Response schemas constrain an AgentComponent's output to a structured format.
Without one, the agent returns a plain string in `final_answer`. With one,
`final_answer` is a dict and each field is also accessible as
`context:{name}.final_answer.{field}`.

#### Inline schema (recommended for custom flows)

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    response_schema_id: "code_review"   # no response_schema_version = inline lookup
    toolset: ["read_file"]

response_schemas:
  - schema_id: "code_review"
    definition:
      "$schema": "http://json-schema.org/draft-07/schema#"
      title: "code_review_response"
      type: object
      properties:
        summary:
          type: string
          description: "Brief summary of findings"
        overall_score:
          type: integer
          minimum: 1
          maximum: 10
      required: [summary, overall_score]
```

#### Registry schema

Provide both `response_schema_id` and `response_schema_version` to load from the
server-side registry at `ai_gateway/response_schemas/definitions/`:

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review/detailed_analysis"
    prompt_version: "^1.0.0"
    response_schema_id: "analysis/code_review"
    response_schema_version: "^1.0.0"
```

Downstream components can reference individual schema fields:

```yaml
inputs:
  - from: "context:code_reviewer.final_answer.overall_score"
    as: "score"
```

#### Schema definition reference

Response schemas use [JSON Schema](https://json-schema.org/) format. Important top-level fields:

| Field | Description |
|---|---|
| `$schema` | Schema dialect. Defaults to `draft-07` if not provided. |
| `title` | Maps to the tool name the agent calls for its final response. Must not match any existing tool name - a collision raises a `ValueError`. |
| `type` | Must be `"object"`. |
| `properties` | Nested JSON objects defining the schema fields. Supports `"object"` type for nested structures. |
| `required` | List of field names that must be present in the output. |

The following JSON Schema validation constraints are supported by AgentComponent response schemas.

##### Numeric constraints (integer/number)

| JSON Schema constraint | Pydantic field parameter | Description |
|---|---|---|
| `minimum` | `ge=` | Minimum value (inclusive) - greater than or equal to. |
| `maximum` | `le=` | Maximum value (inclusive) - less than or equal to. |
| `exclusiveMinimum` | `gt=` | Minimum value (exclusive) - greater than. |
| `exclusiveMaximum` | `lt=` | Maximum value (exclusive) - less than. |
| `multipleOf` | `multiple_of=` | Value must be a multiple of this number. |

##### String constraints

| JSON Schema constraint | Pydantic field parameter | Description |
|---|---|---|
| `minLength` | `min_length=` | Minimum string length in characters. |
| `maxLength` | `max_length=` | Maximum string length in characters. |
| `pattern` | `pattern=` | Regular expression pattern the string must match. |

##### Array constraints

| JSON Schema constraint | Pydantic field parameter | Description |
|---|---|---|
| `minItems` | `min_length=` | Minimum number of items in array. |
| `maxItems` | `max_length=` | Maximum number of items in array. |

##### Enumeration and constants

| JSON Schema constraint | Python type | Description |
|---|---|---|
| `enum` | `Literal[val1, val2, ...]` | Field must be one of the specified values. |
| `const` | `Literal[value]` | Field must be exactly this value. |

##### Metadata

| JSON Schema field | Pydantic field parameter | Description |
|---|---|---|
| `default` | `default=` | Default value for optional fields. |
| `examples` | `examples=` | Example values shown to the agent as guidance. |

##### Full schema example

```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "code_review_response_tool",
    "type": "object",
    "properties": {
        "summary": {
            "type": "string",
            "description": "Brief summary of the code review findings"
        },
        "issues_found": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "severity": {
                        "type": "string",
                        "enum": ["low", "medium", "high", "critical"]
                    },
                    "description": { "type": "string" },
                    "file_path": { "type": "string" },
                    "line_number": { "type": "integer" }
                },
                "required": ["severity", "description"]
            }
        },
        "recommendations": {
            "type": "array",
            "items": { "type": "string" }
        },
        "overall_score": {
            "type": "integer",
            "minimum": 1,
            "maximum": 10
        }
    },
    "required": ["summary", "issues_found", "overall_score"]
}
```

### AgentComponent example

```yaml
components:
  - name: "code_assistant"
    type: AgentComponent
    prompt_id: "code_review_helper"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
      - "create_file_with_contents"
      - "create_merge_request_note":
          "internal": true
      - "edit_file"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
    ui_role_as: "agent"
```

## HumanInputComponent

The HumanInputComponent:

- Pauses workflow execution.
- Presents a prompt to the human.
- Resumes when the human responds.

Use it for review gates, approvals, and feedback loops.

### Required parameters

| Parameter | Description |
|---|---|
| `name` | Unique identifier. Must not contain `:` or `.` characters. |
| `type` | Must be `"HumanInputComponent"`. |
| `sends_response_to` | Name of the AgentComponent that receives the human's response in its conversation history. [This must be a component that has already run](#critical-constraint-sends_response_to-must-point-to-an-already-run-component). |
| `message_template` | Jinja2 template shown to the human. May reference variables through `inputs`. |

### Optional parameters

| Parameter | Default | Description |
|---|---|---|
| `interaction_type` | `"approval"` | `"approval"` renders Approve/Reject/Modify buttons. `"input"` renders a text input. Always set this explicitly - do not rely on the default. |
| `inputs` | `[]` | Variables to render into `message_template`. |
| `ui_log_events` | `[]` | Should always include both [UI log events](#ui-log-events). |

### Critical constraint: `sends_response_to` must point to an already-run component

> [!note]
> This is the most commonly misunderstood field in `HumanInputComponent`.

The framework injects the human's feedback into the existing conversation history
of the target component. If that component has not yet run, it has no conversation
history entry and the framework crashes with `KeyError('<component_name>')`.

> [!note]
> `sends_response_to` must name a component that has already completed execution before the gate fires.

In practice this almost always means pointing it
back to the agent that ran immediately before the gate.

If the `modify` route target has not run yet, pass feedback to it through its `inputs`
instead:

```yaml
# Correct pattern - sends_response_to points to the already-run agent
- name: "review_gate"
  type: HumanInputComponent
  sends_response_to: "suggester_agent"    # suggester already ran ✅
  interaction_type: "approval"
  ...

# The modify handler gets feedback through inputs instead:
- name: "modify_handler"
  type: AgentComponent
  inputs:
    - from: "context:review_gate.approval"
      as: "human_feedback"               # feedback passed explicitly ✅
```

```yaml
# Wrong pattern - crashes with KeyError
- name: "review_gate"
  sends_response_to: "modify_handler"    # has not run yet → KeyError ❌
```

### UI log events

Both events must be included. Without them, the gate is invisible in the session UI:

| Event | Description |
|---|---|
| `on_user_input_prompt` | Shows the prompt and renders the correct input control (buttons or text box). |
| `on_user_response` | Captures the human's response in the UI chat log. |

### Outputs

| Output key | Description |
|---|---|
| `context:{name}.approval` | The human's decision: `"approve"`, `"reject"`, or `"modify"`. |
| `conversation_history:{sends_response_to}` | The human's message, injected into the target agent's history. |

### Approval router - three values, not two

When `interaction_type: "approval"`, the human can respond with three values. Your
router must handle all three or the `modify` path silently falls through to
`default_route`:

| Value | Meaning |
|---|---|
| `"approve"` | Human accepted - proceed to the next step. |
| `"reject"` | Human rejected - route to end or error handling. |
| `"modify"` | Human provided feedback - route back to a prior agent for revision. |

```yaml
routers:
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "next_step"
        "modify": "prior_agent"      # loop back - feedback available in history or inputs
        "reject": "end"
        "default_route": "end"       # always include a fallback
```

### HumanInputComponent checklist

Before saving your YAML, verify:

- `interaction_type` is explicitly set (`"approval"` or `"input"`).
- `ui_log_events` includes both `"on_user_input_prompt"` and `"on_user_response"`.
- The downstream router uses `condition:` (not `to:`).
- The router handles `"approve"`, `"modify"`, and `"reject"` explicitly.
- `"default_route"` is present in the router.
- `sends_response_to` points to a component that has already run before the gate fires.
- If the `modify` target has not run yet, its `inputs` include `from: "context:{gate_name}.approval" as: "human_feedback"`.

### Usage patterns

#### Approval workflow

```yaml
components:
  - name: "user_approval"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"   # proposal_agent already ran
    interaction_type: "approval"
    message_template: |
      Please review the proposed changes and choose an action:
      - ✅ Approve: Proceed
      - ✏️ Modify: Provide feedback for revision
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_approval"
    condition:
      input: "context:user_approval.approval"
      routes:
        "approve": "executor"
        "modify": "proposal_agent"
        "reject": "end"
        "default_route": "end"
```

#### Interactive chat

```yaml
components:
  - name: "user_input"
    type: HumanInputComponent
    sends_response_to: "chat_agent"
    interaction_type: "input"
    message_template: "How can I help you today?"
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_input"
    to: "chat_agent"
  - from: "chat_agent"
    to: "user_input"  # loop back for continued interaction
```

## DeterministicStepComponent

Executes a single tool directly without LLM involvement. Parameters are extracted
from the flow state. Chain multiple instances to execute sequential tool operations.

### Required parameters

| Parameter | Description |
|---|---|
| `name` | Unique identifier. Must not contain `:` or `.` characters. |
| `type` | Must be `"DeterministicStepComponent"`. |
| `tool_name` | Name of the single tool to execute. |

### Optional parameters

| Parameter | Default | Description |
|---|---|---|
| `toolset` | auto | Toolset containing the tool (auto-created if omitted). |
| `inputs` | `[]` | Input sources that map to tool parameters. |
| `ui_log_events` | `[]` | Events to surface in UI. |
| `ui_role_as` | `"tool"` | Display role in UI. |

### Outputs

| Output key | Description |
|---|---|
| `context:{name}.tool_responses` | Result of the tool execution. |
| `context:{name}.error` | Any error that occurred. |
| `context:{name}.execution_result` | `"success"` or `"failed"`. |

### Validation

The component validates tool arguments at initialization time:

- Verifies the specified tool exists in the toolset.
- Checks that all required tool parameters are configured in `inputs`.
- Verifies parameters match the tool's expected schema.

Errors are caught at configuration time rather than runtime.

### Example: chain multiple tools

```yaml
components:
  - name: "read_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:goal"
        as: "config_path"
    tool_name: "read_file"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "backup_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:read_config.tool_responses"
        as: "contents"
      - from: "config_backup.txt"
        as: "file_path"
        literal: true
    tool_name: "create_file_with_contents"
```

## OneOffComponent

Sits between `AgentComponent` and `DeterministicStepComponent`. Uses an LLM to
generate tool calls in a single round, then exits on success. Includes built-in
retry logic for failed executions.

Use when a task can be completed in one LLM call but benefits from LLM reasoning to
determine tool parameters.

### Required parameters

| Parameter | Description |
|---|---|
| `name` | Unique identifier. Must not contain `:` or `.` characters. |
| `type` | Must be `"OneOffComponent"`. |
| `prompt_id` | Prompt that instructs the tool call. |
| `toolset` | Tools available for the single round. |

### Optional parameters

| Parameter | Default | Description |
|---|---|---|
| `prompt_version` | omitted | Omit to use a locally defined prompt. |
| `inputs` | `["context:goal"]` | Input data sources. |
| `max_correction_attempts` | `3` | Retry limit for failed tool executions. |
| `model_size_preference` | `null` | `"small"` or `"large"`. |
| `compaction` | None | Conversation compaction configuration. |
| `ui_log_events` | `[]` | Events to surface in UI. |

### Outputs

| Output key | Description |
|---|---|
| `context:{name}.tool_responses` | Tool execution results. |
| `context:{name}.tool_calls` | Record of tool calls made. |
| `context:{name}.execution_result` | `"success"` or `"failed"`. |

### UI log events

| Event | Description |
|---|---|
| `on_tool_call_input` | Tool is about to be called with its arguments. |
| `on_tool_execution_success` | Tool completed successfully. |
| `on_tool_execution_failed` | Tool execution failed. |
| `on_agent_reasoning` | Agent could not produce tool calls due to limitations. |

### Internal architecture

The OneOffComponent consists of three internal nodes:

- LLM node (`{name}#llm`): Uses `AgentNode` to generate one or more tool calls.
- Tools node (`{name}#tools`): Executes tool calls with error correction through `ToolNodeWithErrorCorrection`.
- Exit node (`{name}#exit`): Handles completion and state logging.

### Example

```yaml
components:
  - name: "file_reader"
    type: OneOffComponent
    prompt_id: "read_specific_file"
    prompt_version: "^1.0.0"
    inputs:
      - from: "context:goal"
        as: "target_file"
    toolset:
      - "read_file"
    max_correction_attempts: 2
    ui_log_events:
      - "on_tool_call_input"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
```

## EndComponent and AbortComponent

Both are automatically available in every flow. No definition needed.

| Name | Router key | Status set | Use when |
|---|---|---|---|
| EndComponent | `"end"` | `COMPLETED` | Workflow finished successfully. |
| AbortComponent | `"abort"` | `ERROR` | Unrecoverable error; retries exhausted. |

```yaml
routers:
  - from: "my_component"
    to: "end"    # successful completion

  - from: "my_component"
    to: "abort"  # error termination
```

## Routers

Routers define how execution moves between components after each one completes.

### Simple router

Routes unconditionally to the next component:

```yaml
routers:
  - from: "component_a"
    to: "component_b"
```

### Conditional router

Routes based on the value of a context variable:

```yaml
routers:
  - from: "component_a"
    condition:
      input: "context:component_a.final_answer"
      routes:
        "approved": "component_b"
        "rejected": "end"
        "default_route": "end"   # fallback if value matches nothing
```

Always include `"default_route"` to prevent silent dead-ends.

## Common pitfalls

| Symptom | Root cause | Fix |
|---|---|---|
| Agent says it cannot find the project or has no project context | `project_id` not in component `inputs` | Add `- from: "context:project_id" as: "project_id"` to every component that calls GitLab API tools, and include `Project ID: {{ project_id }}` in the `user:` block. |
| `primary_branch` is undefined | `flow.inputs` stanza missing | Add the full `flow.inputs` block with `agent_platform_standard_context` schema. |
| HITL gate shows nothing in the UI | `ui_log_events` missing on `HumanInputComponent` | Add `on_user_input_prompt` and `on_user_response` to `ui_log_events`. |
| `KeyError('<component_name>')` on modify | `sends_response_to` points to a component that has not run yet. | Point `sends_response_to` to the most recently completed agent; pass feedback to the modify target through its `inputs`. |
| `modify` response routes to `default_route` unexpectedly | Router missing `"modify"` route | Add `"modify": "<target_component>"` to every conditional router after a `HumanInputComponent`. |
| Agent loops endlessly | Prompt missing stopping instruction | End every `system:` prompt with an explicit completion instruction. |
| `NoneType: None` crash at session start | `{{ }}` Jinja2 syntax in the agent system prompt | The platform renders the system prompt through Jinja2 before passing it to the model. Any `{{ variable }}` in prompt text is treated as a template variable. Use `<<variable>>` notation in documentation or escape with `{% raw %}{{ }}{% endraw %}`. |
| YAML parse error at load time | Missing `unit_primitives: []` on inline prompt | Always include `unit_primitives: []`, even when empty. |
| Agent receives blank variable | `as:` alias does not match `{{ }}` placeholder | Verify the `as:` value in `inputs` exactly matches the placeholder name. |

## Flow examples

### Simple ambient flow with local prompt

```yaml
version: "v1"
environment: ambient

components:
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]
    ui_log_events:
      - "on_agent_final_answer"

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and provide actionable feedback. When complete, your final answer is a
        summary of your findings. No further steps are needed after that.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "code_analyzer"
    to: "end"

flow:
  entry_point: "code_analyzer"
```

### Ambient flow with tool options for controlled tool behavior

```yaml
version: "v1"
environment: ambient

components:
  - name: "security_agent"
    type: AgentComponent
    prompt_id: "security_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note":
          "internal": true
      - "get_merge_request"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

  - name: "general_agent"
    type: AgentComponent
    prompt_id: "general_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

prompts:
  - prompt_id: "security_prompt"
    name: "Security Analysis Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a security analyst. Review the MR and leave an internal note
        summarizing any security concerns. When complete, your final answer is
        a confirmation that the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "general_prompt"
    name: "General Summary Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a helpful assistant. Leave a public note on the MR summarizing
        the changes. When complete, your final answer is a confirmation that
        the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "security_agent"
    to: "general_agent"
  - from: "general_agent"
    to: "end"

flow:
  entry_point: "security_agent"
```

### HITL approval flow

This flow proposes an action, presents it for human review, and executes on approval.
It demonstrates the correct `sends_response_to` pattern and all three router routes.

```yaml
version: "v1"
environment: ambient

components:
  - name: "proposal_agent"
    type: AgentComponent
    prompt_id: "proposal_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
    toolset:
      - "get_issue"
      - "list_issues"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "review_gate"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"     # proposal_agent has already run ✅
    interaction_type: "approval"
    message_template: |
      The agent has proposed an action. Please review and choose:
      - ✅ Approve: Proceed with the proposed action
      - ✏️ Modify: Provide feedback - the agent will revise
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

  - name: "executor_agent"
    type: AgentComponent
    prompt_id: "executor_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
      - from: "context:proposal_agent.final_answer"
        as: "approved_proposal"
    toolset:
      - "update_issue"
      - "create_issue_note"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

prompts:
  - prompt_id: "proposal_prompt"
    name: "Proposal Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Review the goal and propose a concrete action. Do not execute anything yet.
        When you have formed your proposal, your final answer is a clear description
        of the proposed action. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "executor_prompt"
    name: "Executor Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Execute the approved proposal. If the human provided modification feedback,
        it is in your conversation history - incorporate it before executing.
        When execution is complete, your final answer is a confirmation of what
        was done. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
        Approved proposal: {{ approved_proposal }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "proposal_agent"
    to: "review_gate"
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "executor_agent"
        "modify": "proposal_agent"    # loops back - feedback in proposal_agent history
        "reject": "end"
        "default_route": "end"
  - from: "executor_agent"
    to: "end"

flow:
  entry_point: "proposal_agent"
```

### Flow with model size preference

Routes lightweight tasks to a smaller model and complex tasks to a larger model:

```yaml
version: "v1"
environment: ambient

components:
  - name: "explorer"
    type: AgentComponent
    prompt_id: "explorer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "small"
    inputs: ["context:goal"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_tool_execution_success"

  - name: "implementer"
    type: AgentComponent
    prompt_id: "implementer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "large"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:explorer.final_answer"
        as: "codebase_context"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "explorer"
    to: "implementer"
  - from: "implementer"
    to: "end"

flow:
  entry_point: "explorer"
```

### Multi-agent supervisor flow

```yaml
version: "v1"
environment: ambient

components:
  - name: "developer"
    type: AgentComponent
    description: "Implements code changes, creates and edits files based on requirements."
    prompt_id: "developer_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "tester"
    type: AgentComponent
    description: "Writes and runs automated tests to verify code correctness."
    prompt_id: "tester_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "create_file_with_contents"
      - "run_command"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "supervisor"
    type: AgentComponent
    prompt_id: "supervisor_agent"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    subagents:
      - name: "developer"
      - name: "tester"
    max_delegations: 20
    toolset:
      - "get_issue"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "supervisor"
    to: "end"

flow:
  entry_point: "supervisor"
```

### Chat-partial flow for conversational code review

```yaml
version: "v1"
environment: chat-partial

components:  # exactly one AgentComponent when using chat-partial
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    ui_log_events: ["on_agent_final_answer"]
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and mentor engineers on best practices.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers: []
flow: {}
```
