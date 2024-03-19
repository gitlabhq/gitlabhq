---
status: accepted
creation-date: "2022-09-28"
authors: [ "@ntepluhina" ]
coach: "@ayufan"
approvers: [ "@gweaver" ]
owning-stage: "~devops::plan"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# Work Items

This document is a work-in-progress. Some aspects are not documented, though we expect to add them in the future.

## Summary

Work Items is a new architecture created to support the various types of built and planned entities throughout the product, such as issues, requirements, and incidents. It will make these types easy to extend and customize while sharing the same core functionality.

## Terminology

We use the following terms to describe components and properties of the Work items architecture.

### Work Item

Base type for issue, requirement, test case, incident and task (this list is planned to extend in the future). Different work items have the same set of base properties but their [widgets](#work-item-widgets) list is different.

### Work Item types

A set of predefined types for different categories of work items. Currently, the available types are:

- [Incident](/ee/operations/incident_management/incidents.md)
- [Test case](/ee/ci/test_cases/index.md)
- [Requirement](/ee/user/project/requirements/index.md)
- [Task](/ee/user/tasks.md)
- [OKRs](/ee/user/okrs.md)

Work is underway to convert existing objects to Work Item Types or add new ones:

- [Issue](https://gitlab.com/groups/gitlab-org/-/epics/9584)
- [Epic](https://gitlab.com/groups/gitlab-org/-/epics/9290)
- [Ticket](https://gitlab.com/groups/gitlab-org/-/epics/10419)

#### Work Item properties

Every Work Item type has the following common properties:

**NOTE:**
You can also refer to fields of [Work Item](../../../api/graphql/reference/index.md#workitem) to learn more.

- `id` - a unique Work Item global identifier;
- `iid` - internal ID of the Work Item, relative to the parent workspace (currently workspace can only be a project)
- Work Item type;
- properties related to Work Item modification time: `createdAt`, `updatedAt`, `closedAt`;
- title string;
- Work Item confidentiality state;
- Work Item state (can be open or closed);
- lock version, incremented each time the work item is updated;
- permissions for the current user on the resource
- a list of [Work Item widgets](#work-item-widgets)

### Work Item widgets

All Work Item types share the same pool of predefined widgets and are customized by which widgets are active on a specific type. The list of widgets for any certain Work Item type is currently predefined and is not customizable. However, in the future we plan to allow users to create new Work Item types and define a set of widgets for them.

### Widget types (updating)

| Widget  | Description | Feature flag | Write permission | GraphQL Subscription Support |
|---|---|---|---|---|
| [WorkItemWidgetAssignees](../../../api/graphql/reference/index.md#workitemwidgetassignees) | List of work item assignees | |`Guest`|Yes|
| [WorkItemWidgetAwardEmoji](../../../api/graphql/reference/index.md#workitemwidgetawardemoji) | Emoji reactions added to work item, including support for upvote/downvote counts | |Anyone who can view|No|
| [WorkItemWidgetCurrentUserTodos](../../../api/graphql/reference/index.md#workitemwidgetcurrentusertodos) | User todo state of work item | |Anyone who can view|No|
| [WorkItemWidgetDescription](../../../api/graphql/reference/index.md#workitemwidgetdescription) | Description of work item, including support for edited state, timestamp, and author | |`Reporter`|No|
| [WorkItemWidgetHealthStatus](../../../api/graphql/reference/index.md#workitemwidgethealthstatus) | Health status assignment support for work item | |`Reporter`|No|
| [WorkItemWidgetHierarchy](../../../api/graphql/reference/index.md#workitemwidgethierarchy) | Hierarchy of work items, including support for boolean representing presence of children. **Note:** Hierarchy is currently available only for OKRs. | `okrs_mvc` |`Guest`|No|
| [WorkItemWidgetIteration](../../../api/graphql/reference/index.md#workitemwidgetiteration) | Iteration assignment support for work item | |`Reporter`|No|
| [WorkItemWidgetLabels](../../../api/graphql/reference/index.md#workitemwidgetlabels) | List of labels added to work items, including support for checking whether scoped labels are supported | |`Reporter`|Yes|
| [WorkItemWidgetLinkedItems](../../../api/graphql/reference/index.md#workitemwidgetlinkeditems) | List of work items added as related to a given work item, with possible relationship types being `relates_to`, `blocks`, and `blocked_by`. Includes support for individual counts of blocked status, blocked by, blocking, and related to. | `linked_work_items`|`Guest`|No|
| [WorkItemWidgetMilestone](../../../api/graphql/reference/index.md#workitemwidgetmilestone) | Milestone assignment support for work item | |`Reporter`|No|
| [WorkItemWidgetNotes](../../../api/graphql/reference/index.md#workitemwidgetnotes) | List of discussions within a work item | |`Guest`|Yes|
| [WorkItemWidgetNotifications](../../../api/graphql/reference/index.md#workitemwidgetnotifications) | Notifications subscription status of a work item for current user | |Anyone who can view|No|
| [WorkItemWidgetProgress](../../../api/graphql/reference/index.md#workitemwidgetprogress) | Progress value of a work item. **Note:** Progress is currently available only for OKRs. | `okrs_mvc` |`Reporter`|No|
| [WorkItemWidgetStartAndDueDate](../../../api/graphql/reference/index.md#workitemwidgetstartandduedate) | Set start and due dates for a work item | |`Reporter`|No|
| [WorkItemWidgetStatus](../../../api/graphql/reference/index.md#workitemwidgetstatus) | Status of a work item when type is Requirement, with possible status types being `unverified`, `satisfied`, or `failed` | | |No|
| [WorkItemWidgetTestReports](../../../api/graphql/reference/index.md#workitemwidgettestreports) | Test reports associated with a work item | | | |
| [WorkItemWidgetWeight](../../../api/graphql/reference/index.md#workitemwidgetweight) | Set weight of a work item | |`Reporter`|No|
| WorkItemWidgetLock | Lock/Unlock a work item | |`Reporter`|No|
| [WorkItemWidgetColor](../../../api/graphql/reference/index.md#workitemwidgetcolor) | Set color of a work item. **Note:** Color is currently available only for epics. | |`Reporter`|No|

#### Widget availability (updating)

| Widget | Epic | Issue | Task | Objective | Key Result |
|---|---|---|---|---|---|
| [WorkItemWidgetAssignees](../../../api/graphql/reference/index.md#workitemwidgetassignees) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetAwardEmoji](../../../api/graphql/reference/index.md#workitemwidgetawardemoji) | ✅ | ✔️ | ✅ | ✅ | ✅ |
| [WorkItemWidgetCurrentUserTodos](../../../api/graphql/reference/index.md#workitemwidgetcurrentusertodos) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetDescription](../../../api/graphql/reference/index.md#workitemwidgetdescription) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetHealthStatus](../../../api/graphql/reference/index.md#workitemwidgethealthstatus) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetHierarchy](../../../api/graphql/reference/index.md#workitemwidgethierarchy) | ✔ | ✔️ | ❌ | ✅ | ❌ |
| [WorkItemWidgetIteration](../../../api/graphql/reference/index.md#workitemwidgetiteration) | ❌ | ✅ | ✅ | ❌ | ❌ |
| [WorkItemWidgetLabels](../../../api/graphql/reference/index.md#workitemwidgetlabels) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetLinkedItems](../../../api/graphql/reference/index.md#workitemwidgetlinkeditems) | ✔️ | ✔️ | ✔️ | ✅ | ✅ |
| [WorkItemWidgetMilestone](../../../api/graphql/reference/index.md#workitemwidgetmilestone) | 🔍 | ✅ | ✅ | ✅ | ❌ |
| [WorkItemWidgetNotes](../../../api/graphql/reference/index.md#workitemwidgetnotes) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetNotifications](../../../api/graphql/reference/index.md#workitemwidgetnotifications) | ✅ | ✅ | ✅ | ✅ | ✅ |
| [WorkItemWidgetProgress](../../../api/graphql/reference/index.md#workitemwidgetprogress) | ❌ | ❌ | ❌ | ✅ | ✅ |
| [WorkItemWidgetStartAndDueDate](../../../api/graphql/reference/index.md#workitemwidgetstartandduedate) | 🔍 | ✅ | ✅ | ❌ | ✅ |
| [WorkItemWidgetStatus](../../../api/graphql/reference/index.md#workitemwidgetstatus) | ❓ | ❓ | ❓ | ❓ | ❓ |
| [WorkItemWidgetTestReports](../../../api/graphql/reference/index.md#workitemwidgettestreports) | ❌ | ❌ | ❌ | ❌ | ❌ |
| [WorkItemWidgetWeight](../../../api/graphql/reference/index.md#workitemwidgetweight) | 🔍 | ✅ | ✅ | ❌ | ❌ |
| [WorkItemWidgetColor](../../../api/graphql/reference/index.md#workitemwidgettestreports) | ✅ | ❌ | ❌ | ❌ | ❌ |

##### Legend

- ✅ - Widget available
- ✔️ - Widget planned to be available
- ❌ - Widget not available
- ❓ - Widget pending for consideration
- 🔍 - Alternative widget planned

### Work item relationships

Work items can be related to other work items in a number of different ways:

- Parent: A direct ancestor to the current work item, whose completion relies on completing this work item.
- Child: A direct descendant of the current work item, which contributes to this work item's completion.
- Blocked by: A work item preventing the completion of the current work item.
- Blocks: A work item whose completion is blocked by the current work item.
- Related: A work item that is relevant to the subject of the current work item, but does not directly contribute to or block the completion of this work item.

#### Hierarchy

Parent-child relationships form the basis of **hierarchy** in work items. Each work item type has a defined set of types that can be parents or children of that type.

As types expand, and parent items have their own parent items, the hierarchy capability can grow exponentially.

[Pajamas](https://design.gitlab.com/objects/work-item#hierarchy) documents how to display hierarchies depending on context.

### Work Item view

The new frontend view that renders Work Items of any type using global Work Item `id` as an identifier.

### Task

Task is a special Work Item type. Tasks can be added to issues as child items and can be displayed in the modal on the issue view.

### Feature flags

Since this is a large project with numerous moving parts, feature flags are being used to track promotions of available widgets. The table below shows the different feature flags that are being used, and the audience that they are available to.

| feature flag name | audience |
|---|---|
| `work_items` | defaulted to on |
| `work_items_beta` | `gitlab-org`, `gitlab-com` |
| `work_items_mvc_2` | `gitlab-org/plan-stage` |

## Motivation

Work Items main goal is to enhance the planning toolset to become the most popular collaboration tool for knowledge workers in any industry.

- Puts all like-items (issues, incidents, epics, test cases etc.) on a standard platform to simplify maintenance and increase consistency in experience
- Enables first-class support of common planning concepts to lower complexity and allow users to plan without learning GitLab-specific nuances.

## Goals

### Scalability

Currently, different entities like issues, epics, merge requests etc share many similar features but these features are implemented separately for every entity type. This makes implementing new features or refactoring existing ones problematic: for example, if we plan to add new feature to issues and incidents, we would need to implement it separately on issue and incident types. With work items, any new feature is implemented via widgets for all existing types which makes the architecture more scalable.

### Flexibility

With existing implementation, we have a rigid structure for issuables, merge requests, epics etc. This structure is defined on both backend and frontend, so any change requires a coordinated effort. Also, it would be very hard to make this structure customizable for the user without introducing a set of flags to enable/disable any existing feature. Work Item architecture allows frontend to display Work Item widgets in a flexible way: whatever is present in Work Item widgets, will be rendered on the page. This allows us to make changes fast and makes the structure way more flexible. For example, if we want to stop displaying labels on the Incident page, we remove labels widget from Incident Work Item type on the backend. Also, in the future this will allow users to define the set of widgets they want to see on custom Work Item types.

### A consistent experience

As much as we try to have consistent behavior for similar features on different entities, we still have differences in the implementation. For example, updating labels on merge request via GraphQL API can be done with dedicated `setMergeRequestLabels` mutation, while for the issue we call more coarse-grained `updateIssue`. This provides inconsistent experience for both frontend and external API users. As a result, epics, issues, requirements, and others all have similar but just subtle enough differences in common interactions that the user needs to hold a complicated mental model of how they each behave.

Work Item architecture is designed with making all the features for all the types consistent, implemented as Work Item widgets.

## High-level architecture problems to solve

- how can we bypass groups and projects consolidation to migrate epics to Work Item type;
- dealing with parent-child relationships for certain Work Item types: epic > issue > task, and to the same Work Item types: issue > issue.
- [implementing custom Work Item types and custom widgets](https://gitlab.com/gitlab-org/gitlab/-/issues/335110)

### Links

- [Work items in Pajamas Design System](https://design.gitlab.com/objects/work-item)
- [Work items initiative epic](https://gitlab.com/groups/gitlab-org/-/epics/6033)
- [Tasks roadmap](https://gitlab.com/groups/gitlab-org/-/epics/7103?_gl=1*zqatx*_ga*NzUyOTc3NTc1LjE2NjEzNDcwMDQ.*_ga_ENFH3X7M5Y*MTY2MjU0MDQ0MC43LjEuMTY2MjU0MDc2MC4wLjAuMA..)
- [Work Item "Vision" Prototype](https://gitlab.com/gitlab-org/gitlab/-/issues/368607)
- [Work Item Discussions](https://gitlab.com/groups/gitlab-org/-/epics/7060)
