<!--

This Issue template is meant to provide guidance for User Acceptance Tests.

1. Create the Issue and assign a title referring to the tested feature.
1. Fill the below details when relevant.

-->

# User Acceptance Testing

# Summary

Manual testing for the <issue-link> feature.

# Pre-requisite

_Add any steps to be performed before end to end testing can begin_

- [ ] Set a milestone for the test session issue to inform all the DRIs about the upcoming testing session.
- [ ] System leaders identify a DRI to participate in the testing session.
- [ ] Completion of Staging Rollout issue ([example](https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/6202)).
- [ ] Ensure all testers have the right access/permissions in all our Staging applications (Zuora, Salesforce, CDot, etc) for testing purposes.
- [ ] Ensure all system DRIs have reviewed the new test scenarios and approved the changes.
    - [ ] Sales Systems: `@handle`.
    - [ ] Sales Ops: `@handle`.
    - [ ] Enterprise Apps: `@handle`.
    - [ ] Data: `@handle`.
    - [ ] Billing: `@handle`.
    - [ ] Revenue: `@handle`.
    - [ ] Fulfillment: `@pm-handle` and `@em-handle`.
- [ ] Communicate an estimated time for the testing session to all the DRIs.
- [ ] **{-Enable feature flag:}** {feature-flag-name} on {environment-name}: [Feature flag rollout issue](<link to feature flag rollout issue>).
- [ ] Clear any caches.

# Useful Links

_Add any links that are helpful to carry out testing such as links to the flows involved, etc._

<!--

Example below:

1. [Zuora Staging](https://test.zuora.com/)
1. [Salesforce Staging](https://gitlab--test1.sandbox.my.salesforce.com)

-->

1. ...

# How to

1. Create a [**Task**](User%20Acceptance%20Test%20Task.md) for each scenario mentioned in the list.
    - The Task holds each relevant Test Case for the scenario in its own section.
    - Each section holds that case's testing outcome and artifacts. (E.g. screenshots, screen recordings, or text notes.)
1. Create a [**Test Case**](https://gitlab.com/gitlab-org/customers-gitlab-com/-/quality/test_cases) for each variation of the scenario, if one does not already exist. (E.g. testing across product tiers or user roles.)
    - The Test Case outlines the testing scenario, the test steps involved, and the expected result.
    - **Make sure to set the Test Case to be confidential if applicable when it's created**, as it might not be confidential by default.
1. Before testing a Task, assign yourself to it to avoid multiple people testing the same scenario.
1. **\[Optional\]** assign a tested Task to a PM for review.
    - Use the `Task` comments section to discuss any unexpected behaviour and create follow-up Issue(s).
1. **\[Optional\]** A PM should sign-off the test scenario if everything looks good. The, close the Task, and mark it as complete in this issue.
1. Add [Bug(s)](#identified-bugs) and/or [Question(s)](#open-questions) to the corresponding sections below.

# Test Cases

<table>
    <tr>
        <th>Scenario #</th>
        <th>Task</th>
        <th>Test Case</th>
        <th>Scenario</th>
        <th>Expected Outcome</th>
        <th>Product Sign-off</th>
        <th>UX Sign-off</th>
    </tr>
    <tr>
        <td>
        </td>
        <td>
        </td>
        <td>
        </td>
        <td>
        </td>
        <td>
        </td>
        <td>
        </td>
        <td>
        </td>
    </tr>
</table>

# Identified Bugs

| Bugs | Testing type (Automated/ Manual) | Resolution | MR  | DRI |
|------|----------------------------------|------------|-----|-----|
|  |  |  |  |  |

| Question | Related Test Case | Answer | DRI |
| -------- | ----------------- | -------| --- |
| _Summary of question here (can have link to discussion from comments)_ | _Test case link_ | _Final answer / resolution_ | _Person responsible for answering question_ |

## Sign-offs

_Once all scenarios have passed validation, stakeholders will provide final sign-off below_

- [ ] Sales Systems: `@handle`
- [ ] Sales Ops: `@handle`
- [ ] Enterprise Apps: `@handle`
- [ ] Data: `@handle`
- [ ] Billing: `@handle`
- [ ] Revenue: `@handle`
- [ ] Fulfillment: `@pm-handle` and `@em-handle`

/label ~"devops::fulfillment" ~"section::fulfillment"
