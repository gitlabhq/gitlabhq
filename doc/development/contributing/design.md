---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Implement design & UI elements

For guidance on UX implementation at GitLab, please refer to our [Design System](https://design.gitlab.com/).

The UX team uses labels to manage their workflow.

The ~"UX" label on an issue is a signal to the UX team that it will need UX attention.
To better understand the priority by which UX tackles issues, see the [UX section](https://about.gitlab.com/handbook/engineering/ux/) of the handbook.

Once an issue has been worked on and is ready for development, a UXer removes the ~"UX" label and applies the ~"UX ready" label to that issue.

There is a special type label called ~"product discovery" intended for UX,
PM, FE, and BE. It represents a discovery issue to discuss the problem and
potential solutions. The final output for this issue could be a doc of
requirements, a design artifact, or even a prototype. The solution will be
developed in a subsequent milestone.

~"product discovery" issues are like any other issue and should contain a milestone label, ~"Deliverable" or ~"Stretch", when scheduled in the current milestone.

The initial issue should be about the problem we are solving. If a separate [product discovery issue](https://about.gitlab.com/handbook/engineering/ux/ux-department-workflow/#how-we-use-labels)
is needed for additional research and design work, it will be created by a PM or UX person.
Assign the ~UX, ~"product discovery" and ~"Deliverable" labels, add a milestone and
use a title that makes it clear that the scheduled issue is product discovery
(for example, `Product discovery for XYZ`).

In order to complete a product discovery issue in a release, you must complete the following:

1. UXer removes the ~UX label, adds the ~"UX ready" label.
1. Modify the issue description in the product discovery issue to contain the final design. If it makes sense, the original information indicating the need for the design can be moved to a lower "Original Information" section.
1. Copy the design to the description of the delivery issue for which the product discovery issue was created. Do not simply refer to the product discovery issue as a separate source of truth.
1. In some cases, a product discovery issue also identifies future enhancements that will not go into the issue that originated the product discovery issue. For these items, create new issues containing the designs to ensure they are not lost. Put the issues in the backlog if they are agreed upon as good ideas. Otherwise leave them for triage.

---

[Return to Contributing documentation](index.md)
