---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Unify Circuit
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The Unify Circuit integration sends notifications from GitLab to a Circuit conversation.

## Set up Unify Circuit

In Unify Circuit, [add a webhook](https://www.circuit.com/unifyportalfaqdetail?articleId=164448) and
copy its URL.

In GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Unify Circuit**.
1. Turn on the **Active** toggle.
1. Select the checkboxes corresponding to the GitLab events you want to receive in Unify Circuit.
1. Paste the **Webhook URL** that you copied from the Unify Circuit configuration step.
1. Select the **Notify only broken pipelines** checkbox to notify only on failures.
1. In the **Branches for which notifications are to be sent** dropdown list, select which types of branches to send notifications for.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

Your Unify Circuit conversation now starts receiving GitLab event notifications.
