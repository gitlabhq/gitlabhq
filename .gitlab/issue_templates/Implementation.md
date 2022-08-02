<!--
Implementation issues are used break-up a large piece of work into small, discrete tasks that can
move independently through the build workflow steps. They're typically used to populate a Feature
Epic. Once created, an implementation issue is usually refined in order to populate and review the
implementation plan and weight.
Example workflow: https://about.gitlab.com/handbook/engineering/development/threat-management/planning/diagram.html#plan
-->

## Why are we doing this work
<!--
A brief explanation of the why, not the what or how. Assume the reader doesn't know the
background and won't have time to dig-up information from comment threads.
-->


## Relevant links
<!--
Information that the developer might need to refer to when implementing the issue.

- [Design Issue](https://gitlab.com/gitlab-org/gitlab/-/issues/<id>)
  - [Design 1](https://gitlab.com/gitlab-org/gitlab/-/issues/<id>/designs/<image>.png)
  - [Design 2](https://gitlab.com/gitlab-org/gitlab/-/issues/<id>/designs/<image>.png)
- [Similar implementation](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/<id>)
-->


## Non-functional requirements
<!--
Add details for required items and delete others.
-->

- [ ] Documentation:
- [ ] Feature flag:
- [ ] Performance:
- [ ] Testing:


## Implementation plan
<!--
Steps and the parts of the code that will need to get updated.
The plan can also call-out responsibilities for other team members or teams and
can be split into smaller MRs to simplify the code review process.

e.g.:

- MR 1: Part 1
- [ ] ~frontend Step 1
- [ ] ~frontend Step 2
- MR 2: Part 2
- [ ] ~backend Step 1
- [ ] ~backend Step 2
- MR 3: Part 3
- [ ] ~frontend Step 1
- [ ] ~frontend Step 2

-->


<!--
Workflow and other relevant labels

# ~"group::" ~"Category:" ~"GitLab Ultimate"
Other settings you might want to include when creating the issue.

# /assign @
# /epic &
-->

## Verification steps
<!--
Add verification steps to help GitLab team members test the implementation. This is particularly useful
during the MR review and the ~"workflow::verification" step. You may not know exactly what the
verification steps should be during issue refinement, so you can always come back later to add
them.

1. Check-out the corresponding branch
1. ...
1. Profit!
-->

/label ~"workflow::refinement"
/milestone %Backlog
