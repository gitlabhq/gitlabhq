---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Monitor application performance and troubleshoot performance issues.
ignore_in_report: true
title: Set up Observability on GitLab.com
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

To set up GitLab Observability on GitLab.com, enable GitLab Observability for your group.

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the group.

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Observability** > **Setup**.
1. Select **Enable Observability**.
1. After enabling, your OpenTelemetry (OTEL) endpoint URL is generated and displayed on the page.

Copy the OTEL endpoint URL to use when instrumenting your applications.

## Next steps

- [Send your telemetry data to GitLab Observability](send.md).
- [Show CI/CD pipeline telemetry](ci_cd.md).
- [Get troubleshooting information](troubleshooting.md).
