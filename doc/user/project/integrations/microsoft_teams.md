---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Microsoft Teams service

## On Microsoft Teams

To enable Microsoft Teams integration you must create an incoming webhook integration on Microsoft
Teams by following the steps described in [Sending messages to Connectors and Webhooks](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using).

## On GitLab

After you set up Microsoft Teams, it's time to set up GitLab.

Navigate to the [Integrations page](overview.md#accessing-integrations)
and select the **Microsoft Teams Notification** service to configure it.
There, you will see a checkbox with the following events that can be triggered:

- Push
- Issue
- Confidential issue
- Merge request
- Note
- Tag push
- Pipeline
- Wiki page

At the end fill in your Microsoft Teams details:

| Field | Description |
| ----- | ----------- |
| **Webhook** | The incoming webhook URL which you have to set up on Microsoft Teams. |
| **Notify only broken pipelines** | If you choose to enable the **Pipeline** event and you want to be only notified about failed pipelines. |

After you are all done, click **Save changes** for the changes to take effect.

![Microsoft Teams configuration](img/microsoft_teams_configuration.png)
