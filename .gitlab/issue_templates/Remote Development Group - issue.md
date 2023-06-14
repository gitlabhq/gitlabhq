MR: Pending
<!--
The first line of the MR must be one of the following:

1. `MR: Pending`
2. `MR: <MR link with trailing +>`,
   and the first description line of the MR should be `Issue: <Issue link with trailing +>` 
3. `MR: No MR`

For more context, see:
https://about.gitlab.com/handbook/engineering/development/dev/create/ide/index.html#1-to-1-relationship-of-issues-to-mrs
-->

<!--
The following sections should be filled out as part of the refinement process before the issue is prioritized.

For more context, see:
https://about.gitlab.com/handbook/engineering/development/dev/create/ide/#2-pre-iteration-planning-meeting
-->

## Description

TODO: Fill out (required)
`As a [user or stakeholder], I want [goal or objective] so that [reason or benefit].`

## Acceptance Criteria

TODO: Fill out (required)
- [ ] [Describe what must be achieved to complete this issue.]
- [ ] [Describe another requirement needed to complete this issue.]
- [ ] [Add additional acceptance criteria as needed.]

## Technical Requirements

TODO: Fill out or delete
[If applicable, please list out any technical requirements for this feature/enhancement.]

## Design Requirements

TODO: Fill out or delete
[If applicable, please provide a link to the design specifications for this feature/enhancement.]

## Impact Assessment

TODO: Fill out or delete
[Please describe the impact this feature/enhancement will have on the user experience and/or the product as a whole.]

## User Story

TODO: Fill out or delete
[Provide a user story to illustrate the use case for this feature/enhancement. Include examples to help communicate the intended functionality.]


/label ~"Category:Remote Development"
/label  ~"section::dev"
/label  ~"devops::create"
/label  ~"group::ide"

<!-- Replace with other type, e.g. bug or maintenance, if appropriate -->
/label ~"type::feature"
<!-- Replace with other subtype if appropriate -->
/label ~"feature::addition"

<!-- By default, all issues start in the unprioritized status. See https://about.gitlab.com/handbook/engineering/development/dev/create/ide/#-remote-development-planning-process -->
/label  ~"rd-workflow::unprioritized"

<!-- For simplicity and to avoid triage bot warnings about missing workflow labels, we will default to issues starting at the refinement phase --> 
/label ~"workflow::refinement"
