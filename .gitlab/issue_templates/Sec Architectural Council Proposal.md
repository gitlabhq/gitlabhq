# Sec Architectural Council Proposal

- [ ] I have read the [Sec Architectural Council](https://about.gitlab.com/handbook/engineering/development/sec/#architectural-council-slack-s_sec-architectural-council) handbook entry.
- [ ] I have read the [Engineering Architecture](https://about.gitlab.com/handbook/engineering/architecture) page.
- [ ] A DRI has already been assigned in the [Reviewed by](#reviewed-by) section of this issue based the above guidance.

## Table of Contents

- [Proposal](#proposal)
- [Scope](#scope)
- [Out of scope](#out-of-scope)
- [In scope](#in-scope)
- [Reviewed by](#reviewed-by)
- [SLO](#slo)

## Proposal

<!--
Review the proposal process here: https://about.gitlab.com/handbook/engineering/development/sec/#architectural-council-slack-s_sec-architectural-council 

TL;DR you want to ask and discuss the following to arrive at a proposed solution:

1. What is the issue at hand and what is the preferred action?
2. What are the potential solutions and their associated pros/cons?
3. What approach was decided and why?
-->

### What is the issue at hand?

### What is the preferred action?

### What are the potential solutions?

<!------------------------------------------------------------------------------
| Define a few headings inside of the proposal to go over your solution.       |
| If you have more than one solution creating comment threads and summarizing  |
| conversations in the issue description description could be easier to follow |
| for folks.                                                                   |
------------------------------------------------------------------------------->
<!-- StartSolution -->

#### Solution A

<!--
-->

##### Solution A Pros

<!--
-->

##### Solution A Cons

<!--
-->

<!-- EndSolution -->

### What approach was decided and why?

<!--
-->

### Scope

Use the checkboxes below to determine whether your is in scope for the Sec Architectural Council.

#### Out of scope

If any of the following apply then this issue is out of scope for the Sec Architectural Council.
  - [ ] Does not involve architectural decisions
  - [ ] Is after-the-fact

#### In scope

If any of the following apply then a proposal *should* be made:
  - [ ] Has a broad impact within Sec

If any of the following apply then you may opt-in to submitting a proposal to the Sec Architectural Council:
  - [ ] Is not already covered by architecture guidelines/handbook
  - [ ] Is a new unit of work
  - [ ] Is strictly Secure
  - [ ] Involves architectural decisions

Once opted-in in some cases you may find that you:
  - [ ] Could not come to an agreement (escalation)

In which case you may opt-out closing this proposal if there is no broad impact within of Sec. If doing so please close the issue with a comment summarizing of your decision given you will follow standard architecture guidelines.

## Reviewed by

Assigned DRI: `@dri`

I am asking The following Sec Architectural Council [Team Representatives][] to review the proposal outline in this issue:
  - [ ] @alan representing the [Security Policies](https://about.gitlab.com/handbook/engineering/development/sec/govern/security-policies/) team
  - [ ] @cam_swords representing the [Dynamic Analysis](https://about.gitlab.com/handbook/engineering/development/sec/secure/dynamic-analysis/) team
  - [ ] @fcatteau or @adamcohen representing the [Composition Analysis](https://about.gitlab.com/handbook/engineering/development/sec/secure/composition-analysis/) team
  - [ ] @idawson representing the [Vulnerability Research](secure/vulnerability-research/) team
  - [ ] @julianthome representing the [Vulnerability Research](secure/vulnerability-research/) team
  - [ ] @minac representing the [Threat Insights Backend](https://about.gitlab.com/handbook/engineering/development/sec/govern/threat-insights/) team
  - [ ] @svedova representing the [Threat Insights Frontend](https://about.gitlab.com/handbook/engineering/development/sec/govern/threat-insights/) team
  - [ ] @theoretick representing the [Static Analysis](https://about.gitlab.com/handbook/engineering/development/sec/secure/static-analysis/) team
- [ ] @sashi_kumar representing the [Security Policies](https://about.gitlab.com/handbook/engineering/development/sec/govern/security-policies) team
- [ ] @huzaifaiftikhar1 representing the [Compliance](https://about.gitlab.com/handbook/engineering/development/sec/govern/compliance) team
<!-- Please update the following quick action in case of changes to the representatives list above. -->
/assign @alan @cam_swords @fcatteau @idawson @julianthome @minac @svedova @sashi_kumar @huzaifaiftikhar1

## SLO

While the Sec Architectural Council has a Service Level Objective of 2-business days our Team Representatives are spread out globally so it may take longer than 48 hours in some cases for all parties to review your proposal.

Please update this issue's Due Date accordingly when you:
  * Create a proposal after Wednesday 17:00 Australian Eastern Time/Japan Time.
  * Create a proposal over the weekend (e.g. before Monday 09:00 Mountain Time/Pacific Time).

---

[Proposal](#proposal)|[Scope](#scope)|[Out of scope](#out-of-scope)|[In scope](#in-scope)|[Reviewed by](#reviewed-by)|[SLO](#slo)

[Team Representatives]: https://about.gitlab.com/handbook/engineering/development/sec/#team-representatives

<!-- Due Date for meeting our 2 day SLO. -->
/due in 2 days
/label ~"group::threat insights" ~"devops::govern" ~section::sec
