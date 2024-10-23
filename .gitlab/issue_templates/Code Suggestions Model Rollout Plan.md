<!-- Title suggestion: [Model] Rollout Plan -->

<!-- Do not remove this confidential declaration and make sure to mark this issue as confidential! -->

_The issue is marked confidential, as we'll share SAFE metrics in the comments._

## Overview

_Add a short statement here about the new model. Make sure your overview includes a reason as to why you are introducing this new model._

<!-- Add relevant links. Example below: -->

| Resource | Links |
| -------------- | - |
| Model | <!-- add relevant link(s) about the model, e.g.: model documentation --> |
| Epic or Issue | <!-- it is recommended to create an epic when introducing a new model --> |
| Feature Flag Rollout Issue | <!-- this is required --> |
| Status updates | <!-- this is optional but recommended --> |

### Rollout success criteria

_Add a list of success criteria here_

### Dashboard References

_This can be the acceptance rate or latency dashboards filtered to the new model. Add as many dashboards as is relevant._

## Legal notes

_Add legal notes here_

## Known issue list

_List of issues identified throughout the evaluation, implementation, and rollout of the model._

## Rollout

### Timeline

_Optional: add a short description here of the expected timeline._

<!-- Add a detailed timeline similar to the example below: -->

| Date | Audience | Status |
|------|----------|--------|
| ??? | Code Creation team members and other stakeholeders | |
| ??? | All GitLab team members | |
| ??? | 50% of all users | |
| ??? | 100% of all users | |

### Feedback from GitLab team members

_Add link to the internal feedback issue._

### Persevere / Continue Criteria

<!-- example criteria: -->

1. Latency remains within observed p50/90/95 ranges below
1. Acceptance rate remains within observed range below, or improves
1. Nothing was raised as a blocker

<!-- example supporting details -->

_Observed latency from May 17 to Aug 21_

* p50: 637ms to 782ms
* p90: 881ms to 1,046ms
* p95: 977ms to 1,212 ms

_Observed acceptance rate from July 4 to Aug 21_

* Acceptance rate: 13.9% to 20.4%

### Pivot / Pause / Rollback Criteria

<!-- example criteria: -->

1. Requests are not using the new model as expected
1. There is an increase or spike in time-to-show for the new model vs the old model
1. There is a decrease in acceptance rate compared to the old model

## Mitigation and Rollback Plan

<!-- Example plan description: -->

We will use a Feature Flag to control the rollout. If there are any concerns (see above), we will disable the feature flag, especially for external users, to investigate any potential issues.

## Release Announcement

_Add details here about where to make announcements when the model is ready for rollout to external users._

/confidential
/label "group::code creation"
/label "devops::create"
/label "section::dev"
/label "type::feature"
/label "feature::maintenance"
/label "Category:Code Suggestions"
