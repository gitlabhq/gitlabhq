---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Unify Circuit **(FREE)**

The Unify Circuit integration sends notifications from GitLab to a Circuit conversation.

## Set up Unify Circuit

In Unify Circuit, [add a webhook](https://www.circuit.com/unifyportalfaqdetail?articleId=164448) and
copy its URL.

In GitLab:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Unify Circuit**.
1. Turn on the **Active** toggle.
1. Select the checkboxes corresponding to the GitLab events you want to receive in Unify Circuit.
1. Paste the **Webhook URL** that you copied from the Unify Circuit configuration step.
1. Select the **Notify only broken pipelines** checkbox to notify only on failures.
1. In the **Branches for which notifications are to be sent** dropdown list, select which types of branches to send notifications for.
1. Select `Save changes` or optionally select **Test settings**.

Your Unify Circuit conversation now starts receiving GitLab event notifications.
