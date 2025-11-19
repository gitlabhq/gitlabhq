---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: AI Evaluation Guidelines
---

Unlike traditional software systems that behave more-or-less predictably, minor input changes can cause AI-powered systems to produce significantly different outputs. This unpredictability stems from the non-deterministic nature of AI-generated responses. Traditional software testing methods are not designed to handle such variability, which is why AI evaluation has become essential. AI evaluation is a data-driven, quantitative process that analyzes AI outputs to assess system performance, quality, and reliability.

The [Centralized Evaluation Framework (CEF)](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library) provides a streamlined, unified approach to evaluating AI features at GitLab.
It is essential to our strategy for ensuring the quality of our AI-powered features.

Conceptually, there are three parts to an evaluation:

1. **Dataset**: A collection of test inputs (and, optionally, expected outputs).
1. **Target**: The target of the evaluation. For example, a prompt, an agent, a tool, a feature, a system component, or the application end-to-end.
1. **Metrics**: Measurable criteria used to assess the AI-generated output.

Each part plays a role in the evaluation process, as described below:

1. **Establish acceptance criteria**: Define metrics to indicate correct target behavior.
1. **Design evaluations**: Design evaluators and scenarios to score the metrics to assess the criteria.
1. **Create a dataset**: Collect representative examples covering typical usage patterns, edge cases, and error conditions.
1. **Execute**: Run evaluations of the target against the dataset.
1. **Analyze results**: Compare results with acceptance criteria and identify areas for improvement.
1. **Iterate and refine**: Make necessary adjustments based on evaluation findings.

## Establish acceptance criteria

Define metrics to determine when the target AI feature or component is working correctly.
The chosen metrics should align with success metrics that determine when desired business outcomes have been met.

### Types of metrics

The following are examples of metrics that might be relevant:

- **Accuracy**: Measures how often AI predictions are correct.
- **Precision and Recall**: Evaluate the balance between correctly identified positive results and the number of actual positives.
- **F1 score**: Combines precision and recall into a single metric.
- **Latency**: Measures the time taken to produce a response.
- **Token usage**: Evaluates the efficiency of the model in terms of token consumption.
- **Conciseness and Coherence**: Assess the clarity and logical consistency of the AI output.

Please note that for some targets, domain-specific metrics are essential, perhaps even more important than the general metrics listed here.
In some cases, choosing the right metric is a gradual, iterative process of discovery and experimentation involving multiple teams as well as feedback from users.

### Define thresholds

Establish clear thresholds for each metric if possible, such as minimum acceptable performance. For example:

- Accuracy: ≥85% of explanations are technically correct
- Latency: ≤3 seconds for 95th percentile response time

Note that it might not be feasible to define a threshold for novel metrics. This particularly applies to domain-specific metrics.
In general, we rely on user expectations to define thresholds for acceptable performance.
In some cases we'll know what users will expect before releasing a feature and can define thresholds accordingly.
In other cases we'll need to wait until we get feedback before we know what threshold to set.

## Design evaluations

When designing an evaluation, you define how you'll measure the target AI feature or component performance against acceptance criteria.
This involves choosing the right evaluators.
[Evaluators](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/tree/main/doc/evaluators) are functions that score the target AI performance on specific metrics.
Designing evaluations can also involve creating scenarios that test the target AI feature or component under realistic conditions.
You can implement different scenarios as distinct categories of dataset examples, or as variations in how the evaluation invokes the target AI feature or component.

Scenarios to consider include:

- **Baseline comparisons**: Compare new models or prompts against a baseline to determine improvements.
- **Side-by-side evaluations**: Compare different models, prompts, or configurations directly against each other.
- **Custom evaluators**: Implement custom evaluation functions to test specific aspects of AI performance relevant to your application's needs.
- **Dataset sampling**: Sample different subsets of the dataset that focus on different aspects of the target.

## Create a dataset

A well-structured dataset enables consistent testing and validation of an AI system or component across different scenarios and use cases.

For an overview of working with datasets in the CEF and LangSmith, see the [dataset management](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/datasets/-/blob/main/doc/dataset_management.md) documentation.

For more detailed information on creating and preparing datasets for evaluation, see our [dataset creation guidelines](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/tree/main/doc/datasets#dataset-creation-guidelines-for-gitlab-ai-features) and [instructions for uploading datasets to LangSmith](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/datasets/-/blob/main/doc/guidelines/create_dataset.md).

### Synthetic prompt evaluation dataset generator

If you are evaluating a prompt, a quick way to get started is to use our [dataset generator](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/evaluation/dataset_generation.md).
It generates a synthetic evaluation dataset directly from an AI Gateway prompt definition.
You can watch a quick [demonstration](https://www.youtube.com/watch?v=qZEnC4PN3Co).

## Execute evaluations

When an evaluation is executed, the CEF invokes the target AI feature or component at least once for each input example in the evaluation dataset.
The framework then invokes evaluators to score the AI output, and provides you with the results of the evaluation.

### In merge requests

[Evaluation Runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner) can be used to run an evaluation in a CI pipeline in a merge request. It spins up a new [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/) instance on a remote environment, runs an evaluation using the CEF, and reports the results in the CI job log. See the guide for [how to use evaluation runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#how-to-use).

### On your local machine

See the [step-by-step guide for conducting evaluations using the CEF](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/index.md?ref_type=heads).

## Analyze results

The CEF uses LangSmith to store and analyze evaluation results. See the [LangSmith guide for how to analyze an experiment](https://docs.smith.langchain.com/evaluation/how_to_guides/analyze_single_experiment).

For guidance regarding specific features, see the Analyze Results section of the feature-specific documentation for [running evaluations locally](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/tree/main/doc/running_evaluation_locally). You can also find some information about interpreting evaluation metrics in the [GitLab Duo Chat evaluation documentation](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/tree/main/doc/duo_chat).

Please note that we're updating the documentation on executing and interpreting the results of existing evaluation pipelines (see [#671](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/issues/671)).

## Iterate and refine

Similar to the [AI feature development process](ai_feature_development_playbook.md), iterating on evaluation means returning to previous steps as indicated by the evaluation results. [Prompt engineering](prompt_engineering.md) is key to this step. However, it might also involve adding examples to the dataset, editing existing examples, adjusting the design of the evaluations, or reviewing and revising the metrics and success criteria.

## Additional resources

- [AI evaluation tooling](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation): The group containing AI evaluation tooling used at GitLab.
- [LangSmith Evaluations YouTube playlist](https://www.youtube.com/playlist?list=PLfaIDFEXuae0um8Fj0V4dHG37fGFU8Q5S):
  Deep dive on evaluation with LangSmith.
- [LangSmith Evaluation Cookbook](https://github.com/langchain-ai/langsmith-cookbook/blob/main/README.md#testing--evaluation):
  Contains various evaluation scenarios and examples.
- [LangSmith How To Guides](https://docs.smith.langchain.com/evaluation/how_to_guides): Contains various how to
  walkthroughs.
- [GitLab Duo Chat Documentation](duo_chat.md):
  Comprehensive guide on setting up and using LangSmith for chat evaluations.
- [Prompt and AI Feature Evaluation Setup and Workflow](https://gitlab.com/groups/gitlab-org/-/epics/13952):
  Details on the overall workflow and setup for evaluations.
