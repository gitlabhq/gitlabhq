---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: concepts, reference, howto
---

# Webhooks and insecure internal web services **(FREE SELF)**

Users with at least the Maintainer role can set up [webhooks](../user/project/integrations/webhooks.md) that are
triggered when specific changes occur in a project. When triggered, a `POST` HTTP request is sent to a URL. A webhook is
usually configured to send data to a specific external web service, which processes the data in an appropriate way.

However, a webhook can be configured with a URL for an internal web service instead of an external web service.
When the webhook is triggered, non-GitLab web services running on your GitLab server or in its local network could be
exploited.

Webhook requests are made by the GitLab server itself and use a single optional secret token per hook for authorization
instead of:

- A user token.
- A repository-specific token.

As a result, these requests can have broader access than intended, including access to everything running on the server
that hosts the webhook including:

- The GitLab server.
- The API itself.
- For some webhooks, network access to other servers in that webhook server's local network, even if these services
  are otherwise protected and inaccessible from the outside world.

Webhooks can be used to trigger destructive commands using web services that don't require authentication. These webhooks
can get the GitLab server to make `POST` HTTP requests to endpoints that delete resources.

## Allow webhook and service requests to local network

To prevent exploitation of insecure internal web services, all webhook requests to the following local network addresses are not allowed:

- The current GitLab instance server address.
- Private network addresses, including `127.0.0.1`, `::1`, `0.0.0.0`, `10.0.0.0/8`, `172.16.0.0/12`,
  `192.168.0.0/16`, and IPv6 site-local (`ffc0::/10`) addresses.

To allow access to these addresses:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests**.
1. Select the **Allow requests to the local network from web hooks and services** checkbox.

## Prevent system hook requests to local network

[System hooks](../administration/system_hooks.md) are permitted to make requests to local network by default because
they are set up by administrators. To prevent system hook requests to the local network:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests**.
1. Clear the **Allow requests to the local network from system hooks** checkbox.

## Create an allowlist for local requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/44496) in GitLab 12.2

You can allow certain domains and IP addresses to be accessible to both system hooks and webhooks, even when local
requests are forbidden. To add these domains to the allowlist:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests** and add entries.

The entries can:

- Be separated by semicolons, commas, or whitespaces (including newlines).
- Be in different formats like hostnames, IP addresses, IP address ranges. IPv6 is supported. Hostnames that contain
  Unicode characters should use [Internationalized Domain Names in Applications](https://www.icann.org/en/icann-acronyms-and-terms/internationalized-domain-names-in-applications-en)
  (IDNA) encoding.
- Include ports. For example, `127.0.0.1:8080` only allows connections to port 8080 on `127.0.0.1`. If no port is specified,
  all ports on that IP address or domain are allowed. An IP address range allows all ports on all IP addresses in that
  range.
- Number no more than 1000 entries of no more than 255 characters for each entry.
- Not contain wildcards (for example, `*.example.com`).

For example:

```plaintext
example.com;gitlab.example.com
127.0.0.1,1:0:0:0:0:0:0:1
127.0.0.0/8 1:0:0:0:0:0:0:0/124
[1:0:0:0:0:0:0:1]:8080
127.0.0.1:8080
example.com:8080
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
