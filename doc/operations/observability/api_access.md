---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Access the GitLab Observability API to query traces, metrics, and logs programmatically.
ignore_in_report: true
title: Access the Observability API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

Use the GitLab Observability API to query traces, metrics, and logs,
and to manage dashboards and alerts programmatically.

## Prerequisites

- Observability must be enabled for your group.
  For setup instructions, see
  [Set up Observability on GitLab.com](setup_gitlab_com.md) or
  [Set up Observability on GitLab Self-Managed](setup_self_managed.md).
- You must have the Developer, Maintainer, or Owner role for the group.

## Get your API key

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Observability** > **API Keys**.
1. Copy your API key.

Use this key in the `SIGNOZ-API-KEY` header when you make API requests.

## API endpoint

The API endpoint depends on your GitLab offering.

### GitLab.com

Your API base URL follows this pattern:

```plaintext
https://<group_id>.gitlab-o11y.com
```

Replace `<group_id>` with your GitLab group ID.

### GitLab Self-Managed

Your API base URL is the same URL you configured as the
`o11y_service_url` for your group. For example:

```plaintext
http://<your-instance-ip>:8080
```

## Make API requests

Include your API key in the `SIGNOZ-API-KEY` header with every request.

The following example queries the health endpoint:

```shell
curl --header "SIGNOZ-API-KEY: <your_api_key>" \
  https://<group_id>.gitlab-o11y.com/api/v1/health
```

Replace `<your_api_key>` with the key from the **API Keys** page, and
`<group_id>` with your GitLab group ID (or your self-managed instance URL).

## Available API endpoints

GitLab Observability uses the SigNoz API.
For the complete list of available endpoints, request and response formats,
and usage examples, see the
[SigNoz API reference](https://signoz.io/api-reference/).

## Related topics

- [Send telemetry data to GitLab Observability](send.md)
- [Troubleshooting Observability](troubleshooting.md)
