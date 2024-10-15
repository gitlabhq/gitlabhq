---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Linked epics

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Linked epics are a bi-directional relationship between any two epics and appear in a block below
the epic description. You can link epics in different groups.

The relationship only shows up in the UI if the user can see both epics.
When you try to close an epic that has open blockers, a warning is displayed.

To manage linked epics through our API, see [Linked epics API](../../../api/linked_epics.md).

## Add a linked epic

> - Minimum required role for the group [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/381308) from Reporter to Guest in GitLab 15.8.

Prerequisites:

- You must have at least the Guest role for both groups.
- For GitLab SaaS: the epic that you're editing must be in a group on GitLab Ultimate.
  The epics you're linking can be in a group on a lower tier.

To link one epic to another:

1. In the **Linked epics** section of an epic,
   select the add linked epic button (**{plus}**).
1. Select the relationship between the two epics. Either:

   - **relates to**
   - **[blocks](#blocking-epics)**
   - **[is blocked by](#blocking-epics)**

1. To enter the linked epic, either:

   - Enter `&`, followed by the epic's number. For example, `&123`.
   - Enter `&`, followed by a word from the epic's title. For example, `&Deliver`.
   - Paste in the epic's full URL.

   ![Adding a related epic](img/related_epics_add_v14_9.png)

   Epics of the same group can be specified just by the reference number.
   Epics from a different group require additional information like the
   group name. For example:

   - The same group: `&44`
   - Different group: `group&44`

   Valid references are added to a temporary list that you can review.

1. Select **Add**.

The linked epics are then displayed on the epic grouped by relationship.

![Related epic block](img/related_epic_block_v14_9.png)

## Remove a linked epic

> - Minimum required role for the group [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/381308) from Reporter to Guest in GitLab 15.8.

Prerequisites:

- You must have at least the Guest role for the epic's group.

To remove a linked epic:

- In the **Linked epics** section of an epic, next to each epic, select **Remove** (**{close}**).

The relationship is removed from both epics.

![Removing a related epic](img/related_epics_remove_v14_9.png)

## Blocking epics

When you [add a linked epic](#add-a-linked-epic), you can show that it **blocks** or
**is blocked by** another epic.

If you try to close a blocked epic using the "Close epic" button, a confirmation message appears.

## When using the new look for epics

> - Linking epics to issues, tasks, and OKRs [introduced](https://gitlab.com/groups/gitlab-org/-/epics/9290) in GitLab 17.5. Your administrator must have [enabled the new look for epics](epic_work_items.md).

<!-- When epics as work items are GA, integrate this and below sections with the ones above. -->

If your administrator [enabled the new look for epics](epic_work_items.md), you can also link epics
and the following items:

- Issues
- Tasks
- Objectives
- Key results

Linked items appear in the **Linked items** section, under the **Child items** section on the epic.
You can link epics to work items in different groups.

The relationship only shows up in the UI if the user can see both items.
When you try to close an epic linked to an open blocker, a warning is displayed.

To manage linked epics through our API, see the
[Work Items API](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items/).

### Add a linked item

Prerequisites:

- Your administrator must have [enabled the new look for epics](epic_work_items.md).
- You must have at least the Guest role for both groups or group and project.
- For GitLab SaaS: the epic that you're editing must be in a group on GitLab Ultimate.
  The item you're linking can be in a group on a lower tier.

To link an epic to another item:

1. In the **Linked items** section of an epic, select **Add**.
1. Select the relationship between the two items. Either:

   - **relates to**
   - **blocks**
   - **is blocked by**

1. To enter the linked item, either:

   - Enter `#`, followed by the item's number. For example, `#123`.
   - Enter `#`, followed by a word from the item's title. For example, `#Deliver`.
   - Paste in the item's full URL.

   Items of the same group can be specified just by the reference number.
   Items from a different group require additional information like the
   group name. For example:

   - The same group: `#44`
   - Different group: `group#44`

   Valid references are added to a temporary list that you can review.

1. Select **Add**.

The linked items are then displayed on the epic grouped by relationship.

### Remove a linked item

Prerequisites:

- Your administrator must have [enabled the new look for epics](epic_work_items.md).
- You must have at least the Guest role for the epic's group.

To remove a linked item:

- In the **Linked items** section of an epic, next to each item, select **Remove** (**{close}**).

The relationship is removed from both items.
