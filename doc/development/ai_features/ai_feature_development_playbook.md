---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: AI feature development playbook
---

This playbook outlines our approach to developing AI features at GitLab, similar to and concurrent with [the Build track of our product development flow](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#build-track). It serves as a playbook for AI feature development and operational considerations.

## Getting Started

- Start with [an overview of the AI-powered stage](https://about.gitlab.com/direction/ai-powered/).
- Play around with [existing features](../../user/gitlab_duo/feature_summary.md) in your [local development environment](_index.md#instructions-for-setting-up-gitlab-duo-features-in-the-local-development-environment).
- When you're ready, proceed with the development flow below.

## AI Feature Development Flow

The AI feature development process consists of five key interdependent and iterative phases:

### Plan

This phase prepares AI features so they are ready to be built by engineering. It supplements the [plan phase of the build track of the product development flow](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#build-phase-1-plan).

At this point, the customer problem should be well understood, either because of a clearly stated requirement,
or by working through the [product development flow validation track](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#validation-track).

As part of this phase, teams decide if [approved models](../ai_architecture.md#models) satisfy the requirements of the new feature, or [submit a proposal for the approval of other models](../ai_architecture.md#supported-technologies). Teams also design or adopt testing and evaluation strategies, which includes identifying required datasets.

#### Key Activities

- Define AI feature requirements and success criteria
- Select models and assess their capabilities
- Plan testing and evaluation strategy

#### Resources

- [AI architecture overview](../ai_architecture.md)

### Develop

The develop phase, and the closely aligned test and evaluate phase, are where we build AI features,
address bugs or technical debt, and test the solutions before launching them. It supplements the [develop and test phase of the build track of the product development flow](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#build-phase-2-develop--test).

This phase includes prompt engineering, where teams craft and refine prompts to achieve desired AI model behavior.
This often requires multiple iterations to optimize for accuracy, consistency, and user experience.

Development might include integrating chosen models with GitLab infrastructure through the AI Gateway,
and implementing API interfaces.
Teams must consider requirements for supporting [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md).

#### Key Activities

- [Local development environment setup](_index.md)
- [Prompt development and engineering](prompt_engineering.md)
- Model integration and API development
- [Connecting a new feature via Cloud Connector](cloud_connector.md)
- [Feature flag implementation](_index.md#push-feature-flags-to-ai-gateway)
- Event tracking instrumentation:
  - [AI usage tracking metrics](usage_tracking.md)
  - [Duo feature classification](../internal_analytics/internal_event_instrumentation/duo_classification.md)

#### Resources

- [AI Gateway architecture design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/)
- [AI Gateway API documentation](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md)
- [AI Gateway prompt registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/aigw_prompt_registry.md)
- [Developing AI Features for Duo Self-Hosted](developing_ai_features_for_duo_self_hosted.md)
- [Cloud Connector dev docs](cloud_connector.md)
- [Cloud Connector design docs in Handbook](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector)

### Test & Evaluate

In the test and evaluate phase, we validate AI feature quality, performance, and security,
using [traditional automated testing practices](../testing_guide/_index.md), as well as evaluation of AI-generated content.
It supplements the [develop and test phase of the build track of the product development flow](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#build-phase-2-develop--test).

Evaluation involves creating datasets that represent real-world usage scenarios to ensure comprehensive coverage of the feature's behavior.
Teams implement evaluation strategies covering multiple aspects of the quality of AI-generated content, as well as performance characteristics.

#### Key Activities

- [Functional testing](../testing_guide/testing_ai_features.md)
- Performance testing
- Security and safety validation
- [Dataset creation](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/datasets/-/blob/main/doc/guidelines/create_dataset.md) and [management](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/datasets/-/blob/main/doc/dataset_management.md)
- [Evaluation](ai_evaluation_guidelines.md)

### Launch & Monitor

This phase focuses on safely introducing AI features to production through controlled rollouts and comprehensive monitoring.
It supplements the [launch phase of the build track of the product development flow](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#build-phase-3-launch).

We employ feature flags to control access and gradually expand user exposure,
starting with internal teams before broader incremental release.
Monitoring tracks technical metrics (latency, error rates, resource usage)
and AI-specific indicators (model performance, response quality, user satisfaction).
Alerting systems can be used to detect performance degradation, unusual patterns, or safety concerns that require immediate attention.

#### Key Activities

- [Feature flag controlled rollout](../feature_flags/controls.md)
- Production monitoring setup
- Performance tracking and alerting
- User feedback collection
- Quality assurance in production

#### Resources

- [AI Gateway release process](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md)
- [AI Gateway infrastructure runbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/ai-gateway/README.md)

### Improve

This phase focuses on iteratively improving the feature based on data, user feedback, and changing requirements.
It supplements the [improve phase of the build track of the product development flow](https://handbook.gitlab.com/handbook/product-development/product-development-flow/#build-phase-4-improve).

We analyze real-world usage patterns and performance metrics to identify opportunities for improvement,
whether in prompt engineering, model selection, system architecture, or feature design.
User feedback should capture qualitative insights about user satisfaction.
Teams can iteratively refine prompts based on user interactions and feedback.

This phase includes model migrations as newer, more capable models become available.

#### Key Activities

- Performance analysis and optimization
- [Prompt iteration and refinement](prompt_engineering.md#prompt-tuning-for-llms-using-langsmith-and-anthropic-workbench-together--cef)
- [Model migration and upgrades](model_migration.md)
- Dataset enhancement and expansion

## Phase Interdependencies

Each phase can feed back into any or all earlier phases as development proceeds. The develop and test & evaluate phases are especially intertwined.
Examples of interdependencies include:

- **Evaluation** insights might require new development iterations.
- **Production monitoring** results may suggest architectural replanning.
- **User feedback** could inform evaluation strategy changes.
