**Please note:** if the incident relates to sensitive data or is security-related, consider
labeling this issue with ~security and mark it confidential, or create it in a private repository. 

There is now a separate internal-only RCA template for SIRT issues referenced https://handbook.gitlab.com/handbook/security/root-cause-analysis/
***

## Summary

A brief summary of what happened. Try to make it as executive-friendly as possible.

- Service(s) affected:
- Team attribution:
- Minutes downtime or degradation:

## Impact & Metrics

Start with the following:

| Question | Answer |
| ----- | ----- |
| What was the impact? | (i.e. service outage, sub-service brown-out, exposure of sensitive data, ...) |
| Who was impacted? | (i.e. external customers, internal customers, specific teams, ...) |
| How did this impact customers? | (i.e. preventing them from doing X, incorrect display of Y, ...) |
| How many attempts made to access? |  |
| How many customers affected? |  |
| How many customers tried to access? |  |

Include any additional metrics that are of relevance.

Provide any relevant graphs that could help understand the impact of the incident and its dynamics.

## Detection & Response

Start with the following:

| Question | Answer |
| ----- | ----- |
| When was the incident detected? | YYYY-MM-DD UTC |
| How was the incident detected? | (i.e. DELKE, H1 Report, ...) |
| Did alarming work as expected? |  |
| How long did it take from the start of the incident to its detection? |  |
| How long did it take from detection to remediation? |  |
| What steps were taken to remediate? |  |
| Were there any issues with the response? | (i.e. bastion host used to access the service was not available, relevant team member wasn't page-able, ...) |

## MR Checklist

Consider these questions if a code change introduced the issue.

| Question | Answer |
| ----- | ----- |
| Was the [MR acceptance checklist](https://docs.gitlab.com/ee/development/code_review.html#acceptance-checklist) marked as reviewed in the MR? | |
| Should the checklist be updated to help reduce chances of future recurrences? If so, who is the DRI to do so? | |

## Timeline

YYYY-MM-DD

- 00:00 UTC - something happened
- 00:01 UTC - something else happened
- ...

YYYY-MM-DD+1

- 00:00 UTC - and then this happened
- 00:01 UTC - and more happened
- ...


## Root Cause Analysis

The purpose of this document is to understand the reasons that caused an incident, and to create mechanisms to prevent it from recurring in the future. A root cause can **never be a person**, the way of writing has to refer to the system and the context rather than the specific actors.

Follow the "**5 whys**" in a **blameless** manner as the core of the root cause analysis.

For this, it is necessary to start with the incident and question why it happened. Keep iterating asking "why?" 5 times. While it's not a hard rule that it has to be 5 times, it helps to keep questions get deeper in finding the actual root cause.

Keep in mind that from one "why?" there may come more than one answer, consider following the different branches.

### Example of the usage of "5 whys"

The vehicle will not start. (the problem)

1. Why? - The battery is dead.
2. Why? - The alternator is not functioning.
3. Why? - The alternator belt has broken.
4. Why? - The alternator belt was well beyond its useful service life and not replaced.
5. Why? - The vehicle was not maintained according to the recommended service schedule. (Fifth why, a root cause)

## What went well

Start with the following:

- Identify the things that worked well or as expected.
- Any additional call-outs for what went particularly well.

## What can be improved

Start with the following:

- Using the root cause analysis, explain what can be improved to prevent this from happening again.
- Is there anything that could have been done to improve the detection or time to detection?
- Is there anything that could have been done to improve the response or time to response?
- Is there an existing issue that would have either prevented this incident or reduced the impact?
- Did we have any indication or beforehand knowledge that this incident might take place?
- Was the [MR acceptance checklist](https://docs.gitlab.com/ee/development/code_review.html#acceptance-checklist) marked as reviewed in the MR?
- Should the checklist be updated to help reduce chances of future recurrences?



## Corrective actions

- List issues that have been created as corrective actions from this incident.
- For each issue, include the following:
    - `<Bare issue link>` - Issue labeled as ~"corrective action".
    - An estimated date of completion of the corrective action.
    - The named individual who owns the delivery of the corrective action.

## Guidelines

- [Blameless RCA Guideline](https://about.gitlab.com/handbook/customer-success/professional-services-engineering/workflows/internal/root-cause-analysis.html)
- [5 whys](https://en.wikipedia.org/wiki/5_Whys)

/confidential
/label ~RCA
