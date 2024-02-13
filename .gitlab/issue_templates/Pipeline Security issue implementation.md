<!--
## Implementation Issue To-Do list 
(_NOTE: This section can be removed when the issue is ready for creation_)
- [ ] Ensure that the issue title is concise yet descriptive.
- [ ] Add `Frontend :` or `Backend :` to the title per group [naming conventions](https://about.gitlab.com/handbook/engineering/development/ops/verify/pipeline-security/#splitting-issues)
- [ ] Ensure the issue containing the feature or change proposal and related discussions is linked as related to this implementation issue.
- [ ] Aside from default labeling, please make sure to include relevant labels for `~type::`, `~workflow::`, and `~frontend` or `~backend`.
- [ ] Issues with user-facing changes should include the `~UX` label, and `~documentation` if docs changes will be required.

*This template is meant to be a reference tool. Not all sections are applicable to each feature, bug, or maintenance item. Use your best judgment when completion the sections below.*
-->

## Summary
<!-- Briefly describe the issue. -->


### Why this matters and how we measure
<!-- What is the value to the customer or our business? Does this align with our OKRs? If we need to create or update existing instrumentation, please note here. -->

### User Stories
<!--
A user story is a requirement for any functionality or feature and follows this format:

- _As a `<user role/customer>`, I want to `<JTBD>` so that I can `<achieve a benefit or result>`._

Please try to include one user story for the main [persona](https://handbook.gitlab.com/handbook/product/personas/#list-of-user-personas) who needs this feature.
-->


## Proposal
<!-- Try to keep the proposal limited in scope. Plan for iterations, create follow up issues as required and add them as related. -->

## Performance Considerations
<!-- Performance concerns to be aware of and monitor when implementing the issue.-->

## Out of Scope
<!-- Include this section for specific use cases that are out of scope / out of bounds for this specific issue. -->

## Acceptance Criteria 
<!-- This needs to be true or demonstrable to consider this specific issue complete. Keep this dependent on other issues when possible -->

## Additional details
<!--
_NOTE: If the issue has addressed all of these questions, this separate section can be removed._
-->

Some relevant technical details, if applicable, such as:

- Does this need a ~"feature flag"?
- Does there need to be an associated ~"instrumentation" issue created related to this work?
- Is there an example response showing the data structure that should be returned (new endpoints only)?
- What permissions should be used?
- Which tier(s) is this for?
  - [ ] ~"GitLab Ultimate"
  - [ ] ~"GitLab Premium"
  - [ ] ~"GitLab Free"
- Additional comments:

## Implementation Table

<!--
_NOTE: Use this to indicate all dependent issues related to this one which are required for launch._
-->


| Group | Issue Link |
| ------ | ------ |
| ~backend | :point_left: You are here |
| ~frontend | [Issue Title](url) |
| ~documentation | [Issue Title](url) |
| Instrumentation | [Issue Title](url) |

<!--
## Documentation 

_NOTE: This section is optional, but can be used for easy access to any relevant documentation URLs._
-->

## Links/References




/label ~"group::pipeline security" 
/milestone %Backlog

<!-- select the correct category (and feature label if applicable) below: 
/label ~"category:Build Artifacts"
/label ~"category:Secrets Management"
/label ~"ci variables"
/label ~"ci job token"
-->

<!-- select the appropriate licence below (Use the highest tier applicable): 
/label ~"GitLab Ultimate"
/label ~"GitLab Premium"
/label ~"GitLab Free"
-->
