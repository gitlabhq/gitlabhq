# Slack Service

Go to your project's **Settings > Services > Slack** and you will see a checkbox with the following events that can be triggered:

* Push
* Issue
* Merge request
* Note
* Tag push
* Build
* Wiki page

Below each of these event checkboxes you will have an input to insert which Slack channel do you want to send that event message,
`#general` channel is default.


![Slack configuration](img/slack_configuration.png)


| Field | Description |
| ----- | ----------- |
| `Webhook`   | The incoming webhook url which you have to setup on slack. (https://my.slack.com/services/new/incoming-webhook/) |
| `Username`   | Optional username which can be on messages sent to slack. |
| `notify only broken builds`    | Notify only about broken builds, when build events are marked to be sent.|


