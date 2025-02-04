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

NOTE:
While some migrations can technically be completed quickly, we typically plan for longer timelines to ensure proper testing and staged rollouts. This approach helps maintain system stability and reliability.

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

NOTE:
Documentation of model changes is crucial for tracking the impact of migrations and helping with future troubleshooting. Always create an issue to track these changes before beginning the migration process.

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

NOTE:
Feature flag implementations will affect self-hosted cloud-connected customers. These customers won't receive the model upgrade until the feature flag is removed from the AI gateway codebase, as they won't have access to the new GitLab release.

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

For more details on monitoring during migrations, see the [Monitoring and Metrics](#monitoring-and-metrics) section below.

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

## Testing and Validation

### Model Evaluation

The `ai-model-validation` team created the following library to evaluate the performance of prompt changes as well as model changes. The [Prompt Library README.MD](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md) provides details on how to evaluate the performance of AI features.

> Another use-case for running chat evaluation is during feature development cycle. The purpose is to verify how the changes to the code base and prompts affect the quality of chat responses before the code reaches the production environment.

For evaluation in merge request pipelines, we use:

- One click [Duo Chat evaluation](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner)
- Automated evaluation in [merge request pipelines](https://gitlab.com/gitlab-org/gitlab/-/issues/495410)

### Seed project and group resources for testing and evaluation

To seed project and group resources for testing and evaluation, run the following command:

```shell
SEED_GITLAB_DUO=1 FILTER=gitlab_duo bundle exec rake db:seed_fu
```

This command executes the [development seed file](../development_seed_files.md) for GitLab Duo, which creates `gitlab-duo` group in your GDK.

This command is responsible for seeding group and project resources for testing GitLab Duo features.
It's mainly used by the following scenarios:

- Developers or UX designers have a local GDK but don't know how to set up the group and project resources to test a feature in UI.
- Evaluators (e.g. CEF) have input dataset that refers to a group or project resource e.g. (`Summarize issue #123` requires a corresponding issue record in PosstgreSQL)

Currently, the input dataset of evaluators and this development seed file are managed separately.
To ensure that the integration keeps working, this seeder has to create the **same** group/project resources every time.
For example, ID and IID of the inserted PostgreSQL records must be the same every time we run this seeding process.

These fixtures are depended by the following projects:

- [Central Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
- [Evaluation Runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner)

See [this architecture doc](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner/-/blob/main/docs/architecture.md) for more information.

### Local Development

A valuable tool for local development to ensure the changes are correct outside of unit tests is to use [LangSmith](duo_chat.md#tracing-with-langsmith) for tracing. The tool allows you to trace LLM calls within Duo Chat to verify the LLM tool is using the correct model.

To prevent regressions, we also have CI jobs to make sure our tools are working correctly. For more details, see the [Duo Chat testing section](duo_chat.md#prevent-regressions-in-your-merge-request).

## Monitoring and Metrics

Monitor the following during migration:

- **Performance Metrics:**
  - Error ratio and response latency apdex for each AI action on [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview)
  - Spent tokens, usage of each AI feature and other statistics on [periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features)
  - [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel)
  - [AI gateway metrics](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)
  - [Feature usage dashboard via proxy](https://log.gprd.gitlab.net/app/r/s/egybF)
