---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Model Migration Process
---

## Introduction

LLM models are constantly evolving, and GitLab needs to regularly update our AI features to support newer models. This guide provides a structured approach for migrating AI features to new models while maintaining stability and reliability.

## Purpose

Provide a comprehensive guide for migrating AI models within GitLab.

### Expected Duration

Model migrations typically follow these general timelines:

- **Simple Model Updates (Same Provider):** 2-3 weeks
  - Example: Upgrading from Claude Sonnet 3.5 to 3.6
  - Involves model validation, testing, and staged rollout
  - Primary focus on maintaining stability and performance
  - Can sometimes be expedited when urgent, but 2 weeks is standard

- **Complex Migrations:** 1-2 months (full milestone or longer)
  - Example: Adding support for a new provider like AWS Bedrock
  - Example: Major version upgrades with breaking changes (e.g., Claude 2 to 3)
  - Requires significant API integration work
  - May need infrastructure changes
  - Extensive testing and validation required

### Timeline Factors

Several factors can impact migration timelines:

- Current system stability and recent incidents
- Resource availability and competing priorities
- Complexity of behavioral changes in new model
- Scale of testing required
- Feature flag rollout strategy

### Best Practices

- Always err on the side of caution with initial timeline estimates
- Use feature flags for gradual rollouts to minimize risk
- Plan for buffer time to handle unexpected issues
- Communicate conservative timelines externally while working to deliver faster
- Prioritize system stability over speed of deployment

{{< alert type="note" >}}

While some migrations can technically be completed quickly, we typically plan for longer timelines to ensure proper testing and staged rollouts. This approach helps maintain system stability and reliability.

{{< /alert >}}

## Scope

Applicable to all AI model-related teams at GitLab. We currently support using Anthropic and Google Vertex models. Support for AWS Bedrock models is proposed in [issue 498119](https://gitlab.com/gitlab-org/gitlab/-/issues/498119).

## Prerequisites

Before starting a model migration:

- Create an issue under the [AI Model Version Migration Initiative epic](https://gitlab.com/groups/gitlab-org/-/epics/15650) with the following:
  - Label with `group::ai framework`
  - Document any known behavioral changes or improvements in the new model
  - Include any breaking changes or compatibility issues
  - Reference any model provider documentation about the changes

- Verify the new model is supported in our current AI-Gateway API specification by:

  - Check model definitions in AI gateway:
    - For LiteLLM models: `ai_gateway/models/v2/container.py`
    - For Anthropic models: `ai_gateway/models/anthropic.py`
    - For new providers: Create a new model definition file in `ai_gateway/models/`
  - Verify model configurations:
    - Model enum definitions
    - Stop tokens
    - Timeout settings
    - Completion type (text or chat)
    - Max token limits
  - Testing the model locally in AI gateway:
    - Set up the [AI gateway development environment](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally)
    - Configure the necessary API keys in your `.env` file
    - Test the model using the Swagger UI at `http://localhost:5052/docs`
  - If the model isn't supported, create an issue in the [AI gateway repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist) to add support
  - Review the provider's API documentation for any breaking changes:
    - [Anthropic API Documentation](https://docs.anthropic.com/claude/reference/versions)
    - [Google Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/reference)

- Ensure you have access to testing environments and monitoring tools
- Complete model evaluation using the [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md)

{{< alert type="note" >}}

Documentation of model changes is crucial for tracking the impact of migrations and helping with future troubleshooting. Always create an issue to track these changes before beginning the migration process.

{{< /alert >}}

## Migration Tasks

### Migration Tasks for Anthropic Model

- **Optional** - Investigate if the new model is supported within our current AI-Gateway API specification. This step can usually be skipped. However, sometimes to support a newer model, we may need to accommodate a new API format.
- Add the new model to our [available models list](https://gitlab.com/gitlab-org/gitlab/-/blob/32fa9eaa3c8589ee7f448ae683710ec7bd82f36c/ee/lib/gitlab/llm/concerns/available_models.rb#L5-10).
- Change the default model in our [AI-Gateway client](https://gitlab.com/gitlab-org/gitlab/-/blob/41361629b302f2c55e35701d2c0a73cff32f9013/ee/lib/gitlab/llm/chain/requests/ai_gateway.rb#L63-67). Please place the change around a feature flag. We may need to quickly rollback the change.
- Update the model definitions in AI gateway following the [prompt definition guidelines](actions.md#2-create-a-prompt-definition-in-the-ai-gateway)
Note: While we're moving toward AI gateway holding the prompts, feature flag implementation still requires a GitLab release.

### Migration Tasks for Vertex Models

**Work in Progress**

## Feature Flag Process

### Implementation Steps

For implementing feature flags, refer to our [Feature Flags Development Guidelines](../feature_flags/_index.md).

{{< alert type="note" >}}

Feature flag implementations will affect self-hosted cloud-connected customers. These customers won't receive the model upgrade until the feature flag is removed from the AI gateway codebase, as they won't have access to the new GitLab release.

{{< /alert >}}

### Model Selection Implementation

The model selection logic should be implemented in:

- AI gateway client (`ee/lib/gitlab/llm/chain/requests/ai_gateway.rb`)
- Model definitions in AI gateway
- Any custom implementations in specific features that override the default model

### Rollout Strategy

- Enable the feature flag for a small percentage of users/groups initially
- Monitor performance metrics and error rates using:
  - [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview) for error ratios and response latency
  - [AI gateway metrics dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1) for gateway-specific metrics
  - [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel) for detailed error investigation
  - [Feature usage dashboard](https://log.gprd.gitlab.net/app/r/s/egybF) for adoption metrics
  - [Periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features) for token usage and feature statistics
- Gradually increase the rollout percentage
- If issues arise, quickly disable the feature flag to rollback to the previous model
- Once stability is confirmed, remove the feature flag and make the migration permanent

For more details on monitoring during migrations, see the [Monitoring and Metrics](testing_and_validation.md#monitoring-and-metrics) section below.

## Scope of Work

### AI Features to Migrate

- **Duo Chat Tools:**
  - `ci_editor_assistant/prompts/anthropic.rb` - CI Editor
  - `gitlab_documentation/executor.rb` - GitLab Documentation
  - `epic_reader/prompts/anthropic.rb` - Epic Reader
  - `issue_reader/prompts/anthropic.rb` - Issue Reader
  - `merge_request_reader/prompts/anthropic.rb` - Merge Request Reader
- **Chat Slash Commands:**
  - `refactor_code/prompts/anthropic.rb` - Refactor
  - `write_tests/prompts/anthropic.rb` - Write Tests
  - `explain_code/prompts/anthropic.rb` - Explain Code
  - `explain_vulnerability/executor.rb` - Explain Vulnerability
- **Experimental Tools:**
  - Summarize Comments Chat
  - Fill MR Description
