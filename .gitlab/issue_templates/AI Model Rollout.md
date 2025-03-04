<!-- Title suggestion: [Model] Rollout Plan -->

<!-- Do not remove this confidential declaration and make sure to mark this issue as confidential! -->

_The issue is marked confidential, as we'll share SAFE metrics in the comments._

## Overview

_Briefly describe the new model. Mention why you're introducing it._

<!-- Add relevant links. Example below: -->

| Resource | Links |
| -------------- | - |
| Model | <!-- Optional. Add relevant link(s) about the model. For example, links to model documentation. --> |
| Epic or Issue | <!-- We recommended creating an epic when introducing a new model --> |
| Feature Flag Rollout Issue | <!-- Required. --> |
| Status updates | <!-- Optional, but recommended. --> |

### Rollout success criteria

_Add a list of success criteria._

### Dashboard References

_This can be the acceptance rate or latency dashboards filtered to the new model. Add as many dashboards as is relevant._

## Legal notes

_Add legal notes here_

## Known issues

_List the issues identified throughout the evaluation, implementation, and rollout of the model._

## Rollout

### Timeline

_Optional: Breifly describe the expected timeline._

<!-- Add a detailed timeline similar to the example below: -->

| Date | Audience | Status |
|------|----------|--------|
| ??? | Feature team members and other stakeholders | |
| ??? | All GitLab team members | |
| ??? | 50% of all users | |
| ??? | 100% of all users | |

### Feedback from GitLab team members

_Add link to the internal feedback issue._

### Persevere / Continue Criteria

_Add specific criteria that indicates rollout is successful and should continue._

<!-- example criteria: -->
1. Latency remains within observed p50/90/95 ranges
2. Success/acceptance rate remains within observed range or improves
3. No blockers have been identified

<!-- Add supporting details as needed, for example: -->
_Observed latency from [date] to [date]_
* p50: X ms to Y ms
* p90: X ms to Y ms
* p95: X ms to Y ms

_Observed success/acceptance rate from [date] to [date]_
* Rate: X% to Y%

### Pivot / Pause / Rollback Criteria

_Add specific criteria that indicates the rollout should be paused or rolled back._

<!-- example criteria: -->
1. Requests are not using the new model as expected
2. There is an increase or spike in latency for the new model vs the old model
3. There is a decrease in success/acceptance rate compared to the old model

## Mitigation and Rollback Plan

_Describe how you will handle issues if they arise during rollout._

<!-- Example plan description: -->
We will use a [feature flag](https://docs.gitlab.com/operations/feature_flags/) to control the rollout. If we need to pause, pivot, or rollback the model, we will disable the feature flag, especially for external users, to investigate any potential issues.

## Release Announcement

_Describe where to make announcements when the model is ready for rollout to external users._

/confidential
/confidential
/label "type::feature"
/label "feature::maintenance"
/label "AI Model Migration"
<!-- Add appropriate labels based on the feature/team/category -->