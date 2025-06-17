---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Evaluation runner
---

Evaluation runner (`evaluation-runner`) allows GitLab employees to run evaluations on specific GitLab AI features with one click.

- You can run the evaluation on GitLab.com and GitLab-supported self-hosted models.
- To view the AI features that are currently supported, see
  [Evaluation pipelines](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#evaluation-pipelines).

Evaluation runner spins up a new GDK instance on a remote environment, runs an evaluation, and reports the result.

For more details, view the
[`evaluation-runner` repository](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner).

## Architecture

```mermaid
flowchart LR
  subgraph EV["Evaluators"]
    PL(["PromptLibrary/ELI5"])
    DSIN(["Input Dataset"])
  end

  subgraph ER["EvaluationRunner"]
    CI["CI/CD pipelines"]
    subgraph GDKS["Remote GDKs"]
        subgraph GDKM["GDK-master"]
          bl1["Duo features on master branch"]
          fi1["fixtures (Issue,MR,etc)"]
        end
        subgraph GDKF["GDK-feature"]
          bl2["Duo features on feature branch"]
          fi2["fixtures (Issue,MR,etc)"]
        end
    end
  end

  subgraph MR["MergeRequests"]
    GRMR["GitLab-Rails MR"]
    GRAI["AI Gateway MR"]
  end

  MR -- [1] trigger --- CI
  CI -- [2] spins up --- GDKS
  PL -- [3] get responses and evaluate --- GDKS
```
