---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Model Migration Process
---

## Current Migration Issues

The table below shows current open issues labeled with `AI Model Migration`. This provides a live view of ongoing model migration work across GitLab.

```glql
display: table
fields: title, author, assignee, milestone, labels, updated
limit: 10
query: label = "AI Model Migration" AND opened = true
```

*Note: This table is dynamically generated using GitLab Query Language (GLQL) when viewing the rendered documentation. It shows up to 10 open issues with the AI Model Migration label, sorted by most recently updated.*

## Quick Links

- **[GitLab AI Features - Default GitLab AI Vendor Models](https://duo-feature-list-754252.gitlab.io/)**: View all features and their current model mappings
- **[AI Model Version Migration Initiative Epic](https://gitlab.com/groups/gitlab-org/-/epics/15650)**: Central tracking epic for all model migration work
- **[AI Gateway Repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)**: Where model configurations are managed
- **[Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)**: For evaluating models and prompts

## Introduction

LLM models are constantly evolving, and GitLab needs to regularly update our AI features to support newer models. This guide provides a structured approach for migrating AI features to new models while maintaining stability and reliability.

## Model Migration Timelines

Model migrations typically follow these general timelines:

- **Simple Model Updates (Same Provider):** 1-2 weeks
  - Example: Upgrading from Claude Sonnet 3.5 to 3.7
  - Involves model validation, testing, and staged rollout
  - Primary focus on maintaining stability and performance

- **Complex Migrations:** 1-2 months (full milestone or longer)
  - Example: Adding support for a new provider like AWS Bedrock
  - Example: Major version upgrades with breaking changes (e.g., Claude 2 to 3)
  - Requires significant API integration work
  - May need infrastructure changes

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
- Prioritize system stability over speed of deployment

{{< alert type="note" >}}
While some migrations can technically be completed quickly, we typically plan for longer timelines to ensure proper testing and staged rollouts. This approach helps maintain system stability and reliability.
{{< /alert >}}

## Team Responsibilities

Model migrations involve several teams working together. This section clarifies which teams are responsible for different aspects of the migration process.

### RACI Matrix for Model Migrations

| Task | AI Framework | Feature Teams | Product | Infrastructure |
|------|-------------|--------------|---------|---------------|
| Model configuration file creation | R/A | C | I | I |
| Infrastructure compatibility | R/A | I | I | C |
| Feature-specific prompt adjustments | C | R/A | I | I |
| Evaluations & testing | C | R/A | I | I |
| Feature flag implementation | C | R/A | I | I |
| Rollout planning | C | R/A | C | I |
| Documentation updates | C | R/A | C | I |
| Monitoring & incident response | C | R/A | I | C |

R = Responsible, A = Accountable, C = Consulted, I = Informed

## Migration Process

{{< alert type="note" >}}
**Model Mapping Resource**: You can see which features use which models and versions via the [GitLab AI Features - Default GitLab AI Vendor Models](https://duo-feature-list-754252.gitlab.io/) page.
{{< /alert >}}

### Standard Migration Process

1. **Initialization**
   - AI Framework team creates an Issue in the [AI Model Version Migration Initiative Epic](https://gitlab.com/groups/gitlab-org/-/epics/15650)
   - Issue should use the naming convention: `AI Model Migration - Provider/Model/Version`
   - Apply the [`AI Model Migration`](https://gitlab.com/gitlab-org/gitlab/-/labels?subscribed=&sort=relevance&search=AI+Model+Migration#) label
   - AI Framework team adds model configuration to AI Gateway
   - AI Framework team verifies infrastructure compatibility

1. **Feature Team Implementation**
   - Feature teams create implementation plans
   - Feature teams adjust prompts if needed
   - Feature teams implement feature flags for controlled rollout

1. **Testing & Validation**
   - Feature teams run evaluations against the new model
   - AI Framework team provides evaluation support

1. **Deployment**
   - Feature teams manage feature flag rollout
   - Feature teams monitor performance and make adjustments

1. **Completion**
   - Feature teams remove feature flags when migration is complete
   - Feature teams update documentation

### Model Deprecation Process

1. **Identification & Planning**
   - AI Framework team monitors provider announcements
   - AI Framework team creates an epic: `Replace discontinued [model] with [replacement]`
   - Epic should have the `AI Model Migration` label
   - Set due date at least 2-4 weeks before provider's cutoff date
   - AI Framework team identifies replacement models

1. **Evaluation**
   - AI Framework team evaluates replacement models
   - Feature teams test affected features with candidates
   - Teams determine the best replacement model

1. **Implementation**
   - AI Framework team creates model configuration files
   - Feature teams update features to use the replacement model
   - Teams implement feature flags for controlled rollout

1. **Testing**
   - Feature teams run comprehensive evaluations
   - Teams document performance metrics

1. **Deployment**
   - Feature teams manage phased rollout via feature flags
   - Teams monitor performance closely
   - Rollout expands gradually based on performance

1. **Completion**
   - Remove feature flags when migration is complete
   - Update documentation
   - Clean up deprecated model references

## Prerequisites for Model Migration

Before starting a model migration:

1. **Create an issue** under the [AI Model Version Migration Initiative epic](https://gitlab.com/groups/gitlab-org/-/epics/15650):
   - Label with `group::ai framework` and `AI Model Migration`
   - Document behavioral changes or improvements
   - Include any breaking changes or compatibility issues
   - Reference provider documentation

1. **Verify model support** in AI Gateway:
   - Check model definitions:
     - For LiteLLM models: `ai_gateway/models/v2/container.py`
     - For Anthropic models: `ai_gateway/models/anthropic.py`
     - For new providers: Create new model definition file
   - Verify configurations (enums, stop tokens, timeouts, etc.)
   - Test the model locally:
     - Set up the [AI gateway development environment](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally)
     - Configure API keys in `.env` file
     - Test using Swagger UI at `http://localhost:5052/docs`
   - Create an issue for new model support if needed
   - Review provider API documentation for breaking changes

1. **Ensure access** to testing environments and monitoring tools

1. **Complete model evaluation** using the [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md)

### Additional Prerequisites for Model Deprecations

For model deprecations:

1. **Create an epic** when a deprecation is announced:
   - Label with `group::ai framework` and `AI Model Migration`
   - Document the deprecation timeline
   - Include provider migration recommendations
   - Reference the deprecation announcement
   - List all affected features

1. **Evaluate replacement models**:
   - Document evaluation criteria
   - Run comparative evaluations
   - Consider regional availability
   - Assess infrastructure changes required

1. **Create migration timeline**:
   - Set completion target at least 2-4 weeks before cutoff
   - Include time for each feature update
   - Plan for gradual rollout
   - Allow time for infrastructure changes

{{< alert type="note" >}}
Documentation of model changes and deprecations is crucial for tracking impact and future troubleshooting. Always create an issue before beginning any migration process.
{{< /alert >}}

## Implementation Guidelines

### Feature Team Migration Template

Feature teams should use the [AI Model Rollout template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/AI%20Model%20Rollout.md) to implement model migrations. See an example from our [Claude 3.7 Sonnet Code Generation Rollout Plan](https://gitlab.com/gitlab-org/gitlab/-/issues/521044).

### Anthropic Model Migration Tasks

**AI Framework Team:**

- Add new model to AI gateway configurations
- Verify compatibility with current API specification
- Verify the model works with existing API patterns
- Create model configuration file
- Document model-specific parameters or behaviors
- Verify infrastructure compatibility
- Update model definitions following [prompt definition guidelines](actions.md#2-create-a-prompt-definition-in-the-ai-gateway)

**Feature Team:**

- Add new model to [available models list](https://gitlab.com/gitlab-org/gitlab/-/blob/32fa9eaa3c8589ee7f448ae683710ec7bd82f36c/ee/lib/gitlab/llm/concerns/available_models.rb#L5-10)
- Change default model in [AI-Gateway client](https://gitlab.com/gitlab-org/gitlab/-/blob/41361629b302f2c55e35701d2c0a73cff32f9013/ee/lib/gitlab/llm/chain/requests/ai_gateway.rb#L63-67) behind feature flag
- Update model references in feature-specific code
- Implement feature flags for controlled rollout
- Test prompts with new model
- Monitor performance during rollout
- Update documentation

{{< alert type="note" >}}
While we're moving toward AI gateway holding the prompts, feature flag implementation still requires a GitLab release.
{{< /alert >}}

### Vertex Models Migration Tasks

**AI Framework Team:**

- Activate model in Google Cloud Platform
- Update AI gateway to support new Vertex model
- Document model-specific parameters

**Feature Team:**

- Update model references in feature-specific code
- Implement feature flags for controlled rollout
- Test prompts with new model
- Monitor performance during rollout
- Update documentation

## Feature Flag Implementation

### Implementation Steps

For implementing feature flags, refer to our [Feature Flags Development Guidelines](../feature_flags/_index.md).

{{< alert type="note" >}}
Feature flag implementations will affect self-hosted cloud-connected customers. These customers won't receive the model upgrade until the feature flag is removed from the AI gateway codebase, as they won't have access to the new GitLab release.
{{< /alert >}}

### Model Selection Implementation

Implement model selection logic in:

- AI gateway client (`ee/lib/gitlab/llm/chain/requests/ai_gateway.rb`)
- Model definitions in AI gateway
- Any custom implementations in specific features

### Rollout Strategy

1. **Enable feature flag** for small percentage of users/groups
1. **Monitor performance** using:
   - [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview)
   - [AI gateway metrics dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)
   - [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel)
   - [Feature usage dashboard](https://log.gprd.gitlab.net/app/r/s/egybF)
   - [Periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features)
1. **Gradually increase** rollout percentage
1. **If issues arise**, disable feature flag to rollback
1. **Once stable**, remove feature flag

## Common Migration Scenarios

### Simple Model Version Update (Same Provider)

**Example:** Upgrading from Claude 3.5 to Claude 3.7

**AI Framework Team:**

- Create migration issue
- Add model configuration file
- Verify API compatibility
- Ensure infrastructure support

**Feature Teams:**

- Create implementation issues
- Test prompts with new model
- Implement feature flags
- Monitor performance
- Remove feature flags when stable

### New Provider Integration

**Example:** Adding AWS Bedrock models

**AI Framework Team:**

- Create integration plan
- Implement provider API in AI gateway
- Create model configuration files
- Update authentication mechanisms
- Document provider-specific parameters
- Evaluate model performance

**Feature Teams:**

- Evaluate feature quality and performance with the new model
- Adapt prompts for new provider's models
- Implement feature flags
- Deploy and monitor
- Update documentation

### Model Deprecation Response

**Example:** Replacing discontinued Vertex AI Code Gecko v2

**AI Framework Team:**

- Create epic to track deprecation
- Evaluate replacement models
- Create model configuration
- Document routing logic
- Verify infrastructure compatibility

**Feature Teams:**

- Implement routing logic
- Create feature flags for transition
- Run evaluations
- Implement staged rollout
- Monitor performance during transition

## Troubleshooting Guide

### Prompt Compatibility Issues

If you encounter prompt compatibility issues:

1. **Analyze Errors:**
   - Enable "expanded AI logging" to capture model responses
   - Check for "LLM didn't follow instructions" errors
   - Review model outputs for unexpected patterns

1. **Resolve Issues:**
   - Create new prompt version (following semantic versioning)
   - Test prompt variations in evaluation environment
   - Use feature flags to control prompt deployment
   - Monitor performance during rollout

### Example: Claude 3.5 to 3.7 Migration

For Claude 3.7 migrations:

- Create new version 2.0.0 prompt definition
- Implement feature flag for prompt version control
- Use AI Framework team's model configuration file
- Run evaluations to verify performance
- Roll out gradually and monitor

## AI Framework Team Migration Issue Template

The AI Framework team should create a main migration issue following this template:

```markdown
# [Model Name] Model Upgrade

## Overview
[Brief description of the new model and its improvements]

## Features to Update
[List of features affected by this migration, organized by category]

### Generally Available Features
- [Feature 1]
- [Feature 2]

### Beta Features
- [Beta Feature 1]

### Experimental Features
- [Experimental Feature 1]

## Required Changes
- Add model configuration file for model flexibility
- New prompt definition created to use the new model
- Feature flag created for controlled rollout

## Technical Details
- [Any technical specifics about this migration]
- [Impact on GitLab.com and GitLab Self-Managed instances]

## Implementation Steps
- [ ] Update model configurations in each feature
- [ ] Verify performance improvements
- [ ] Deploy updates
- [ ] Update documentation

## Timeline
Priority: [Priority level]

## References
- [Model Announcement]
- [Model Documentation]
- [GitLab Documentation]
- [Other relevant links]

## Proposed Solution
[Description of the high-level implementation approach]

## Implementation Details

Please follow the issues below with the associated rollout plans:

| Feature | DRI | ETA | Issue Link |
|---------|-----|-----|------------|
| [Feature 1] | [@username] | [Date] | [Issue link] |
| [Feature 2] | [@username] | [Date] | [Issue link] |
```

See an example in our [Claude 3.7 Model Upgrade](https://gitlab.com/gitlab-org/gitlab/-/issues/521034) issue.

## References

- **Model Documentation**
  - [Anthropic Model Documentation](https://docs.anthropic.com/claude/reference/versions)
  - [Google Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/reference)

- **GitLab Resources**
  - [GitLab AI Features - Default GitLab AI Vendor Models](https://duo-feature-list-754252.gitlab.io/)
  - [AI Gateway Repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
  - [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
  - [AI Model Version Migration Initiative](https://gitlab.com/groups/gitlab-org/-/epics/15650)
