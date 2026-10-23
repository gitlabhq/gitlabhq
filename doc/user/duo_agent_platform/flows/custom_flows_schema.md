---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Custom flow YAML schema
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
{{< /details >}}

{{< history >}}

- Changed to [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/602415) in GitLab 19.2.

{{< /history >}}

Custom flows use the
[flow registry v1 specification](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md)
syntax. The v1 specification defines the full YAML structure,
including fields like `version`, `environment`, `components`,
`prompts`, `routers`, and `flow`.

Some fields in the v1 specification are restricted in custom flows.
For more information, see [restricted fields](#restricted-fields).

The YAML configuration also has a maximum size. For more information, see
[configuration size limits](../ai_catalog.md#configuration-size-limits).

## Goal values by trigger type

When you design a custom flow, the goal value depends on which
trigger type starts the flow. A flow can have multiple trigger
types configured, and each trigger type passes a different value
as `context:goal`. Your flow must handle the goal format for
each trigger type you configure.

For more information about trigger types, see
[triggers](../triggers/_index.md).

Components access the goal through the `inputs` field:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - "context:goal"
```

### Mention events

When a user mentions the flow service account in a comment,
the full comment text and the resource context are passed as
the goal.

The goal uses this format:

```plaintext
Input: <comment_text>
Context: {<resource_type> IID: <iid>}
```

For example, if a user writes
`@ai-my-flow Can you work on this?` on issue `#2`, the goal is:

```plaintext
Input: @ai-my-flow Can you work on this?
Context: {Issue IID: 2}
```

### Assign and Assign reviewer events

{{< history >}}

- Typed resource reference [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/628996) in GitLab 19.6 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_typed_resource_goal`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

When the flow service account is added as an assignee or reviewer to an issue or merge request, the resource type and URL are passed as the goal:

```plaintext
Context:
<resource_type>: <resource_web_url>
```

The resource type is `Issue` or `MergeRequest`.

For example, if the flow service account is added as a reviewer to merge request `!10`, the goal is:

```plaintext
Context:
MergeRequest: https://gitlab.example.com/my-group/my-project/-/merge_requests/10
```

Use the URL to identify the resource. Don't use the resource type, because the same issue can appear as `Issue` or `WorkItem`, depending on the trigger.

> [!warning]
> When the feature flag is enabled, `context:goal` contains the resource type and URL instead of the IID.
> To keep your custom flows working, update any that read `context:goal` as an IID.

### Merge request and work item events

{{< history >}}

- Typed resource reference [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/628996) in GitLab 19.6 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_typed_resource_goal`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

When a merge request or work item event triggers the flow, the resource type, URL, and action are passed as the goal:

```plaintext
Context:
<resource_type>: <resource_web_url>
Action: <action>
```

The resource type is `MergeRequest` or `WorkItem`.

The action depends on the event and the **Run when** selection:

| Event         | Run when       | Action           |
|---------------|----------------|------------------|
| Merge request | Approved       | `approved`       |
| Merge request | Created        | `created`        |
| Work item     | Created        | `created`        |
| Work item     | Status changed | `status_changed` |

The **Marked ready** and **Merge conflict** actions don't include an action in the goal.

For example, if merge request `!10` is approved, the goal is:

```plaintext
Context:
MergeRequest: https://gitlab.example.com/my-group/my-project/-/merge_requests/10
Action: approved
```

Use the URL to identify the resource. Don't use the resource type, because the same issue can appear as `Issue` or `WorkItem`, depending on the trigger.

> [!warning]
> When the feature flag is enabled, `context:goal` contains the resource type and URL instead of the IID.
> To keep your custom flows working, update any that read `context:goal` as an IID.

### Pipeline events

When a pipeline event triggers the flow, the full
[pipeline event webhook payload](../../project/integrations/webhook_events.md#pipeline-events)
is passed as the goal.

## Optional top-level properties

### `coding_environment`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/606480) in GitLab 19.3.

{{< /history >}}

The optional `coding_environment` property declares what kind of coding
environment the flow needs when a workload starts.

| Value | Description |
|-------|-------------|
| `full` | Default when not provided. A repository clone, setup scripts, Git hooks, and the dependency cache. Use this for flows that read or write repository files. |
| `none` | No repository clone. Setup scripts and the dependency cache are skipped. The flow still runs in the project's configured `image`, so that image must include `curl` or `duo` itself. The Duo session Git hook is still installed, so a flow that clones the repository itself keeps its commits attributed to Duo. Use this for API-only flows that interact only with GitLab APIs and need no local repository. Agent tools that read or write repository files have nothing to act on. The `none` value does not block repository access. A flow that has the `run_command` tool can still clone the repository itself. The property controls only what GitLab prepares before the flow starts. |

Use the `full` value when the flow needs a checkout, so
that the clone happens once, up front, instead of during the run.

If you add a value other than `full` or `none` the schema validation fails
and the flow does not run.

If you don't add the `coding_environment` property, the flow receives the full
environment and still has repository access.

Example:

```yaml
version: v1
environment: ambient
coding_environment: none
components:
  - name: "api_agent"
    type: AgentComponent
    prompt_id: "my_api_prompt"
    inputs:
      - "context:goal"
routers:
  - from: "api_agent"
    to: end
flow:
  entry_point: "api_agent"
```

## Restricted fields

Some fields and features in the v1 specification are restricted
to ensure custom flows work consistently in GitLab.

### `environment`

The `environment` field supports only the `ambient` value in
custom flows.

The `chat` and `chat-partial` values are not supported.

### `model` in prompts

The `model` field inside a `prompts` entry is not supported.

The model is determined by the model provider configured in your
group or instance settings.

### `AgentComponent` fields

The `response_schema_id` and `response_schema_version` fields
are not supported.

### `OneOffComponent` fields

The `ui_role_as` field is not supported.

### `stop` in prompt parameters

The `stop` field is not supported inside a `params` entry.

### Top-level fields

The `name`, `description`, and `product_group` fields from the
v1 specification are not supported.
Custom flows reject these fields.
