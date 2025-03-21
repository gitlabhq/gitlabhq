---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and track relationships between work items in GitLab. Manage dependencies, link strategic goals to execution, and coordinate cross-functional initiatives."
title: Linked items
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Linked items create bi-directional relationships between work items, helping you visualize and manage dependencies across your entire workflow.

With linked items, you can connect various work items including issues, epics, tasks, and objectives to show relationships between them.

These connections help everyone understand how individual pieces of work relate to each other and to larger strategic initiatives.

## Ways to use linked items

You can use linked items to solve several planning and coordination challenges.

The following examples show how linked items help teams work together more effectively.

### Track dependencies

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

Clearly identify work that blocks or is blocked by other items.

When you link items with a blocking relationship:

- Teams can immediately see what other work they depend on.
- Status updates flow automatically between linked items.
- Warnings appear when closing items that have open blockers.
- Teams can avoid delays by addressing dependencies proactively.

This visibility helps coordinate work across teams and reduces bottlenecks.

### Connect strategic goals with implementation details

Use linked items to connect high-level planning with day-to-day execution.

When you link strategic objectives to tactical tasks:

- Teams understand how their work contributes to larger goals.
- Stakeholders can trace progress from strategy to implementation.
- Everyone gains visibility into how individual efforts support the broader vision.
- Changes in strategy can be quickly traced to affected implementation work.

This connection between levels creates alignment and purpose across the organization.

### Organize cross-functional initiatives

Link related work across different teams and projects to coordinate complex initiatives.

When you use linked items for cross-functional work:

- Each team can work in their own area while maintaining connections to related work.
- Dependencies between specialized teams become visible.
- Status updates flow automatically between related items.
- Teams can coordinate their efforts without constant meetings.

This coordination helps break down silos and ensures all aspects of the initiative stay in sync.

## Types of linked items

GitLab supports linking various types of work items:

- [Issues](../project/issues/related_issues.md) help you track tasks, bugs, and features and can be
  linked to show dependencies between discrete pieces of work.
- [Epics](../group/epics/linked_epics.md) let you manage cross-functional initiatives, show
  dependencies, and connect strategic planning to execution across multiple teams or projects.
  Available in the Ultimate tier.
- [Tasks](../tasks.md#linked-items-in-tasks) provide lightweight tracking for smaller units of work
  and can be linked to other items to show relationships or dependencies in a project.
- [Objectives and key results](../okrs.md#linked-items-in-okrs) help connect strategic goals with
  execution details, ensuring that day-to-day work remains aligned with higher-level organizational
  priorities.
- [Incidents](../../operations/incident_management/incidents.md) represent service disruptions or
  outages that need urgent restoration and can be linked to related work items for better tracking
  of operational issues and their impact on planned work.
- [Test cases](../../ci/test_cases/_index.md) integrate test planning directly into your GitLab
  workflows, letting teams document testing scenarios and track requirements in the same platform
  where they manage code. Available in the Ultimate tier.

## Relationship types

When linking items, you can specify the type of relationship:

- **Relates to**: Indicates a general relationship between items.
- **Blocks**: Shows that an item prevents progress on another item.
- **Is blocked by**: Shows that an item cannot proceed until another item is resolved.

## Common tasks with linked items

Learn how to create and manage relationships between your work items with these common procedures.

### Add a linked item

Prerequisites:

- You must have at least the Guest role for the projects or groups of both items.

The general process for adding linked items is similar across all work item types:

1. Go to the work item you want to modify.
1. At the bottom of the description, find the **Linked items** section of the work item.
1. Select **Add**.
1. Select the relationship type: **relates to**, **blocks**, or **is blocked by**.
1. Enter the reference for the item to link. You can:
   - Enter `#` or `&` (depending on item type) followed by the item's number.
   - Enter text to search for the item by title.
   - Paste the full URL of the item.
1. Select **Add** to confirm.

Alternatively, you can add linked items using [quick actions](../project/quick_actions.md):

- `/relate`
- `/blocks`
- `/blocked_by`

For detailed instructions specific to each work item type, see the relevant documentation:

- [Linked issues](../project/issues/related_issues.md#add-a-linked-issue)
- [Linked epics](../group/epics/linked_epics.md#add-a-linked-epic)
- [Linked tasks](../tasks.md#linked-items-in-tasks)
- [Linked OKRs](../okrs.md#linked-items-in-okrs)

### Remove a linked item

Prerequisites:

- You must have at least the Guest role for the projects or groups of both items.

To remove a linked item:

1. Go to the work item you want to modify.
1. At the bottom of the description, find the **Linked items** section of the work item.
1. For each linked item, select **Remove** ({{< icon name="close" >}}).

The bi-directional relationship is removed from both items.

Alternatively, you can remove a linked item using the `/unlink` [quick action](../project/quick_actions.md).

## Related topics

- [Work items](../work_items/_index.md)
- [Issues](../project/issues/_index.md)
- [Epics](../group/epics/_index.md)
- [Tasks](../tasks.md)
- [Objectives and key results](../okrs.md)
