---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Custom flow YAML schema
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

Custom flows use the
[flow registry v1 specification](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md)
syntax. The v1 specification defines the full YAML structure,
including fields like `version`, `environment`, `components`,
`prompts`, `routers`, and `flow`.

Some fields in the v1 specification are restricted in custom flows.
For more information, see [restricted fields](#restricted-fields).

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

When the flow service account is assigned to an issue or merge
request, or assigned as a reviewer, the IID of the resource is
passed as the goal.

For example, if the flow service account is assigned as a reviewer
on merge request `!10`, the value of `context:goal` is `10`.

Use the IID with `context:project_id` to read the resource:

```yaml
components:
  - name: "review_mr"
    type: AgentComponent
    prompt_id: "review_mr_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_iid"
```

### Pipeline events

When a pipeline event triggers the flow, the full
[pipeline event webhook payload](../../project/integrations/webhook_events.md#pipeline-events)
is passed as the goal.

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
