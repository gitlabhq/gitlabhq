---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Escalation Policies **(PREMIUM)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4638) in [GitLab Premium](https://about.gitlab.com/pricing/) 14.1.

Escalation Policies protect your company from missed critical alerts. Escalation Policies contain
time-boxed steps that automatically page the next responder in the escalation step if the responder
in the previous step has not responded. You can create an escalation policy in the GitLab project
where you manage [On-call schedules](oncall_schedules.md).

## Add an escalation policy

If you have at least Maintainer [permissions](../../user/permissions.md),
you can create an escalation policy:

1. Go to **Operations > Escalation Policies** and select **Add an escalation policy**.
1. In the **Add escalation policy** form, enter the policy's name and description, and create
   escalation rules to follow when a primary responder misses an alert.
1. Select **Add escalation policy**.

![Escalation Policy](img/escalation_policy_v14_1.png)

### Edit an escalation policy

Follow these steps to update an escalation policy:

1. Go to **Operations > Escalation Policies** and select the **Pencil** icon on the top right of the
   policy card, across from the policy name.
1. In the **Edit policy** form, edit the information you wish to update.
1. Select the **Edit policy** button to save your changes.

### Delete an escalation policy

Follow these steps to delete a policy:

1. Go to **Operations > Escalation Policies** and select the **Trash Can** icon on the top right of
   the policy card.
1. In the **Delete escalation policy** window, select the **Delete escalation policy** button.
