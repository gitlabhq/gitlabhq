---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: AI principles distillation flow
description: Visual overview of how the weekly sync distills AI development principles from documentation.
---

The weekly sync distills AI development principles from documentation.
Review this flow before changing the manifest, the distiller gem, or the sync schedule.

For the step-by-step description, see
[How the sync works](_index.md#how-the-sync-works).

## Distillation flow

Each sync run starts with drift detection and ends with a merge request that updates the distilled files.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart TD
    accTitle: AI principles distillation flow
    accDescr: Flowchart of the weekly sync run, from drift detection through merge request creation
    Start([Weekly scheduled CI job]) --> Load

    Load[Load manifest.yml] --> Drift

    Drift{Checksum matches<br/>distilled file front matter?}
    Drift -->|Yes| UpToDate[Principle is up to date]
    Drift -->|No| Affected[Principle needs an update]

    UpToDate --> AnyAffected
    Affected --> AnyAffected

    AnyAffected{Any principles<br/>need an update?}
    AnyAffected -->|No| Done([Exit: nothing to do])
    AnyAffected -->|Yes| Validate

    Validate{Source and baseline<br/>files exist?}
    Validate -->|No| Fail([Fail: missing source path])
    Validate -->|Yes| Distill

    Distill[Call GitLab Duo Agent Platform<br/>Workflow API per principle] --> Assemble

    Assemble[Assemble distilled file<br/>and absolutize links] --> Meaningful

    Meaningful{Content changed?}
    Meaningful -->|No| NoChange[Skip principle]
    Meaningful -->|Yes| Write[Write file with<br/>new checksum front matter]

    NoChange --> Collected
    Write --> Collected

    Collected[Collect updated files] --> MR

    MR[Open merge request<br/>targeting the default branch] --> Review([Human approval and merge])
```

## Related

- [Manifest reference](manifest_reference.md) for `.ai/principles/manifest.yml`.
- [`gems/gitlab-ai-principles-distiller`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-ai-principles-distiller)
  for the gem that drives the sync.
