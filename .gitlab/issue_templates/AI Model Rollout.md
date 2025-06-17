<!-- Title suggestion: [AI Model] Rollout Plan -->

<!-- Do not remove this confidential declaration and make sure to mark this issue as confidential! -->

_The issue is marked confidential, as we'll share SAFE metrics in the comments._

## Overview
<!-- Add relevant links. Example below: -->

| Resource | Links |
| -------------- | - |
| Model | <!-- Optional. Add relevant link(s) about the model. For example, links to model documentation. --> |
| Epic or Issue | <!-- We recommended creating an epic when introducing a new model --> |
| Feature Flag Rollout Issue | <!-- Required. --> |
| Status updates | <!-- Optional, but recommended. --> |

### Checklist 
- [ ] Update the following `yml` files to support customer personal model selection:
  - [ ] Add a new configurable to [unit_primitives.yml](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/model_selection/unit_primitives.yml)
  - [ ] Add the new feature model to [model.yml](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/model_selection/models.yml)
- [ ] *Optional*: Pin the prompt version to rollout in the GitLab Rails client by overriding the prompt version [behind a feature flag](https://gitlab.com/gitlab-org/gitlab/-/blob/879066eaafb9a989ad8ca26e97602db7f40e47ca/ee/lib/gitlab/llm/chain/tools/identifier.rb#L152-155).
- [ ] *Optional*: Configure the prompt registry with a non-stable prompt (i.e., `alpha`, `dev`, `rc`) once you fully roll out to internal/external users. [Prompt versioning conventions](https://docs.gitlab.com/development/ai_features/actions/#appendix-a-prompt-versioning-conventions)
- [ ] Once the feature is fully rolled out, add a *stable* prompt version— non `dev`, `alpha` or `beta` prompt to the prompt registry.

### Evaluation Metrics

Use this base table to share evaluation metrics with team members. Run metrics from either the [prompt-library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library) or [evaluation-runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner).

## Evaluation Template
**Langsmith Experiment**: [View Results](<insert_link>)

| Evaluation Pipeline | Model | Quality Metric | P50 Latency | P99 Latency |
|-------------------|-------|----------------|-------------|-------------|
| [pipeline_link] | claude-3-7-sonnet (baseline) | context-qa-accuracy: X | 17.5s | 44s |
| [pipeline_link] | claude-4-0-sonnet | context-qa-accuracy: X | 22s | 40s |
| **Change** | | **XX change** | **+X% slower** | **XX% faster** |

### Rollout Success Criteria

1. Verify the prompt registry selects the correct prompt version in production. 
   1. Filter the [Kibana link](https://log.gprd.gitlab.net/app/r/s/Pu5F3) with `json.jsonPayload.message: Returning prompt from the registry` to view all selected prompt version information. 
2. Confirm Duo Chat streaming works correctly. Check our [Kibana Dashboard](https://log.gprd.gitlab.net/app/r/s/AxFq1) ReAct Agent streaming page [DC | Sidekiq] to verify the LLM follows ReAct instructions (V2 Duo Chat only - broken streaming)

_Add your specific success criteria._

### Dashboard References

_Filter acceptance rate or latency dashboards to the new model. Add all relevant dashboards._

## Legal Notes

_Add legal notes here_

## Known Issues

_List issues you identified during evaluation, implementation, and rollout of the model._

## Rollout

### Timeline

_Optional: Describe your expected timeline._

<!-- Add a detailed timeline similar to the example below: -->

| Date | Audience | Status |
|------|----------|--------|
| ??? | Feature team members and other stakeholders | |
| ??? | All GitLab team members | |
| ??? | 50% of all users | |
| ??? | 100% of all users | |

### Feedback from GitLab Team Members

_Add link to the internal feedback issue._

### Persevere / Continue Criteria

_Define specific criteria that indicate successful rollout and continuation._

<!-- example criteria: -->
1. Maintain latency within observed p50/90/95 ranges
2. Keep success/acceptance rate within observed range or improve it
3. Identify no blockers

<!-- Add supporting details as needed, for example: -->
_Observed latency from [date] to [date]_
* p50: X ms to Y ms
* p90: X ms to Y ms
* p95: X ms to Y ms

_Observed success/acceptance rate from [date] to [date]_
* Rate: X% to Y%

### Pivot / Pause / Rollback Criteria

_Define specific criteria that require pausing or rolling back the rollout._

<!-- example criteria: -->
1. Requests fail to use the new model as expected
2. Latency increases or spikes for the new model vs the old model
3. Success/acceptance rate decreases compared to the old model

## Mitigation and Rollback Plan

_Describe how you will handle issues during rollout._

<!-- Example plan description: -->
We will control the rollout using a [feature flag](https://docs.gitlab.com/operations/feature_flags/). If we need to pause, pivot, or rollback the model, we will disable the feature flag, especially for external users, to investigate potential issues.

## Useful Documentation

- [Prompt Versioning Guidelines](https://docs.gitlab.com/development/ai_features/actions/#appendix-a-prompt-versioning-conventions)

- [How to add a new prompt version](https://docs.gitlab.com/development/ai_features/actions/#1-add-your-action-to-the-cloud-connector-feature-list)

- [Model Selection Blueprint](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_model_selection/)

## Release Announcement

_Describe where you will announce the model when ready for rollout to external users._

/confidential
/confidential
/label "type::feature"
/label "feature::maintenance"
/label "AI Model Migration"
<!-- Add appropriate labels based on the feature/team/category -->