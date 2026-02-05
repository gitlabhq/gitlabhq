---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Ensure GitLab Duo is configured and operating correctly on GitLab Self-Managed.
title: Configure GitLab Duo on GitLab Self-Managed
gitlab_dedicated: no
---

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

## Prerequisites

- Silent Mode is [turned off](../../silent_mode/_index.md#turn-off-silent-mode).
- [Your instance is activated with an activation code](../../license.md#activate-gitlab-ee).
  - You cannot use a license key.
  - You cannot use GitLab Duo with an offline license, with the exception of [GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/_index.md).

## Turn on composite identity

You must turn on [composite identity](../../../user/duo_agent_platform/composite_identity.md)
so that the `@duo-developer` service account can perform actions
on behalf of users.

Prerequisites:

- Administrator access.

To turn on composite identity:

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. Under **GitLab Duo Agent Platform composite identity**, select **Turn on composite identity**.

## Allow outbound connections from the GitLab instance to GitLab Duo

- GitLab application nodes must connect to the GitLab Duo Workflow at `https://duo-workflow-svc.runway.gitlab.net` with HTTP/2. The application and service communicate with gRPC.
- For GitLab Duo Agent Platform features your firewalls and HTTP/S proxy servers must allow outbound
  connections to `duo-workflow-svc.runway.gitlab.net` on port `443` with `https://` and support for
  HTTP/2 traffic.

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

## Allow connections from the runner

For GitLab Duo Agent Platform features that make use of runners, like flows,
the runner must be able to connect to the GitLab instance.

The same [inbound connections from clients to the GitLab instance](#allow-inbound-connections-from-clients-to-the-gitlab-instance)
must be allowed as outbound connections from the runner to the GitLab instance.

In addition, runners must be able to connect to:

| Destination | Port | Purpose |
|-------------|------|---------|
| `registry.npmjs.org` | `443` | Download the Duo CLI package at runtime |
| `registry.gitlab.com` | `443` | Download the default Docker image (unless using a [custom image](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image)) |

If your organization cannot allow access to the public npm registry, you can use a
[custom Docker image](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image)
with the required dependencies already installed.

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

This is a [beta](../../../policy/development_stages_support.md) feature.

Prerequisites:

- You must be an administrator.

To run a health check:

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. In the upper-right corner, select **Run health check**.
1. Optional. In GitLab 17.5 and later, after the health check is complete, you can select **Download report** to save a detailed report of the health check results.

These tests are performed:

| Test                      | Description |
|---------------------------|-------------|
| AI Gateway                | GitLab Duo Self-Hosted models only. Tests whether the AI Gateway URL is configured as an environment variable. This connectivity is required for self-hosted model deployments that use the AI Gateway. |
| Network                   | Tests whether your instance can connect to `customers.gitlab.com` and `cloud.gitlab.com`.<br><br>If your instance cannot connect to either destination, ensure that your firewall or proxy server settings [allow connection](#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo). |
| Synchronization           | Tests whether your subscription: <br>- Has been activated with an activation code and can be synchronized with `customers.gitlab.com`.<br>- Has correct access credentials.<br>- Has been synchronized recently. If it hasn't or the access credentials are missing or expired, you can [manually synchronize](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data) your subscription data. |
| Code Suggestions          | GitLab Duo Self-Hosted models only. Tests whether Code Suggestions is available: <br>- Your license includes access to Code Suggestions.<br>- You have the necessary permissions to use the feature. |
| GitLab Duo Agent Platform | Tests whether the backend service is operational and accessible. This service is required for agentic features like the Agent Platform and GitLab Duo Chat (Agentic). |
| System exchange           | Tests whether Code Suggestions can be used in your instance. If the system exchange assessment fails, users might not be able to use GitLab Duo features. |

For GitLab instances earlier than version 17.10, if you are encountering any issues with the health check,
see the [troubleshooting page](../../../user/gitlab_duo/troubleshooting.md).

## Other hosting options

By default, GitLab Duo uses supported AI vendor language models and sends data through a cloud-based AI Gateway that's hosted by GitLab.

If you want to host your own language models or AI Gateway:

- You can [use GitLab Duo Self-Hosted to host the AI Gateway and use any of the supported self-hosted models](../../gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms).
  This option provides full control over your data and security.
- Use a [hybrid configuration](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration),
  where you host your own AI Gateway and models for some features, but configure other features to use the GitLab AI Gateway and vendor models.

## Hide sidebar widget that shows GitLab Duo Core availability (removed)

<!--- start_remove The following content will be removed on remove_date: '2026-02-11' -->

This feature was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210564) in GitLab 18.6.

<!--- end_remove -->
