<!--
# README first!

This template covers steps required to do a Root Cause Analysis for unplanned upgrade stop.

Unplanned upgrade stop documentation: https://handbook.gitlab.com/handbook/engineering/unplanned-upgrade-stop/

Example RCA as a reference: https://gitlab.com/gitlab-org/gitlab/-/issues/423895
-->

## Summary

A brief summary of what happened. Try to make it as executive-friendly as possible.

- Upgrade path(s) affected:
- Upgrade type: downtime / zero downtime upgrade
- [Type of degradation](https://handbook.gitlab.com/handbook/engineering/unplanned-upgrade-stop/#unplanned-upgrade-types): Database migration error / Configuration changes / Breaking functionality changes
- Relevant bug issue:
- Team attribution: ~group::

## Impact & Metrics

Start with the following:

| Question | Answer |
| ----- | ----- |
| Who was impacted? | (i.e. customers with specific environment configurations or data ...) |
| How many customers affected? |  |

Include any additional metrics that are of relevance.

## Detection & Response

Start with the following:

| Question | Answer |
| ----- | ----- |
| When was the issue detected? | YYYY-MM-DD |
| How was the issue detected? | (i.e. Support request, Bug raised, ...) |
| How long did it take from the start of the issue to its detection? |  |
| How long did it take from detection to remediation? |  |
| What steps were taken to remediate? |  |
| Was patch release created? |  |
| Was patch backported to older versions? |  |

## Timeline

YYYY-MM-DD

- something happened
- something else happened
- ...

YYYY-MM-DD+1

- and then this happened
- and more happened
- ...

## Root Cause Analysis

The purpose of this document is to understand the reasons that caused an issue, and to create mechanisms to prevent it from recurring in the future. A root cause can **never be a person**, the way of writing has to refer to the system and the context rather than the specific actors.

### What is causing upgrade error

Start with the following:

- What is the cause of the upgrade error?
- What steps could be done to reproduce the upgrade error?

### What can be improved

DRI: Corresponding Engineering team

- Using the root cause analysis, explain what can be improved to prevent this from happening again.
- What changes to our tooling or review process would have prevented this issue?
- Is there an existing issue that would have either prevented this issue or reduced the impact?
- Did we have any indication or beforehand knowledge that this issue might take place?

DRI: Test Platform

- What is the cause of the test gap on integration and system level testing?
- What can be done to increase test coverage?
- Did relevant tests pass for this upgrade path?

## Corrective actions

- Link issues that have been created as corrective actions from this issue.
- For each issue, include the following:
    - `<Issue link>` - Issue labeled as ~"corrective action" ~upgrades.
    - An estimated date of completion of the corrective action. Priority of the issue should correspond with RCA severity.

## Guidelines

- [Blameless RCA Guideline](https://about.gitlab.com/handbook/customer-success/professional-services-engineering/workflows/internal/root-cause-analysis.html)
- [5 whys](https://en.wikipedia.org/wiki/5_Whys)

/confidential
/label ~RCA ~upgrades ~"type::ignore"

<!--
Workflow and other relevant labels

Select appropriate severity based on impact. For example:
~"severity::1" when unplanned upgrade stop needed to be added,
~"severity::2" when no unplanned stop was introduced but patch releases needed to be created
https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity
-->
/label ~severity::

<!--
Specify Engineering group owning the bug related to this RCA
-->
/label ~group::

<!--
Link existing upgrade bug to this RCA
-->
/relate 
