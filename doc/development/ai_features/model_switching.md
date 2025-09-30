---
stage: AI-powered
group: Custom Models
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Model Switching
---

The Model Switching Framework in the GitLab AI Gateway allows customers to choose between different AI models for various features. 

This feature is available for GitLab SaaS and self-managed instances using the cloud-connected AI Gateway.

- On GitLab SaaS, this feature is available at the namespace level, allowing groups to choose between different models for their namespace.
  - If the namespace has not decided to "pin" a model, the default model will be used. This will also allow users to change the model themselves for specific features, like Agentic chat. This feature is termed as "User model selection".
- On self-managed instances using the cloud-connected AI Gateway, this feature is available at the instance level.

This guide explains how to add new models to make them selectable by users on both SaaS and self-managed instances.

## Adding models to the Model Switching Framework

### Overview

Adding a new model to the Model Switching Framework involves two main steps:

1. Define the model in `models.yml` with its configuration parameters
1. Make the model selectable for relevant features in `unit_primitives.yml`

Both files are located in the [`gitlab-ai-gateway`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/ai_gateway/model_selection) repository.

### Prerequisites

Before adding a new model, ensure that:

- Appropriate authentication/credentials are configured (if needed), on Runway. The access to most common providers is already configured. This includes OpenAI, Anthropic, and Vertex AI. But if you need to add a model from a completely new provider, you will need to add the credentials to Runway.
- Appropriate authentication/credentials are configured (if needed), on the local GDK environment. Example, ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.
- Prompt definitions for the model family exist under the specific feature's folder. These are located in the [`gitlab-ai-gateway`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/ai_gateway/prompts/definitions) repository.
- Set the environment variable `FETCH_MODEL_SELECTION_DATA_FROM_LOCAL=true` in your GDK environment. This will ensure that the model selection data is fetched from the local `models.yml` and `unit_primitives.yml` files.

#### Step 1: Define the Model

Add your model definition to `ai_gateway/model_selection/models.yml`. Each model requires the following properties:

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Human-readable name displayed in the UI (for example, `"OpenAI GPT-5-Mini"`) |
| `gitlab_identifier` | Yes | Unique identifier used internally (for example, `gpt_5_mini`) |
| `family` | No | Ordered list of prompt definition families to use (see [Prompt Selection](#prompt-selection)) |
| `params` | Yes | Dictionary of parameters passed to the model client |

##### Example Model Definition

```yaml
# ai_gateway/model_selection/models.yml
models:
  - name: "OpenAI GPT-5-Mini"
    gitlab_identifier: "gpt_5_mini"
    family:
      - gpt_5
    params:
      model: gpt-5-mini-2025-08-07
      max_tokens: 4_096
```

##### Common Parameters

The `params` dictionary typically includes:

- `model`: The actual model identifier used by the provider's API
- `max_tokens`: Maximum number of tokens in the response
- `temperature`: Controls randomness (0.0 = deterministic, higher = more random)
- `model_class_provider`: The provider (for example, `anthropic`, `litellm`, `vertex_ai`)
- Provider-specific parameters (for example, `top_p`, `top_k`, `verbosity`)

##### Prompt Selection

The optional `family` field determines which prompt definitions are used with this model:

- The framework searches for prompts in directories matching each family name in order
- If a matching prompt folder exists, it uses that prompt definition
- If no family is specified or no matches are found, the `base` prompts are used

#### Step 2: Make the Model Selectable

After defining the model, add it to the appropriate feature's `selectable_models` list in `ai_gateway/model_selection/unit_primitives.yml`.

##### Example Configuration

```yaml
# ai_gateway/model_selection/unit_primitives.yml
configurable_unit_primitives:
  - feature_setting: "duo_agent_platform"
    unit_primitives:
      - "duo_agent_platform"
    default_model: "claude_sonnet_4_20250514"
    selectable_models:
      - "claude_sonnet_3_7_20250219"
      - "claude_sonnet_4_20250514"
      - "claude_sonnet_4_5_20250929"
      - "gpt_5"
      - "gpt_5_mini"      # Add your new model here
      - "gpt_5_codex"
```

##### Configuration Properties

Each feature setting entry includes:

- `feature_setting`: The feature identifier
- `unit_primitives`: List of unit primitives using this configuration
- `default_model`: The `gitlab_identifier` of the default model
- `selectable_models`: List of `gitlab_identifier` values that users can choose from

{{< alert type="note" >}}
The `default_model` must always be included in the `selectable_models` list, or validation will fail.
{{< /alert >}}

### Validation

The AI Gateway automatically validates the configuration:

- All models referenced in `unit_primitives.yml` must be defined in `models.yml`
- The `default_model` must be included in `selectable_models`
- Model identifiers must be unique

If validation fails, you'll see clear error messages indicating what needs to be fixed.

### Testing

After adding a new model:

1. Verify the configuration files are syntactically correct (valid YAML)
1. Test the model selection in the GitLab UI
1. Ensure the model responds correctly to requests and that the right prompts are being used. You can do this by tailing the logs of the ai_gateway service and duo workflow service, using:

   ```shell
   gdk tail duo-workflow-service gitlab-ai-gateway
   ```

1. Validate that appropriate prompts are being used

## Notes

- Please note that adding a new model will automatically make it available for the feature, not just for GitLab SaaS, but also for self-managed instances using the cloud-connected AI Gateway.
- For a real-world example of adding new models, see [commit 16b9fee8](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/commit/16b9fee8d2ecdbb1d1d0f7e436883ed0769d8ba9) which added `gpt-5-mini` and `gpt-5-codex` models.
