---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: concepts, reference, howto
---

# Filtering outbound requests **(FREE SELF)**

To protect against the risk of data loss and exposure, GitLab administrators can now use outbound request filtering controls to restrict certain outbound requests made by the GitLab instance.

## Secure webhooks and integrations

Users with at least the Maintainer role can set up [webhooks](../user/project/integrations/webhooks.md) that are
triggered when specific changes occur in a project or group. When triggered, a `POST` HTTP request is sent to a URL. A webhook is
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

### Allow requests to the local network from webhooks and integrations

Prerequisite:

- You must have administrator access to the instance.

To prevent exploitation of insecure internal web services, all webhook and integration requests to the following local network addresses are not allowed:

- The current GitLab instance server address.
- Private network addresses, including `127.0.0.1`, `::1`, `0.0.0.0`, `10.0.0.0/8`, `172.16.0.0/12`,
  `192.168.0.0/16`, and IPv6 site-local (`ffc0::/10`) addresses.

To allow access to these addresses:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests**.
1. Select the **Allow requests to the local network from webhooks and integrations** checkbox.

### Prevent requests to the local network from system hooks

Prerequisite:

- You must have administrator access to the instance.

[System hooks](../administration/system_hooks.md) can make requests to the local network by default. To prevent system hook requests to the local network:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests**.
1. Clear the **Allow requests to the local network from system hooks** checkbox.

## Filter requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/377371) in GitLab 15.10.

Prerequisite:

- You must have administrator access to the GitLab instance.

To filter requests by blocking many requests:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests**.
1. Select the **Block all requests, except for IP addresses, IP ranges, and domain names defined in the allowlist** checkbox.

When this checkbox is selected, requests to the following are still not blocked:

- Core services like Geo, Git, GitLab Shell, Gitaly, PostgreSQL, and Redis.
- Object storage.
- IP addresses and domains in the [allowlist](#allow-outbound-requests-to-certain-ip-addresses-and-domains).

This setting is respected by the main GitLab application only, so other services like Gitaly can still make requests that break the rule.
Additionally, [some areas of GitLab](https://gitlab.com/groups/gitlab-org/-/epics/8029) do not respect outbound filtering
rules.

## Allow outbound requests to certain IP addresses and domains

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/44496) in GitLab 12.2.

Prerequisite:

- You must have administrator access to the instance.

To allow outbound requests to certain IP addresses and domains:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Outbound requests**.
1. In **Local IP addresses and domain names that hooks and integrations can access**, enter your IP addresses and domains.

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

## Troubleshooting

When filtering outbound requests, you might encounter the following issues.

### Configured URLs are blocked

You can only select the **Block all requests, except for IP addresses, IP ranges, and domain names defined in the allowlist** checkbox if no configured URLs would be blocked. Otherwise, you might get an error message that says the URL is blocked.

If you can't enable this setting, do one of the following:

- Disable the URL setting.
- Configure another URL, or leave the URL setting empty.
- Add the configured URL to the [allowlist](#allow-requests-to-the-local-network-from-webhooks-and-integrations).

### Public runner releases URL is blocked

Most GitLab instances have their `public_runner_releases_url` set to
`https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-runner/releases`,
which can prevent you from [filtering requests](#filter-requests).

To resolve this issue, [configure GitLab to no longer fetch runner release version data from GitLab.com](../user/admin_area/settings/continuous_integration.md#disable-runner-version-management).

### GitLab subscription management is blocked

When you [filter requests](#filter-requests), [GitLab subscription management](../subscriptions/self_managed/index.md)
is blocked.

To work around this problem, add `customers.gitlab.com:443` to the
[allowlist](#allow-outbound-requests-to-certain-ip-addresses-and-domains).
