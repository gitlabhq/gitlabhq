---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Linked epics

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353473) in GitLab 14.9 [with a flag](../../../administration/feature_flags.md) named `related_epics_widget`. Enabled by default.
> - [Feature flag `related_epics_widget`](https://gitlab.com/gitlab-org/gitlab/-/issues/357089) removed in GitLab 15.0.

Linked epics are a bi-directional relationship between any two epics and appear in a block below
the epic description. You can link epics in different groups.

The relationship only shows up in the UI if the user can see both epics. When you try to close an
epic that has open blockers, a warning is displayed.

NOTE:
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

To remove a linked epic, in the **Linked epics** section of an epic,
select **Remove** (**{close}**) next to
each epic.

The relationship is removed from both epics.

![Removing a related epic](img/related_epics_remove_v14_9.png)

## Blocking epics

When you [add a linked epic](#add-a-linked-epic), you can show that it **blocks** or
**is blocked by** another epic.

If you try to close a blocked epic using the "Close epic" button, a confirmation message appears.
