---
stage: Foundations
group: Import and Integrate
description: Custom HTTP callbacks, used to send events.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting webhooks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Troubleshoot and resolve common issues with GitLab webhooks.

## Debug webhooks

Debug GitLab webhooks and capture payloads using these methods:

- [Public webhook inspection tools](#use-public-webhook-inspection-tools)
- [Webhook request and response details](webhooks.md#inspect-request-and-response-details)
- [GitLab Development Kit (GDK)](#use-the-gitlab-development-kit-gdk)
- [Private webhook receiver](#create-a-private-webhook-receiver)

For information about webhook events and JSON payloads, see [webhook events](webhook_events.md).

### Use public webhook inspection tools

Use public tools to inspect and test webhook payloads.
These tools provide catch-all endpoints for HTTP requests and respond with a `200 OK` status code.

WARNING:
Exercise caution when using public tools, as you might send sensitive data to external services.
Use test tokens and rotate any secrets inadvertently sent to third parties.
For enhanced privacy, [create a private webhook receiver](#create-a-private-webhook-receiver).

Public webhook inspection tools include:

<!-- vale gitlab_base.Spelling = NO -->
- [Beeceptor](https://beeceptor.com): Create a temporary HTTPS endpoint and inspect incoming payloads.
<!-- vale gitlab_base.Spelling = YES -->
- [Webhook.site](https://webhook.site): Review incoming payloads.
- [Webhook Tester](https://webhook-test.com): Inspect and debug incoming payloads.

### Use the GitLab Development Kit (GDK)

For a safer development environment, use the
[GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit) to work with
GitLab webhooks locally.
Use the GDK to send webhooks from your local GitLab instance to a webhook receiver on your machine.

To use this approach, install and configure the GDK.

### Create a private webhook receiver

Create your own private webhook receiver if you cannot send webhook payloads
to a [public receiver](#use-public-webhook-inspection-tools).

Prerequisites:

- Ruby is installed on your system.

To create a private webhook receiver:

1. Save this script as `print_http_body.rb`:

   ```ruby
   require 'webrick'

   server = WEBrick::HTTPServer.new(:Port => ARGV.first)
   server.mount_proc '/' do |req, res|
     puts req.body
   end

   trap 'INT' do
     server.shutdown
   end
   server.start
   ```

1. Choose an unused port (for example, `8000`) and start the script:

   ```shell
   ruby print_http_body.rb 8000
   ```

1. In GitLab, [configure the webhook](webhooks.md#configure-webhooks) with your
   receiver's URL (for example, `http://receiver.example.com:8000/`).
1. Select **Test**. You should see output similar to:

   ```plaintext
   {"before":"077a85dd266e6f3573ef7e9ef8ce3343ad659c4e","after":"95cd4a99e93bc4bbabacfa2cd10e6725b1403c60",<SNIP>}
   example.com - - [14/May/2014:07:45:26 EDT] "POST / HTTP/1.1" 200 0
   - -> /
   ```

NOTE:
To add this receiver, you might need to [allow requests to the local network](../../../security/webhooks.md).

## Resolve SSL certificate verification errors

When SSL verification is enabled, GitLab might fail to verify the SSL certificate of the webhook endpoint with the following error:

```plaintext
unable to get local issuer certificate
```

This error typically occurs when the root certificate is not issued by a trusted certificate
authority as determined by [CAcert.org](http://www.cacert.org/).

To resolve this issue:

1. Use [SSL Checker](https://www.sslshopper.com/ssl-checker.html) to identify specific errors.
1. Check for missing intermediate certificates, a common cause of verification failure.

## Webhook not triggered

> - Webhooks not triggered in Silent Mode [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393639) in GitLab 16.3.

If a webhook is not triggered, verify that:

- The webhook is not [disabled automatically](webhooks.md#auto-disabled-webhooks).
- The GitLab instance is not in [Silent Mode](../../../administration/silent_mode/_index.md).
- The **Push event activities limit** and **Push event hooks limit** settings in the
  [**Admin** area](../../../administration/settings/push_event_activities_limit.md) are set to a value greater than `0`.
