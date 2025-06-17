---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Testing and Validation
---

## Testing and validation

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
- Evaluators (for example, CEF) have input dataset that refers to a group or project resource (for instance, `Summarize issue #123` requires a corresponding issue record in PostgreSQL)

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

- **Performance Metrics**:
  - Error ratio and response latency apdex for each AI action on [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview)
  - Spent tokens, usage of each AI feature and other statistics on [periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features)
  - [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel)
  - [AI gateway metrics](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)
  - [Feature usage dashboard via proxy](https://log.gprd.gitlab.net/app/r/s/egybF)
