---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Ensure GitLab Duo is configured and operating correctly.
title: Configure GitLab Duo on a GitLab Self-Managed instance
gitlab_dedicated: no
---

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

## Prerequisites

- [Turn on beta and experimental features](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- Have both outbound and inbound connections allowed.
  Network firewalls might cause delay.
- [Ensure Silent Mode is turned off](../../administration/silent_mode/_index.md).
- [Activate your GitLab instance with an activation code](../../administration/license.md#activate-gitlab-ee).
  You cannot use a legacy license.
  Except for [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md),
  you also cannot use an offline license.
- Turn on composite identity.

For the best results, use GitLab 17.2 and later.
Earlier versions might continue to work, but performance might be degraded.

## Turn on composite identity

You must turn on [composite identity](../../user/duo_agent_platform/security.md),
so that the `@duo-developer` service account can perform actions
on behalf of users.

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **GitLab Duo**.
1. Under **GitLab Duo Agent Platform composite identity**, select **Turn on composite identity**.

## Allow outbound connections from the GitLab instance

 Check both your outbound and inbound settings:

- Your firewalls and HTTP/S proxy servers must allow outbound connections
  to `cloud.gitlab.com` and `customers.gitlab.com` on port `443` both with `https://`.
  These hosts are protected by Cloudflare. Update your firewall settings to allow traffic to
  all IP addresses in the [list of IP ranges Cloudflare publishes](https://www.cloudflare.com/ips/).
- To use an HTTP/S proxy, both `gitLab_workhorse` and `gitLab_rails` must have the necessary
  [web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) set.
- In multi-node GitLab installations, configure the HTTP/S proxy on all **Rails** and **Sidekiq** nodes.
- GitLab application nodes must connect to the GitLab Duo Workflow at `https://duo-workflow-svc.runway.gitlab.net` with HTTP/2. The application and service communicate with gRPC.

## Allow inbound connections from clients to the GitLab instance

Your GitLab instance must allow inbound connections from IDE clients.

1. Allow WebSocket Protocol upgrade requests with headers:
   - `Connection: upgrade`
   - `Upgrade: websocket`
   - `HTTP/2` protocol support
   - Standard WebSocket security headers: `Sec-WebSocket-*`
1. Enable `wss://` (WebSocket Secure) protocol support.
1. Add specific endpoints to allow:
   - Primary endpoint: `wss://<customer-instance>/-/cable`
   - Ensure `HTTP/2` protocol is not downgraded to `HTTP/1.1`.
   - Port: `443` (HTTPS/WSS)

If you have issues:

- Check for restrictions on WebSocket traffic to `wss://gitlab.example.com/-/cable` and other `.com` domains.
- If you use reverse proxies like Apache, you might see GitLab Duo Chat connection issues in your
  logs, like **WebSocket connection to .... failures**.

To resolve this issue, edit your proxy settings:

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## Run a health check for GitLab Duo

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997) in GitLab 17.3.
- [Download health check report added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032) in GitLab 17.5.

{{< /history >}}

You can determine if your instance meets the requirements to use GitLab Duo.
When the health check completes, it displays a pass or fail result and the types of issues.
If the health check fails any of the tests, users might not be able to use GitLab Duo features in your instance.

This is a [beta](../../policy/development_stages_support.md) feature.

Prerequisites:

- You must be an administrator.

To run a health check:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **GitLab Duo**.
1. In the upper-right corner, select **Run health check**.
1. Optional. In GitLab 17.5 and later, after the health check is complete, you can select **Download report** to save a detailed report of the health check results.

These tests are performed:

| Test | Description |
|-----------------|-------------|
| AI Gateway | GitLab Duo Self-Hosted models only. Tests whether the AI Gateway URL is configured as an environment variable. This connectivity is required for self-hosted model deployments that use the AI Gateway. |
| Network | Tests whether your instance can connect to `customers.gitlab.com` and `cloud.gitlab.com`.<br><br>If your instance cannot connect to either destination, ensure that your firewall or proxy server settings [allow connection](setup.md). |
| Synchronization | Tests whether your subscription is properly synchronized: <br>- **License**: Has been activated with an online cloud license (not offline or legacy license).<br>- **Subscription data**: Has been synchronized with `customers.gitlab.com` recently (within the last 72 hours).<br>- **Access credentials**: Valid access token exists and has not expired.<br><br>If synchronization fails, you can [manually synchronize](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data) your subscription data. |
| Code Suggestions | GitLab Duo Self-Hosted models only. Tests whether Code Suggestions is available: <br>- Your license includes access to Code Suggestions.<br>- You have the necessary permissions to use the feature. |
| GitLab Duo Agent Platform | Tests whether the backend service is operational and accessible. This service is required for agentic features like the Agent Platform and GitLab Duo Chat (Agentic). |
| System exchange | Tests end-to-end authentication and connectivity with the AI Gateway by performing a real code completion request. This test verifies that users can successfully use GitLab Duo features like Code Suggestions in their IDE. If this test fails, users will not be able to use GitLab Duo features. |

For GitLab instances earlier than version 17.10, if you are encountering any issues with the health check,
see the [troubleshooting page](../../user/gitlab_duo/troubleshooting.md).

## Other hosting options

By default, GitLab Duo uses supported AI vendor language models and sends data through a cloud-based AI gateway that's hosted by GitLab.

If you want to host your own language models or AI gateway:

- You can [use GitLab Duo Self-Hosted to host the AI gateway and use any of the supported self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms).
  This option provides full control over your data and security.
- Use a [hybrid configuration](../../administration/gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration),
  where you host your own AI gateway and models for some features, but configure other features to use the GitLab AI gateway and vendor models.

## Hide sidebar widget that shows GitLab Duo Core availability (removed)

<!--- start_remove The following content will be removed on remove_date: '2026-02-11' -->

This feature was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210564) in GitLab 18.6.

<!--- end_remove -->
