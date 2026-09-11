---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Receive GitLab Duo flow lifecycle events on a project or group webhook.
title: Webhook callbacks
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249145) in GitLab 19.4 [with a feature flag](../../../administration/feature_flags/_index.md) named `duo_flow_callback_hooks`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

When you trigger a flow with the [Flows API](../../../api/duo_agent_platform_flows.md), GitLab can
send the flow lifecycle events to a webhook that you specify.
You can then react when the flow starts, finishes, or fails, instead of polling the API for the
flow status.

You can use webhooks in a project or a group. Child projects inherit webhooks. This means that a
webhook on a top-level group serves the flows of every project in that group.

## Prerequisites

For a webhook to receive flow events, ensure the following prerequisites are met:

- A webhook has been [created](../../project/integrations/webhooks.md#create-a-webhook) for the
  project or group, and [callbacks are turned on](#turn-on-callbacks-for-a-webhook) for it.
- The webhook belongs to the project or group the flow runs in, or to one of the ancestor groups
  of that project or group.
- The webhook is not a [system webhook](../../../administration/system_hooks.md).

## Turn on callbacks for a webhook

Prerequisites:

- For project webhooks, you must have the Maintainer or Owner role for the project.
- For group webhooks, you must have the Owner role for the group.

To turn on callbacks for a webhook:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Settings** > **Webhooks**.
1. Select **Add new webhook**, or select **Edit** for an existing webhook.
1. Under **GitLab Duo Agent Platform**, select the **Send Duo flow events to this webhook**
   checkbox.
1. Select **Add webhook** or **Save changes**.

You can also set the `duo_flow_callback_enabled` attribute with the
[project webhooks API](../../../api/project_webhooks.md) or the
[group webhooks API](../../../api/group_webhooks.md).
Use either API to list the webhooks and find the ID of the webhook you turned callbacks on for.

The roles required to turn callbacks on apply only to the webhook.
A user who triggers a flow that references the webhook does not need them.

## Receive callbacks for a flow

Prerequisites:

- You must meet the [prerequisites for flows](_index.md#prerequisites).

To receive callbacks, pass the webhook ID as the `callback_hook_id` attribute when you
[trigger a flow](../../../api/duo_agent_platform_flows.md#trigger-a-flow):

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true,
    "callback_hook_id": 42,
    "client_reference": "run-abc123"
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

For the events GitLab sends and the structure of each payload, see
[GitLab Duo flow events](../../project/integrations/webhook_events.md#gitlab-duo-flow-events).

### Correlate callbacks with a request

Use the optional `client_reference` attribute to correlate callbacks with the request that
triggered the flow.
GitLab echoes the value back in every callback for that flow and does not interpret it.

## Handling callbacks in your endpoint

Verify that a callback came from GitLab before you act on it.
Callbacks carry the same headers as every other webhook event, so configure a signing token on
the webhook and
[verify the signature](../../project/integrations/webhooks.md#verify-the-signature).

GitLab can deliver the same event more than once, so make your endpoint idempotent.
If your endpoint does not return a success or redirect response, GitLab retries the delivery up
to five times with a backoff.
Retries repeat the `event_id` from the original payload, so store the `event_id` values you have
processed and ignore an event you have already seen.
After the retries are exhausted, GitLab stops trying to deliver that event.

Repeated delivery failures count towards the webhook failure limits, and GitLab can
[automatically disable the webhook](../../project/integrations/webhooks.md#auto-disabled-webhooks).
When a webhook is
[temporarily disabled](../../project/integrations/webhooks.md#temporarily-disabled-webhooks),
GitLab holds the flow events for that webhook and delivers them after the disabled period ends.
GitLab holds an event a maximum of three times.
If the webhook is still disabled, GitLab does not deliver the event.
GitLab sends no flow events to a
[permanently disabled](../../project/integrations/webhooks.md#permanently-disabled-webhooks)
webhook.
To receive flow events again,
[re-enable the webhook](../../project/integrations/webhooks.md#re-enable-disabled-webhooks).

Before every delivery attempt, GitLab verifies that
[callbacks are still turned on](#turn-on-callbacks-for-a-webhook) for the webhook.
If you turn callbacks off while a flow is running, GitLab stops sending events for that flow,
including queued events and pending retries.

To see what GitLab sent and what your endpoint returned, view the
[webhook request history](../../project/integrations/webhooks.md#view-webhook-request-history).
The **Recent events** section displays all requests made to a webhook in the last two days.
This section displays only delivery attempts, so it does not include events that GitLab held or
did not deliver while the webhook was disabled.

## Related topics

- [GitLab Duo flow events](../../project/integrations/webhook_events.md#gitlab-duo-flow-events)
- [Flows API](../../../api/duo_agent_platform_flows.md)
- [Webhooks](../../project/integrations/webhooks.md)
